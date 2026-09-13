import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/utils/file_utils.dart';

/// 非常规文件的详细信息卡：名称、大小、类型、路径、修改时间。
class FileInfoCard extends StatelessWidget {
  const FileInfoCard({
    super.key,
    required this.name,
    required this.path,
    required this.sizeBytes,
    required this.ext,
  });

  final String name;
  final String path;
  final int sizeBytes;
  final String ext;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final modified =
        File(path).existsSync() ? File(path).statSync().modified : null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: scheme.secondaryContainer,
                  child: Icon(Icons.description_outlined,
                      color: scheme.onSecondaryContainer),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: Theme.of(context).textTheme.titleMedium),
                      Text('.${ext.isEmpty ? '未知' : ext}  ·  ${FileUtils.humanSize(sizeBytes)}',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _row(context, '路径', path),
            if (modified != null) _row(context, '修改时间', modified.toString()),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 72,
                child: Text(k,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
            Expanded(child: SelectableText(v)),
          ],
        ),
      );
}
