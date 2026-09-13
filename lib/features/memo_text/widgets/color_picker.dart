import 'package:flutter/material.dart';

import '../../../core/theme/md3e_tokens.dart';

/// 颜色选择器：返回选中的 ARGB 颜色，"清除"返回 null。
class ColorPickerSheet extends StatelessWidget {
  const ColorPickerSheet({super.key, required this.selected});

  final int? selected;

  static const _colors = <int>[
    0xFFE57373,
    0xFFFFB74D,
    0xFFFFF176,
    0xFF81C784,
    0xFF4DB6AC,
    0xFF64B5F6,
    0xFF7986CB,
    0xFFBA68C8,
    0xFFF06292,
    0xFFA1887F,
    0xFF90A4AE,
    0xFF455A64,
  ];

  static Future<int?> show(BuildContext context, {int? current}) {
    return showModalBottomSheet<int?>(
      context: context,
      builder: (_) => ColorPickerSheet(selected: current),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('选择颜色', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 6,
              shrinkWrap: true,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                for (final c in _colors)
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.pop(context, c),
                    child: CircleAvatar(
                      backgroundColor: Color(c),
                      child: selected == c
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('清除颜色'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(Md3eTokens.radiusBar)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
