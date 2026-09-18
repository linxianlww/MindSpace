import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/folder/folder_page.dart';
import '../../features/home/home_page.dart';
import '../../features/memo_anniversary/anniversary_edit_page.dart';
import '../../features/memo_anniversary/anniversary_view_page.dart';
import '../../features/memo_audio/audio_player_page.dart';
import '../../features/memo_audio/audio_recorder_page.dart';
import '../../features/memo_file/file_viewer_page.dart';
import '../../features/memo_media/media_editor_page.dart';
import '../../features/memo_media/media_viewer_page.dart';
import '../../features/memo_text/text_editor_page.dart';
import '../../features/memo_todo/todo_edit_page.dart';
import '../../features/memo_totp/totp_edit_page.dart';
import '../../features/memo_totp/totp_scan_page.dart';
import '../../features/memo_totp/totp_view_page.dart';
import '../../features/settings/backup_settings_page.dart';
import '../../features/settings/developer_info_page.dart';
import '../../features/settings/font_settings_page.dart';
import '../../features/settings/settings_page.dart';
import '../../features/settings/storage_settings_page.dart';
import '../../features/settings/text_settings_page.dart';
import '../../features/settings/theme_settings_page.dart';
import '../../features/share/share_image_page.dart';

/// 全局路由观察者：供页面感知返回（如主页收起搜索框）。
final rootRouteObserver = RouteObserver<ModalRoute<dynamic>>();

/// 全局路由表（需求第 9 节）。
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    observers: [rootRouteObserver],
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (c, s) => _sharedAxis(const HomePage()),
      ),
      GoRoute(
        path: '/folder/:folderId',
        pageBuilder: (c, s) =>
            _fade(FolderPage(folderId: s.pathParameters['folderId']!)),
      ),
      // 文本铭记（直接进入编辑页，不主动弹键盘）
      GoRoute(
        path: '/memo/text/:memoId/edit',
        pageBuilder: (c, s) =>
            _sharedAxis(TextEditorPage(memoId: s.pathParameters['memoId']!)),
      ),
      GoRoute(
        path: '/memo/text/:memoId',
        pageBuilder: (c, s) =>
            _sharedAxis(TextEditorPage(memoId: s.pathParameters['memoId']!)),
      ),
      // 待办（直接进入编辑页，不主动弹键盘）
      GoRoute(
        path: '/memo/todo/:memoId/edit',
        pageBuilder: (c, s) =>
            _sharedAxis(TodoEditPage(memoId: s.pathParameters['memoId']!)),
      ),
      GoRoute(
        path: '/memo/todo/:memoId',
        pageBuilder: (c, s) =>
            _sharedAxis(TodoEditPage(memoId: s.pathParameters['memoId']!)),
      ),
      // 媒体集
      GoRoute(
        path: '/memo/media/:memoId/edit',
        pageBuilder: (c, s) =>
            _sharedAxis(MediaEditorPage(memoId: s.pathParameters['memoId']!)),
      ),
      GoRoute(
        path: '/memo/media/:memoId',
        pageBuilder: (c, s) =>
            _sharedAxis(MediaViewerPage(memoId: s.pathParameters['memoId']!)),
      ),
      // 音频
      GoRoute(
        path: '/memo/audio/:memoId/record',
        pageBuilder: (c, s) =>
            _sharedAxis(AudioRecorderPage(memoId: s.pathParameters['memoId']!)),
      ),
      GoRoute(
        path: '/memo/audio/:memoId',
        pageBuilder: (c, s) =>
            _sharedAxis(AudioPlayerPage(memoId: s.pathParameters['memoId']!)),
      ),
      // 文件
      GoRoute(
        path: '/memo/file/:memoId',
        pageBuilder: (c, s) =>
            _sharedAxis(FileViewerPage(memoId: s.pathParameters['memoId']!)),
      ),
      // TOTP 验证码
      GoRoute(
        path: '/memo/totp/:memoId',
        pageBuilder: (c, s) =>
            _sharedAxis(TotpViewPage(memoId: s.pathParameters['memoId']!)),
      ),
      GoRoute(
        path: '/memo/totp/:memoId/edit',
        pageBuilder: (c, s) =>
            _sharedAxis(TotpEditPage(memoId: s.pathParameters['memoId']!)),
      ),
      GoRoute(
        path: '/memo/totp/:memoId/scan',
        pageBuilder: (c, s) => _sharedAxis(const TotpScanPage()),
      ),
      // 纪念日
      GoRoute(
        path: '/memo/anniversary/:memoId',
        pageBuilder: (c, s) =>
            _sharedAxis(AnniversaryViewPage(memoId: s.pathParameters['memoId']!)),
      ),
      GoRoute(
        path: '/memo/anniversary/:memoId/edit',
        pageBuilder: (c, s) =>
            _sharedAxis(AnniversaryEditPage(memoId: s.pathParameters['memoId']!)),
      ),
      GoRoute(
        path: '/share/image/:memoId',
        pageBuilder: (c, s) =>
            _sharedAxis(ShareImagePage(memoId: s.pathParameters['memoId']!)),
      ),
      // 设置
      GoRoute(
        path: '/settings/developer',
        pageBuilder: (c, s) => _sharedAxis(const DeveloperInfoPage()),
      ),
      GoRoute(
        path: '/settings/theme',
        pageBuilder: (c, s) => _sharedAxis(const ThemeSettingsPage()),
      ),
      GoRoute(
        path: '/settings/text',
        pageBuilder: (c, s) => _sharedAxis(const TextSettingsPage()),
      ),
      GoRoute(
        path: '/settings/font',
        pageBuilder: (c, s) => _sharedAxis(const FontSettingsPage()),
      ),
      GoRoute(
        path: '/settings/storage',
        pageBuilder: (c, s) => _sharedAxis(const StorageSettingsPage()),
      ),
      GoRoute(
        path: '/settings/backup',
        pageBuilder: (c, s) => _sharedAxis(const BackupSettingsPage()),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (c, s) => _sharedAxis(const SettingsPage()),
      ),
    ],
    errorBuilder: (c, s) => Scaffold(
      appBar: AppBar(title: const Text('页面不存在')),
      body: Center(child: Text(s.error?.toString() ?? '未知路由')),
    ),
  );
});

