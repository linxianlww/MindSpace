import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/providers.dart';
import '../../core/router/memo_nav.dart';
import '../../core/widgets/state_views.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(entity.maybeWhen(
          data: (f) => f?.name ?? '文件夹',
          orElse: () => '文件夹',
        )),
      ),
      body: memos.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
            message: '$e',
            onRetry: () => ref.invalidate(memoListProvider(folderId))),
        data: (memoList) {
          if (memoList.isEmpty &&
              folders.maybeWhen(data: (f) => f.isEmpty, orElse: () => true)) {
            return const EmptyState(
              icon: Icons.folder_open_rounded,
              title: '空文件夹',
              subtitle: '通过右下角新建或从外部导入内容',
            );
          }
          final subFolders = folders.valueOrNull ?? const <Folder>[];
          return SliverToBoxAdapter(
            child: MemoMasonry(
              folders: subFolders,
              memos: memoList,
              onOpenMemo: (m) => openMemo(context, m),
              onOpenFolder: (f) => context.push('/folder/${f.id}'),
              onLongPressMemo: (m) => MemoActions.show(context, ref, m),
              onLongPressFolder: (f) => FolderActions.show(context, ref, f),
            ),
          );
        },
      ),
      floatingActionButton: CreateFab(
        onSelect: (t) async {
          final repo = ref.read(memoRepositoryProvider);
          switch (t) {
            case CreateTarget.folder:
              final ctrl = TextEditingController();
              final name = await showDialog<String>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('新建子文件夹'),
                  content: TextField(controller: ctrl, autofocus: true),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('取消')),
                    FilledButton(
                        onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                        child: const Text('创建')),
                  ],
                ),
              );
              if (name != null && name.isNotEmpty) {
                await ref
                    .read(folderRepositoryProvider)
                    .create(name, parentId: folderId);
              }
            case CreateTarget.text:
              final m = await repo.createBlank(MemoType.text,
                  folderId: folderId);
              if (context.mounted) {
                context.push('/memo/text/${m.id}/edit');
              }
            case CreateTarget.media:
              final m = await repo.createBlank(MemoType.media,
                  folderId: folderId);
              if (context.mounted) context.push('/memo/media/${m.id}/edit');
            case CreateTarget.audio:
              final m = await repo.createBlank(MemoType.audio,
                  folderId: folderId);
              if (context.mounted) {
                context.push('/memo/audio/${m.id}/record');
              }
            case CreateTarget.file:
              final result = await FilePicker.platform
                  .pickFiles(allowMultiple: true, type: FileType.any);
              final paths = result?.files
                      .map((e) => e.path)
                      .whereType<String>()
                      .toList() ??
                  const [];
              if (paths.isNotEmpty) {
                await ref
                    .read(importRepositoryProvider)
                    .importFiles(paths, folderId: folderId);
              }
            case CreateTarget.totp:
              final m = await repo.createBlank(MemoType.totp,
                  folderId: folderId);
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
        },
      ),
    );
  }
}
