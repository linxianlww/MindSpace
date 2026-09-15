import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';

/// 文本排版：行距与段距（作用于阅读页、编辑器及分享长图排版）。
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
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: Text(
              '行距与段距会同步应用到阅读页、编辑器与“分享为图片”生成的长图排版。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
              onPressed: () {
                notifier.setLineHeight(1.7);
                notifier.setParagraphSpacing(10);
              },
              icon: const Icon(Icons.restart_alt),
              label: const Text('恢复默认（行距 1.7 · 段距 10）'),
            ),
          ),
        ],
      ),
    );
  }
}