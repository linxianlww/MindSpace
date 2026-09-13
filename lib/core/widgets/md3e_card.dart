import 'package:flutter/material.dart';

import '../theme/md3e_tokens.dart';

/// MD3E 统一卡片：大圆角、柔和阴影、按下时轻微缩放 + 涟漪。
class Md3eCard extends StatefulWidget {
  const Md3eCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding = EdgeInsets.zero,
    this.color,
    this.borderColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsets padding;
  final Color? color;
  final Color? borderColor;

  @override
  State<Md3eCard> createState() => _Md3eCardState();
}

class _Md3eCardState extends State<Md3eCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: Md3eTokens.fast,
      curve: Md3eTokens.standard,
      child: Material(
        color: widget.color ?? Theme.of(context).cardTheme.color,
        elevation: 0,
        borderRadius: Md3eTokens.cardBorder,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: Md3eTokens.cardBorder,
              border: widget.borderColor == null
                  ? null
                  : Border.all(color: widget.borderColor!),
            ),
            child: Padding(padding: widget.padding, child: widget.child),
          ),
        ),
      ),
    );
  }
}

/// 小型标签胶囊（颜色/备注标签等）。
class LabelChip extends StatelessWidget {
  const LabelChip({
    super.key,
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = color ?? scheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(Md3eTokens.radiusChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 7, color: c),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: c),
            ),
          ),
        ],
      ),
    );
  }
}
