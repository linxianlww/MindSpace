import 'package:flutter/material.dart';
import 'package:flutter_miuix/miuix.dart';

enum AppButtonStyle { filled, outlined, text }

/// 统一按钮 —— 直接包装 MIUIX [MiuixButton] + Squircle 形状。
///
/// - filled: 主色背景 + onPrimary 文字
/// - outlined: 透明背景 + Squircle 细边框 + primary 文字
/// - text:    透明背景 + primary 文字
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.variant = AppButtonStyle.filled,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final AppButtonStyle variant;

  @override
  Widget build(BuildContext context) {
    if (variant == AppButtonStyle.outlined) {
      return _MiuixOutlinedButton(onPressed: onPressed, child: child);
    }

    final colors = MiuixTheme.of(context).colors;
    final isFilled = variant == AppButtonStyle.filled;

    return MiuixButton(
      onPressed: onPressed,
      colors: isFilled
          ? MiuixButtonDefaults.buttonColorsPrimary(context)
          : MiuixButtonColors(
              color: Colors.transparent,
              disabledColor: Colors.transparent,
              contentColor: colors.primary,
              disabledContentColor: colors.onSurfaceSecondary,
            ),
      child: _fit(child),
    );
  }

  /// 防止图标+长文本按钮在窄屏上横向溢出（RenderFlex overflow 黄色条纹）。
  ///
  /// MIUIX 按钮内部用 [Center] 约束子项（有界宽松约束），当
  /// 图标+文本的固有宽度超过按钮内宽时，Row 会直接溢出。用
  /// `FittedBox(scaleDown)` 把超宽内容等比缩小以适配按钮，正常宽度
  /// 时视觉不变。
  static Widget _fit(Widget child) =>
      FittedBox(fit: BoxFit.scaleDown, child: child);
}

/// Outlined 按钮：透明背景 + Squircle 边框 + 文字取 primary 色。
///
/// MIUIX [MiuixButton] 无 outlined 变体，故使用 [MiuixSurface] + 边框实现
/// 液态玻璃边框按钮。
class _MiuixOutlinedButton extends StatelessWidget {
  const _MiuixOutlinedButton({required this.onPressed, required this.child});

  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = MiuixTheme.of(context).colors;
    final enabled = onPressed != null;
    final borderColor = enabled ? colors.outline : colors.disabledOnSecondaryVariant;
    final textColor = enabled ? colors.primary : colors.onSurfaceSecondary;

    return MiuixSurface(
      cornerRadius: 16,
      squircleEnabled: true,
      border: Border.all(color: borderColor, width: 1),
      onPressed: onPressed,
      enabled: enabled,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: DefaultTextStyle.merge(
          textAlign: TextAlign.center,
          style: MiuixTheme.of(context).textStyles.button.copyWith(
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
          child: Center(child: AppButton._fit(child)),
        ),
      ),
    );
  }
}
