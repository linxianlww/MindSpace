import 'package:flutter/material.dart';

/// 屏幕响应式工具。
///
/// 目标：让所有布局在极端屏幕比例下都完整显示在屏幕内——
/// 包括 1:1（近方形）小屏、以及 16:9 / 16:10 / 3:2 横屏平板。
/// 策略：所有棋盘/瀑布流布局按“可用宽度 ÷ 目标最小单元格宽”推导列数，
/// 而不是写死 2/3/4 列。
class ScreenUtils {
  const ScreenUtils._();

  /// 依据可用宽度推导列数。
  ///
  /// [minCell] 为期望的单个单元格最小宽度（逻辑像素）；
  /// [maxColumns] 防止极宽屏上列数失控。
  static int columns(double width, {double minCell = 150, int maxColumns = 6}) {
    if (width <= 0) return 1;
    final n = (width / minCell).floor();
    return n.clamp(1, maxColumns);
  }

  /// 是否为“紧凑/1:1 小屏”（窄宽、纵横比接近 1 或小于屏）。
  /// 用于决定是否需要单列、隐藏次要装饰等。
  static bool isCompact(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // 1:1 小屏特征：宽高接近且绝对宽度小。
    return size.width < 400 || (size.width <= 480 && size.height <= 480);
  }

  /// 是否为横屏平板（宽度明显大于高度，且宽度足够宽）。
  static bool isLandscapeTablet(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.width > size.height && size.width >= 800;
  }
}
