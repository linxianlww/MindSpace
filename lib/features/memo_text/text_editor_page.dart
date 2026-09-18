import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/providers.dart';
import '../../core/utils/markdown_delta.dart';
import '../share/share_service.dart';
import 'text_provider.dart';
import 'widgets/color_picker.dart';
import 'widgets/font_picker.dart';
import 'widgets/remark_editor.dart';
import 'widgets/rich_toolbar.dart';

/// 文本铭记编辑页。
class TextEditorPage extends ConsumerStatefulWidget {
  const TextEditorPage({super.key, required this.memoId});
  final String memoId;

  @override
  ConsumerState<TextEditorPage> createState() => _TextEditorPageState();
}

class _TextEditorPageState extends ConsumerState<TextEditorPage> {
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  Future<void> _save() =>
      ref.read(textEditorProvider(widget.memoId).notifier).save();

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(textEditorProvider(widget.memoId));
    return async.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('加载失败：$e')),
      ),
      data: (data) {
        final settings = ref.watch(settingsProvider);
        final memo = data.memo;
        return PopScope(
          // 返回时自动保存，避免内容丢失。
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) _save();
          },
          child: Scaffold(
            appBar: AppBar(
              title: GestureDetector(
                onTap: () => _rename(data),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(memo.title,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    const Icon(Icons.edit, size: 16),
                  ],
                ),
              ),
              actions: [
                // 编辑页右上角只有「更多」三点菜单 + 保存按钮；
                // 颜色 / 标签 / 字体 / 分享全部收敛至三级菜单。
                PopupMenuButton<String>(
                  tooltip: '更多',
                  onSelected: (v) => _menu(v, data),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                        value: 'color',
                        enabled: false,
                        child: Row(
                          children: [
                            Icon(Icons.palette_outlined,
                                size: 18,
                                color: memo.color != null
                                    ? Color(memo.color!)
                                    : Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 10),
                            const Text('卡片颜色'),
                          ],
                        )),
                    PopupMenuItem(
                      value: 'set_color',
                      onTap: () => WidgetsBinding.instance
                          .addPostFrameCallback((_) => _setMemoColor(data)),
                      child: const Padding(
                        padding: EdgeInsets.only(left: 28),
                        child: Text('修改颜色'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'clear_color',
                      enabled: memo.color != null,
                      onTap: () => WidgetsBinding.instance
                          .addPostFrameCallback((_) => _clearMemoColor(data)),
                      child: const Padding(
                        padding: EdgeInsets.only(left: 28),
                        child: Text('清除颜色'),
                      ),
                    ),
                    PopupMenuItem(
                        value: 'label',
                        enabled: false,
                        child: Row(
                          children: [
                            const Icon(Icons.label_outline, size: 18),
                            const SizedBox(width: 10),
                            Text(memo.remark == null ? '备注标签' : memo.remark!),
                          ],
                        )),
                    PopupMenuItem(
                      value: 'edit_label',
                      onTap: () => WidgetsBinding.instance
                          .addPostFrameCallback((_) => _editRemark(data)),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 28),
                        child: Text(memo.remark == null ? '设置标签' : '修改标签'),
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                        value: 'font', child: Text('字体')),
                    const PopupMenuItem(
                        value: 'share_text', child: Text('分享为文本')),
                    const PopupMenuItem(
                        value: 'share_image', child: Text('分享为图片')),
                    const PopupMenuItem(
                        value: 'share_file', child: Text('分享为文件')),
                  ],
                ),
                IconButton(
                  icon: data.saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.check),
                  onPressed: () async {
                    await _save();
                    if (context.mounted) context.pop();
                  },
                ),
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  child: Center(
                    // 横屏平板等宽屏下限制正文宽度并居中，避免行长过长影响阅读；
                    // 1:1 小屏/竖屏手机时自动占满可用宽度。
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 840),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ColoredBox(
                          color: Theme.of(context).colorScheme.surface,
                          child: QuillEditor.basic(
                            focusNode: _focus,
                            controller: data.controller,
                            config: QuillEditorConfig(
                              expands: true,
                              placeholder: '开始书写…',
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              customStyles:
                                  _styles(context, data.fontFamily,
                                      settings.lineHeight,
                                      settings.paragraphSpacing),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                RichToolbar(
                  controller: data.controller,
                  onPickColor: () => _textColor(data),
                  onPickFont: () => _pickFont(data),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  DefaultStyles _styles(BuildContext context, String? family,
      double lineHeight, double paragraphSpacing) {
    // 无论是否选择自定义字体，行距与段距都应生效。
    // 仅当选择自定义字体时才注入 fontFamily。
    final base = TextStyle(
      fontFamily: family,
      fontSize: 16,
      height: lineHeight,
      color: Theme.of(context).colorScheme.onSurface,
    );
    return DefaultStyles(
      paragraph: DefaultTextBlockStyle(
        base,
        const HorizontalSpacing(0, 0),
        VerticalSpacing(0, paragraphSpacing),
        const VerticalSpacing(0, 0),
        null,
      ),
    );
  }

  Future<void> _setMemoColor(TextEditorData data) async {
    final r = await ColorPickerSheet.show(context, current: data.memo.color);
    if (r == null) return;
    await ref
        .read(textEditorProvider(widget.memoId).notifier)
        .setColor(r.cleared ? null : r.value);
  }

  Future<void> _clearMemoColor(TextEditorData data) async {
    await ref.read(textEditorProvider(widget.memoId).notifier).setColor(null);
  }

  Future<void> _editRemark(TextEditorData data) async {
    final r = await RemarkEditor.show(context, initial: data.memo.remark);
    if (r != null) {
      await ref
          .read(textEditorProvider(widget.memoId).notifier)
          .setRemark(r.isEmpty ? null : r);
    }
  }

  Future<void> _textColor(TextEditorData data) async {
    final r = await ColorPickerSheet.show(context);
    // 取消（null）不做任何处理。
    if (r == null) return;
    if (r.cleared) {
      // “清除颜色”：移除选中区域上的 color 属性。
      data.controller.formatSelection(Attribute.clone(Attribute.color, null));
      return;
    }
    final hex = '#${(r.value! & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    data.controller.formatSelection(ColorAttribute(hex));
  }

  Future<void> _pickFont(TextEditorData data) async {
    await FontPicker.show(context, ref,
        currentFontId: data.memo.fontId,
        onPicked: (font) => ref
            .read(textEditorProvider(widget.memoId).notifier)
            .applyFont(font));
  }

  Future<void> _rename(TextEditorData data) async {
    final ctrl = TextEditingController(text: data.memo.title);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重命名'),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('确定')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await ref
          .read(textEditorProvider(widget.memoId).notifier)
          .save(title: name);
    }
  }

  Future<void> _menu(String value, TextEditorData data) async {
    final share = ref.read(shareServiceProvider);
    switch (value) {
      case 'font':
        _pickFont(data);
      case 'share_text':
        await _save();
        share.shareText(data.controller.document.toPlainText());
      case 'share_file':
        await _save();
        // 正文仅存 delta.json，分享为文件时实时转 Markdown，不再落盘副本。
        final ops = data.controller.document.toDelta().toJson();
        final md = MarkdownDelta.toMarkdown(ops);
        share.shareBytes(utf8.encode(md), fileName: '${data.memo.id}.md');
      case 'share_image':
        await _save();
        if (mounted) {
          context.push('/share/image/${widget.memoId}');
        }
    }
  }
}
