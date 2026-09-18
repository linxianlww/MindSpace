import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('文本排版')),
      body: ListView(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.format_line_spacing),
                    title: const Text('行距'),
                    subtitle: Text(
                      '${settings.lineHeight.toStringAsFixed(1)} 倍字号',
                      style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  Slider(
                    value: settings.lineHeight.clamp(_minLine, _maxLine),
                    min: _minLine,
                    max: _maxLine,
                    divisions: 10,
                    label:
                        settings.lineHeight.toStringAsFixed(1),
                    onChanged: (v) => notifier.setLineHeight(v),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.space_bar),
                    title: const Text('段距'),
                    subtitle: Text(
                      settings.paragraphSpacing.round() == 0
                          ? '无段距'
                          : '${settings.paragraphSpacing.round()} px',
                      style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  Slider(
                    value: settings.paragraphSpacing.clamp(_minPara, _maxPara),
                    min: _minPara,
                    max: _maxPara,
                    divisions: 16,
                    label: settings.paragraphSpacing.round().toString(),
                    onChanged: (v) => notifier.setParagraphSpacing(v),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.ios_share_outlined),
                    title: const Text('分享水印'),
                    subtitle: Text(
                      '分享自 ${settings.shareImageWatermarkSuffix}',
                      style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600),
                    ),
                    trailing: const Icon(Icons.edit, size: 18),
                    onTap: () => _editShareSuffix(context, ref),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44)),
              onPressed: () =>
                  notifier.setShareImageWatermarkSuffix(AppConstants.defaultShareImageSuffix),
              icon: const Icon(Icons.restart_alt),
              label: const Text('恢复默认水印（NekoBox）'),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: Text(
              '行距与段距同步应用到阅读页、编辑器以及“分享为图片”长图排版。\n'
              '“分享为图片”的长图底部会显示「分享自 ___」水印后缀。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(44)),
              onPressed: () {
                notifier.setLineHeight(1.7);
                notifier.setParagraphSpacing(10);
                notifier.setShareImageWatermarkSuffix(
                    AppConstants.defaultShareImageSuffix);
              },
              icon: const Icon(Icons.restart_alt),
              label: const Text('全部恢复默认'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editShareSuffix(BuildContext context, WidgetRef ref) async {
    final current =
        ref.read(settingsProvider).shareImageWatermarkSuffix;
    final ctrl = TextEditingController(text: current);
    final suffix = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('分享水印后缀'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 20,
          decoration: const InputDecoration(
            hintText: '将显示在分享长图底部',
            prefixText: '分享自 ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: const Text('确定')),
        ],
      ),
    );
    if (suffix != null) {
      ref.read(settingsProvider.notifier).setShareImageWatermarkSuffix(suffix);
    }
  }
}
