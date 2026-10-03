import 'package:flutter/widgets.dart';
import 'package:flutter_miuix/miuix.dart';

/// 统一圆形头像 —— MIUIX Squircle 裁切。
///
/// 使用 [MiuixSquircleBorder] 实现 HyperOS 标志性平滑圆角。
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.radius = 20,
    this.borderRadius,
    this.imageProvider,
    this.elevation = 0,
    this.border,
  });

  final Widget? child;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double radius;

  /// 自定义圆角半径；默认 40% 尺寸（MIUIX squircle 手感）
  final double? borderRadius;
  final ImageProvider? imageProvider;
  final double elevation;

  /// 可选边框（常用于选中态）
  final Border? border;

  @override
  Widget build(BuildContext context) {
    final colors = MiuixTheme.of(context).colors;
    final bg = backgroundColor ?? colors.primaryContainer;
    final fg = foregroundColor ?? colors.onPrimaryContainer;
    final size = radius * 2;
    final r = borderRadius ?? size * 0.4;

    Widget content;
    if (imageProvider != null) {
      content = Image(
        image: imageProvider!,
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    } else {
      content = Container(
        width: size,
        height: size,
        color: bg,
        child: Center(
          child: DefaultTextStyle(
            style: TextStyle(color: fg, fontSize: radius * 0.6),
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(
        color: imageProvider != null ? const Color(0x00000000) : bg,
        shape: MiuixSquircleBorder(cornerRadius: r),
        shadows: elevation > 0
            ? [
                BoxShadow(
                  color: colors.onSurface.withValues(alpha: 0.08),
                  blurRadius: elevation,
                  offset: Offset(0, elevation / 2),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }
}
