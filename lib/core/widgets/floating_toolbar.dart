import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/md3e_tokens.dart';

/// 浮动工具栏：半透明 + 毛玻璃 + 大圆角 + 横向滚动。
///
/// 文本编辑器在键盘弹出时贴底显示；按钮由调用方以 [ToolbarItem] 提供。
class FloatingToolbar extends StatelessWidget {
  const FloatingToolbar({super.key, required this.items, this.height = 52});

  final List<ToolbarItem> items;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(Md3eTokens.radiusBar),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(Md3eTokens.radiusBar),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            itemCount: items.length,
            separatorBuilder: (_, __) => VerticalDivider(
              width: 1,
              indent: 12,
              endIndent: 12,
              color: scheme.outlineVariant,
            ),
            itemBuilder: (_, i) {
              final item = items[i];
              return Tooltip(
                message: item.tooltip ?? '',
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: item.onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(
                      item.icon,
                      size: 22,
                      color: item.active
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
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

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final bool active;
}
