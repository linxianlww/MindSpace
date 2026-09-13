import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/utils/font_loader.dart';
import '../../data/models/font_asset.dart';

/// 字体管理：导入（复制到 data/font 并 UUID 命名）、预览、删除。
class FontSettingsPage extends ConsumerWidget {
  const FontSettingsPage({super.key});

  Future<void> _import(WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ttf', 'otf'],
    );
    final path = result?.files.single.path;
    if (path == null) return;
    await ref
        .read(fontRepositoryProvider)
        .importFont(path, result!.files.single.name);
    ref.invalidate(fontListProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fonts = ref.watch(fontListProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('字体管理'),
        actions: [
          IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _import(ref)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _import(ref),
        icon: const Icon(Icons.file_upload_outlined),
        label: const Text('导入字体'),
      ),
      body: fonts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('尚未导入字体，可导入 .ttf/.otf'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (_, i) => _FontTile(font: list[i]),
          );
        },
      ),
    );
  }
}

class _FontTile extends ConsumerWidget {
  const _FontTile({required this.font});
  final FontAsset font;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<String>(
      future: FontLoaderCache.ensure(font),
      builder: (context, snap) {
        final family = snap.data;
        return Card(
          child: ListTile(
            leading: const Icon(Icons.font_download_outlined),
            title: Text(font.name,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('永和九年，岁在癸丑。ABCabc 123',
                style: TextStyle(fontFamily: family, fontSize: 16)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('删除字体？'),
                    content: Text('确定删除「${font.name}」？'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('取消')),
                      FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('删除')),
                    ],
                  ),
                );
                if (ok == true) {
                  await ref.read(fontRepositoryProvider).delete(font);
                  ref.invalidate(fontListProvider);
                }
              },
            ),
          ),
        );
      },
    );
  }
}
