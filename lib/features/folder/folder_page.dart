import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mindspace/ui/design_system/app_design_system.dart';

import '../../core/di/providers.dart';
import '../../core/router/memo_nav.dart';
import '../../data/models/folder.dart';
import '../../data/models/memo_type.dart';
import '../home/home_provider.dart';
import '../home/widgets/create_fab.dart';
import '../home/widgets/folder_actions.dart';
import '../home/widgets/memo_actions.dart';
import '../home/widgets/memo_masonry.dart';
import 'folder_provider.dart';

/// 文件夹页：独立路由层级，支持系统返回手势逐层退出。
class FolderPage extends ConsumerWidget {
  const FolderPage({super.key, required this.folderId});

  final String folderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entity = ref.watch(folderEntityProvider(folderId));
    final folders = ref.watch(folderListProvider(folderId));
    final memos = ref.watch(memoListProvider(folderId));

    return AppScaffold(
      topBar: AppHeader(
        title: entity.maybeWhen(
          data: (f) => f?.name ?? '文件夹',
          orElse: () => '文件夹',
        ),
      ),
      // content builder 传入的 context 是脚手架 State 自身，无法反查脚手架；
      // 用 Builder 捕获子树 context 供 AppSheet / 路由调用。
      content: (context, padding) => Builder(
        builder: (overlayCtx) => memos.when(
          loading: () => Padding(padding: padding, child: const LoadingState()),
          error: (e, _) => Padding(
            padding: padding,
            child: ErrorState(
                message: '$e',
                onRetry: () => ref.invalidate(memoListProvider(folderId))),
          ),
          data: (memoList) {
            if (memoList.isEmpty &&
                folders.maybeWhen(data: (f) => f.isEmpty, orElse: () => true)) {
              return Padding(
                padding: padding,
                child: const EmptyState(
                  icon: HiuiIcons.folderOpen,
                  title: '空文件夹',
                  subtitle: '通过右下角新建或从外部导入内容',
                ),
              );
            }
            final subFolders = folders.valueOrNull ?? const <Folder>[];
            return CustomScrollView(
              slivers: [
                if (padding.top > 0)
                  SliverPadding(
                    padding: EdgeInsets.only(top: padding.top),
                    sliver: SliverToBoxAdapter(
                      child: _buildBreadcrumb(overlayCtx, ref),
                    ),
                  ),
                SliverPadding(
                  padding: EdgeInsets.only(bottom: padding.bottom),
                  sliver: SliverToBoxAdapter(
                    child: MemoMasonry(
                      folders: subFolders,
                      memos: memoList,
                      onOpenMemo: (m) => openMemo(overlayCtx, m),
                      onOpenFolder: (f) => overlayCtx.push('/folder/${f.id}'),
                      onLongPressMemo: (m) =>
                          MemoActions.show(overlayCtx, ref, m),
                      onLongPressFolder: (f) =>
                          FolderActions.show(overlayCtx, ref, f),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: Builder(
        builder: (fabCtx) => CreateFab(
          onSelect: (t) => _onCreate(fabCtx, ref, t),
        ),
      ),
    );
  }

  /// 父级路径面包屑：手写横向 Row（替代 MiuixBreadcrumbBar，去除底色 pill
  /// 裁剪与两侧留白），仅在存在祖先时展示，点击任意祖先层级推入对应文件夹页。
  Widget _buildBreadcrumb(BuildContext context, WidgetRef ref) {
    final chainAsync = ref.watch(breadcrumbProvider(folderId));
    final chain = chainAsync.valueOrNull ?? const <Folder>[];
    if (chain.length <= 1) return const SizedBox.shrink();
    final colors = MiuixTheme.of(context).colors;
    final ts = MiuixTheme.of(context).textStyles;

    Widget crumb(String label, bool current, VoidCallback? onTap) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.spacingS, vertical: 6),
          child: MiuixText(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: (current ? ts.body2 : ts.footnote1).copyWith(
              fontWeight: current ? FontWeight.w600 : FontWeight.w400,
              color: current ? colors.primary : colors.onSurfaceVariantSummary,
            ),
          ),
        ),
      );
    }

    final children = <Widget>[];
    for (var i = 0; i < chain.length; i++) {
      final f = chain[i];
      final isLast = i == chain.length - 1;
      if (i > 0) {
        children.add(HiuiIcon(HiuiIcons.chevronRight,
            size: 14, color: colors.onSurfaceVariantActions));
      }
      children.add(crumb(f.name, isLast, () {
        if (!isLast) context.push('/folder/${f.id}');
      }));
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.spacingXS),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }

  Future<void> _onCreate(
      BuildContext context, WidgetRef ref, CreateTarget t) async {
    final repo = ref.read(memoRepositoryProvider);
    switch (t) {
      case CreateTarget.folder:
        final ctrl = TextEditingController();
        final name = await AppDialog.show<String>(
          context: context,
          title: '新建子文件夹',
          content: AppInput(
            controller: ctrl,
            hintText: '文件夹名称',
            onChanged: (_) {},
          ),
          actions: [
            AppButton(
                variant: AppButtonStyle.text,
                onPressed: () => AppDialog.close(context),
                child: const MiuixText('取消')),
            AppButton(
                onPressed: () =>
                    AppDialog.close<String>(context, ctrl.text.trim()),
                child: const MiuixText('创建')),
          ],
        ).whenComplete(() => ctrl.dispose());
        if (name != null && name.isNotEmpty) {
          await ref
              .read(folderRepositoryProvider)
              .create(name, parentId: folderId);
        }
      case CreateTarget.text:
        final m = await repo.createBlank(MemoType.text, folderId: folderId);
        if (context.mounted) {
          context.push('/memo/text/${m.id}/edit');
        }
      case CreateTarget.media:
        final m = await repo.createBlank(MemoType.media, folderId: folderId);
        if (context.mounted) context.push('/memo/media/${m.id}/edit');
      case CreateTarget.audio:
        final m = await repo.createBlank(MemoType.audio, folderId: folderId);
        if (context.mounted) {
          context.push('/memo/audio/${m.id}/record');
        }
      case CreateTarget.file:
        final result = await FilePicker.platform
            .pickFiles(allowMultiple: true, type: FileType.any);
        final paths =
            result?.files.map((e) => e.path).whereType<String>().toList() ??
                const [];
        if (paths.isNotEmpty) {
          await ref
              .read(importRepositoryProvider)
              .importFiles(paths, folderId: folderId);
        }
      case CreateTarget.totp:
        final m = await repo.createBlank(MemoType.totp, folderId: folderId);
        if (context.mounted) context.push('/memo/totp/${m.id}/edit');
      case CreateTarget.todo:
        final m = await repo.createBlank(MemoType.todo,
            folderId: folderId, title: '新待办');
        if (context.mounted) context.push('/memo/todo/${m.id}/edit');
      case CreateTarget.anniversary:
        final m = await repo.createBlank(MemoType.anniversary,
            folderId: folderId, title: '新纪念日');
        if (context.mounted) {
          context.push('/memo/anniversary/${m.id}/edit');
        }
    }
  }
}
