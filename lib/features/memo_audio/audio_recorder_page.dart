import 'package:mindspace/ui/design_system/app_design_system.dart';
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

  /// AppScaffold 子树内的宿主 context（弹层 API 需要脚手架下方的 context）。
  BuildContext? _hostCtx;

  BuildContext? get _pageCtx {
    final ctx = _hostCtx;
    return (ctx != null && ctx.mounted) ? ctx : null;
  }

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

    return AppScaffold(
      topBar: const AppHeader(title: '录制音频'),
      body: memoAsync.when(
        loading: () => const Center(child: AppCircleProgress()),
        error: (e, _) => Center(child: MiuixText('$e')),
        data: (memo) {
          if (memo == null) return const Center(child: MiuixText('铭记不存在'));
          return Builder(
            builder: (hostCtx) {
              _hostCtx = hostCtx;
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Spacer(),
                    MiuixText(
                      MsDateUtils.formatDuration(rec.elapsedMs),
                      style: MiuixTheme.of(context)
                          .textStyles
                          .title1
                          .copyWith(fontFeatures: const [
                        FontFeature.tabularFigures(),
                      ]),
                    ),
                    const SizedBox(height: 24),
                    LiveWaveform(controller: notifier.controller),
                    const Spacer(),
                    MiuixText(
                      switch (rec.status) {
                        RecStatus.recording => '正在录音…',
                        RecStatus.paused => '已暂停',
                        RecStatus.stopped => '已停止',
                        RecStatus.idle => '点击开始录音',
                      },
                      style: TextStyle(
                          color: MiuixTheme.of(context)
                              .colors
                              .onSurfaceVariantSummary),
                    ),
                    const SizedBox(height: 28),
                    // 初始/停止态只有主按钮：直接全宽居中，不再沿用录制态
                    // 的横排布局（原实现两侧留 16/76 不等占位，按钮偏左）。
                    if (rec.status == RecStatus.recording ||
                        rec.status == RecStatus.paused)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 放弃是破坏性动作：错误色文字按钮（旧实现为
                          // 主色填充底 + onErrorContainer 内容，对比度错误）
                          AppButton(
                            variant: AppButtonStyle.outlined,
                            onPressed: () async {
                              // await 前先捕获路由，避免跨异步使用 BuildContext。
                              final router = GoRouter.of(context);
                              await notifier.cancel();
                              router.pop();
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                HiuiIcon(HiuiIcons.trash,
                                    color: MiuixTheme.of(context).colors.error),
                                const SizedBox(width: 8),
                                MiuixText('放弃',
                                    style: TextStyle(
                                        color: MiuixTheme.of(context)
                                            .colors
                                            .error)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          _mainButton(rec, notifier, memo.folderId),
                          const SizedBox(width: 16),
                          if (rec.status == RecStatus.recording)
                            MiuixFloatingActionButton(
                              onPressed: notifier.pause,
                              child: HiuiIcon(HiuiIcons.pause,
                                  color:
                                      MiuixTheme.of(context).colors.onPrimary),
                            )
                          else if (rec.status == RecStatus.paused)
                            MiuixFloatingActionButton(
                              onPressed: () async {
                                await _ensurePath(memo.folderId);
                                if (_targetPath != null) {
                                  final ok =
                                      await notifier.resume(_targetPath!);
                                  final ctx = _pageCtx;
                                  if (!ok && ctx != null && ctx.mounted) {
                                    AppSnackbar.show(ctx,
                                        message: '需要麦克风权限才能录音');
                                  }
                                }
                              },
                              child: HiuiIcon(HiuiIcons.mic,
                                  color:
                                      MiuixTheme.of(context).colors.onPrimary),
                            ),
                        ],
                      )
                    else
                      _mainButton(rec, notifier, memo.folderId),
                    const SizedBox(height: 32),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _mainButton(
      RecorderValue rec, AudioRecorderNotifier n, String? folderId) {
    if (rec.status == RecStatus.recording || rec.status == RecStatus.paused) {
      return MiuixFloatingActionButton(
        minWidth: 72,
        minHeight: 72,
        onPressed: () => _stop(n),
        containerColor: MiuixTheme.of(context).colors.error,
        // error 容器上的图标取 onError（主题语义色）
        child: HiuiIcon(HiuiIcons.stop,
            color: MiuixTheme.of(context).colors.onError),
      );
    }
    return MiuixFloatingActionButton(
      minWidth: 72,
      minHeight: 72,
      onPressed: () async {
        final ok = await _requestMic();
        if (!ok) {
          final ctx = _pageCtx;
          if (ctx != null && ctx.mounted) {
            AppSnackbar.show(ctx, message: '需要麦克风权限才能录音');
          }
          return;
        }
        await _ensurePath(folderId);
        if (_targetPath == null) return;
        try {
          final started = await n.start(_targetPath!);
          final ctx = _pageCtx;
          if (!started && ctx != null && ctx.mounted) {
            AppSnackbar.show(ctx, message: '需要麦克风权限才能录音');
          }
        } catch (_) {
          final ctx = _pageCtx;
          if (ctx != null && ctx.mounted) {
            AppSnackbar.show(ctx, message: '录音启动失败，请重试');
          }
        }
      },
      child: HiuiIcon(HiuiIcons.record,
          color: MiuixTheme.of(context).colors.onPrimary),
    );
  }

  Future<void> _stop(AudioRecorderNotifier n) async {
    final result = await n.stop();
    // 录音失败（插件返回空路径）时不再用目标路径兑底：否则会把一个
    // 不存在的文件写进元数据，导致后续播放/导入完全无效。
    final savedPath = result.path;
    if (savedPath == null) {
      final ctx = _pageCtx;
      if (ctx != null && ctx.mounted) {
        AppSnackbar.show(ctx, message: '录音保存失败，请重试');
      }
      return;
    }
    final memo = await ref.read(memoRepositoryProvider).findById(widget.memoId);
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
    // 刷新详情缓存，避免播放页读到录音前的旧元数据（表现为"没有音频"）。
    ref.invalidate(memoDetailProvider(widget.memoId));
    if (mounted) {
      context.pushReplacement('/memo/audio/${widget.memoId}');
    }
  }
}
