import 'package:mindspace/ui/design_system/app_design_system.dart';

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

  /// [context] 必须位于 [AppScaffold] 子树内（页面级调用请传脚手架下方
  /// 的 context，否则找不到弹层宿主）。
  static Future<ColorPickResult?> show(BuildContext context, {int? current}) {
    return AppSheet.show<ColorPickResult?>(
      context: context,
      title: '选择颜色',
      builder: (_) => ColorPickerSheet(selected: current),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 键盘与底部安全区由 MiuixOverlayBottomSheet 处理，这里只补
    // 底部安全区之上的留白（SafeArea 不与库的 viewInsets 叠加冲突）。
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.count(
              crossAxisCount: 6,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                for (final c in _colors)
                  // 色块：MiuixSurface 承载（squircle 圆角 + 按压反馈，
                  // 替代裸 GestureDetector + AppAvatar 组合）
                  MiuixSurface(
                    onPressed: () => AppSheet.close(
                        context, ColorPickResult.color(c)),
                    cornerRadius: 20,
                    color: Color(c),
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: selected == c
                          // 白色勾为色块前景的功能性硬编码
                          ? const HiuiIcon(HiuiIcons.check,
                              color: Colors.white, size: 20)
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppButton(
                  variant: AppButtonStyle.text,
                  onPressed: () => AppSheet.close(
                      context, const ColorPickResult.clear()),
                  child: MiuixText('清除颜色',
                      style: TextStyle(
                          color: MiuixTheme.of(context).colors.error)),
                ),
                // 取消是最次级动作，不做主视觉强调
                AppButton(
                  variant: AppButtonStyle.outlined,
                  onPressed: () => AppSheet.close(context),
                  child: const MiuixText('取消'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
