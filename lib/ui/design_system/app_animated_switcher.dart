import 'package:flutter/widgets.dart';

/// 动画过渡 —— 直接透传 Flutter AnimatedSwitcher。
class AppAnimatedSwitcher extends StatelessWidget {
  const AppAnimatedSwitcher({
    super.key,
    required this.duration,
    required this.child,
    this.reverseDuration,
    this.switchInCurve,
    this.switchOutCurve,
    this.transitionBuilder,
    this.layoutBuilder,
  });

  final Duration duration;
  final Widget? child;
  final Duration? reverseDuration;
  final Curve? switchInCurve;
  final Curve? switchOutCurve;
  final AnimatedSwitcherTransitionBuilder? transitionBuilder;
  final AnimatedSwitcherLayoutBuilder? layoutBuilder;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      reverseDuration: reverseDuration,
      switchInCurve: switchInCurve ?? Curves.linear,
      switchOutCurve: switchOutCurve ?? Curves.linear,
      transitionBuilder: transitionBuilder ?? AnimatedSwitcher.defaultTransitionBuilder,
      layoutBuilder: layoutBuilder ?? AnimatedSwitcher.defaultLayoutBuilder,
      child: child,
    );
  }
}
