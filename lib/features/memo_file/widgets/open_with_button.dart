import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';

import '../../share/share_service.dart';

/// “用其他应用打开”按钮：调用系统应用处理该文件（open_filex）。
///
/// 加固：任何插件异常（如平台实现缺失）都会被捕获并给出反馈；
/// 若系统中没有能处理该类型的应用，则回退到系统分享面板。
class OpenWithButton extends ConsumerWidget {
  const OpenWithButton({super.key, required this.path});
  final String path;

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    try {
      final result = await OpenFilex.open(path);
      if (result.type == ResultType.done) return;
      // 常见失败：找不到可处理该 mime 的应用（noAppToOpen / fileError）。
      if (result.type == ResultType.noAppToOpen && context.mounted) {
        // 回退到系统分享面板，让用户选择目标应用。
        await ref.read(shareServiceProvider).shareFile(path);
        return;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('无法打开：${result.message}')),
        );
      }
    } catch (e) {
      // open_filex 抛出的异常不能吞掉，否则按钮看起来毫无反应。
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('无法打开：$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
      ),
      onPressed: () => _open(context, ref),
      icon: const Icon(Icons.open_in_new),
      label: const Text('用其他应用打开'),
    );
  }
}
