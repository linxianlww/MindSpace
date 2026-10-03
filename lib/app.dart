import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_miuix/miuix.dart';

import 'core/di/providers.dart';
import 'core/router/app_router.dart';
import 'core/share/share_receiver_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_logger.dart';
import 'features/desktop_shortcut/desktop_shortcut_service.dart';
import 'features/memo_media/media_provider.dart';

/// 应用根组件：MIUIX 主题 + 路由。
class NekoBoxApp extends ConsumerStatefulWidget {
  const NekoBoxApp({super.key});

  @override
  ConsumerState<NekoBoxApp> createState() => _NekoBoxAppState();
}

class _NekoBoxAppState extends ConsumerState<NekoBoxApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // 私密空间：监听前后台切换（进入后台即锁定）
    WidgetsBinding.instance.addObserver(this);
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 进入后台时锁定私密空间（防止被他人看到或被截屏）。
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      final service = ref.read(privateSpaceServiceProvider);
      if (service.hasPin && service.sessionUnlocked) {
        appLogger.i('私密空间：应用进入后台 → 锁定');
        service.lock();
      }
    }
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

    final bool? themeDark = settings.themeMode == ThemeMode.dark
        ? true
        : settings.themeMode == ThemeMode.light
            ? false
            : null;
    final bool resolvedDark = themeDark ??
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;

    // 状态栏 / 导航栏图标明暗随主题（MIUIX 不负责系统栏样式）。
    SystemChrome.setSystemUIOverlayStyle(
      resolvedDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );

    return MiuixThemeController(
      isDark: themeDark,
      // HyperOS 标准蓝：system 模式按深浅色取 miuix 默认配色
      //（浅色 primary 0xFF3482FF / 深色 0xFF277AF7），不读壁纸、无全局主题色设置。
      colorSchemeMode: MiuixColorSchemeMode.system,
      child: Builder(
        builder: (context) {
          final mx = MiuixTheme.of(context);
          final materialScheme = _miuixToColorScheme(mx);
          return MaterialApp.router(
            title: 'NekoBox',
            debugShowCheckedModeBanner: false,
            themeMode: settings.themeMode,
            theme: AppTheme.light(materialScheme),
            darkTheme: AppTheme.dark(materialScheme),
            routerConfig: router,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              FlutterQuillLocalizations.delegate,
            ],
            supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
          );
        },
      ),
    );
  }
}

/// 从 MIUIX 主题色彩构造 Material [ColorScheme]，使两套件调色板一致。
///
/// MIUIX 颜色体系不含 tertiary/outlineVariant/shadow 等 MD3 token，
/// 缺失字段以 [ColorScheme.fromSeed] 推导兜底，确保两套件整体一致。
ColorScheme _miuixToColorScheme(MiuixThemeData mx) {
  final c = mx.colors;
  final fallback = ColorScheme.fromSeed(
    seedColor: c.primary,
    brightness: mx.brightness,
  );
  return ColorScheme(
    brightness: mx.brightness,
    primary: c.primary,
    onPrimary: c.onPrimary,
    primaryContainer: c.primaryContainer,
    onPrimaryContainer: c.onPrimaryContainer,
    secondary: c.secondary,
    onSecondary: c.onSecondary,
    secondaryContainer: c.secondaryContainer,
    onSecondaryContainer: c.onSecondaryContainer,
    tertiary: fallback.tertiary,
    onTertiary: fallback.onTertiary,
    tertiaryContainer: c.tertiaryContainer,
    onTertiaryContainer: c.onTertiaryContainer,
    error: c.error,
    onError: c.onError,
    errorContainer: c.errorContainer,
    onErrorContainer: c.onErrorContainer,
    surface: c.surface,
    onSurface: c.onSurface,
    surfaceContainerHighest: c.surfaceContainerHighest,
    onSurfaceVariant: c.onSurfaceSecondary,
    outline: c.outline,
    outlineVariant: fallback.outlineVariant,
    shadow: fallback.shadow,
    scrim: fallback.scrim,
    inverseSurface: fallback.inverseSurface,
    onInverseSurface: fallback.onInverseSurface,
    inversePrimary: fallback.inversePrimary,
    surfaceTint: c.primary,
  );
}
