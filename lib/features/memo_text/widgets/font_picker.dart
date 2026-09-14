import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/md3e_tokens.dart';
import '../../../data/models/font_asset.dart';

/// 字体选择底部弹层：默认字体 + 已导入字体 + 从文件导入（ttf/otf）。
class FontPicker extends ConsumerWidget {
  const FontPicker({super.key, required this.currentFontId, required this.onPicked});

  final String? currentFontId;
  final void Function(FontAsset? font) onPicked;

  static Future<void> show(BuildContext context, WidgetRef ref,
      {String? currentFontId,
      required void Function(FontAsset? font) onPicked}) {
    return showModalBottomSheet(
      context: context,
      // 横屏下内容可能超出默认高度，允许占满全屏并内部滚动。
      isScrollControlled: true,
      builder: (_) =>
          FontPicker(currentFontId: currentFontId, onPicked: onPicked),
    );
  }

  Future<void> _import(WidgetRef ref, BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ttf', 'otf'],
    );
    final path = result?.files.single.path;
    if (path == null) return;
    final name = result!.files.single.name;
    final font =
        await ref.read(fontRepositoryProvider).importFont(path, name);
    ref.invalidate(fontListProvider);
    if (context.mounted) Navigator.pop(context);
    onPicked(font);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fonts = ref.watch(fontListProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            ListTile(
              leading: const Icon(Icons.font_download_off_outlined),
              title: const Text('默认字体'),
              trailing: currentFontId == null
                  ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () {
                Navigator.pop(context);
                onPicked(null);
              },
            ),
            fonts.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('字体加载失败：$e'),
              ),
              data: (list) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final FontAsset f in list)
                    ListTile(
                      leading: const Icon(Icons.font_download_outlined),
                      title: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: f.id == currentFontId
                          ? Icon(Icons.check,
                              color: Theme.of(context).colorScheme.primary)
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        onPicked(f);
                      },
                    ),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Md3eTokens.radiusBar)),
                ),
                onPressed: () => _import(ref, context),
                icon: const Icon(Icons.add),
                label: const Text('从文件导入字体 (.ttf/.otf)'),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}
