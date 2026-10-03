import 'package:flutter/widgets.dart';
import 'package:flutter_miuix/miuix.dart';

import 'hiui_icons.dart';

/// 统一列表行。使用 [MiuixBasicComponent]（MIUIX 原生基础组件）。
///
/// 直接复用 MIUIX 基础组件，获得按压反馈、启用语义与 2:5:3 布局约束。
/// 纯文本 title / subtitle 时启用 MIUIX 原生样式（headline1/body2 + w500），
/// 同时保留自定义 TextStyle 中的颜色语义（如警示红）。
class AppListRow extends StatelessWidget {
  const AppListRow({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showArrow = true,
  });

  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// 是否在末尾显示右箭头。
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    final colors = MiuixTheme.of(context).colors;

    final List<Widget> trailingWidgets = <Widget>[
      if (trailing != null) trailing!,
      if (showArrow && onTap != null)
        HiuiIcon(
          HiuiIcons.chevronRight,
          size: 16,
          color: colors.onSurfaceVariantActions,
        ),
    ];

    final bool hasTrailing = trailingWidgets.isNotEmpty;

    // 纯文本模式 */
    if (title is Text && (subtitle == null || subtitle is Text)) {
      final Text titleText = title as Text;
      final Text? subtitleText =
          subtitle is Text ? (subtitle! as Text) : null;

      // 提取 title 自定义 TextStyle 中的颜色，保留警示色等语义。
      final Color? titleCustomColor = titleText.style?.color;
      final Color? subtitleCustomColor = subtitleText?.style?.color;

      return MiuixBasicComponent(
        title: titleText.data ?? '',
        titleColor: titleCustomColor != null
            ? MiuixBasicComponentColors(
                color: titleCustomColor,
                disabledColor: colors.disabledOnSecondaryVariant,
              )
            : null,
        summary: subtitleText?.data,
        summaryColor: subtitleCustomColor != null
            ? MiuixBasicComponentColors(
                color: subtitleCustomColor,
                disabledColor: colors.disabledOnSecondaryVariant,
              )
            : null,
        startAction: leading,
        endActions: hasTrailing ? trailingWidgets : null,
        onClick: onTap,
      );
    }

    // 富文本 / 自定义 widget 模式：leading 走 startAction、trailing 走
    // endActions，标题/副标题放 content。
    //
    // 注意：不能把 Expanded 放进 content —— MiuixBasicComponent 会把
    // content 直接作为内部 Column（miuix_basic_component.dart 的 center
    // Column，mainAxisSize.min）的子项；Column 位于 ListView 等无界高度
    // 上下文时，Expanded/Flexible 会抛 "RenderFlex children have non-zero
    // flex but incoming height constraints are unbounded"（表现为 Scaffold
    // 高度溢出 + 文本下黄色溢出条纹）。用 start/end 槽位由组件的
    // _BasicComponentRow 渲染对象负责 2:5:3 横向测量，中心区宽度有界，
    // 文本自行换行，任何滚动容器下都不会溢出。
    return MiuixBasicComponent(
      startAction: leading,
      endActions: hasTrailing ? trailingWidgets : null,
      content: <Widget>[
        title,
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          subtitle!,
        ],
      ],
      onClick: onTap,
    );
  }
}
