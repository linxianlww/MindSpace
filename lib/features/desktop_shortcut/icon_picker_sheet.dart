import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/theme/md3e_tokens.dart';

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
Future<IconPickerResult> showIconPickerSheet(
  BuildContext context, {
  required String initialTitle,
}) async {
  final result = await showModalBottomSheet<IconPickerResult?>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
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
    final scheme = Theme.of(context).colorScheme;
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
            const Text('选择图标', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
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
                      icon: _CharIcon(char: _firstChar, color: scheme.primary),
                      label: '使用首字符「$_firstChar」自动生成',
                    ),
                    const SizedBox(height: 12),
                    // 自定义图标
                    _PreviewTile(
                      selected: !_useAutoChar,
                      onTap: _pickImage,
                      icon: _customBytes != null
                          ? ClipOval(
                              child: Image.memory(_customBytes!, width: 56, height: 56, fit: BoxFit.cover))
                          : CircleAvatar(
                              backgroundColor: scheme.surfaceContainerHighest,
                              child: Icon(Icons.add_photo_alternate_outlined, color: scheme.onSurfaceVariant),
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
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, const IconPickerResult.cancel()),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () {
                      if (_useAutoChar) {
                        Navigator.pop(context, const IconPickerResult.auto());
                      } else if (_customBytes != null) {
                        Navigator.pop(context, IconPickerResult.custom(_customBytes!));
                      }
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('创建桌面图标'),
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
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: Md3eTokens.dialogBorder,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: Md3eTokens.dialogBorder,
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
          color: selected ? scheme.primaryContainer.withValues(alpha: 0.3) : null,
        ),
        child: Row(
          children: [
            SizedBox(width: 56, height: 56, child: icon),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? scheme.primary : scheme.onSurface,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: scheme.primary),
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
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        char.length == 1 && RegExp('[a-zA-Z]').hasMatch(char) ? char.toUpperCase() : char,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

