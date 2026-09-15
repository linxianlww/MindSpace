import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/theme/md3e_tokens.dart';

/// 主题设置：浅色/深色/跟随系统、动态取色开关、种子色（预设 + 取色器自定义 HEX）。
class ThemeSettingsPage extends ConsumerWidget {
  const ThemeSettingsPage({super.key});

  /// 用户自定义的种子色 HEX 文案（ARGB → #RRGGBB）。
  static String hexLabel(int? argb) {
    if (argb == null) return '-';
    final rgb = argb & 0xFFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  Future<void> _openPicker(
      BuildContext context, WidgetRef ref, Color current) async {
    Color picked = current;
    final saved = await showDialog<Color>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('自定义种子色'),
          content: SizedBox(
            width: 340,
            child: SingleChildScrollView(
              child: SizedBox(
                height: 360,
                child: ColorPicker(
                  pickerColor: picked,
                  onColorChanged: (c) => setState(() => picked = c),
                  enableAlpha: false,
                  displayThumbColor: true,
                  hexInputBar: true,
                  labelTypes: const [ColorLabelType.hex],
                  paletteType: PaletteType.hsv,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, picked),
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
    if (saved != null) {
      await ref.read(settingsProvider.notifier).setSeedColor(saved.toARGB32());
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final isBrandDefault = settings.seedColorValue == null;

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
          // 预设色板
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
                      // 品牌默认（未自定义）时在"亮橙"上打勾，
                      // 自定义后与已选预设匹配时打勾。
                      child:
                          (isBrandDefault && e.value.toARGB32() ==
                                  Md3eTokens.brandSeed.toARGB32()) ||
                                  settings.seedColorValue ==
                                      e.value.toARGB32()
                              ? const Icon(Icons.check, color: Colors.white)
                              : null,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              isBrandDefault
                  ? '当前：品牌默认（亮橙 · 红，符合 MD3E 双种子取色）'
                  : '当前：自定义 ${hexLabel(settings.seedColorValue)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 8),
          // 取色器自定义 HEX
          ListTile(
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: settings.seedColor,
              child: const Icon(Icons.colorize, color: Colors.white, size: 20),
            ),
            title: const Text('取色器自定义颜色'),
            subtitle: Text('从色盘 / HEX 输入框选择任意颜色作为种子色'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openPicker(
              context,
              ref,
              settings.seedColor,
            ),
          ),
          // 恢复品牌默认（亮橙+红）
          if (!isBrandDefault)
            ListTile(
              leading: const Icon(Icons.restart_alt),
              title: const Text('恢复品牌默认（亮橙 · 红）'),
              onTap: () => notifier.setSeedColor(null),
            ),
        ],
      ),
    );
  }
}