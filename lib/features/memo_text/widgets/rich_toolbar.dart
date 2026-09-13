import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../../core/theme/md3e_tokens.dart';
import '../../../core/widgets/floating_toolbar.dart';

/// 文本编辑器键盘弹出时贴底显示的浮动富文本工具栏。
class RichToolbar extends StatefulWidget {
  const RichToolbar({
    super.key,
    required this.controller,
    this.onPickColor,
    this.onPickFont,
  });

  final QuillController controller;
  final VoidCallback? onPickColor;
  final VoidCallback? onPickFont;

  @override
  State<RichToolbar> createState() => _RichToolbarState();
}

class _RichToolbarState extends State<RichToolbar> {
  QuillController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    c.addListener(_onChange);
  }

  @override
  void dispose() {
    c.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  /// 切换行内样式：已存在则取消，否则应用。
  void _toggleInline(Attribute attr) {
    final current = c.getSelectionStyle().attributes[attr.key];
    c.formatSelection(current == null ? attr : Attribute.clone(attr, null));
  }

  /// 切换块级样式。
  void _toggleBlock(Attribute attr) {
    final styles = c.getSelectionStyle().attributes;
    final current = styles[attr.key];
    c.formatSelection(current == null ? attr : Attribute.clone(attr, null));
  }

  bool _has(String key) => c.getSelectionStyle().attributes[key] != null;

  @override
  Widget build(BuildContext context) {
    final items = <ToolbarItem>[
      ToolbarItem(
          icon: Icons.undo,
          tooltip: '撤销',
          onTap: () => c.undo()),
      ToolbarItem(
          icon: Icons.redo,
          tooltip: '重做',
          onTap: () => c.redo()),
      ToolbarItem(
          icon: Icons.format_bold,
          tooltip: '加粗',
          active: _has(Attribute.bold.key),
          onTap: () => _toggleInline(Attribute.bold)),
      ToolbarItem(
          icon: Icons.format_italic,
          tooltip: '斜体',
          active: _has(Attribute.italic.key),
          onTap: () => _toggleInline(Attribute.italic)),
      ToolbarItem(
          icon: Icons.format_underlined,
          tooltip: '下划线',
          active: _has(Attribute.underline.key),
          onTap: () => _toggleInline(Attribute.underline)),
      ToolbarItem(
          icon: Icons.format_strikethrough,
          tooltip: '删除线',
          active: _has(Attribute.strikeThrough.key),
          onTap: () => _toggleInline(Attribute.strikeThrough)),
      ToolbarItem(
          icon: Icons.text_fields,
          tooltip: '标题',
          onTap: _pickHeader),
      ToolbarItem(
          icon: Icons.format_list_bulleted,
          tooltip: '无序列表',
          active: _has(Attribute.ul.key),
          onTap: () => _toggleBlock(Attribute.ul)),
      ToolbarItem(
          icon: Icons.format_list_numbered,
          tooltip: '有序列表',
          active: _has(Attribute.ol.key),
          onTap: () => _toggleBlock(Attribute.ol)),
      ToolbarItem(
          icon: Icons.format_quote,
          tooltip: '引用',
          active: _has(Attribute.blockQuote.key),
          onTap: () => _toggleBlock(Attribute.blockQuote)),
      ToolbarItem(
          icon: Icons.code,
          tooltip: '行内代码',
          active: _has(Attribute.inlineCode.key),
          onTap: () => _toggleInline(Attribute.inlineCode)),
      ToolbarItem(
          icon: Icons.data_object,
          tooltip: '代码块',
          active: _has(Attribute.codeBlock.key),
          onTap: () => _toggleBlock(Attribute.codeBlock)),
      ToolbarItem(
          icon: Icons.link,
          tooltip: '链接',
          onTap: _insertLink),
      ToolbarItem(
          icon: Icons.palette_outlined,
          tooltip: '文字颜色/高亮',
          onTap: () => widget.onPickColor?.call()),
      ToolbarItem(
          icon: Icons.font_download_outlined,
          tooltip: '字体',
          onTap: () => widget.onPickFont?.call()),
      ToolbarItem(
          icon: Icons.format_align_left,
          tooltip: '左对齐',
          onTap: () => c.formatSelection(Attribute.leftAlignment)),
      ToolbarItem(
          icon: Icons.format_align_center,
          tooltip: '居中',
          onTap: () => c.formatSelection(Attribute.centerAlignment)),
      ToolbarItem(
          icon: Icons.format_align_right,
          tooltip: '右对齐',
          onTap: () => c.formatSelection(Attribute.rightAlignment)),
    ];
    return FloatingToolbar(items: items);
  }

  Future<void> _pickHeader() async {
    final selected = await showModalBottomSheet<Attribute?>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in const [
              ('正文', null),
              ('H1', Attribute.h1),
              ('H2', Attribute.h2),
              ('H3', Attribute.h3),
              ('H4', Attribute.h4),
            ])
              ListTile(
                title: Text(entry.$1),
                onTap: () => Navigator.pop(ctx, entry.$2),
              ),
          ],
        ),
      ),
    );
    if (selected == null) {
      // HeaderAttribute() 的空值即清除标题层级，回到正文。
      c.formatSelection(Attribute.header);
    } else {
      c.formatSelection(selected);
    }
  }

  Future<void> _insertLink() async {
    final ctrl = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('插入链接'),
        shape:
            const RoundedRectangleBorder(borderRadius: Md3eTokens.dialogBorder),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(hintText: 'https://'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('插入')),
        ],
      ),
    );
    if (url != null && url.isNotEmpty) {
      c.formatSelection(LinkAttribute(url));
    }
  }
}
