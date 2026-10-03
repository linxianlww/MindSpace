import 'package:mindspace/ui/design_system/app_design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../share/share_service.dart';
import '../home/home_provider.dart';
import 'media_provider.dart';
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

  /// AppScaffold 子树内的宿主 context（弹层 API 需要脚手架下方的 context）。
  BuildContext? _hostCtx;

  /// 页面级弹层调用的宿主 context；未就绪时返回 null。
  BuildContext? get _pageCtx {
    final ctx = _hostCtx;
    return (ctx != null && ctx.mounted) ? ctx : null;
  }

  @override
  Widget build(BuildContext context) {
    final memoAsync = ref.watch(memoDetailProvider(widget.memoId));
    final itemsAsync = ref.watch(mediaItemsProvider(widget.memoId));

    return AppScaffold(
      topBar: AppHeader(
        title: memoAsync.maybeWhen(
            data: (m) => m?.title ?? '媒体集', orElse: () => '媒体集'),
        alwaysSmall: true,
        actions: [
          AppTapIcon(
            tooltip: _editMode ? '完成' : '管理',
            icon: HiuiIcon(_editMode ? HiuiIcons.checkCircle : HiuiIcons.tune),
            onPressed: () => setState(() => _editMode = !_editMode),
          ),
          AppTapIcon(
            tooltip: '打包分享',
            icon: const HiuiIcon(HiuiIcons.share),
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
      body: Builder(builder: (hostCtx) {
        _hostCtx = hostCtx;
        return itemsAsync.when(
          loading: () => const LoadingState(),
          error: (e, _) => ErrorState(
              message: '$e',
              onRetry: () => ref.invalidate(mediaItemsProvider(widget.memoId))),
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                icon: HiuiIcons.image,
                title: '还没有媒体',
                subtitle: '点击右下角添加图片或视频',
                actionLabel: '添加媒体',
                onAction: _add,
              );
            }
            return MediaGrid(
              items: items,
              editMode: _editMode,
              onTap: _openViewer,
              onReorder: (from, to) => ref
                  .read(mediaControllerProvider)
                  .reorder(widget.memoId, items, from, to),
              onRemove: (item) async {
                await ref.read(mediaControllerProvider).remove(item);
              },
            );
          },
        );
      }),
      floatingActionButton: MiuixFloatingActionButton(
        onPressed: _add,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HiuiIcon(HiuiIcons.image,
                color: MiuixTheme.of(context).colors.onPrimary),
            const SizedBox(width: 8),
            // FAB 内容色默认继承 onSurface，这里显式取 onPrimary 与背景/图标一致。
            MiuixText('添加媒体',
                style:
                    TextStyle(color: MiuixTheme.of(context).colors.onPrimary)),
          ],
        ),
      ),
    );
  }

  /// 进入查看器。查看器携带被点击的初始下标，经路由 `extra` 参数传递
  /// （go_router push 式导航，与其余页面保持一致）。
  void _openViewer(int index) {
    context.push('/memo/media/${widget.memoId}', extra: index);
  }

  Future<void> _add() async {
    final folderId =
        ref.read(memoDetailProvider(widget.memoId)).value?.folderId;
    final n = await ref
        .read(mediaControllerProvider)
        .addFiles(widget.memoId, folderId);
    final ctx = _pageCtx;
    if (ctx != null && ctx.mounted && n > 0) {
      AppSnackbar.show(ctx, message: '已添加 $n 个媒体');
    }
  }
}
