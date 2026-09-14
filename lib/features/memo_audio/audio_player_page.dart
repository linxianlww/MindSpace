import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/file_types.dart';
import '../../../core/di/providers.dart';
import '../../../core/utils/ms_date_utils.dart';
import '../../../core/utils/subtitle_parser.dart';
import '../../../core/utils/uuid_utils.dart';
import '../share/share_service.dart';
import '../home/home_provider.dart';
import 'audio_provider.dart';
import 'audio_recorder_page.dart';
import 'widgets/audio_trimmer.dart';
import 'widgets/subtitle_view.dart';
import 'widgets/waveform_view.dart';

/// 音频播放/详情页。
class AudioPlayerPage extends ConsumerWidget {
  const AudioPlayerPage({super.key, required this.memoId});
  final String memoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memoAsync = ref.watch(memoDetailProvider(memoId));
    return Scaffold(
      appBar: AppBar(
        // 与其它铭记页一致：标题跟随重命名实时刷新。
        title: Text(
          memoAsync.maybeWhen(
            data: (m) => m?.title ?? '音频铭记',
            orElse: () => '音频铭记',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            onPressed: () {
              final m = memoAsync.value;
              final path = m?.metadata['originalPath'] as String?;
              if (path != null) {
                ref.read(shareServiceProvider).shareFile(path);
              }
            },
          ),
        ],
      ),
      body: memoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (memo) {
          if (memo == null) return const Center(child: Text('铭记不存在'));
          final hasAudio = memo.metadata['originalPath'] != null;
          if (!hasAudio) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('还没有音频'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => AudioRecorderPage(memoId: memoId),
                      ),
                    ),
                    icon: const Icon(Icons.mic),
                    label: const Text('去录音'),
                  ),
                ],
              ),
            );
          }
          return _PlayerBody(memoId: memoId);
        },
      ),
    );
  }
}

