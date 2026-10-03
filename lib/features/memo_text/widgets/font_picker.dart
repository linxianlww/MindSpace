import 'package:file_picker/file_picker.dart';
import 'package:mindspace/ui/design_system/app_design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../data/models/font_asset.dart';

/// 字体选择底部弹层：默认字体 + 已导入字体 + 从文件导入（ttf/otf）。
class FontPicker extends ConsumerWidget {
  const FontPicker({super.key, required this.currentFontId, required this.onPicked});

  final String? currentFontId;
  final void Function(FontAsset? font) onPicked;

  /// [context] 必须位于 [AppScaffold] 子树内（页面级调用请传脚手架下方
  /// 的 context，否则找不到弹层宿主）。
  static Future<void> show(BuildContext context, WidgetRef ref,
      {String? currentFontId,
      required void Function(FontAsset? font) onPicked}) {
    return AppSheet.show<void>(
      context: context,
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
    if (context.mounted) AppSheet.close(context);
    onPicked(font);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fonts = ref.watch(fontListProvider);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 8),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppListRow(
                leading: const HiuiIcon(HiuiIcons.font),
                title: const MiuixText('默认字体'),
                trailing: currentFontId == null
                    ? HiuiIcon(HiuiIcons.check,
                        color:
                            MiuixTheme.of(context).colors.primary)
                    : null,
                showArrow: false,
                onTap: () {
                  AppSheet.close(context);
                  onPicked(null);
                },
              ),
              fonts.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: AppCircleProgress(),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: MiuixText('字体加载失败：$e'),
                ),
                data: (list) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final FontAsset f in list)
                      AppListRow(
                        leading: const HiuiIcon(HiuiIcons.font),
                        title: MiuixText(f.name,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: f.id == currentFontId
                            ? HiuiIcon(HiuiIcons.check,
                                color:
                                    MiuixTheme.of(context).colors.primary)
                            : null,
                        showArrow: false,
                        onTap: () {
                          AppSheet.close(context);
                          onPicked(f);
                        },
                      ),
                  ],
                ),
              ),
              const AppSeparator(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: AppButton(
                  onPressed: () => _import(ref, context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const HiuiIcon(HiuiIcons.add),
                      const SizedBox(width: 8),
                      const MiuixText('从文件导入字体 (.ttf/.otf)'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
