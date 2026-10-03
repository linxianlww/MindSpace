import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Material 兼容桥主题。
///
/// 应用 UI 全部由 MIUIX（`MiuixTheme`）驱动，配色唯一来源是 app.dart 中的
/// `MiuixThemeController`（HyperOS 标准蓝，无全局主题色设置）。此文件只
/// 生成一份最小 [ThemeData]，供仍以 Material 语义渲染的第三方组件内部
/// 使用（flutter_quill 工具栏、chewie 控制条、pdfrx 上下文菜单等），
/// 确保它们的观感与 MIUIX 调色板一致。业务代码不得依赖此主题。
class AppTheme {
  const AppTheme._();

  /// miuix 默认浅色 primary（HyperOS 蓝），用于 Material 兜底种子。
  static const Color _fallbackSeed = Color(0xFF3482FF);

  static ThemeData light(ColorScheme? dynamicScheme) {
    final scheme = dynamicScheme?.brightness == Brightness.light
        ? dynamicScheme!
        : _fallback(Brightness.light);
    return _base(scheme);
  }

  static ThemeData dark(ColorScheme? dynamicScheme) {
    final scheme = dynamicScheme?.brightness == Brightness.dark
        ? dynamicScheme!
        : _fallback(Brightness.dark);
    return _base(scheme);
  }

  /// 未拿到 MIUIX 派生配色时的兜底方案。
  static ColorScheme _fallback(Brightness brightness) =>
      ColorScheme.fromSeed(seedColor: _fallbackSeed, brightness: brightness);

  static ThemeData _base(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      dialogTheme: DialogThemeData(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.6),
        space: 1,
        thickness: 1,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          // Android 14+ 预测性返回（滑动跟随系统手势动画，低版本自动回退）。
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
