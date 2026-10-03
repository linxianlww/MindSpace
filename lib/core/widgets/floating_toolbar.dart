import 'package:flutter/widgets.dart';
import 'package:flutter_miuix/miuix.dart';

import '../../ui/design_system/tokens.dart';

/// 浮动工具栏：毛玻璃卡片 + 横向滚动，MIUIX 风格（文本编辑等页内使用）。
class FloatingToolbar extends StatelessWidget {
  const FloatingToolbar({super.key, required this.items, this.height = 52});

  final List<ToolbarItem> items;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = MiuixTheme.of(context).colors;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final sysBottomPadding = MediaQuery.paddingOf(context).bottom;
    final double extraBottom = bottomInset <= 0 ? sysBottomPadding : 0.0;
    return Padding(
      padding: EdgeInsets.only(bottom: extraBottom),
      child: MiuixCard(
        cornerRadius: AppTokens.radiusBar,
        insideMargin: EdgeInsets.zero,
        feedbackType: MiuixPressFeedbackType.none,
        child: SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            itemCount: items.length,
            separatorBuilder: (_, __) => MiuixVerticalDivider(
              thickness: 0.75,
            ),
            itemBuilder: (_, i) {
              final item = items[i];
              final tooltip = item.tooltip;
              // MiuixIconButton 自带按压反馈（替代裸 GestureDetector）
              // 图标着色由调用方在构造 [ToolbarItem.icon] 时决定
              // （active 用 primary，否则 onSurfaceSecondary）。
              final Widget button = MiuixIconButton(
                onPressed: item.onTap,
                minWidth: 44,
                minHeight: 40,
                child: item.icon,
              );
              if (tooltip == null || tooltip.isEmpty) return button;
              return MiuixTooltipBox(
                tooltip: (ctx, _) => MiuixSurface(
                  color: colors.surface,
                  contentColor: colors.onSurface,
                  cornerRadius: AppTokens.radiusMedium,
                  shadowElevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    child: MiuixText(tooltip,
                        style: MiuixTheme.of(ctx).textStyles.footnote1),
                  ),
                ),
                child: button,
              );
            },
          ),
        ),
      ),
    );
  }
}

class ToolbarItem {
  const ToolbarItem({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.active = false,
  });

  /// 图标 widget（调用点用 `HiuiIcon(HiuiIcons.x, size: 22, color: ...)`）。
  final Widget icon;
  final VoidCallback onTap;
  final String? tooltip;
  final bool active;
}
