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
        title: const Text('音频铭记'),
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
                        builder: (_) =>
                            AudioRecorderPage(memoId: memoId),
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
    final player = ref.watch(audioPlayerProvider(memo));
    final notifier = ref.read(audioPlayerProvider(memo).notifier);

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Column(
              children: [
                Text(memo.title,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                PlaybackWaveform(
                  wave: player.wave,
                  positionMs: player.positionMs,
                  durationMs: player.durationMs,
                  onSeek: notifier.seekTo,
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
                      icon: Icon(player.looping
                          ? Icons.repeat_one
                          : Icons.repeat),
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
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
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
                        builder: (_) => AudioTrimmer(
                          durationMs: player.durationMs,
                          initialStart: player.trimStartMs,
                          initialEnd: player.trimEndMs,
                          onPreview: notifier.seekTo,
                          onApply: notifier.setTrimWindow,
                        ),
                      ),
                      icon: const Icon(Icons.content_cut),
                      label: const Text('裁剪'),
                    ),
                    TextButton.icon(
                      onPressed: () => _importSubtitle(context, ref, memo.id),
                      icon: const Icon(Icons.subtitles_outlined),
                      label: const Text('导入字幕'),
                    ),
                  ],
                ),
              ],
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
                _InfoTab(memoId: memoId),
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
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('已导入 ${items.length} 条字幕')));
    }
  }
}

class _InfoTab extends ConsumerWidget {
  const _InfoTab({required this.memoId});
  final String memoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memo = ref.watch(memoDetailProvider(memoId)).value;
    if (memo == null) return const SizedBox.shrink();
    final meta = memo.metadata;
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
          subtitle: Text(MsDateUtils.formatDuration(
              (meta['durationMs'] as int?) ?? 0)),
        ),
        ListTile(
          leading: const Icon(Icons.folder_zip_outlined),
          title: const Text('原始文件'),
          subtitle: Text('${meta['originalPath'] ?? '-'}'),
        ),
        if (meta['trimStartMs'] != null)
          ListTile(
            leading: const Icon(Icons.content_cut),
            title: const Text('裁剪区间'),
            subtitle: Text(
                '${MsDateUtils.formatDuration(meta['trimStartMs'] as int)} ~ ${MsDateUtils.formatDuration((meta['trimEndMs'] as int?) ?? 0)}'),
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
