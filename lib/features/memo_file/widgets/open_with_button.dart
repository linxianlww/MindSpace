import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

/// “用其他应用打开”按钮：调用系统应用处理该文件（open_filex）。
class OpenWithButton extends StatelessWidget {
  const OpenWithButton({super.key, required this.path});
  final String path;

  Future<void> _open(BuildContext context) async {
    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('无法打开：${result.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
      ),
      onPressed: () => _open(context),
      icon: const Icon(Icons.open_in_new),
      label: const Text('用其他应用打开'),
    );
  }
}
