import 'package:flutter/widgets.dart';
import 'package:flutter_miuix/miuix.dart';

import 'app_scaffold.dart';

/// 统一对话框入口 —— MIUIX [MiuixOverlayDialog]。
///
/// [show] 把对话框挂载到最近 [AppScaffold] 的弹层（MiuixScaffold popup 层），
/// 遮罩、HyperOS 弹簧动效、大小屏布局与键盘避让全部由 MIUIX 处理。
///
/// ```dart
/// AppDialog.show(
///   context,
///   title: '删除铭记',
///   message: '删除后可在回收站恢复。',
///   actions: [
///     MiuixTextButton('取消', onPressed: () => AppDialog.close(context)),
///     MiuixButton(
///       onPressed: () => AppDialog.close(context, true),
///       child: const MiuixText('删除'),
///     ),
///   ],
/// );
/// ```
class AppDialog {
  const AppDialog._();

  /// 显示对话框，返回关闭时的结果值。
  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    String? message,
    Widget? content,
    List<Widget>? actions,
    bool barrierDismissible = true,
  }) {
    final scaffold = AppScaffold.maybeOf(context);
    if (scaffold == null) {
      assert(false, 'AppDialog.show 必须在 AppScaffold 子树内调用');
      return Future.value(null);
    }
    return scaffold.showDialog<T>(
      title: title,
      summary: message,
      content: content,
      actions: actions,
      barrierDismissible: barrierDismissible,
    );
  }

  /// 关闭（从对话框内容或按钮回调中调用）。
  ///
  /// 典型的确认对话框按钮：
  /// ```dart
  /// MiuixTextButton('确定', onPressed: () => AppDialog.close(context, true))
  /// ```
  static void close<T>(BuildContext context, [T? result]) {
    final scaffold = AppScaffold.maybeOf(context);
    scaffold?.closeDialog<T>(result);
  }
}
