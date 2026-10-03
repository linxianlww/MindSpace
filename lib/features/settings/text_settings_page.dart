import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindspace/ui/design_system/app_design_system.dart';

import '../../core/constants/app_constants.dart';
import '../../core/di/providers.dart';

/// 文本排版：行距与段距 + 长图水印后缀（分享为图片时显示在长图底部）。
class TextSettingsPage extends ConsumerWidget {
  const TextSettingsPage({super.key});

  static const double _minLine = 1.2;
  static const double _maxLine = 2.2;
  static const double _minPara = 0;
  static const double _maxPara = 32;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final miuixTheme = MiuixTheme.of(context);

    return AppScaffold(
      topBar: AppHeader(title: '文本排版'),
      content: (context, padding) => ListView(
        padding: padding,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: MiuixSurface(
              cornerRadius: AppTokens.radiusMedium,
              color: miuixTheme.colors.surfaceContainer,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MiuixSliderPreference(
                    title: '行距',
                    startAction: HiuiIcon(HiuiIcons.lineSpacing),
                    value: settings.lineHeight.clamp(_minLine, _maxLine),
                    min: _minLine,
                    max: _maxLine,
                    steps: 10,
                    showKeyPoints: true,
                    summary: '${settings.lineHeight.toStringAsFixed(1)} 倍字号',
                    onValueChange: notifier.setLineHeight,
                  ),
                  MiuixSliderPreference(
                    title: '段距',
                    startAction: HiuiIcon(HiuiIcons.spaceBar),
                    value: settings.paragraphSpacing.clamp(_minPara, _maxPara),
                    min: _minPara,
                    max: _maxPara,
                    steps: 16,
                    showKeyPoints: true,
                    summary: settings.paragraphSpacing.round() == 0
                        ? '无段距'
                        : '${settings.paragraphSpacing.round()} px',
                    onValueChange: notifier.setParagraphSpacing,
                  ),
                  AppListRow(
                    leading: HiuiIcon(HiuiIcons.share),
                    title: MiuixText('分享水印'),
                    subtitle: MiuixText(
                      '分享自 ${settings.shareImageWatermarkSuffix}',
                      style: TextStyle(
                          color: miuixTheme.colors.primary,
                          fontWeight: FontWeight.w600),
                    ),
                    trailing: HiuiIcon(HiuiIcons.edit, size: 18),
                    showArrow: false,
                    onTap: () => _editShareSuffix(context, ref),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: AppButton(
                variant: AppButtonStyle.outlined,
                onPressed: () => notifier.setShareImageWatermarkSuffix(
                    AppConstants.defaultShareImageSuffix),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HiuiIcon(HiuiIcons.reset),
                    const SizedBox(width: 8),
                    MiuixText('恢复默认水印（NekoBox）'),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: MiuixText(
              '行距与段距同步应用到阅读页、编辑器以及"分享为图片"长图排版。\n'
              '"分享为图片"的长图底部会显示「分享自 ___」水印后缀。',
              style: miuixTheme.textStyles.footnote1
                  .copyWith(color: miuixTheme.colors.onSurfaceVariantSummary),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: AppButton(
                variant: AppButtonStyle.outlined,
                onPressed: () {
                  notifier.setLineHeight(1.7);
                  notifier.setParagraphSpacing(10);
                  notifier.setShareImageWatermarkSuffix(
                      AppConstants.defaultShareImageSuffix);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HiuiIcon(HiuiIcons.reset),
                    const SizedBox(width: 8),
                    MiuixText('全部恢复默认'),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _editShareSuffix(BuildContext context, WidgetRef ref) async {
    final current = ref.read(settingsProvider).shareImageWatermarkSuffix;
    final ctrl = TextEditingController(text: current);
    try {
      final suffix = await AppDialog.show<String>(
        context: context,
        title: '分享水印后缀',
        content: AppInput(
          controller: ctrl,
          autofocus: true,
        ),
        actions: [
          MiuixTextButton(
            '取消',
            onPressed: () => AppDialog.close<void>(context),
          ),
          MiuixButton(
            onPressed: () => AppDialog.close<String>(context, ctrl.text),
            child: const MiuixText('确定'),
          ),
        ],
      );
      if (suffix != null && suffix.trim().isNotEmpty) {
        ref
            .read(settingsProvider.notifier)
            .setShareImageWatermarkSuffix(suffix);
      } else if (suffix != null && suffix.trim().isEmpty) {
        ref
            .read(settingsProvider.notifier)
            .setShareImageWatermarkSuffix(AppConstants.defaultShareImageSuffix);
      }
    } finally {
      ctrl.dispose();
    }
  }
}
