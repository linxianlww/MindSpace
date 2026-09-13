import 'package:flutter/material.dart';

/// 备注标签编辑弹框，返回新备注；清空返回空串。
class RemarkEditor {
  const RemarkEditor._();

  static Future<String?> show(BuildContext context, {String? initial}) {
    final ctrl = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('备注标签'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 30,
          decoration: const InputDecoration(hintText: '例如：重要 / 灵感 / 待办'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
