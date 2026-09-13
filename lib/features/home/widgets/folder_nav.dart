import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/folder.dart';
import '../home_provider.dart';

/// 文件夹面包屑：根 / 一级 / 二级 ...，点击任意层级返回。
class FolderNav extends ConsumerWidget {
  const FolderNav({super.key, required this.currentFolderId});

  final String? currentFolderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (currentFolderId == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.home_rounded, size: 18),
            const SizedBox(width: 6),
            Text('全部铭记', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
    }
    final chain = ref.watch(breadcrumbProvider(currentFolderId));
    return chain.when(
      loading: () => const SizedBox(height: 36),
      error: (_, __) => const SizedBox(height: 36),
      data: (folders) => SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            _crumb(context, ref, '全部铭记', null),
            for (final Folder f in folders)
              Row(
                children: [
                  const Icon(Icons.chevron_right_rounded, size: 18),
                  _crumb(context, ref, f.name, f.id),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _crumb(
      BuildContext context, WidgetRef ref, String label, String? id) {
    final selected = id == currentFolderId;
    return TextButton(
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        foregroundColor: selected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      onPressed: selected
          ? null
          : () => ref.read(currentFolderIdProvider.notifier).state = id,
      child: Text(label),
    );
  }
}
