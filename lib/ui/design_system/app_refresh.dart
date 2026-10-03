import 'package:flutter/widgets.dart';
import 'package:flutter_miuix/miuix.dart';

/// 下拉刷新 —— MIUIX [MiuixPullToRefresh] 风格。
///
/// 用法与 Material [RefreshIndicator] 类似，但视觉全面 HyperOS 化：
/// - 圆形进度环替代线性进度条
/// - 弹簧回弹手感
/// - 跟随 MIUIX 主题色
class AppRefresh extends StatefulWidget {
  const AppRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.controller,
    this.color,
    this.isRefreshing = false,
    this.contentPadding = EdgeInsets.zero,
    this.topAppBarScrollBehavior,
  });

  /// 下拉刷新回调 —— 返回 Future，完成后刷新自动结束
  final Future<void> Function() onRefresh;

  /// 被包裹的可滚动内容
  final Widget child;

  /// 控制器 —— 可外部驱动刷新状态
  final MiuixPullToRefreshController? controller;

  /// 进度环颜色；默认跟随主题 primary
  final Color? color;

  /// 外部传入的刷新状态
  final bool isRefreshing;

  /// 内容区 padding
  final EdgeInsetsGeometry contentPadding;

  /// 页面折叠顶栏的滚动行为；传入后下拉手势与标题折叠联动，
  /// 避免下拉时标题与刷新指示器争抢滚动位移。
  final MiuixScrollBehavior? topAppBarScrollBehavior;

  @override
  State<AppRefresh> createState() => _AppRefreshState();
}

class _AppRefreshState extends State<AppRefresh> {
  MiuixPullToRefreshController? _internalController;
  MiuixPullToRefreshController get _controller =>
      widget.controller ?? (_internalController ??= MiuixPullToRefreshController());

  bool _isRefreshing = false;

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MiuixPullToRefresh(
      isRefreshing: widget.isRefreshing || _isRefreshing,
      onRefresh: _handleRefresh,
      controller: _controller,
      contentPadding: widget.contentPadding,
      topAppBarScrollBehavior: widget.topAppBarScrollBehavior,
      color: widget.color ?? MiuixTheme.of(context).colors.primary,
      child: widget.child,
    );
  }
}
