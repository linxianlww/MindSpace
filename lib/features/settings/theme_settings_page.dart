import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/theme/md3e_tokens.dart';

/// 主题设置：浅色/深色/跟随系统、动态取色开关、种子色选择。
class ThemeSettingsPage extends ConsumerWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('主题设置')),
      body: ListView(
        children: [
          RadioGroup<ThemeMode>(
            groupValue: settings.themeMode,
            onChanged: (m) {
              if (m != null) notifier.setThemeMode(m);
            },
            child: Column(
              children: [
                for (final mode in ThemeMode.values)
                  RadioListTile<ThemeMode>(
                    value: mode,
                    title: Text(switch (mode) {
                      ThemeMode.light => '浅色',
                      ThemeMode.dark => '深色',
                      ThemeMode.system => '跟随系统',
                    }),
                    secondary: Icon(switch (mode) {
                      ThemeMode.light => Icons.light_mode_outlined,
                      ThemeMode.dark => Icons.dark_mode_outlined,
                      ThemeMode.system => Icons.smartphone_outlined,
                    }),
                  ),
              ],
            ),
          ),
          const Divider(),
          SwitchListTile(
            secondary: const Icon(Icons.auto_awesome_outlined),
            title: const Text('动态取色'),
            subtitle: const Text('Android 12+ 从壁纸取色（Material You）'),
            value: settings.useDynamicColor,
            onChanged: notifier.setDynamicColor,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('种子色（关闭动态取色时生效）',
                style: Theme.of(context).textTheme.titleSmall),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final e in Md3eTokens.seedPalette.entries)
                  GestureDetector(
                    onTap: () => notifier.setSeedColor(e.value.toARGB32()),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: e.value,
                      child: settings.seedColorValue == e.value.toARGB32()
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
