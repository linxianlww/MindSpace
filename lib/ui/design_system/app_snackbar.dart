import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// 统一轻提示入口 —— 系统 Toast。
///
/// 提示使用系统级 Toast（与 Android 原生 Toast 样式一致），
/// 不会受页面脚手架 / FAB 位置影响。
///
/// ```dart
/// AppSnackbar.show(context, message: '保存完成');
/// ```
class AppSnackbar {
  const AppSnackbar._();

  /// 显示一条系统 Toast 轻提示。
  static void show(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    // actionLabel / onAction 在系统 Toast 中忽略（Android Toast 不支持动作按钮）。
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      fontSize: 14.0,
    );
  }
}
