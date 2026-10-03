import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mindspace/ui/design_system/app_design_system.dart';

import '../../core/di/providers.dart';
import '../../core/router/app_router.dart';
import '../../core/router/memo_nav.dart';
import '../../core/settings/private_space_service.dart';
import '../../core/utils/app_logger.dart';
import '../../core/widgets/pin_input_dialog.dart';
import '../../core/widgets/system_pin_channel.dart';
import '../../data/models/folder.dart';
import '../../data/models/memo.dart';
import '../../data/models/memo_type.dart';
import 'home_provider.dart';
import 'widgets/create_fab.dart';
import 'widgets/folder_actions.dart';
import 'widgets/memo_actions.dart';
import 'widgets/memo_masonry.dart';

/// 主页：折叠大标题顶栏、常驻搜索栏、文件夹面包屑、私密空间入口、
/// 子文件夹/铭记瀑布流与展开式 FAB。
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with RouteAware {
  bool _fabOpen = false;
  bool _sheetOpen = false;
  final _fabKey = GlobalKey<CreateFabState>();

  /// 顶栏折叠大标题的滚动行为：折叠量锚定到滚动位置（State 字段，
  /// 由 [MiuixTopAppBar] 与 [MiuixScrollBehaviorListener] 共享）。
  final MiuixExitUntilCollapsedScrollBehavior _collapse = miuixScrollBehavior();

  /// 脚手架子树内的 context，供 AppDialog / AppSheet / AppSnackbar 挂载弹层。
  BuildContext? _overlayContext;

  /// 搜索框是否处于展开态（聚焦态）。
  bool _searchBarExpanded = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual<String?>(currentFolderIdProvider, (previous, next) {
      if (previous == kPrivateSpaceFolderId && next != kPrivateSpaceFolderId) {
        final service = ref.read(privateSpaceServiceProvider);
        if (service.sessionUnlocked) {
          appLogger.i('私密空间：导航离开私密空间 → 锁定');
          service.lock();
        }
      }
      ref.read(previousFolderIdProvider.notifier).state = previous;
    });
  }

  @override
  void dispose() {
    rootRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    rootRouteObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {}

  @override
  void didPushNext() => _fabKey.currentState?.forceClose();

  @override
  Widget build(BuildContext context) {
    final folderId = ref.watch(currentFolderIdProvider);
    final memosAsync = ref.watch(memoListProvider(folderId));
    final keyword = ref.watch(searchKeywordProvider);
    final searchMode = _searchBarExpanded || keyword.trim().isNotEmpty;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _onBackInvoked(didPop),
      child: AppScaffold(
        scrollBehavior: _collapse,
        topBar: MiuixTopAppBar(
          title: 'MindSpace',
          scrollBehavior: _collapse,
          blurred: true,
          actions: [
            // 排序：锚定下拉菜单
            Consumer(builder: (context, ref, _) {
              final settings = ref.watch(settingsProvider);
              return MiuixOverlayIconDropdownMenu(
                entry: MiuixDropdownEntry(items: [
                  for (final (field, label) in const <(String, String)>[
                    ('updatedAt', '更新时间'),
                    ('createdAt', '创建时间'),
                    ('title', '标题'),
                  ])
                    MiuixDropdownItem(
                      text: label,
                      selected: settings.sortField == field,
                      onClick: () => ref
                          .read(settingsProvider.notifier)
                          .setSort(field, settings.sortAscending),
                    ),
                  MiuixDropdownItem(
                    text: '升序排列',
                    selected: settings.sortAscending,
                    onClick: () => ref
                        .read(settingsProvider.notifier)
                        .setSort(settings.sortField, !settings.sortAscending),
                  ),
                ]),
                child: HiuiIcon(HiuiIcons.sort),
              );
            }),
            MiuixIconButton(
              onPressed: () => context.push('/settings'),
              child: HiuiIcon(HiuiIcons.settings),
            ),
          ],
        ),
        content: (context, padding) => Builder(builder: (overlayCtx) {
          _overlayContext = overlayCtx;
          return Stack(
            children: [
              // 始终渲染基础内容；搜索态叠加搜索结果覆盖层。
              _baseContent(overlayCtx, padding, folderId, memosAsync),
              if (searchMode)
                _searchOverlay(padding, memosAsync, overlayCtx),
            ],
          );
        }),
        floatingActionButton: CreateFab(
          key: _fabKey,
          onSelect: (t) => _onCreate(t, folderId),
          onOpenChanged: (open) => setState(() => _fabOpen = open),
          onLongPress: () => _onPrivateSpaceTap(context, ref),
        ),
      ),
    );
  }

  /// 基础内容：搜索栏 + 面包屑 + 持久化滚动的瀑布流。
  Widget _baseContent(BuildContext overlayCtx, EdgeInsets padding,
      String? folderId, AsyncValue<List<Memo>> memosAsync) {
    return CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.only(top: padding.top),
            sliver: SliverToBoxAdapter(child: _buildSearchBar()),
          ),
          SliverToBoxAdapter(child: _buildBreadcrumb(folderId)),
          memosAsync.when(
            loading: () => SliverFillRemaining(
                hasScrollBody: false,
                child: LoadingState()),
            error: (e, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: ErrorState(
                message: '$e',
                onRetry: () => ref.invalidate(memoListProvider(folderId)),
              ),
            ),
            data: (memos) {
              final folders = ref.watch(folderListProvider(folderId)).valueOrNull ?? const <Folder>[];
              if (memos.isEmpty && folders.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: HiuiIcons.mosaic,
                    title: '这里还没有内容',
                    subtitle: '点击右下角「新建」，创建你的第一条铭记',
                  ),
                );
              }
              return SliverPadding(
                padding: EdgeInsets.only(bottom: padding.bottom),
                sliver: SliverToBoxAdapter(
                  child: MemoMasonry(
                    folders: folders,
                    memos: memos,
                    onOpenMemo: (m_) => openMemo(overlayCtx, m_),
                    onOpenFolder: (f) => ref
                        .read(currentFolderIdProvider.notifier)
                        .state = f.id,
                    onLongPressMemo: (m_) =>
                        _openSheet(() => MemoActions.show(overlayCtx, ref, m_)),
                    onLongPressFolder: (f) =>
                        _openSheet(() => FolderActions.show(overlayCtx, ref, f)),
                  ),
                ),
              );
            },
          ),
        ],
    );
  }

  /// 搜索态覆盖层：仅覆盖面包屑 + 瀑布流区域，下方为搜索结果列表。
  /// 搜索栏本身保留在基础内容中，不重建，焦点不丢失。
  Widget _searchOverlay(EdgeInsets padding, AsyncValue<List<Memo>> memosAsync,
      BuildContext overlayCtx) {
    final colors = MiuixTheme.of(context).colors;
    final keyword = ref.watch(searchKeywordProvider);
    final searchBarHeight =
        45.0 + AppTokens.spacingS + AppTokens.spacingXS + 8;

    return Positioned(
      left: 0,
      right: 0,
      top: padding.top + searchBarHeight,
      bottom: 0,
      child: ColoredBox(
        color: colors.surface,
        child: memosAsync.when(
          loading: () => LoadingState(),
          error: (e, _) => ErrorState(
            message: '$e',
            onRetry: () => ref.invalidate(memoListProvider(ref.read(currentFolderIdProvider))),
          ),
          data: (memos) {
            if (keyword.trim().isEmpty) {
              return EmptyState(
                icon: HiuiIcons.search,
                title: '搜索铭记',
                subtitle: '输入关键词以搜索文字 / 待办 / 文件等',
              );
            }
            if (memos.isEmpty) {
              return EmptyState(
                icon: HiuiIcons.search,
                title: '搜索无结果',
              );
            }
            return ListView.builder(
              padding: EdgeInsets.only(
                top: AppTokens.spacingS,
                bottom: padding.bottom + 96,
              ),
              itemCount: memos.length,
              itemBuilder: (context, i) {
                final memo = memos[i];
                final ts = MiuixTheme.of(context).textStyles;
                final summaryColor = MiuixTheme.of(context).colors.onSurfaceVariantSummary;
                return Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: AppTokens.spacingM,
                    end: AppTokens.spacingM,
                    top: AppTokens.spacingXS,
                    bottom: AppTokens.spacingXS,
                  ),
                  child: MiuixBasicComponent(
                    onClick: () => openMemo(overlayCtx, memo),
                    content: [
                      MiuixText(
                        memo.title,
                        fontSize: ts.headline1.fontSize,
                        fontWeight: ts.headline1.fontWeight,
                        color: ts.headline1.color,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      MiuixText(
                        _memoSummary(memo),
                        fontSize: ts.footnote1.fontSize,
                        color: summaryColor,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _memoSummary(Memo memo) {
    final excerpt = memo.metadata['excerpt'] as String?;
    if (excerpt != null && excerpt.isNotEmpty) return excerpt;
    return switch (memo.type) {
      MemoType.text => '文本铭记',
      MemoType.media => '媒体集',
      MemoType.audio => '音频铭记',
      MemoType.file => '文件铭记',
      MemoType.totp => '动态验证码',
      MemoType.todo => '待办列表',
      MemoType.anniversary => '纪念日',
    };
  }

  /// 搜索框：原本的业务逻辑 ——
  /// 未聚焦时右侧显示搜索图标，聚焦后改为「取消」按钮（纯文本样式）。
  /// 使用 Stack 叠加搜索态覆盖层而非重建，同源输入框不卸载，焦点不丢失。
  Widget _buildSearchBar() {
    final colors = MiuixTheme.of(context).colors;
    final ts = MiuixTheme.of(context).textStyles;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.spacingM - 2,
        AppTokens.spacingS,
        AppTokens.spacingM - 2,
        AppTokens.spacingXS,
      ),
      child: MiuixSearchBar(
        content: const SizedBox.shrink(),
        insideMargin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        outsideEndAction: _searchBarExpanded
            ? Padding(
                padding: const EdgeInsetsDirectional.only(start: AppTokens.spacingM),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _exitSearch,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.spacingXS,
                      vertical: AppTokens.spacingXS,
                    ),
                    child: MiuixText(
                      '取消',
                      style: ts.body2.copyWith(color: colors.primary),
                    ),
                  ),
                ),
              )
            : null,
        expanded: _searchBarExpanded,
        onExpandedChange: (expanded) {
          if (mounted && expanded != _searchBarExpanded) {
            setState(() => _searchBarExpanded = expanded);
          }
        },
        inputField: MiuixInputField(
          query: ref.watch(searchKeywordProvider),
          onQueryChange: (v) =>
              ref.read(searchKeywordProvider.notifier).state = v,
          onSearch: (_) {},
          expanded: _searchBarExpanded,
          onExpandedChange: (expanded) {
            if (mounted && expanded != _searchBarExpanded) {
              setState(() => _searchBarExpanded = expanded);
            }
          },
          leadingIcon: HiuiIcon(HiuiIcons.search, size: 22),
          label: '搜索铭记',
        ),
      ),
    );
  }

  /// 文件夹面包屑。
  Widget _buildBreadcrumb(String? folderId) {
    final colors = MiuixTheme.of(context).colors;
    final ts = MiuixTheme.of(context).textStyles;
    Widget crumb(String label, bool current, VoidCallback? onTap) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          child: MiuixText(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: (current ? ts.body2 : ts.footnote1).copyWith(
              fontWeight: current ? FontWeight.w600 : FontWeight.w400,
              color: current
                  ? colors.primary
                  : colors.onSurfaceVariantSummary,
            ),
          ),
        ),
      );
    }

    Widget buildRow(List<Widget> children) {
      return Padding(
        padding: const EdgeInsetsDirectional.only(
          start: AppTokens.spacingM - 2,
          end: AppTokens.spacingM - 2,
          top: AppTokens.spacingXS,
          bottom: AppTokens.spacingXS,
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(mainAxisSize: MainAxisSize.min, children: children),
        ),
      );
    }

    if (folderId == null) {
      return buildRow([crumb('全部铭记', true, null)]);
    }
    final chainAsync = ref.watch(breadcrumbProvider(folderId));
    return chainAsync.when(
      loading: () => const SizedBox(height: 48),
      error: (_, __) => const SizedBox(height: 48),
      data: (chain) {
        final children = <Widget>[
          crumb(
            '全部铭记',
            false,
            () => ref.read(currentFolderIdProvider.notifier).state = null,
          ),
        ];
        for (var i = 0; i < chain.length; i++) {
          final f = chain[i];
          final isLast = i == chain.length - 1;
          children.add(HiuiIcon(HiuiIcons.chevronRight,
              size: 14, color: colors.onSurfaceVariantActions));
          children.add(crumb(f.name, isLast, () {
            if (!isLast) {
              ref.read(currentFolderIdProvider.notifier).state = f.id;
            }
          }));
        }
        return buildRow(children);
      },
    );
  }

  Future<void> _onBackInvoked(bool didPop) async {
    if (didPop) return;
    if (_fabOpen) {
      _fabKey.currentState?.close();
      return;
    }
    if (_sheetOpen) {
      final ctx = _overlayContext;
      if (ctx != null && ctx.mounted) AppSheet.close(ctx);
      return;
    }
    if (_searchBarExpanded || ref.read(searchKeywordProvider).isNotEmpty) {
      _exitSearch();
      return;
    }
    final current = ref.read(currentFolderIdProvider);
    if (current != null) {
      final folder = await ref.read(folderRepositoryProvider).findById(current);
      if (mounted) {
        ref.read(currentFolderIdProvider.notifier).state = folder?.parentId;
      }
      return;
    }
    SystemNavigator.pop();
  }

  void _exitSearch() {
    ref.read(searchKeywordProvider.notifier).state = '';
    if (mounted) setState(() => _searchBarExpanded = false);
  }

  Future<void> _openSheet(Future<void> Function() show) async {
    setState(() => _sheetOpen = true);
    try {
      await show();
    } finally {
      if (mounted) setState(() => _sheetOpen = false);
    }
  }

  void _showToast(String message) {
    final ctx = _overlayContext;
    if (ctx == null || !ctx.mounted) return;
    AppSnackbar.show(ctx, message: message);
  }

  Future<void> _onCreate(CreateTarget target, String? folderId) async {
    final memoRepo = ref.read(memoRepositoryProvider);
    switch (target) {
      case CreateTarget.folder:
        final name = await _promptName('新建文件夹', '文件夹名称');
        if (name != null && name.isNotEmpty) {
          await ref.read(folderRepositoryProvider).create(name, parentId: folderId);
        }
      case CreateTarget.text:
        final m_ = await memoRepo.createBlank(MemoType.text,
            folderId: folderId, title: '无标题文本');
        if (mounted) context.push('/memo/text/${m_.id}/edit');
      case CreateTarget.todo:
        final m_ = await memoRepo.createBlank(MemoType.todo,
            folderId: folderId, title: '新待办');
        if (mounted) context.push('/memo/todo/${m_.id}/edit');
      case CreateTarget.media:
        final m_ = await memoRepo.createBlank(MemoType.media,
            folderId: folderId, title: '新媒体集');
        if (mounted) context.push('/memo/media/${m_.id}/edit');
      case CreateTarget.audio:
        final m_ = await memoRepo.createBlank(MemoType.audio,
            folderId: folderId, title: '新录音');
        if (mounted) context.push('/memo/audio/${m_.id}/record');
      case CreateTarget.file:
        await _importFiles(folderId);
      case CreateTarget.totp:
        final m_ = await memoRepo.createBlank(MemoType.totp,
            folderId: folderId, title: '新验证码');
        if (mounted) context.push('/memo/totp/${m_.id}/edit');
      case CreateTarget.anniversary:
        final m_ = await memoRepo.createBlank(MemoType.anniversary,
            folderId: folderId, title: '新纪念日');
        if (mounted) {
          context.push('/memo/anniversary/${m_.id}/edit');
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
    _showToast('正在导入…');
    final created = await ref
        .read(importRepositoryProvider)
        .importFiles(paths, folderId: folderId);
    if (mounted && created.length == 1) openMemo(context, created.first);
  }

  Future<String?> _promptName(String title, String hint) async {
    final ctx = _overlayContext;
    if (ctx == null || !ctx.mounted) return null;
    final ctrl = TextEditingController();
    try {
      return await AppDialog.show<String>(
        context: ctx,
        title: title,
        content: AppInput(
          controller: ctrl,
          hintText: hint,
          onChanged: (_) {},
        ),
        actions: [
          AppButton(
              variant: AppButtonStyle.text,
              onPressed: () => AppDialog.close(ctx),
              child: MiuixText('取消')),
          AppButton(
              onPressed: () => AppDialog.close<String>(ctx, ctrl.text.trim()),
              child: MiuixText('创建')),
        ],
      );
    } finally {
      ctrl.dispose();
    }
  }

  Future<void> _onPrivateSpaceTap(BuildContext context, WidgetRef ref) async {
    final service = ref.read(privateSpaceServiceProvider);
    if (!service.hasPin) {
      final folderCreated = await _ensurePrivateSpaceFolder(ref);
      if (!folderCreated && context.mounted) {
        _showToast('无法创建私密空间文件夹');
        return;
      }
      if (!context.mounted) return;
      await _promptCreatePin(context, service);
      return;
    }
    if (service.sessionUnlocked) {
      if (context.mounted) {
        ref.read(currentFolderIdProvider.notifier).state =
            kPrivateSpaceFolderId;
      }
      return;
    }
    await _promptUnlock(context, ref, service);
  }

  Future<bool> _ensurePrivateSpaceFolder(WidgetRef ref) async {
    try {
      await ref.read(folderRepositoryProvider).ensurePrivateSpaceFolder();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _promptCreatePin(
      BuildContext context, PrivateSpaceService service) async {
    await showPinInputDialog(
      context: context,
      mode: PinDialogMode.create,
      onCreated: (pin) async {
        await service.setPin(pin);
        if (context.mounted) {
          _showToast('私密空间已创建并解锁');
          ref.read(currentFolderIdProvider.notifier).state =
              kPrivateSpaceFolderId;
        }
      },
    );
  }

  Future<void> _promptUnlock(
      BuildContext context, WidgetRef ref, PrivateSpaceService service) async {
    final verificationCountBefore = SystemPinChannel.verificationCount;
    await showPinInputDialog(
      context: context,
      mode: PinDialogMode.verify,
      biometricEnabled: service.canCheckBiometrics && service.biometricEnabled,
      onBiometricTap: () async {
        final ok = await service.unlockWithBiometric();
        if (ok && context.mounted) {
          PinInputDialog.close(context);
          ref.read(currentFolderIdProvider.notifier).state =
              kPrivateSpaceFolderId;
        }
      },
      onVerify: (pin) async {
        final ok = await service.unlock(pin);
        if (ok && context.mounted) {
          ref.read(currentFolderIdProvider.notifier).state =
              kPrivateSpaceFolderId;
        }
        return ok;
      },
    );
    if (!context.mounted) return;
    if (SystemPinChannel.verificationCount != verificationCountBefore &&
        !service.sessionUnlocked) {
      await service.unlockWithSystemCredential();
    }
    if (service.sessionUnlocked) {
      ref.read(currentFolderIdProvider.notifier).state = kPrivateSpaceFolderId;
    }
  }
}
