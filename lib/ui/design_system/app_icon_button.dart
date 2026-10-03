import 'package:flutter/widgets.dart';
import 'package:flutter_miuix/miuix.dart';

/// 统一图标按钮。使用 [MiuixIconButton]。
class AppTapIcon extends StatelessWidget {
  const AppTapIcon({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 24,
    this.color,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? MiuixTheme.of(context).colors.onSurface;
    final Widget iconWidget = color != null
        ? IconTheme(
            data: IconThemeData(color: resolvedColor, size: size),
            child: icon,
          )
        : icon;
    return MiuixIconButton(
      onPressed: onPressed,
      child: iconWidget,
    );
  }
}