class _PlayerBody extends ConsumerWidget {
  const _PlayerBody({required this.memoId});
  final String memoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memo = ref.watch(memoDetailProvider(memoId)).value!;
    // 播放器以 memoId 为 key：裁剪/改名等保存不会重建播放器、中断播放。
    final player = ref.watch(audioPlayerProvider(memoId));
    final notifier = ref.read(audioPlayerProvider(memoId).notifier);

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // 面板区可收缩：横屏/小屏高度不足时内部滚动，防止 RenderFlex 溢出。
          Flexible(
            flex: 0,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Column(
                  children: [
                    Text(memo.title,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    // 加载中 / 初始化失败的状态提示，避免"点击无反应"。
                    if (player.error != null) ...[
                      Card(
                        color: Theme.of(context)
                            .colorScheme
                            .errorContainer
                            .withValues(alpha: 0.6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(player.error!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onErrorContainer)),
                              ),
                              TextButton(
                                onPressed: notifier.retry,
                                child: const Text('重试'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else if (!player.ready) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 10),
                          Text('正在加载音频…',
                              style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    PlaybackWaveform(
                      wave: player.wave,
                      positionMs: player.positionMs,
                      // 波形进度条按裁剪后有效时长绘制。
                      durationMs: player.durationMs,
                      // seek 回调统一绝对时间轴坐标（未裁剪时 trimStart 为 0）。
                      onSeek: (ms) => notifier.seekTo(
                          ms + (player.trimStartMs ?? 0)),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(MsDateUtils.formatDuration(player.positionMs)),
                        Text(MsDateUtils.formatDuration(player.durationMs)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          iconSize: 30,
                          icon: Icon(
                              player.looping ? Icons.repeat_one : Icons.repeat),
                          color: player.looping
                              ? Theme.of(context).colorScheme.primary
                              : null,
                          onPressed: notifier.toggleLoop,
                        ),
                        const SizedBox(width: 8),
                        FloatingActionButton(
                          onPressed: notifier.toggle,
                          child: Icon(player.playing
                              ? Icons.pause
                              : Icons.play_arrow),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<double>(
                          icon: Text('${player.speed}x',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          onSelected: notifier.setSpeed,
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 0.75, child: Text('0.75x')),
                            PopupMenuItem(value: 1.0, child: Text('1.0x')),
                            PopupMenuItem(value: 1.25, child: Text('1.25x')),
                            PopupMenuItem(value: 1.5, child: Text('1.5x')),
                            PopupMenuItem(value: 2.0, child: Text('2.0x')),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: () => showModalBottomSheet(
                            context: context,
                            showDragHandle: true,
                            // 横屏（高度受限）下允许 sheet 占满全屏并内部滚动。
                            isScrollControlled: true,
                            builder: (_) => SafeArea(
                              child: SingleChildScrollView(
                                child: AudioTrimmer(
                                  memoId: memoId,
                                  // 滑块坐标始终基于文件原始全长。
                                  durationMs: player.fullDurationMs > 0
                                      ? player.fullDurationMs
                                      : player.durationMs,
                                  initialStart: player.trimStartMs,
                                  initialEnd: player.trimEndMs,
                                  onApply: notifier.setTrimWindow,
                                ),
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.content_cut),
                          label: const Text('裁剪'),
                        ),
                        TextButton.icon(
                          onPressed: () => _importSubtitle(context, ref, memoId),
                          icon: const Icon(Icons.subtitles_outlined),
                          label: const Text('导入字幕'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const TabBar(tabs: [Tab(text: '字幕'), Tab(text: '信息')]),
          Expanded(
            child: TabBarView(
              children: [
                SubtitleView(
                  subs: player.subs,
                  activeIndex: player.activeSubIndex,
                  onTap: notifier.jumpToSubtitle,
                ),
                _InfoTab(
                  memoId: memoId,
                  // 信息页时长以播放器实时状态为准；播放器未就绪时回退
                  // 到持久化 meta 中的旧值。
                  durationMs: player.ready ? player.durationMs : null,
                  trimStartMs: player.trimStartMs,
                  trimEndMs: player.trimEndMs,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _importSubtitle(
      BuildContext context, WidgetRef ref, String memoId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['lrc', 'srt', 'txt'],
    );
    final path = result?.files.single.path;
    if (path == null) return;
    final raw = await ref.read(fileSystemDatasourceProvider).readString(path);
    final ext = FileTypes.extensionOf(path);
    final parsed = SubtitleParser.parse(memoId, raw, ext);
    // 为缺少 id 的条目兜底（解析器已生成，这里确保非空）。
    final items = parsed
        .map((s) => s.id.isEmpty ? s.copyWith(id: UuidUtils.newId()) : s)
        .toList();
    await ref.read(memoRepositoryProvider).replaceSubtitles(items);
    ref.invalidate(memoDetailProvider(memoId));
    // 播放器以 memoId 为 key 且不随 memo 变化重建，必须显式刷新字幕列表，
    // 否则“提示成功但字幕区仍空白”。
    await ref.read(audioPlayerProvider(memoId).notifier).reloadSubtitles();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('已导入 ${items.length} 条字幕')));
    }
  }
}

class _InfoTab extends ConsumerWidget {
  const _InfoTab({
    required this.memoId,
    this.durationMs,
    this.trimStartMs,
    this.trimEndMs,
  });
  final String memoId;
  final int? durationMs;
  final int? trimStartMs;
  final int? trimEndMs;

  static String _fileNameOf(String? path) {
    if (path == null || path.isEmpty) return '-';
    final idx = path.lastIndexOf('/');
    return idx >= 0 && idx < path.length - 1 ? path.substring(idx + 1) : path;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memo = ref.watch(memoDetailProvider(memoId)).value;
    if (memo == null) return const SizedBox.shrink();
    final meta = memo.metadata;
    final dur = durationMs ?? (meta['durationMs'] as int?) ?? 0;
    final tStart = trimStartMs ?? meta['trimStartMs'] as int?;
    final tEnd = trimEndMs ?? meta['trimEndMs'] as int?;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ListTile(
          leading: const Icon(Icons.title),
          title: const Text('标题'),
          subtitle: Text(memo.title),
        ),
        ListTile(
          leading: const Icon(Icons.timer_outlined),
          title: const Text('时长'),
          subtitle: Text(MsDateUtils.formatDuration(dur)),
        ),
        ListTile(
          leading: const Icon(Icons.audiotrack_outlined),
          title: const Text('原始文件'),
          // 隐私考虑：只展示文件名，不展示应用内部完整路径。
          subtitle: Text(meta['originalName'] as String? ??
              _fileNameOf(meta['originalPath'] as String?)),
        ),
        if (tStart != null || tEnd != null)
          ListTile(
            leading: const Icon(Icons.content_cut),
            title: const Text('裁剪区间'),
            subtitle: Text(
                '${MsDateUtils.formatDuration(tStart ?? 0)} ~ ${MsDateUtils.formatDuration(tEnd ?? dur)}'),
          ),
        ListTile(
          leading: const Icon(Icons.schedule),
          title: const Text('创建时间'),
          subtitle: Text(MsDateUtils.formatFull(memo.createdAt)),
        ),
      ],
    );
  }
}