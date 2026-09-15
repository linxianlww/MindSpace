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
                IconButton(
                  tooltip: '卡片颜色',
                  icon: Icon(Icons.palette_outlined,
                      color: memo.color != null ? Color(memo.color!) : null),
                  onPressed: () async {
                    final r = await ColorPickerSheet.show(context,
                        current: memo.color);
                    // 取消（null）不变更；“清除颜色”与选色都落入 setColor。
                    if (r != null) {
                      await ref
                          .read(textEditorProvider(widget.memoId).notifier)
                          .setColor(r.value);
                    }
                  },
                ),
                IconButton(
                  tooltip: '备注',
                  icon: const Icon(Icons.label_outline),
                  onPressed: () async {
                    final r =
                        await RemarkEditor.show(context, initial: memo.remark);
                    if (r != null) {
                      await ref
                          .read(textEditorProvider(widget.memoId).notifier)
                          .setRemark(r.isEmpty ? null : r);
                    }
                  },
                ),
                PopupMenuButton<String>(
                  onSelected: (v) => _menu(v, data),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'font', child: Text('选择字体')),
                    PopupMenuItem(value: 'share_text', child: Text('分享为文本')),
                    PopupMenuItem(value: 'share_image', child: Text('分享为图片')),
                    PopupMenuItem(value: 'share_file', child: Text('分享为文件')),
                    PopupMenuItem(value: 'preview', child: Text('预览')),
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

  DefaultStyles? _styles(BuildContext context, String? family,
      double lineHeight, double paragraphSpacing) {
    if (family == null) return null;
    // 自定义样式会整体替换默认段落样式，必须显式保留主题前景色，
    // 否则浅色模式下文字会退化为未着色（发白）。
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
      case 'preview':
        context.push('/memo/text/${widget.memoId}');
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
