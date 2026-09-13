import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindspace/features/settings/developer_info_page.dart';

void main() {
  // 模拟 package_info_plus 平台通道，返回固定版本号。
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dev.fluttercommunity.plus/package_info');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getAll') {
        return {
          'appName': 'MindSpace',
          'packageName': 'com.aria.mindspace',
          'version': '1.2.3',
          'buildNumber': '42',
        };
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('关于与开发者页显示应用、版本、作者与开源项目', (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: DeveloperInfoPage()));
    // 等待 PackageInfo.fromPlatform 异步完成后重建。
    await tester.pumpAndSettle();

    expect(find.text('MindSpace'), findsOneWidget);
    expect(find.text('版本 1.2.3 (42)'), findsOneWidget);
    expect(find.text('咏叹调 Aria'), findsOneWidget);
    expect(find.text('https://linxianlww.github.io/'), findsOneWidget);
    expect(find.text('开源项目'), findsOneWidget);
    // 顶部可见的开源项目条目。
    expect(find.text('Flutter'), findsOneWidget);

    // ListView 懒加载，持续滚动直到下方条目构建出现。
    await tester.scrollUntilVisible(
      find.text('just_audio'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('just_audio'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('感谢所有开源项目的贡献者'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('感谢所有开源项目的贡献者'), findsOneWidget);
  });
}
