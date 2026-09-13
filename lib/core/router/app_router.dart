import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/folder/folder_page.dart';
import '../../features/home/home_page.dart';
import '../../features/memo_audio/audio_player_page.dart';
import '../../features/memo_audio/audio_recorder_page.dart';
import '../../features/memo_file/file_viewer_page.dart';
import '../../features/memo_media/media_editor_page.dart';
import '../../features/memo_media/media_viewer_page.dart';
import '../../features/memo_text/text_editor_page.dart';
import '../../features/memo_text/text_viewer_page.dart';
import '../../features/settings/backup_settings_page.dart';
import '../../features/settings/developer_info_page.dart';
import '../../features/settings/font_settings_page.dart';
import '../../features/settings/settings_page.dart';
import '../../features/settings/storage_settings_page.dart';
import '../../features/settings/theme_settings_page.dart';
import '../../features/share/share_image_page.dart';

/// 全局路由表（需求第 9 节）。
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (c, s) => _sharedAxis(const HomePage()),
      ),
      GoRoute(
        path: '/folder/:folderId',
        pageBuilder: (c, s) =>
            _sharedAxis(FolderPage(folderId: s.pathParameters['folderId']!)),
      ),
      // 文本铭记
      GoRoute(
        path: '/memo/text/:memoId/edit',
        pageBuilder: (c, s) =>
            _sharedAxis(TextEditorPage(memoId: s.pathParameters['memoId']!)),
      ),
      GoRoute(
        path: '/memo/text/:memoId',
        pageBuilder: (c, s) =>
            _sharedAxis(TextViewerPage(memoId: s.pathParameters['memoId']!)),
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
      // 分享为图片
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

/// 共享轴（Shared Axis）风格的页面转场：Fade + 轻微横向位移。
CustomTransitionPage<T> _sharedAxis<T>(Widget child) {
  return CustomTransitionPage<T>(
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, secondary, child) {
      final curved =
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.03, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
