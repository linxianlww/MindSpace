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
  /// 默认品牌配色：亮橙 + 红双种子（MD3E），红色仅接管 secondary 角色。
  static ColorScheme _fallback(Brightness brightness) => dualSeedScheme(
        seed: Md3eTokens.brandSeed,
        secondarySeed: Md3eTokens.brandSecondarySeed,
        brightness: brightness,
      );

  /// MD3E 双种子取色：主种子生成整套色调方案，次种子仅接管 secondary 角色
  /// （含容器色与固定色），使次级色独立出自红色调——
  /// 当前 Flutter 的 `fromSeed` 只接受单一 seedColor，故用此公开 API 组合实现。
  static ColorScheme dualSeedScheme({
    required Color seed,
    required Color secondarySeed,
    required Brightness brightness,
  }) {
    final scheme =
        ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    final sec =
        ColorScheme.fromSeed(seedColor: secondarySeed, brightness: brightness);
    return scheme.copyWith(
      secondary: sec.primary,
      onSecondary: sec.onPrimary,
      secondaryContainer: sec.primaryContainer,
      onSecondaryContainer: sec.onPrimaryContainer,
      secondaryFixed: sec.primaryFixed,
      secondaryFixedDim: sec.primaryFixedDim,
      onSecondaryFixed: sec.onPrimaryFixed,
      onSecondaryFixedVariant: sec.onPrimaryFixedVariant,
    );
  }

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
          // Android 14+ 预测性返回（滑动跟随系统手势动画，低版本自动回退）。
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
