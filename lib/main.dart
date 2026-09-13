import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/di/providers.dart';
import 'core/storage/mindspace_storage.dart';
import 'core/utils/app_logger.dart';

Future<void> main() async {
  // 确保插件绑定可用。
  WidgetsFlutterBinding.ensureInitialized();

  // 全局 Flutter 框架错误捕获。
  FlutterError.onError = (details) {
    appLogger.e('FlutterError', details.exception, details.stack);
  };
  // 框架外的异步错误捕获。
  PlatformDispatcher.instance.onError = (error, stack) {
    appLogger.e('PlatformDispatcher', error, stack);
    return true;
  };

  // 初始化本地存储（全部位于应用私有目录）。
  await MindspaceStorage.instance.init();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: const MindSpaceApp(),
    ),
  );
}
