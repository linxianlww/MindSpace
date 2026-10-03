import 'package:flutter/widgets.dart';
import 'package:flutter_miuix/miuix.dart';

import 'hiui_icons.dart';

/// HyperOS 风格偏好行 —— 对齐 [MiuixArrowPreference] 视觉，
/// 但末尾箭头带「圆形底」（HyperOS 规范：右侧箭头置于浅色圆形容器内）。
///
/// 库内 `MiuixArrowPreference` 的箭头是无底的 10×16 图标，无法配置；
/// 本组件按 [MiuixBasicComponent] 的槽位结构自绘末尾箭头：
/// 26×26 的 squircle 圆底（`onBackground` 6% 透明度）内嵌 14 的
/// `chevronRight`（`onSurfaceVariantActions` 色）。
///
/// - [onClick] 为 null 时不显示箭头（不可点击的展示行）；
/// - [endActions] 传了自定义 trailing 时，附加在圆底箭头之前；
/// - 其余视觉（标题/摘要字号颜色、内边距、2:5:3 布局）与
///   [MiuixBasicComponent] 完全一致。
class AppSettingsRow extends StatelessWidget {
  const AppSettingsRow({
    super.key,
    required this.title,
    this.summary,
    this.startAction,
    this.endActions,
    this.onClick,
  });

  /// 行标题。
  final String title;

  /// 行摘要（可选）。
  final String? summary;

  /// 起始侧内容（可选，通常为图标）。
  final Widget? startAction;

  /// 末尾自定义 trailing（可选），显示在圆底箭头之前。
  final List<Widget>? endActions;

  /// 点击回调；为 null 时行不可点击且不显示箭头。
  final VoidCallback? onClick;

  @override
  Widget build(BuildContext context) {
    final colors = MiuixTheme.of(context).colors;
    final showArrow = onClick != null;
    final hasTrailing = endActions != null && endActions!.isNotEmpty;

    final List<Widget> trailing = <Widget>[
      if (hasTrailing)
        Flexible(
          fit: FlexFit.loose,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: endActions!,
            ),
          ),
        ),
      if (showArrow)
        Container(
          width: 26,
          height: 26,
          decoration: ShapeDecoration(
            color: colors.onBackground.withValues(alpha: 0.06),
            shape: const MiuixSquircleBorder(cornerRadius: 13),
          ),
          child: Center(
            child: HiuiIcon(
              HiuiIcons.chevronRight,
              size: 14,
              color: colors.onSurfaceVariantActions,
            ),
          ),
        ),
    ];

    return MiuixBasicComponent(
      title: title,
      summary: summary,
      startAction: startAction,
      endActions: trailing.isEmpty ? null : trailing,
      onClick: onClick,
    );
  }
}
