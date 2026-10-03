import 'package:flutter/widgets.dart';
import 'package:flutter_miuix/miuix.dart';

/// 统一加载指示器 —— MIUIX 无限旋转 ([MiuixInfiniteProgressIndicator])。
///
/// HyperOS 轨道点旋转动画，自动跟随主题 primary 色。
/// 有限进度用 [MiuixLinearProgressIndicator] / [MiuixCircularProgressIndicator]。
class AppCircleProgress extends StatelessWidget {
  const AppCircleProgress({
    super.key,
    this.size = 24,
    this.strokeWidth = 3,
    this.color,
  });

  final double size;
  final double strokeWidth;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: MiuixInfiniteProgressIndicator(
        color: color ?? MiuixTheme.of(context).colors.primary,
        size: size,
        strokeWidth: strokeWidth,
      ),
    );
  }
}
