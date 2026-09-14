import 'package:flutter/material.dart';

import '../../../core/theme/md3e_tokens.dart';

/// 颜色选择器的返回结果。
/// [value] 为 null 表示"清除颜色"，result 本身为 null 表示"取消"。
class ColorPickResult {
  const ColorPickResult.clear()
      : value = null,
        cleared = true;
  const ColorPickResult.color(int this.value) : cleared = false;

  /// 选中的颜色；仅在 [cleared] 为 false 时有效。
  final int? value;

  /// 是否为"清除颜色"操作。
  final bool cleared;
}

/// 颜色选择器。
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

  static Future<ColorPickResult?> show(BuildContext context, {int? current}) {
    return showModalBottomSheet<ColorPickResult?>(
      context: context,
      // 横屏下内容可能超出默认高度，允许占满全屏并内部滚动。
      isScrollControlled: true,
      builder: (_) => ColorPickerSheet(selected: current),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          // 避免键盘等 insets 遮挡。
          bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('选择颜色', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 6,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: [
                  for (final c in _colors)
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () =>
                          Navigator.pop(context, ColorPickResult.color(c)),
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
                    onPressed: () =>
                        Navigator.pop(context, const ColorPickResult.clear()),
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
      ),
    );
  }
}
