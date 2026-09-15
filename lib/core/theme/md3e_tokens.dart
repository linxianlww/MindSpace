import 'package:flutter/material.dart';

/// Material 3 Expressive 设计令牌。
///
/// MD3E 强调大圆角、柔和高度、弹性动效与鲜明色彩，这里集中管理，
/// 避免各页面硬编码数值导致风格不一致。
class Md3eTokens {
  const Md3eTokens._();

  // —— 圆角 ——
  static const double radiusCard = 26; // 卡片 24~28
  static const double radiusDialog = 28;
  static const double radiusFab = 20; // FAB 16~20
  static const double radiusSheet = 28;
  static const double radiusChip = 16;
  static const double radiusBar = 22;

  static const BorderRadius cardBorder =
      BorderRadius.all(Radius.circular(radiusCard));
  static const BorderRadius dialogBorder =
      BorderRadius.all(Radius.circular(radiusDialog));
  static const BorderRadius sheetBorder = BorderRadius.vertical(
    top: Radius.circular(radiusSheet),
  );

  // —— 间距 ——
  static const double gapS = 8;
  static const double gapM = 16;
  static const double gapL = 24;
  static const EdgeInsets pagePadding = EdgeInsets.all(16);

  // —— 动效：MD3E 偏好的弹性/强调曲线 ——
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 320);
  static const Curve emphasized = Curves.easeOutBack; // FAB 展开弹性
  static const Curve standard = Curves.easeOutCubic;

  // —— 瀑布流 ——
  /// 依据宽度决定列数，覆盖 1:1 小屏与横屏平板等极端比例：
  /// 至少 2 列（保证小屏可读性），横屏平板 3~5 列。
  static int masonryColumns(double width) {
    if (width >= 1600) return 5;
    if (width >= 1200) return 4;
    if (width >= 800) return 3;
    return 2;
  }

  // —— 品牌色（NekoBox）：亮橙主种子 + 红次种子，符合 MD3E 双种子取色规范 ——
  /// 品牌主种子色：亮橙。
  static const Color brandSeed = Color(0xFFFF6D00);
  /// 品牌次种子色：红（MD3E 双种子取色，丰富衍生调色板）。
  static const Color brandSecondarySeed = Color(0xFFE53935);

  // —— 备选种子色板（设置页可切换，也可用取色器自定义 HEX）——
  static const Map<String, Color> seedPalette = {
    '亮橙': Color(0xFFFF6D00),
    '红': Color(0xFFE53935),
    '暖橙': Color(0xFF8B4A00),
    '靛蓝': Color(0xFF5B5BD6),
    '青绿': Color(0xFF00696E),
    '玫红': Color(0xFFB0005B),
    '森绿': Color(0xFF3B6B2E),
  };
}
