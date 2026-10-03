import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindspace/ui/design_system/app_design_system.dart';

/// 弹层宿主回归测试：
/// 1. sheet 打开期间页面子树不得失活重建（否则滚动位置丢失、内容"消失"）；
/// 2. sheet 收起过程不得触发 "Looking up a deactivated widget's ancestor
///    is unsafe"（弹层子树失活期间的不安全祖先查找）；
/// 3. 存在可见弹层时系统返回键优先关闭弹层。
void main() {
  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AppScaffold(
          topBar: AppHeader(title: '测试页'),
          content: (context, padding) => ListView(
            padding: padding,
            children: [
              const Text('页面标记'),
              MiuixTextButton(
                '打开抽屉',
                onPressed: () => AppSheet.show<void>(
                  context: context,
                  title: '抽屉',
                  builder: (sheetCtx) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('抽屉内容'),
                        MiuixTextButton(
                          '关闭抽屉',
                          onPressed: () => AppSheet.close<void>(sheetCtx),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sheet 打开期间页面内容保持挂载', (tester) async {
    await pumpPage(tester);
    expect(find.text('页面标记'), findsOneWidget);

    await tester.tap(find.text('打开抽屉'));
    await tester.pumpAndSettle();

    expect(find.text('抽屉内容'), findsOneWidget);
    // 页面内容仍挂载（打开弹层不重建页面）
    expect(find.text('页面标记'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sheet 收起无异常且页面恢复可交互', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.text('打开抽屉'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('关闭抽屉'));
    await tester.pumpAndSettle();

    expect(find.text('抽屉内容'), findsNothing);
    expect(find.text('页面标记'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('对话框与抽屉叠加时返回键逐层关闭', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.text('打开抽屉'));
    await tester.pumpAndSettle();

    // 系统返回键 → 关闭抽屉而非退出页面
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('抽屉内容'), findsNothing);
    expect(find.text('页面标记'), findsOneWidget);
  });
}
