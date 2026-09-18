import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 若铭记设置了自定义颜色，用该铭记色作为种子色覆盖子树主题；否则不做任何改变。
///
/// 用于铭记卡片、查看页、编辑页：让「已设颜色」的铭记/页面以铭记色为
/// seed 渲染一整套 ColorScheme，未设颜色时沿用全局主题。
/// [useMd3eDualSeed] = true 时使用 MD3E 双种子取色（主种子来自铭记色，
/// 次种子按色相偏移33°自动生成协调色）。
class MemoScopedTheme extends StatelessWidget {
  const MemoScopedTheme({
    super.key,
    required this.colorValue,
    required this.brightness,
    required this.useMd3eDualSeed,
    required this.child,
  });

  final int? colorValue;
  final Brightness brightness;

  /// 使用 MD3E 双种子取色（true）还是 ColorScheme.fromSeed（false）。
  final bool useMd3eDualSeed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (colorValue == null) return child;
    final seed = Color(colorValue!);
    final ColorScheme scheme = useMd3eDualSeed
        ? AppTheme.dualSeedScheme(
            seed: seed,
            secondarySeed: _deriveSecondary(seed),
            brightness: brightness,
          )
        : ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    final ThemeData base = brightness == Brightness.dark
        ? AppTheme.dark(scheme)
        : AppTheme.light(scheme);
    return Theme(data: base, child: child);
  }

  /// 由主种子派生一个协调的次种子（色相+33°），使 secondary / tertiary 有足够对比。
  static Color _deriveSecondary(Color seed) {
    final hsl = HSLColor.fromColor(seed);
    return hsl.withHue((hsl.hue + 33) % 360).toColor();
  }
}
