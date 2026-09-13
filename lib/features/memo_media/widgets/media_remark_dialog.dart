import 'package:flutter/material.dart';

/// 为单个媒体添加/修改备注标签。
class MediaRemarkDialog {
  const MediaRemarkDialog._();

  static Future<String?> show(BuildContext context, {String? initial}) {
    final ctrl = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('媒体备注'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 40,
          decoration: const InputDecoration(hintText: '给这张图片/视频加个备注'),
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
