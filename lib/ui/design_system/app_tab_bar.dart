import 'package:flutter/widgets.dart';
import 'package:flutter_miuix/miuix.dart';

/// 统一标签栏 —— MIUIX [MiuixTabRow]。
///
/// 横向可滚动，选中项以 squircle 背景指示；
/// `contour: true` 使用 [MiuixTabRowWithContour] 外轮廓样式。
class AppTabStrip extends StatelessWidget {
  const AppTabStrip({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.contour = false,
    this.scrollController,
  });

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  /// 是否启用带外轮廓的标签栏样式
  final bool contour;

  /// 横向滚动控制器
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    if (contour) {
      return MiuixTabRowWithContour(
        tabs: tabs,
        selectedTabIndex: selectedIndex,
        onTabSelected: onTabSelected,
        scrollController: scrollController,
      );
    }
    return MiuixTabRow(
      tabs: tabs,
      selectedTabIndex: selectedIndex,
      onTabSelected: onTabSelected,
      scrollController: scrollController,
    );
  }
}
