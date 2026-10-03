import 'package:flutter/widgets.dart';
import 'package:flutter_miuix/miuix.dart';

/// 统一标签芯片 —— MIUIX 风格。
///
/// 使用 [MiuixCard]（Squircle + 按压反馈），替代旧版手动 GestureDetector 拼装。
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.leading,
    this.cornerRadius,
    this.feedbackType = MiuixPressFeedbackType.sink,
  });

  final Widget label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final Widget? leading;
  final double? cornerRadius;
  final MiuixPressFeedbackType feedbackType;

  @override
  Widget build(BuildContext context) {
    final colors = MiuixTheme.of(context).colors;
    final fg = selected ? colors.onPrimary : colors.onSurface;
    final bg = selected ? colors.primary : colors.surfaceContainerHigh;

    return MiuixCard(
      cornerRadius: cornerRadius ?? 16,
      colors: MiuixCardColors(
        color: bg,
        contentColor: fg,
      ),
      feedbackType: feedbackType,
      insideMargin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      onPressed: () => onSelected(!selected),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 4)],
          DefaultTextStyle(
            style: TextStyle(color: fg, fontSize: 13),
            child: label,
          ),
        ],
      ),
    );
  }
}
