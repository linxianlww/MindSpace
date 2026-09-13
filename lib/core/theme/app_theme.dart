import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'md3e_tokens.dart';

/// 基于 Material 3 Expressive 的主题构建。
///
/// 外部（[AppThemeController]）决定使用动态取色还是种子色，再调用
/// [AppTheme.light]/[AppTheme.dark] 得到最终 [ThemeData]。
class AppTheme {
  const AppTheme._();

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

  /// 未开启动态取色 / 系统不支持时的兜底种子色方案。
  static ColorScheme _fallback(Brightness brightness) =>
      ColorScheme.fromSeed(
        seedColor: Md3eTokens.seedPalette['靛蓝']!,
        brightness: brightness,
      );

  static ThemeData _base(ColorScheme scheme) {
    final isLight = scheme.brightness == Brightness.light;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,
      // 全局字体由设置中的自定义字体在 app 层覆盖。
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface),
        systemOverlayStyle: isLight
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        elevation: 1.5,
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shadowColor: scheme.shadow.withValues(alpha: 0.18),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: Md3eTokens.cardBorder,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Md3eTokens.radiusBar),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Md3eTokens.radiusBar),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 3,
        highlightElevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Md3eTokens.radiusFab),
        ),
      ),
      dialogTheme: DialogThemeData(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: Md3eTokens.dialogBorder,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        elevation: 6,
        backgroundColor: scheme.surfaceContainerLow,
        modalElevation: 6,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: Md3eTokens.sheetBorder,
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Md3eTokens.radiusChip),
        ),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Md3eTokens.radiusBar),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Md3eTokens.radiusBar),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Md3eTokens.radiusBar),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.6),
        space: 1,
        thickness: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.secondaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 72,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Md3eTokens.radiusChip),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
