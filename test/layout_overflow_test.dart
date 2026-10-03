import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mindspace/app.dart';
import 'package:mindspace/core/constants/app_constants.dart';
import 'package:mindspace/core/database/app_database.dart';
import 'package:mindspace/core/di/providers.dart';
import 'package:mindspace/core/storage/mindspace_storage.dart';
import 'package:mindspace/features/home/home_page.dart';

/// 布局回归测试：在矮屏视口下逐页 pump，捕获 RenderFlex 溢出异常。
/// （用户反馈：scaffold 高度溢出、文本出现黄色下划线 = 调试模式溢出条纹）
void main() {
  late AppDatabase db;
  late SharedPreferences prefs;

  setUp(() async {
    // 测试中 AppDatabase.forTesting 与 app 内 provider 各建一次实例，
    // 这是预期行为，静音 drift 的重复实例警告。
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.customStatement('PRAGMA foreign_keys = ON');
    PackageInfo.setMockInitialValues(
      appName: 'NekoBox',
      packageName: 'aria.neko.box',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
      installerStore: null,
    );
    // 真实 app 在 main() 中初始化 MindspaceStorage；测试环境手动指向临时目录
    final tmp = await Directory.systemTemp.createTemp('mindspace_overflow_test');
    MindspaceStorage.instance
      ..supportDir = tmp
      ..baseDir = Directory(p.join(tmp.path, AppConstants.mindspaceDirName))
      ..rootDir =
          Directory(p.join(tmp.path, AppConstants.mindspaceDirName, AppConstants.rootDirName))
      ..foldersDir =
          Directory(p.join(tmp.path, AppConstants.mindspaceDirName, AppConstants.foldersDirName))
      ..fontDir = Directory(p.join(tmp.path, AppConstants.fontDirName))
      ..cacheThumbDir = Directory(p.join(tmp.path, 'cache', 'thumb'));
  });

  Future<void> pumpSized(
    WidgetTester tester, {
    required Size size,
    String? route,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWith((ref) => db),
        ],
        child: const NekoBoxApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    if (route != null && route != '/') {
      final ctx = tester.element(find.byType(HomePage));
      final router = GoRouter.of(ctx);
      router.go(route);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  /// 卸载整棵树并冲刷 drift 关闭流的零时长定时器，
  /// 避免测试结束时报 "A Timer is still pending"。
  Future<void> flushTimers(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  }

  // 每个页面在 4 种矮屏尺寸下渲染，溢出异常会使测试失败。
  Future<void> verifySizes(WidgetTester tester, String label,
      {String? route}) async {
    final sizes = const <Size>[
      Size(360, 640), // 常见小屏手机
      Size(320, 568), // iPhone SE 1
      Size(280, 560), // 极矮
      Size(320, 480), // 老安卓
    ];
    for (final size in sizes) {
      final captured = <FlutterErrorDetails>[];
      final oldHandler = FlutterError.onError;
      FlutterError.onError = (details) => captured.add(details);
      await pumpSized(tester, size: size, route: route);
      FlutterError.onError = oldHandler;

      if (captured.isNotEmpty) {
        final buf = StringBuffer();
        for (final d in captured) {
          buf.writeln('=== $label @ $size ===');
          buf.writeln(d.exception);
          final collector = d.informationCollector;
          if (collector != null) {
            for (final node in collector()) {
              buf.writeln(node.toStringDeep());
            }
          }
        }
        // ignore: avoid_print
        debugDumpRenderTree();
        fail(buf.toString());
      }
      expect(tester.takeException(), isNull, reason: '$label @ $size');
      await flushTimers(tester);
    }
  }

  testWidgets('主页布局：矮屏无溢出', (tester) async {
    await verifySizes(tester, 'HomePage');
  });

  testWidgets('设置页布局：矮屏无溢出', (tester) async {
    await verifySizes(tester, 'SettingsPage', route: '/settings');
  });

  testWidgets('主题设置页布局：矮屏无溢出', (tester) async {
    await verifySizes(tester, 'ThemeSettingsPage', route: '/settings/theme');
  });

  testWidgets('文本排版页布局：矮屏无溢出', (tester) async {
    await verifySizes(tester, 'TextSettingsPage', route: '/settings/text');
  });

  testWidgets('存储管理页布局：矮屏无溢出', (tester) async {
    await verifySizes(tester, 'StorageSettingsPage', route: '/settings/storage');
  });

  testWidgets('字体管理页布局：矮屏无溢出', (tester) async {
    await verifySizes(tester, 'FontSettingsPage', route: '/settings/font');
  });

  testWidgets('备份与恢复页布局：矮屏无溢出', (tester) async {
    await verifySizes(tester, 'BackupSettingsPage', route: '/settings/backup');
  });

  testWidgets('私密空间设置页布局：矮屏无溢出', (tester) async {
    await verifySizes(tester, 'PrivateSpaceSettingsPage',
        route: '/settings/private_space');
  });

  testWidgets('关于与开发者页布局：矮屏无溢出', (tester) async {
    await verifySizes(tester, 'DeveloperInfoPage',
        route: '/settings/developer');
  });
}
