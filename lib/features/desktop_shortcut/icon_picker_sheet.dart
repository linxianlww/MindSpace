import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:mindspace/ui/design_system/app_design_system.dart';

/// 桌面快捷方式图标选择弹窗。
/// 返回用户选择的图片字节（自定义图标），返回 null 表示使用默认首字符图标。
/// 用户点取消返回 [PickerResult.cancel]，点确定返回对应字节或确定使用首字符。
class IconPickerResult {
  const IconPickerResult.custom(Uint8List bytes)
      : _bytes = bytes,
        autoChar = false,
        canceled = false;
  const IconPickerResult.auto()
      : _bytes = null,
        autoChar = true,
        canceled = false;
  const IconPickerResult.cancel()
      : _bytes = null,
        autoChar = false,
        canceled = true;

  final Uint8List? _bytes;
  final bool autoChar;
  final bool canceled;

  Uint8List? get bytes => _bytes;
  bool get isAutoChar => autoChar;
  bool get isCanceled => canceled;
}

/// 显示图标选择弹窗，让用户选择自定义图标或使用首字符自动生成的默认图标。
///
/// [initialTitle] 用于生成首字符预览。
/// 返回 [IconPickerResult]，调用方据此决定是否传递 iconBytes 给原生服务。
///
/// 弹层内关闭一律走 [AppSheet.close]（弹层不是路由，Navigator.pop 会误退页面）；
/// sheetCtx 位于 AppScaffold 子树内（MiuixScaffold popup 层），可被
/// `AppScaffold.maybeOf` 反查到宿主。
Future<IconPickerResult> showIconPickerSheet(
  BuildContext context, {
  required String initialTitle,
}) async {
  final result = await AppSheet.show<IconPickerResult?>(
    context: context,
    title: '选择图标',
    builder: (ctx) => _IconPickerBody(title: initialTitle),
  );
  return result ?? const IconPickerResult.cancel();
}

class _IconPickerBody extends StatefulWidget {
  const _IconPickerBody({required this.title});
  final String title;

  @override
  State<_IconPickerBody> createState() => _IconPickerBodyState();
}

class _IconPickerBodyState extends State<_IconPickerBody> {
  Uint8List? _customBytes;
  bool _useAutoChar = true;

  String get _firstChar {
    final ch = widget.title.characters.firstWhere(
      (c) => c.trim().isNotEmpty,
      orElse: () => '铭',
    );
    return ch.length > 2 ? ch.substring(0, 2) : ch;
  }

  Future<void> _pickImage() async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (picked != null && picked.files.single.bytes != null) {
        setState(() {
          _customBytes = picked.files.single.bytes;
          _useAutoChar = false;
        });
      }
    } catch (_) {
      // 选择失败，保持原态。
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = MiuixTheme.of(context).colors;
    final mediaQuery = MediaQuery.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: mediaQuery.size.height * 0.85,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          8,
          24,
          mediaQuery.viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题由 AppSheet.show 的 title 参数渲染（MiuixOverlayBottomSheet），
            // 这里不再自绘。
            const SizedBox(height: 8),
            // 可滚动的预览内容区域
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 首字符自动图标预览
                    _PreviewTile(
                      selected: _useAutoChar,
                      onTap: () => setState(() => _useAutoChar = true),
                      icon: _CharIcon(char: _firstChar, color: colors.primary),
                      label: '使用首字符「$_firstChar」自动生成',
                    ),
                    const SizedBox(height: 12),
                    // 自定义图标
                    _PreviewTile(
                      selected: !_useAutoChar,
                      onTap: _pickImage,
                      icon: _customBytes != null
                          ? ClipOval(
                              child: Image.memory(_customBytes!,
                                  width: 56, height: 56, fit: BoxFit.cover))
                          : Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: colors.surfaceContainerHighest,
                                shape: BoxShape.circle,
                              ),
                              child: HiuiIcon(HiuiIcons.image,
                                  color: colors.onSurfaceVariantActions),
                            ),
                      label: _customBytes != null ? '已选择图片' : '从相册选择图标',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 底部按钮固定不滚动
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    variant: AppButtonStyle.outlined,
                    onPressed: () => AppSheet.close(
                        context, const IconPickerResult.cancel()),
                    child: const MiuixText('取消'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: AppButton(
                    variant: AppButtonStyle.filled,
                    onPressed: () {
                      if (_useAutoChar) {
                        AppSheet.close(
                            context, const IconPickerResult.auto());
                      } else if (_customBytes != null) {
                        AppSheet.close(context,
                            IconPickerResult.custom(_customBytes!));
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HiuiIcon(HiuiIcons.check),
                        const SizedBox(width: 8),
                        MiuixText('创建桌面图标'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 预览条目：圆形图标 + 描述文字 + 选中状态。
class _PreviewTile extends StatelessWidget {
  const _PreviewTile({
    required this.selected,
    required this.onTap,
    required this.icon,
    required this.label,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = MiuixTheme.of(context).colors;
    return MiuixSurface(
      onPressed: onTap,
      cornerRadius: AppTokens.radiusDialog,
      squircleEnabled: true,
      color: selected
          ? colors.primaryContainer.withValues(alpha: 0.3)
          : colors.surface,
      border: Border.all(
        color: selected ? colors.primary : colors.outline,
        width: selected ? 2 : 1,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(width: 56, height: 56, child: icon),
            const SizedBox(width: 16),
            Expanded(
              child: MiuixText(
                label,
                style: MiuixTheme.of(context).textStyles.body1.copyWith(
                      color: selected ? colors.primary : colors.onSurface,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.normal,
                    ),
              ),
            ),
            if (selected) HiuiIcon(HiuiIcons.checkCircle, color: colors.primary),
          ],
        ),
      ),
    );
  }
}

/// 首字符圆形图标 Widget（预览用）。
class _CharIcon extends StatelessWidget {
  const _CharIcon({required this.char, required this.color});

  final String char;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // 圆形图标底座：AppAvatar 默认 squircle，传 borderRadius = 尺寸一半得正圆。
    // 白色文字为图标底色上的固定前景，属功能性硬编码。
    return AppAvatar(
      radius: 28,
      borderRadius: 28,
      backgroundColor: color,
      child: MiuixText(
        char.length == 1 && RegExp('[a-zA-Z]').hasMatch(char)
            ? char.toUpperCase()
            : char,
        style: MiuixTheme.of(context)
            .textStyles
            .title2
            .copyWith(color: Colors.white, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }
}
