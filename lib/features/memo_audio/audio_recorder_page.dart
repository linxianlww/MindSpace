import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

import '../../../core/di/providers.dart';
import '../../../core/storage/mindspace_storage.dart';
import '../../../core/utils/audio_probe.dart';
import '../../../core/utils/ms_date_utils.dart';
import '../home/home_provider.dart';
import 'audio_provider.dart';
import 'widgets/waveform_view.dart';

/// 录音页：开始/暂停/继续/停止 + 计时 + 实时波形，完成后进入播放页。
class AudioRecorderPage extends ConsumerStatefulWidget {
  const AudioRecorderPage({super.key, required this.memoId});
  final String memoId;

  @override
  ConsumerState<AudioRecorderPage> createState() => _AudioRecorderPageState();
}

class _AudioRecorderPageState extends ConsumerState<AudioRecorderPage> {
  String? _targetPath;

  Future<void> _ensurePath(String? folderId) async {
    final dir = MindspaceStorage.instance
        .audioDir(memoId: widget.memoId, folderId: folderId);
    MindspaceStorage.instance.ensureDir(dir);
    _targetPath = p.join(dir, 'original.m4a');
  }

  Future<bool> _requestMic() async {
    // permission_handler 会等到用户对权限弹窗作出选择；
    // 仅靠插件的 checkPermission 在首次授权时可能拿到未决结果。
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  @override
  Widget build(BuildContext context) {
    final rec = ref.watch(recorderProvider);
    final notifier = ref.read(recorderProvider.notifier);
    final memoAsync = ref.watch(memoDetailProvider(widget.memoId));
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('录制音频')),
      body: memoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (memo) {
          if (memo == null) return const Center(child: Text('铭记不存在'));
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                Text(
                  MsDateUtils.formatDuration(rec.elapsedMs),
                  style: Theme.of(context)
                      .textTheme
                      .displaySmall
                      ?.copyWith(fontFeatures: const [
                        FontFeature.tabularFigures(),
                      ]),
                ),
                const SizedBox(height: 24),
                LiveWaveform(controller: notifier.controller),
                const Spacer(),
                Text(
                  switch (rec.status) {
                    RecStatus.recording => '正在录音…',
                    RecStatus.paused => '已暂停',
                    RecStatus.stopped => '已停止',
                    RecStatus.idle => '点击开始录音',
                  },
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (rec.status == RecStatus.recording ||
                        rec.status == RecStatus.paused)
                      FloatingActionButton.extended(
                        heroTag: 'cancel',
                        backgroundColor: scheme.errorContainer,
                        foregroundColor: scheme.onErrorContainer,
                        onPressed: () async {
                          // await 前先捕获路由，避免跨异步使用 BuildContext。
                          final router = GoRouter.of(context);
                          await notifier.cancel();
                          router.pop();
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('放弃'),
                      ),
                    const SizedBox(width: 16),
                    _mainButton(rec, notifier, memo.folderId),
                    const SizedBox(width: 16),
                    if (rec.status == RecStatus.recording)
                      FloatingActionButton(
                        heroTag: 'pause',
                        onPressed: notifier.pause,
                        child: const Icon(Icons.pause),
                      )
                    else if (rec.status == RecStatus.paused)
                      FloatingActionButton(
                        heroTag: 'resume',
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await _ensurePath(memo.folderId);
                          if (_targetPath != null) {
                            final ok = await notifier.resume(_targetPath!);
                            if (!ok) {
                              messenger.showSnackBar(
                                const SnackBar(
                                    content: Text('需要麦克风权限才能录音')),
                              );
                            }
                          }
                        },
                        child: const Icon(Icons.mic),
                      )
                    else
                      const SizedBox(width: 56),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _mainButton(
      RecorderValue rec, AudioRecorderNotifier n, String? folderId) {
    if (rec.status == RecStatus.recording || rec.status == RecStatus.paused) {
      return FloatingActionButton.large(
        heroTag: 'stop',
        backgroundColor: Theme.of(context).colorScheme.error,
        onPressed: () => _stop(n),
        child: const Icon(Icons.stop, color: Colors.white),
      );
    }
    return FloatingActionButton.large(
      heroTag: 'start',
      onPressed: () async {
        final ok = await _requestMic();
        if (!ok) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('需要麦克风权限才能录音')),
            );
          }
          return;
        }
        await _ensurePath(folderId);
        if (_targetPath == null) return;
        try {
          final started = await n.start(_targetPath!);
          if (!started && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('需要麦克风权限才能录音')),
            );
          }
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('录音启动失败，请重试')),
            );
          }
        }
      },
      child: const Icon(Icons.fiber_manual_record),
    );
  }

  Future<void> _stop(AudioRecorderNotifier n) async {
    final result = await n.stop();
    // 录音失败（插件返回空路径）时不再用目标路径兑底：否则会把一个
    // 不存在的文件写进元数据，导致后续播放/导入完全无效。
    final savedPath = result.path;
    if (savedPath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('录音保存失败，请重试')),
        );
      }
      return;
    }
    final memo =
        await ref.read(memoRepositoryProvider).findById(widget.memoId);
    if (memo == null) return;
    // 用解码器校准真实时长：计时器可能因编码开销存在误差，避免信息页
    // 显示 00:00 或与播放实际长度不一致。probe 失败时回退计时值。
    final probed = await probeAudioDuration(savedPath);
    await ref.read(memoRepositoryProvider).save(memo.copyWith(
      title: memo.title == '新录音'
          ? '录音 ${MsDateUtils.format(memo.createdAt)}'
          : memo.title,
      metadata: {
        ...memo.metadata,
        'originalPath': savedPath,
        'waveform': result.wave,
        'durationMs': probed > 0 ? probed : result.elapsedMs,
      },
    ));
    // 刷新详情缓存，避免播放页读到录音前的旧元数据（表现为“没有音频”）。
    ref.invalidate(memoDetailProvider(widget.memoId));
    if (mounted) {
      context.pushReplacement('/memo/audio/${widget.memoId}');
    }
  }
}
