import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'core/di/providers.dart';
import 'core/router/app_router.dart';
import 'core/share/share_receiver_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/md3e_tokens.dart';
import 'core/utils/app_logger.dart';
import 'data/models/memo_type.dart';
import 'features/desktop_shortcut/desktop_shortcut_service.dart';
import 'features/home/widgets/native_home_widget_service.dart';
import 'features/memo_media/media_provider.dart';

/// 应用根组件：主题（动态取色 / 种子色）+ 路由。
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

      // 监听小组件点击事件（EventChannel 推送）
      _listenWidgetClicks();

      // 处理由小组件点击触发的 deep link（如 widget/create/text）
      _handleInitialWidgetDeepLink();
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

  /// 监听小组件点击事件（通过 EventChannel 推送，含热启动场景）
  void _listenWidgetClicks() {
    NativeHomeWidgetService.instance.widgetClickStream.listen((uriStr) {
      if (!mounted) return;
      final uri = Uri.tryParse(uriStr);
      if (uri != null) {
        _routeFromWidgetUri(uri);
      }
    }).onError((e) {
      appLogger.w('小组件点击监听错误', e);
    });
  }

  /// 处理小组件按钮点击带来的 deep link（冷启动场景）
  Future<void> _handleInitialWidgetDeepLink() async {
    try {
      final launched = await NativeHomeWidgetService.instance.initialWidgetUri();
      if (launched == null || !mounted) return;
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      _routeFromWidgetUri(launched);
    } catch (e) {
      appLogger.w('小组件 deep link 处理失败', e);
    }
  }

  /// 根据 widget 触发的 Uri 路由到对应页面
  void _routeFromWidgetUri(Uri uri) {
    // 处理 host=widget 的小组件直接操作（create/toggle-todo/open*）
    if (uri.host == 'widget') {
      final segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segs.isEmpty) return;
      // 使用 if-is 避免 switch-case 穿透：case 'create' 之前没有 break 导致穿透到 toggle-todo
      if (segs[0] == 'create' && segs.length >= 2) {
        _openCreate(segs[1]);
      } else if (segs[0] == 'toggle-todo' && segs.length >= 2) {
        _toggleTodo(segs[1]);
      } else if (segs[0].startsWith('open')) {
        // 标题栏点击（openMemoList/openTodoList/openMediaList）：回到主页。
        ref.read(appRouterProvider).go('/');
      }
      return;
    }
    // 处理 host=memo 的铭记跳转（来自小组件点击）
    if (uri.host == 'memo') {
      final memoUri = uri.toString();
      final route = DesktopShortcutService.parseDeepLinkToRoute(memoUri);
      if (route != null) {
        ref.read(appRouterProvider).go(route);
      }
    }
  }

  Future<void> _openCreate(String type) async {
    // 与主页 FAB 新建流程保持一致：先落库创建空白铭记拿到真实 id，
    // 再进入对应编辑页。不能直接 push /memo/text/new/edit——
    // 路由 :memoId 会把字面量 "new" 当成铭记 id，查无此铭记，进入错误页。
    try {
      final repo = ref.read(memoRepositoryProvider);
      switch (type) {
        case 'text':
          final memo = await repo.createBlank(
            MemoType.text,
            title: '无标题文本',
          );
          if (mounted) {
            ref.read(appRouterProvider).push('/memo/text/${memo.id}/edit');
          }
        case 'todo':
          final memo = await repo.createBlank(
            MemoType.todo,
            title: '新待办',
          );
          if (mounted) {
            ref.read(appRouterProvider).push('/memo/todo/${memo.id}/edit');
          }
        default:
          // 未知类型：不做任何事
          break;
      }
    } catch (e) {
      appLogger.w('小组件新建铭记失败', e);
    }
  }

  void _toggleTodo(String todoItemId) {
    // 通过 HomeWidgetService 切换状态
    // 需要先获取 widget 对应的 todoMemoId
    // 此逻辑在具体实现时扩展
    debugPrint('Toggle todo item: $todoItemId');
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
