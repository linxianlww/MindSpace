import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/di/providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/md3e_tokens.dart';

/// 应用根组件：主题（动态取色 / 种子色）+ 路由。
class MindSpaceApp extends ConsumerWidget {
  const MindSpaceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final settings = ref.watch(settingsProvider);

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final seed = settings.seedColorValue != null
            ? Color(settings.seedColorValue!)
            : Md3eTokens.seedPalette['靛蓝'];

        ColorScheme lightScheme;
        ColorScheme darkScheme;
        if (settings.useDynamicColor &&
            (lightDynamic != null || darkDynamic != null)) {
          // Android 12+ 壁纸取色。
          lightScheme = lightDynamic ??
              ColorScheme.fromSeed(seedColor: seed!, brightness: Brightness.light);
          darkScheme = darkDynamic ??
              ColorScheme.fromSeed(seedColor: seed!, brightness: Brightness.dark);
        } else {
          lightScheme = ColorScheme.fromSeed(
              seedColor: seed!, brightness: Brightness.light);
          darkScheme = ColorScheme.fromSeed(
              seedColor: seed, brightness: Brightness.dark);
        }

        return MaterialApp.router(
          title: 'MindSpace',
          debugShowCheckedModeBanner: false,
          themeMode: settings.themeMode,
          theme: AppTheme.light(lightScheme),
          darkTheme: AppTheme.dark(darkScheme),
          routerConfig: router,
          // flutter_quill 需要本地化委托。
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
          supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
        );
      },
    );
  }
}
