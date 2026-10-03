import 'package:flutter/widgets.dart';
import 'package:flutter_miuix/miuix.dart';

/// 统一设计令牌 —— MIUIX / HyperOS 风格。
///
/// 提供圆角、间距、动效、模糊、字号等设计常量，供所有 App* 组件使用。
class AppTokens {
  const AppTokens._();

  // —— 圆角 (Squircle-ready) ——
  static const double radiusSmall = 8;
  static const double radiusMedium = 16;
  static const double radiusLarge = 24;
  static const double radiusExtraLarge = 32;
  static const double radiusFull = 999; // 胶囊 / 全圆角

  // —— 组件圆角（对齐 HyperOS 控件规格）——
  static const double radiusCard = 26; // 卡片 24~28
  static const double radiusDialog = 28;
  static const double radiusFab = 20; // FAB 16~20
  static const double radiusSheet = 28;
  static const double radiusChip = 16;
  static const double radiusBar = 22; // 按钮 / 输入框胶囊感

  // —— 间距 ——
  static const double spacingXS = 4;
  static const double spacingS = 8;
  static const double spacingM = 16;
  static const double spacingL = 24;
  static const double spacingXL = 32;

  // —— 动效 (Folme spring presets) ——
  static const Duration durationFast = Duration(milliseconds: 180);
  static const Duration durationMedium = Duration(milliseconds: 320);

  /// 标准缓出 —— 进场/出现
  static const Curve curveStandard = Curves.easeOutCubic;

  /// MIUIX 按压弹簧 —— 通用按压/状态切换 (临界阻尼, response ≈ 0.35s)
  static SpringDescription pressSpring = MiuixMotion.pressSpring;

  /// MIUIX 弹性弹簧 —— 弹性切换 (轻微欠阻尼, response ≈ 0.45s)
  static SpringDescription bouncySpring = MiuixMotion.bouncySpring;

  // —— 液态玻璃 / 模糊 ——

  /// 默认模糊半径 (dp)，sigma = blurRadius × 0.45
  static const double blurRadius = 20.0;

  /// 最大模糊半径
  static const double blurRadiusMax = 150.0;

  /// 背景模糊叠加的半透明度
  static const double blurBackgroundAlpha = 0.55;

  // —— Squircle 超椭圆 ——

  /// 圆角瓦片尺寸相对 cornerRadius 的倍数；1.0 = 圆弧，1.1 = 连续圆角
  static const double squircleExtension = 1.1;

  // —— 字号 (补充 MIUIX 预设之外的中间值) ——
  static const double fontSizeSmall = 12;
  static const double fontSizeMedium = 14;
  static const double fontSizeLarge = 16;
  static const double fontSizeXL = 20;
  static const double fontSizeXXL = 24;

  // —— 布局 ——

  /// 底部导航栏高度
  static const double navBarHeight = 64;

  /// 悬浮导航栏圆角
  static const double floatingNavBarRadius = 50;

  /// 首页顶栏折叠高度
  static const double topBarCollapsedHeight = 52;

  /// 内容区域标准内边距
  static const EdgeInsets contentPadding = EdgeInsets.symmetric(horizontal: 16);

  /// 列表项标准内边距
  static const EdgeInsets listTilePadding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 12);

  /// 依据宽度决定瀑布流列数，覆盖 1:1 小屏与横屏平板等极端比例：
  /// 至少 2 列（保证小屏可读性），横屏平板 3~5 列。
  static int masonryColumns(double width) {
    if (width >= 1600) return 5;
    if (width >= 1200) return 4;
    if (width >= 800) return 3;
    return 2;
  }
}
