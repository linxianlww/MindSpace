import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/memo.dart';
import 'desktop_shortcut_service.dart';
import 'icon_picker_sheet.dart';

/// 添加到桌面的完整工作流。
///
/// 1. 弹出 [showIconPickerSheet] 让用户选择图标（自定义图片 or 首字符自动生成）。
/// 2. 调用原生 [DesktopShortcutService] 创建桌面快捷方式。
/// 3. 显示 SnackBar 告知用户结果。
///
/// 在铭记详情页或长按操作表中均可复用此函数。
Future<void> addMemoToDesktop(
  BuildContext context,
  WidgetRef ref,
  Memo memo,
) async {
  if (!context.mounted) return;
  final pickerResult = await showIconPickerSheet(
    context,
    initialTitle: memo.title,
  );
  if (pickerResult.isCanceled || !context.mounted) return;

  final bool ok;
  if (pickerResult.isAutoChar) {
    ok = await DesktopShortcutService.create(
      memoId: memo.id,
      memoType: memo.type,
      title: memo.title,
      bgColor: memo.color,
    );
  } else {
    ok = await DesktopShortcutService.create(
      memoId: memo.id,
      memoType: memo.type,
      title: memo.title,
      iconBytes: pickerResult.bytes,
      bgColor: memo.color,
    );
  }

  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(ok
          ? '已添加到桌面${memo.title.isNotEmpty ? "：${memo.title}" : ""}'
          : '添加失败，系统可能不支持桌面快捷方式'),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ),
  );
}
