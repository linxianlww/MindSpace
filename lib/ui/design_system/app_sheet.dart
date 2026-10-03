import 'package:flutter/widgets.dart';
import 'package:flutter_miuix/miuix.dart';

import 'app_scaffold.dart';

/// 统一底部弹层入口 —— MIUIX [MiuixOverlayBottomSheet]。
///
/// [show] 把抽屉挂载到最近 [AppScaffold] 的弹层（MiuixScaffold popup 层），
/// HyperOS 原生底部抽屉动效（上滑进入、下拉关闭、弹簧平移）由 MIUIX 处理。
///
/// ```dart
/// AppSheet.show(context, title: '更多操作', builder: (ctx) => ...);
///
/// // 抽屉内容中关闭：
/// AppSheet.close(context);
/// AppSheet.close(context, result);
/// ```
class AppSheet {
  const AppSheet._();

  /// 显示底部抽屉，返回关闭时的结果值。
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    String? title,
    bool barrierDismissible = true,
    Size insideMargin = const Size(12, 0),
  }) {
    final scaffold = AppScaffold.maybeOf(context);
    if (scaffold == null) {
      assert(false, 'AppSheet.show 必须在 AppScaffold 子树内调用');
      return Future.value(null);
    }
    return scaffold.showSheet<T>(
      title: title,
      builder: builder,
      barrierDismissible: barrierDismissible,
      insideMargin: insideMargin,
    );
  }

  /// 关闭最上层的抽屉（抽屉内容自身调用，带可选返回值）。
  static void close<T>(BuildContext context, [T? result]) {
    final scaffold = AppScaffold.maybeOf(context);
    scaffold?.closeSheet<T>(result);
  }
}
