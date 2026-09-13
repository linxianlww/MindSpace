import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindspace/core/widgets/state_views.dart';

void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('EmptyState 渲染标题、副标题与操作按钮并响应点击', (tester) async {
    var tapped = false;
    await tester.pumpWidget(host(
      EmptyState(
        title: '还没有铭记',
        subtitle: '点击右下角新建',
        actionLabel: '新建',
        onAction: () => tapped = true,
      ),
    ));

    expect(find.text('还没有铭记'), findsOneWidget);
    expect(find.text('点击右下角新建'), findsOneWidget);
    expect(find.text('新建'), findsOneWidget);

    await tester.tap(find.text('新建'));
    expect(tapped, isTrue);
  });

  testWidgets('ErrorState 渲染信息并可触发重试', (tester) async {
    var retried = false;
    await tester.pumpWidget(host(
      ErrorState(message: '出错了', onRetry: () => retried = true),
    ));
    expect(find.text('出错了'), findsOneWidget);
    await tester.tap(find.text('重试'));
    expect(retried, isTrue);
  });

  testWidgets('LoadingState 渲染加载指示与提示', (tester) async {
    await tester.pumpWidget(host(const LoadingState(hint: '加载中')));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('加载中'), findsOneWidget);
  });
}
