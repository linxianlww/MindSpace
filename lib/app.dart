import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/di/providers.dart';
import 'core/router/app_router.dart';
import 'core/share/share_receiver_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/md3e_tokens.dart';
import 'core/utils/app_logger.dart';
import 'features/desktop_shortcut/desktop_shortcut_service.dart';
import 'features/memo_media/media_provider.dart';

/// 应用根组件：主题（动态取色 / 种子色）+ 路由。
class NekoBoxApp extends ConsumerStatefulWidget {
  const NekoBoxApp({super.key});

  @override
  ConsumerState<NekoBoxApp> createState() => _NekoBoxAppState();
}

class _NekoBoxAppState extends ConsumerState<NekoBoxApp> {
  @override
  void initState() {
    super.initState();
    // 启动时自愈：清除缓存 / 缩略图生成失败后，缺失的缩略图在下次
    // 启动也能被重新生成，保证主页与媒体集永远有图可显示。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mediaControllerProvider).repairThumbnails().catchError((e) {
        appLogger.w('启动缩略图修复失败', e);
        return 0;
      });

      // 启动分享接收器：连接 Android native MethodChannel/EventChannel
      // 冷启动场景下 getInitialShare 会被 Event+MethodChannel 双通道触发；
      // 热启动（onNewIntent）由 EventChannel 推送。
      try {
        ref.read(shareReceiverServiceProvider).start();
      } catch (e) {
        appLogger.w('ShareReceiver 启动失败', e);
      }

      // 处理桌面快捷方式 deep link 启动：若由快捷图标打开，直接跳转到对应铭记。
      _handleInitialDeepLink();
    });
  }

  Future<void> _handleInitialDeepLink() async {
    try {
      final uri = await DesktopShortcutService.getInitialDeepLink();
      if (uri == null || !mounted) return;
      final route = DesktopShortcutService.parseDeepLinkToRoute(uri);
      if (route != null) {
        // 延迟一跳，确保根路由已就位
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          // 使用 GoRouter 的 go() 替换根路由（contextless API）
          ref.read(appRouterProvider).go(route);
        }
      }
    } catch (e) {
      appLogger.w('桌面快捷方式 deep link 处理失败', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final settings = ref.watch(settingsProvider);

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final userSeed = settings.seedColorValue;

        ColorScheme lightScheme;
        ColorScheme darkScheme;
        if (settings.useDynamicColor &&
            (lightDynamic != null || darkDynamic != null)) {
          // Android 12+ 壁纸取色；系统无动态方案时回退到品牌默认配色。
          lightScheme = lightDynamic ??
              AppTheme.dualSeedScheme(
                seed: Md3eTokens.brandSeed,
                secondarySeed: Md3eTokens.brandSecondarySeed,
                brightness: Brightness.light,
              );
          darkScheme = darkDynamic ??
              AppTheme.dualSeedScheme(
                seed: Md3eTokens.brandSeed,
                secondarySeed: Md3eTokens.brandSecondarySeed,
                brightness: Brightness.dark,
              );
        } else if (userSeed != null) {
          // 用户通过取色器/预设自定义的 HEX 种子色（单种子取色）。
          lightScheme = ColorScheme.fromSeed(
              seedColor: Color(userSeed), brightness: Brightness.light);
          darkScheme = ColorScheme.fromSeed(
              seedColor: Color(userSeed), brightness: Brightness.dark);
        } else {
          // 品牌默认：亮橙主种子 + 红次种子（MD3E 双种子取色）。
          lightScheme = AppTheme.dualSeedScheme(
            seed: Md3eTokens.brandSeed,
            secondarySeed: Md3eTokens.brandSecondarySeed,
            brightness: Brightness.light,
          );
          darkScheme = AppTheme.dualSeedScheme(
            seed: Md3eTokens.brandSeed,
            secondarySeed: Md3eTokens.brandSecondarySeed,
            brightness: Brightness.dark,
          );
        }

        return MaterialApp.router(
          title: 'NekoBox',
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
