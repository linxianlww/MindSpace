import 'dart:async';

import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';
import 'package:flutter_miuix/miuix.dart';

import 'hiui_icons.dart';

/// 折叠顶栏滚动行为的传递管道。
///
/// [AppScaffold] 在顶栏为 [AppHeader] 或显式传入 [AppScaffold.scrollBehavior]
/// 时创建 [MiuixExitUntilCollapsedScrollBehavior]：一侧交给顶栏驱动折叠，
/// 一侧包住页面内容监听滚动、并把 contentPadding 的顶部**稳定**为展开高度
/// （见 [AppScaffold] 文档），从而「标题折叠不影响内容滚动跟手」。
class AppCollapseScope extends InheritedWidget {
  const AppCollapseScope({
    super.key,
    required this.behavior,
    required super.child,
  });

  final MiuixExitUntilCollapsedScrollBehavior behavior;

  static MiuixExitUntilCollapsedScrollBehavior? maybeOf(BuildContext context) {
    final scope =
        context.getInheritedWidgetOfExactType<AppCollapseScope>();
    return scope?.behavior;
  }

  @override
  bool updateShouldNotify(AppCollapseScope oldWidget) =>
      !identical(behavior, oldWidget.behavior);
}

/// 应用脚手架 —— 基于 MIUIX [MiuixScaffold]。
///
/// 与 Flutter 原生 Scaffold 不同，MiuixScaffold 的内容是**满屏布局**：
/// 顶栏悬浮绘制在内容之上，内容通过 [content] builder 接收避让内边距，
/// 由内容自行消化——滚动视图应把 padding 交给 `ListView.padding` /
/// `SliverPadding`，即可获得「内容滚动到顶栏之下」的 HyperOS 沉浸式效果。
///
/// ## 折叠大标题（默认开启）
///
/// 顶栏为 [AppHeader] 时脚手架自动启用折叠大标题：展开态显示大标题，
/// 滚动逐像素折叠为小标题（毛玻璃）。关键点：
/// - 折叠量锚定滚动位置，但 contentPadding 的顶部被**稳定**为展开高度
///   （MiuixScaffold 上报的是随折叠实时变化的顶栏高度，直接使用会让
///   内容在滚动时二次位移、脱离手指）；因此滚动内顶部 padding 恒定，
///   标题只做视觉覆盖，内容严格跟手。
/// - 页面自建折叠顶栏（如首页的 [MiuixTopAppBar]）时，把 behavior 传给
///   [AppScaffold.scrollBehavior] 即可获得同样的稳定化与滚动监听。
///
/// 脚手架同时是页面的弹层宿主：[AppDialog] / [AppSheet] / [AppSnackbar]
/// 通过 [AppScaffold.maybeOf] 找到当前脚手架，把弹层交给 MiuixScaffold 的
/// popup / snackbar 层渲染；存在可见弹层时，系统返回键优先关闭弹层。
class AppScaffold extends StatefulWidget {
  const AppScaffold({
    super.key,
    this.topBar,
    this.appBar,
    this.scrollBehavior,
    this.content,
    this.body,
    this.floatingActionButton,
    this.fabPosition = MiuixFabPosition.end,
    this.containerColor,
  })  : assert(topBar == null || appBar == null, 'topBar 与 appBar 二选一'),
        assert((content == null) != (body == null), 'content 与 body 二选一');

  /// 顶栏：[AppHeader]（自动折叠大标题）或自定义 [MiuixTopAppBar]。
  final Widget? topBar;

  /// 兼容旧 [AppView] 的 `appBar` 参数名，与 [topBar] 等价。
  final Widget? appBar;

  /// 页面自建折叠顶栏时传入其滚动行为，用于稳定 contentPadding 与
  /// 自动挂接滚动监听；顶栏为 [AppHeader] 时无需传（自动创建）。
  final MiuixExitUntilCollapsedScrollBehavior? scrollBehavior;

  /// 内容 builder，[contentPadding] 含顶栏/底栏高度与系统安全区
  /// （顶栏可折叠时顶部已稳定为展开高度）。
  final Widget Function(BuildContext context, EdgeInsets contentPadding)?
      content;

  /// 静态内容便捷入口：自动包裹 `Padding(padding: contentPadding)`。
  final Widget? body;

