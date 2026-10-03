import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindspace/ui/design_system/app_design_system.dart';

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
    return AppScaffold(
      topBar: AppHeader(
        title: '字体管理',
        actions: [
          AppTapIcon(
              icon: HiuiIcon(HiuiIcons.add), onPressed: () => _import(ref)),
        ],
      ),
      content: (context, padding) => fonts.when(
        loading: () => Padding(
          padding: padding,
          child: const Center(child: AppCircleProgress()),
        ),
        error: (e, _) => Padding(
          padding: padding,
          child: Center(child: MiuixText('$e')),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Padding(
              padding: padding,
              child: const Center(child: MiuixText('尚未导入字体，可导入 .ttf/.otf')),
            );
          }
          return ListView.builder(
            padding: padding,
            itemCount: list.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _FontTile(font: list[i]),
            ),
          );
        },
      ),
    );
  }
}

class _FontTile extends ConsumerWidget {
  const _FontTile({required this.font});
  final FontAsset font;

  /// 字体详情对话框：预览 + 导入时间。
  Future<void> _showDetails(BuildContext context) async {
    final family = await FontLoaderCache.ensure(font);
    if (!context.mounted) return;
    final miuixTheme = MiuixTheme.of(context);
    await AppDialog.show<void>(
      context: context,
      title: font.name,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MiuixText('永和九年，岁在癸丑。ABCabc 123',
              style: TextStyle(fontFamily: family, fontSize: 18)),
          const SizedBox(height: 12),
          MiuixText(
            '导入于 ${DateTime.fromMillisecondsSinceEpoch(font.createdAt)}',
            style: miuixTheme.textStyles.footnote1
                .copyWith(color: miuixTheme.colors.onSurfaceVariantSummary),
          ),
        ],
      ),
      actions: [
        MiuixTextButton(
          '知道了',
          onPressed: () => AppDialog.close<void>(context),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await AppDialog.show<bool>(
      context: context,
      title: '删除字体？',
      message: '确定删除「${font.name}」？',
      actions: [
        MiuixTextButton(
          '取消',
          onPressed: () => AppDialog.close<bool>(context, false),
        ),
        // 破坏性操作：主题错误色文字按钮（禁止硬编码 Colors.red）
        AppButton(
          variant: AppButtonStyle.text,
          onPressed: () => AppDialog.close<bool>(context, true),
          child: MiuixText('删除',
              style: TextStyle(color: MiuixTheme.of(context).colors.error)),
        ),
      ],
    );
    if (ok == true) {
      await ref.read(fontRepositoryProvider).delete(font);
      ref.invalidate(fontListProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<String>(
      future: FontLoaderCache.ensure(font),
      builder: (context, snap) {
        final family = snap.data;
        return MiuixBasicComponent(
          startAction: HiuiIcon(HiuiIcons.font),
          content: [
            MiuixText(font.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            MiuixText(
              '永和九年，岁在癸丑。ABCabc 123',
              style: TextStyle(fontFamily: family, fontSize: 16),
              color: MiuixTheme.of(context).colors.onSurfaceVariantSummary,
            ),
          ],
          endActions: [
            AppTapIcon(
              icon: HiuiIcon(HiuiIcons.trash),
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
          onClick: () => _showDetails(context),
        );
      },
    );
  }
}
