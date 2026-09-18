import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/providers.dart';
import '../../core/router/app_router.dart';
import '../../core/router/memo_nav.dart';
import '../../core/theme/md3e_tokens.dart';
import '../../core/widgets/state_views.dart';
import '../../data/models/folder.dart';
import '../../data/models/memo_type.dart';
import 'home_provider.dart';
import 'widgets/neko_title.dart';
import 'widgets/create_fab.dart';
import 'widgets/folder_actions.dart';
import 'widgets/folder_nav.dart';
import 'widgets/memo_actions.dart';
import 'widgets/memo_masonry.dart';

/// 主页：顶部搜索/排序/设置、文件夹面包屑、子文件夹、铭记瀑布流、展开式 FAB。
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with RouteAware {
  bool _searching = false;
  bool _fabOpen = false;
  bool _sheetOpen = false;
  final _searchCtrl = TextEditingController();
  final _fabKey = GlobalKey<CreateFabState>();

  @override
  void dispose() {
    rootRouteObserver.unsubscribe(this);
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    rootRouteObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    // 离开主界面再返回时，自动收起搜索框并清空关键字。
    if (_searching) {
      setState(() => _searching = false);
    }
    _searchCtrl.clear();
    ref.read(searchKeywordProvider.notifier).state = '';
  }

  @override
  Widget build(BuildContext context) {
    final folderId = ref.watch(currentFolderIdProvider);
    final foldersAsync = ref.watch(folderListProvider(folderId));
    final memosAsync = ref.watch(memoListProvider(folderId));
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _onBackInvoked(didPop),
      child: Scaffold(
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
                          hintText: '搜索标题、正文或备注',
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
                    : const NekoBoxTitle(),
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
                  final folders = foldersAsync.valueOrNull ?? const <Folder>[];
                  if (memos.isEmpty && folders.isEmpty) {
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
                      folders: folders,
                      memos: memos,
                      onOpenMemo: (m) => openMemo(context, m),
                      onOpenFolder: (f) => ref
                          .read(currentFolderIdProvider.notifier)
                          .state = f.id,
                      onLongPressMemo: (m) => _openSheet(
                          () => MemoActions.show(context, ref, m)),
                      onLongPressFolder: (f) => _openSheet(
                          () => FolderActions.show(context, ref, f)),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        floatingActionButton: CreateFab(
          key: _fabKey,
          onSelect: (t) => _onCreate(t, folderId),
          onOpenChanged: (open) => setState(() => _fabOpen = open),
        ),
      ),
    );
  }

  /// 拦截系统返回键（Android 实体键 / 手势返回）。
  /// 优先级：FAB → sheet → 搜索框 → 上级文件夹 → 退出应用。
  Future<void> _onBackInvoked(bool didPop) async {
    if (didPop) return;
    if (_fabOpen) {
      _fabKey.currentState?.close();
      return;
    }
    if (_sheetOpen) {
      Navigator.of(context).pop();
      return;
    }
    if (_searching) {
      setState(() => _searching = false);
      _searchCtrl.clear();
      ref.read(searchKeywordProvider.notifier).state = '';
      return;
    }
    // 非根文件夹时，返回上级文件夹。
    final current = ref.read(currentFolderIdProvider);
    if (current != null) {
      final folder = await ref.read(folderRepositoryProvider).findById(current);
      if (mounted) {
        ref.read(currentFolderIdProvider.notifier).state = folder?.parentId;
      }
      return;
    }
    // 已在根目录：真正退出应用。
    // 根路由下不能用 Navigator.pop，否则会 crash。
    SystemNavigator.pop();
  }

  /// 打开底部弹出菜单（用于铭记/文件夹长按），自动追踪 sheet 状态以支持返回键关闭。
  Future<void> _openSheet(Future<void> Function() show) async {
    setState(() => _sheetOpen = true);
    try {
      await show();
    } finally {
      if (mounted) setState(() => _sheetOpen = false);
    }
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
      case CreateTarget.todo:
        final m = await memoRepo.createBlank(MemoType.todo,
            folderId: folderId, title: '新待办');
        if (mounted) context.push('/memo/todo/${m.id}/edit');
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
case CreateTarget.totp:
final m = await memoRepo.createBlank(MemoType.totp,
folderId: folderId, title: '新验证码');
if (mounted) context.push('/memo/totp/${m.id}/edit');
case CreateTarget.anniversary:
final m = await memoRepo.createBlank(MemoType.anniversary,
folderId: folderId, title: '新纪念日');
if (mounted) {
context.push('/memo/anniversary/${m.id}/edit');
}
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