  /// 悬浮操作按钮。
  final Widget? floatingActionButton;

  /// FAB 位置。
  final MiuixFabPosition fabPosition;

  /// 脚手架背景色，默认 MiuixTheme 的 background。
  final Color? containerColor;

  /// 查找最近的脚手架宿主（对话框 / 抽屉 / 轻提示的挂载点）。
  static AppScaffoldState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<AppScaffoldState>();
  }

  @override
  State<AppScaffold> createState() => AppScaffoldState();
}

class AppScaffoldState extends State<AppScaffold> {
  final MiuixSnackbarHostState _snackbarState = MiuixSnackbarHostState();
  final List<_AppOverlay> _overlays = <_AppOverlay>[];

  /// spent（退场完成）挂载件的保留上限：超过后清理其中完成已久的，
  /// 防止页面内反复开关弹层导致 Stack 子项无限增长。
  static const int _maxSpentOverlays = 12;

  /// 挂载件在完成后再保留的最短时长。popup 层 entry 的遮罩淡出最长
  /// 约 300ms，超过该时长后其 entry 必然已从注册表摘除，此时失活挂载
  /// 件（清理）才安全。
  static const Duration _spentSettleDelay = Duration(seconds: 1);

  /// 折叠滚动行为：页面传入或顶栏为 [AppHeader] 时启用。
  MiuixExitUntilCollapsedScrollBehavior? _collapse;

  bool get _hasVisibleOverlays => _overlays.any((spec) => spec.show);

  @override
  void initState() {
    super.initState();
    _collapse = widget.scrollBehavior ??
        ((widget.topBar ?? widget.appBar) is AppHeader
            ? miuixScrollBehavior()
            : null);
  }

