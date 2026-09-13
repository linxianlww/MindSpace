import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/providers.dart';
import '../../core/router/memo_nav.dart';
import '../../core/theme/md3e_tokens.dart';
import '../../core/widgets/state_views.dart';
import '../../data/models/memo_type.dart';
import 'home_provider.dart';
import 'widgets/create_fab.dart';
import 'widgets/folder_nav.dart';
import 'widgets/memo_actions.dart';
import 'widgets/memo_masonry.dart';

/// 主页：顶部搜索/排序/设置、文件夹面包屑、子文件夹、铭记瀑布流、展开式 FAB。
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _searching = false;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final folderId = ref.watch(currentFolderIdProvider);
    final foldersAsync = ref.watch(folderListProvider(folderId));
    final memosAsync = ref.watch(memoListProvider(folderId));

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(memoListProvider(folderId)),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              title: _searching
                  ? TextField(
                      controller: _searchCtrl,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: '搜索标题或备注',
                        isDense: true,
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(Md3eTokens.radiusBar),
                        ),
                      ),
                      onChanged: (v) =>
                          ref.read(searchKeywordProvider.notifier).state = v,
                    )
                  : const Text('MindSpace'),
              actions: [
                IconButton(
                  tooltip: '搜索',
                  icon: Icon(_searching ? Icons.close : Icons.search),
                  onPressed: () => setState(() {
                    _searching = !_searching;
                    _searchCtrl.clear();
                    ref.read(searchKeywordProvider.notifier).state = '';
                  }),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.sort),
                  tooltip: '排序',
                  onSelected: (v) {
                    final asc = v.endsWith('_asc');
                    final field = v.split('_').first;
                    ref.read(settingsProvider.notifier).setSort(field, asc);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'updatedAt_desc', child: Text('最近更新')),
                    const PopupMenuItem(
                        value: 'createdAt_desc', child: Text('最近创建')),
                    const PopupMenuItem(
                        value: 'title_asc', child: Text('标题 A→Z')),
                  ],
                ),
                IconButton(
                  tooltip: '设置',
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => context.push('/settings'),
                ),
              ],
            ),
            SliverToBoxAdapter(child: FolderNav(currentFolderId: folderId)),
            // 子文件夹横向条
            foldersAsync.maybeWhen(
              data: (folders) => folders.isEmpty
                  ? const SliverToBoxAdapter(child: SizedBox.shrink())
                  : SliverToBoxAdapter(
                      child: SizedBox(
                        height: 44,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: folders.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 8),
                          itemBuilder: (_, i) {
                            final f = folders[i];
                            return ActionChip(
                              avatar: const Icon(Icons.folder_outlined,
                                  size: 18),
                              label: Text(f.name),
                              onPressed: () => ref
                                  .read(currentFolderIdProvider.notifier)
                                  .state = f.id,
                            );
                          },
                        ),
                      ),
                    ),
              orElse: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 4)),
            memosAsync.when(
              loading: () => const SliverFillRemaining(
                  hasScrollBody: false, child: LoadingState()),
              error: (e, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorState(
                  message: '$e',
                  onRetry: () => ref.invalidate(memoListProvider(folderId)),
                ),
              ),
              data: (memos) {
                if (memos.isEmpty && foldersAsync.maybeWhen(
                        data: (f) => f.isEmpty, orElse: () => false)) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.auto_awesome_mosaic_outlined,
                      title: '这里还没有内容',
                      subtitle: '点击右下角「新建」，创建你的第一条铭记',
                    ),
                  );
                }
                return SliverToBoxAdapter(
                  child: MemoMasonry(
                    memos: memos,
                    onOpen: (m) => openMemo(context, m),
                    onLongPress: (m) => MemoActions.show(context, ref, m),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: CreateFab(onSelect: (t) => _onCreate(t, folderId)),
    );
  }

  Future<void> _onCreate(CreateTarget target, String? folderId) async {
    final memoRepo = ref.read(memoRepositoryProvider);
    switch (target) {
      case CreateTarget.folder:
        final name = await _promptName('新建文件夹', '文件夹名称');
        if (name != null && name.isNotEmpty) {
          await ref
              .read(folderRepositoryProvider)
              .create(name, parentId: folderId);
        }
      case CreateTarget.text:
        final m = await memoRepo.createBlank(MemoType.text,
            folderId: folderId, title: '无标题文本');
        if (mounted) context.push('/memo/text/${m.id}/edit');
      case CreateTarget.media:
        final m = await memoRepo.createBlank(MemoType.media,
            folderId: folderId, title: '新媒体集');
        if (mounted) context.push('/memo/media/${m.id}/edit');
      case CreateTarget.audio:
        final m = await memoRepo.createBlank(MemoType.audio,
            folderId: folderId, title: '新录音');
        if (mounted) context.push('/memo/audio/${m.id}/record');
      case CreateTarget.file:
        await _importFiles(folderId);
    }
  }

  Future<void> _importFiles(String? folderId) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );
    if (result == null || result.files.isEmpty) return;
    final paths = result.files
        .map((e) => e.path)
        .whereType<String>()
        .toList(growable: false);
    if (paths.isEmpty) return;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在导入…')),
    );
    final created = await ref
        .read(importRepositoryProvider)
        .importFiles(paths, folderId: folderId);
    if (mounted && created.length == 1) openMemo(context, created.first);
  }

  Future<String?> _promptName(String title, String hint) {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('创建')),
        ],
      ),
    );
  }
}
