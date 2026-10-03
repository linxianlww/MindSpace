import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindspace/ui/design_system/app_design_system.dart';

import '../../core/di/providers.dart';

/// 主题设置：浅色 / 深色 / 跟随系统。
///
/// 配色固定为 MIUIX 默认 HyperOS 蓝，无动态取色与主题色设置。
class ThemeSettingsPage extends ConsumerWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final colors = MiuixTheme.of(context).colors;

    return AppScaffold(
      topBar: AppHeader(title: '主题设置'),
      content: (context, padding) => ListView(
        padding: padding,
        children: [
          MiuixSmallTitle('外观模式'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: MiuixSurface(
              cornerRadius: AppTokens.radiusMedium,
              color: colors.surfaceContainer,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 注意 onClick 恒为非空：传 null 会让选中行的 radio 进入
                  // 禁用配色（对勾发淡）。
                  for (final mode in ThemeMode.values)
                    MiuixRadioButtonPreference(
                      title: switch (mode) {
                        ThemeMode.light => '浅色',
                        ThemeMode.dark => '深色',
                        ThemeMode.system => '跟随系统',
                      },
                      selected: settings.themeMode == mode,
                      onClick: () => notifier.setThemeMode(mode),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