  @override
  void didUpdateWidget(AppScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollBehavior != widget.scrollBehavior ||
        (oldWidget.topBar ?? oldWidget.appBar) !=
            (widget.topBar ?? widget.appBar)) {
      _collapse = widget.scrollBehavior ??
          ((widget.topBar ?? widget.appBar) is AppHeader
              ? (_collapse ?? miuixScrollBehavior())
              : null);
    }
  }

  // —————————————— 轻提示 ——————————————

  /// 显示一条 MIUIX Snackbar。
  void showSnackbar(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    unawaited(_snackbarState
        .showSnackbar(message, actionLabel: actionLabel)
        .then((result) {
      if (result == MiuixSnackbarResult.actionPerformed) {
        onAction?.call();
      }
    }));
  }

  // —————————————— 对话框 ——————————————

  /// 宿主一个 MIUIX 对话框（[MiuixOverlayDialog] 渲染到脚手架弹层）。
  Future<T?> showDialog<T>({
    String? title,
    String? summary,
    Widget? content,
    List<Widget>? actions,
    bool barrierDismissible = true,
  }) {
    final spec = _AppOverlay<T>._(completer: Completer<T?>());
    spec.buildOverlay = (ctx) {
      return MiuixOverlayDialog(
        show: spec.show,
        title: title,
        summary: summary,
        onDismissRequest: barrierDismissible ? () => _dismiss(spec) : null,
        onDismissFinished: () => _finish(spec),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (content != null) content,
if (actions != null && actions.isNotEmpty) ...[
  const SizedBox(height: 24),
  Row(
    children: [
      for (int i = 0; i < actions.length; i++) ...[
        if (i > 0) const SizedBox(width: 12),
        Expanded(child: actions[i]),
      ],
    ],
  ),
],
          ],
        ),
      );
    };
    setState(() => _overlays.add(spec));
    return spec.completer.future;
  }

  // —————————————— 底部抽屉 ——————————————

  /// 宿主一个 MIUIX 底部抽屉（[MiuixOverlayBottomSheet] 渲染到脚手架弹层）。
  Future<T?> showSheet<T>({
    String? title,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    Size insideMargin = const Size(12, 0),
  }) {
    final spec = _AppOverlay<T>._(completer: Completer<T?>())..isSheet = true;
    spec.buildOverlay = (ctx) {
      return MiuixOverlayBottomSheet(
        show: spec.show,
        title: title,
        allowDismiss: barrierDismissible,
        onDismissRequest: barrierDismissible ? () => _dismiss(spec) : null,
        onDismissFinished: () => _finish(spec),
        content: builder(ctx),
        insideMargin: insideMargin,
      );
    };
    setState(() => _overlays.add(spec));
    return spec.completer.future;
  }

  /// 关闭最上层的底部抽屉（抽屉内容自身调用，带可选返回值）。
  void closeSheet<T>([T? result]) {
    for (final spec in _overlays.reversed) {
      if (spec.isSheet && spec.show) {
        _dismiss(spec, result);
        return;
      }
    }
  }

  /// 关闭最上层的对话框（对话框内容自身调用，带可选返回值）。
  void closeDialog<T>([T? result]) {
    for (final spec in _overlays.reversed) {
      if (!spec.isSheet && spec.show) {
        _dismiss(spec, result);
        return;
      }
    }
  }

  // —————————————— 内部：弹层生命周期 ——————————————

  /// 触发退场动画（show -> false），由 onDismissFinished 收尾。
  void _dismiss(_AppOverlay spec, [Object? result]) {
    if (!spec.show) return;
    spec.result = result;
    setState(() => spec.show = false);
  }

  /// 退场动画完成：标记 spent（**不从 Stack 移除挂载件**）并完成 Future。
  ///
  /// popup 层的 entry 在 [MiuixOverlayDialog.onDismissFinished]/抽屉同款回调
  /// 之后还要播放约 250ms 的遮罩淡出，期间它每次重建都会以注册件 build 时
  /// 捕获的 in-tree context 查 MiuixTheme（MiuixOverlayBottomSheet 的实现）；
  /// 若此刻把挂载件从 Stack 移除（或原地换成别的 widget），该 context 失活，
  /// popup 层重建即抛 "Looking up a deactivated widget's ancestor is unsafe"。
  /// 因此这里仅标记 spent——挂载件原地只渲染 SizedBox.shrink（show 已为
  /// false、entry 已由 popup 层自行摘除），待 [_purgeSpentOverlays] 清理。
  void _finish(_AppOverlay spec) {
    if (!mounted) {
      spec.complete();
      return;
    }
    spec.spentAt = DateTime.now();
    // Future 延后到弹层真正出树的那一帧之后完成：调用方的
    // `await AppDialog.show(...).then(...)` 常会立刻 dispose 弹层内容
    // 持有的 controller 等资源，若同步完成，资源会在弹层 widget 仍在
    // 树上的最后一帧前被释放（debug 下触发 "used after being disposed"）。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      spec.complete();
    });
    _purgeSpentOverlays();
  }

  /// 清理完成已久的 spent 挂载件，防列表无限增长。
  ///
  /// 只清理 [spentAt] 距今超过 [_spentSettleDelay] 的挂载件：其 popup entry
  /// 早已从注册表摘除（淡出最长约 300ms），in-tree 元素失活不再会被 popup
  /// 层引用，此时移除是安全的。刚完成的留给下一轮（打开/关闭新的弹层时）
  /// 处理，因此同时打开大量弹层的极端场景下列表也只会在上限附近波动。
  void _purgeSpentOverlays() {
    var spentCount = 0;
    for (final spec in _overlays) {
      if (spec.spentAt != null) spentCount++;
    }
    if (spentCount <= _maxSpentOverlays) return;
    final now = DateTime.now();
    final victims = _overlays
        .where(
          (spec) =>
              spec.spentAt != null &&
              now.difference(spec.spentAt!) >= _spentSettleDelay,
        )
        .toList();
    if (victims.isEmpty) return;
    setState(() {
      for (final spec in victims) {
        _overlays.remove(spec);
      }
    });
  }

  @override
  void dispose() {
    // 页面销毁时兜底完成所有未决 Future，避免调用方永久 await。
    for (final spec in _overlays) {
      spec.complete();
    }
    _overlays.clear();
    _snackbarState.dispose();
    super.dispose();
  }

  /// 把 contentPadding 的顶部稳定为顶栏**展开**高度。
  ///
  /// MiuixScaffold 上报的 padding.top = 顶栏当前高度，随折叠实时变化；
  /// 若页面把它放进滚动视图，滚动时内容会随 padding 收缩产生二次位移、
  /// 脱离手指。这里用折叠行为当前的 heightOffset 把顶部还原成展开高度，
  /// 使滚动内顶部 padding 恒定，标题折叠只做视觉覆盖。
  EdgeInsets _stabilizePadding(EdgeInsets padding) {
    final behavior = _collapse;
    if (behavior == null) return padding;
    final offset = behavior.state.heightOffset;
    if (!offset.isFinite || offset >= 0) return padding;
    return EdgeInsets.fromLTRB(
        padding.left, padding.top - offset, padding.right, padding.bottom);
  }

  @override
  Widget build(BuildContext context) {
    // 透明 Material：MiuixScaffold 不提供 Material 祖先，而
    // MiuixTextField/MiuixInputField 内部使用 Material TextField、
    // flutter_quill / pdfrx 等三方组件也依赖 Material 环境；
    // MaterialType.transparency 不绘制任何内容，仅补齐组件环境。
    return Material(
      type: MaterialType.transparency,
      child: AppCollapseScope(
        // behavior 可能为 null（无折叠顶栏的页面），AppHeader 侧自行兜底。
        behavior: _collapse ?? miuixScrollBehavior(),
        child: PopScope(
          // 存在可见弹层时，系统返回键优先关闭最上层弹层而不是退出页面
          //（弹层不是路由，MiuixOverlayDialog/BottomSheet 自身不拦截返回）。
          canPop: !_hasVisibleOverlays,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            for (final spec in _overlays.reversed) {
              if (spec.show) {
                _dismiss(spec);
                return;
              }
            }
          },
          child: MiuixScaffold(
            topBar: widget.topBar ?? widget.appBar,
            floatingActionButton: widget.floatingActionButton,
            floatingActionButtonPosition: widget.fabPosition,
            snackbarHost: MiuixSnackbarHost(state: _snackbarState),
            popupHost: const MiuixPopupHost(),
            containerColor: widget.containerColor,
            content: (padding) => _buildContent(context, padding),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, EdgeInsets contentPadding) {
    // 关键：页面 content builder 必须拿到 MiuixScaffold **子树内**的 context。
    // 若传入 State 自身的 context（位于 AppScaffold 之上），
    // findAncestorStateOfType 从其父级开始查找，页面里 AppDialog /
    // AppSheet / AppSnackbar 将永远找不到宿主，在 release 下静默无效。
    // 因此 content 的调用放在下方 Builder 内部，用 subtreeContext 调用。
    return Builder(
      builder: (subtreeContext) {
        // MiuixScaffold 的内边距在首帧布局后才上报（一帧沉降）：首帧
        // padding 为零会让内容先满屏再跳到顶栏下方（转场入场的页面表现
        // 为上下闪动）。首帧先只渲染背景色，第二帧起再出内容。
        if (widget.content != null &&
            contentPadding == EdgeInsets.zero &&
            (widget.topBar ?? widget.appBar) != null) {
          return const SizedBox.expand();
        }

        final stablePadding = _stabilizePadding(contentPadding);
        final Widget page;
        if (widget.content != null) {
          page = widget.content!(subtreeContext, stablePadding);
        } else {
          page = Padding(padding: stablePadding, child: widget.body);
        }

        // 折叠顶栏：自动把页面内容挂接滚动监听，页面无需自行包裹
        // MiuixScrollBehaviorListener（首页等自建顶栏的页面传
        // scrollBehavior 后同样生效；其内容若已自行包裹监听器，嵌套的
        // NotificationListener 只会重复回调同一次滚动，折叠量是纯函数，无害）。
        final Widget wired;
        final behavior = _collapse;
        if (behavior != null) {
          wired = MiuixScrollBehaviorListener(
            behavior: behavior,
            child: page,
          );
        } else {
          wired = page;
        }

        // 弹层挂载点：**始终**渲染同一形状的 Stack（即使没有弹层）。
        // 若按有无弹层在「page」与「Stack(page, overlay)」之间切换，
        // 弹出/收起弹层会让整棵页面子树失活重建——滚动位置丢失、状态
        // 重置，且弹层子树在失活期间的不安全祖先查找会触发
        // "Looking up a deactivated widget's ancestor is unsafe" 红屏。
        //
        // 两个细节缺一不可：
        // - 注册件必须用 Positioned.fill 定位。Stack 的尺寸由**非定位**
        //   子项决定（全是定位子项时取 constraints.biggest）；若注册件
        //   裸放（其 build 结果是 SizedBox.shrink），加入弹层的瞬间整个
        //   Stack 会收缩为 0×0，把 Positioned.fill 的页面内容一起压扁。
        // - 退场完成的弹层（spent）**不立即**从 Stack 移除。popup 层的
        //   entry 在 onDismissFinished 之后还要播放约 250ms 的遮罩淡出，
        //   期间它每次重建都会用注册件 build 时捕获的 in-tree context 查
        //   MiuixTheme（MiuixOverlayBottomSheet 的已知实现方式）；此刻
        //   失活会抛 "deactivated ancestor" 断言。挂载件原地只渲染
        //   SizedBox.shrink，常驻无视觉/交互开销，待 entry 确定摘除后再
        //   批量清理（见 [_finish] / [_purgeSpentOverlays]）。
        return Stack(
          children: [
            Positioned.fill(child: wired),
            for (final spec in _overlays)
              Positioned.fill(
                key: ObjectKey(spec),
                child: spec.buildOverlay(subtreeContext),
              ),
          ],
        );
      },
    );
  }
}

/// 一个挂载中的弹层（对话框或抽屉）。
class _AppOverlay<T> {
  _AppOverlay._({required this.completer});

  final Completer<T?> completer;

  /// 是否处于可见（含退场动画中）状态。
  bool show = true;

  /// 是否为底部抽屉（用于 closeSheet 定位）。
  bool isSheet = false;

  /// 关闭时携带的返回值。
  Object? result;

  /// 退场完成（onDismissFinished）的时间；非 null 即 spent——popup entry
  /// 已开始/完成摘除，挂载件常驻 Stack 只渲染 SizedBox.shrink，
  /// 待 [_purgeSpentOverlays] 批量清理。
  DateTime? spentAt;

  late final Widget Function(BuildContext context) buildOverlay;

  void complete() {
    if (!completer.isCompleted) {
      completer.complete(result is T? ? result as T? : null);
    }
  }
}

/// 统一顶栏 —— 可折叠的 HyperOS 大标题顶栏。
///
/// 作为 [AppScaffold] 的 `topBar` 传入：展开态显示大标题，内容滚动时
/// 逐像素折叠为小标题（毛玻璃）。滚动行为由 [AppCollapseScope] 提供
/// （AppScaffold 创建），脱离脚手架单独使用时自动自建。
///
/// [alwaysSmall] 为 true 时，使用静态小标题栏，不参与滚动折叠。
class AppHeader extends StatefulWidget {
  const AppHeader({
    super.key,
    this.title,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.actions,
    this.subtitle,
    this.alwaysSmall = false,
  });

  final String? title;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final List<Widget>? actions;
  final String? subtitle;
  final bool alwaysSmall;

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  MiuixExitUntilCollapsedScrollBehavior? _behavior;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.alwaysSmall) {
      _behavior ??= AppCollapseScope.maybeOf(context) ?? miuixScrollBehavior();
    }
  }

  /// 计算实际 leading：显式设置 > 自动回退 > 无。
  Widget? effectiveLeading(BuildContext context) {
    if (widget.leading != null) return widget.leading;
    if (widget.automaticallyImplyLeading && Navigator.of(context).canPop()) {
      return MiuixIconButton(
        onPressed: () => Navigator.of(context).maybePop(),
        child: const HiuiIcon(HiuiIcons.arrowBack),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.alwaysSmall) {
      return MiuixSmallTopAppBar(
        title: widget.title ?? '',
        subtitle: widget.subtitle ?? '',
        navigationIcon: effectiveLeading(context) ?? const SizedBox.shrink(),
        actions: widget.actions ?? const <Widget>[],
      );
    }
    return MiuixTopAppBar(
      title: widget.title ?? '',
      subtitle: widget.subtitle ?? '',
      scrollBehavior: _behavior,
      blurred: true,
      navigationIcon: effectiveLeading(context) ?? const SizedBox.shrink(),
      actions: widget.actions ?? const <Widget>[],
    );
  }
}