/// iOS 风格滑入式转场：新页面从右侧推入，上一页向左滑出（带回退视差）。
/// 近似 CupertinoPageRoute 的体验：推入 350ms，支持边缘右滑返回。
/// 次级页（被推出的那一层）叠加半透明黑色遮罩，避免两页色彩混淆。
CustomTransitionPage<T> _iosSlide<T>(Widget child) {
  return CustomTransitionPage<T>(
    child: child,
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondary, child) {
      final curved =
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      final secondaryCurved =
          CurvedAnimation(parent: secondary, curve: Curves.easeInCubic);
      return Stack(
        children: [
          // 次级页黑色遮罩：从 0 → 0.25 随推入进程加深。
          FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 0.25).animate(secondaryCurved),
            child: const ColoredBox(color: Colors.black),
          ),
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(curved),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset.zero,
                end: const Offset(-0.3, 0),
              ).animate(secondaryCurved),
              child: child,
            ),
          ),
        ],
      );
    },
  );
}

/// 文件夹层级切换用的「淡入淡出」转场：新页淡入，旧页淡出（用于进入文件夹）。
CustomTransitionPage<T> _fade<T>(Widget child) {
  return CustomTransitionPage<T>(
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondary, child) {
      final curved =
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      final secondaryCurved =
          CurvedAnimation(parent: secondary, curve: Curves.easeInCubic);
      return Stack(
        children: [
          FadeTransition(opacity: secondaryCurved, child: const SizedBox.shrink()),
          FadeTransition(opacity: curved, child: child),
        ],
      );
    },
  );
}

// 兼容旧引用的别名（转场统一为 iOS 风格）。
CustomTransitionPage<T> _sharedAxis<T>(Widget child) => _iosSlide(child);
