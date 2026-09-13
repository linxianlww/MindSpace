import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/state_views.dart';
import '../share/share_service.dart';
import '../home/home_provider.dart';
import 'media_provider.dart';
import 'media_viewer_page.dart';
import 'widgets/media_grid.dart';

/// 媒体集编辑页：增删媒体、拖拽排序，点击进入查看器（裁剪/旋转/备注）。
class MediaEditorPage extends ConsumerStatefulWidget {
  const MediaEditorPage({super.key, required this.memoId});
  final String memoId;

  @override
  ConsumerState<MediaEditorPage> createState() => _MediaEditorPageState();
}

class _MediaEditorPageState extends ConsumerState<MediaEditorPage> {
  bool _editMode = true;

  @override
  Widget build(BuildContext context) {
    final memoAsync = ref.watch(memoDetailProvider(widget.memoId));
    final itemsAsync = ref.watch(mediaItemsProvider(widget.memoId));

    return Scaffold(
      appBar: AppBar(
        title: Text(memoAsync.maybeWhen(
            data: (m) => m?.title ?? '媒体集', orElse: () => '媒体集')),
        actions: [
          IconButton(
            tooltip: _editMode ? '完成' : '管理',
            icon: Icon(_editMode ? Icons.check_circle_outline : Icons.tune),
            onPressed: () => setState(() => _editMode = !_editMode),
          ),
          IconButton(
            tooltip: '打包分享',
            icon: const Icon(Icons.ios_share),
            onPressed: () async {
              final paths = await ref
                  .read(mediaControllerProvider)
                  .allPaths(widget.memoId);
              if (paths.isNotEmpty) {
                ref.read(shareServiceProvider).shareFiles(paths);
              }
            },
          ),
        ],
      ),
      body: itemsAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
            message: '$e',
            onRetry: () => ref.invalidate(mediaItemsProvider(widget.memoId))),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.add_photo_alternate_outlined,
              title: '还没有媒体',
              subtitle: '点击右下角添加图片或视频',
              actionLabel: '添加媒体',
              onAction: _add,
            );
          }
          return MediaGrid(
            items: items,
            editMode: _editMode,
            onTap: (i) => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MediaViewerPage(
                  memoId: widget.memoId,
                  initialIndex: i,
                ),
              ),
            ),
            onReorder: (from, to) => ref
                .read(mediaControllerProvider)
                .reorder(widget.memoId, items, from, to),
            onRemove: (item) async {
              await ref.read(mediaControllerProvider).remove(item);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('添加媒体'),
      ),
    );
  }

  Future<void> _add() async {
    final folderId =
        ref.read(memoDetailProvider(widget.memoId)).value?.folderId;
    final n = await ref
        .read(mediaControllerProvider)
        .addFiles(widget.memoId, folderId);
    if (mounted && n > 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('已添加 $n 个媒体')));
    }
  }
}
