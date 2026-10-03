import 'package:flutter/material.dart' show Icons;
import 'package:mindspace/ui/design_system/app_design_system.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// 文本编辑器键盘弹出时贴底显示的浮动富文本工具栏。
///
/// 布局与 `core/widgets/floating_toolbar.dart` 保持一致（毛玻璃卡片 +
/// 横向滚动 + MiuixIconButton 按钮）；标题层级项为锚定下拉菜单
/// （[MiuixOverlayIconDropdownMenu]），无法直接复用 [ToolbarItem] 的
/// IconData 接口，因此在本文件内组装按钮行。
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
  static const double _height = 52;

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
    final colors = MiuixTheme.of(context).colors;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final sysBottomPadding = MediaQuery.paddingOf(context).bottom;
    final double extraBottom = bottomInset <= 0 ? sysBottomPadding : 0.0;

    // 当前标题层级（'header' 属性缺省即正文），用于菜单勾选态。
    final headerAttr = c.getSelectionStyle().attributes[Attribute.header.key];

    Widget iconButton(
      IconData icon, {
      String? tooltip,
      bool active = false,
      VoidCallback? onTap,
    }) {
      final Widget button = MiuixIconButton(
        onPressed: onTap,
        minWidth: 44,
        minHeight: 40,
        child: Icon(
          icon,
          size: 22,
          color: active ? colors.primary : colors.onSurfaceSecondary,
        ),
      );
      if (tooltip == null || tooltip.isEmpty) return button;
      return _withTooltip(colors, tooltip, button);
    }

    final buttons = <Widget>[
      iconButton(Icons.undo, tooltip: '撤销', onTap: () => c.undo()),
      iconButton(Icons.redo, tooltip: '重做', onTap: () => c.redo()),
      iconButton(Icons.format_bold,
          tooltip: '加粗',
          active: _has(Attribute.bold.key),
          onTap: () => _toggleInline(Attribute.bold)),
      iconButton(Icons.format_italic,
          tooltip: '斜体',
          active: _has(Attribute.italic.key),
          onTap: () => _toggleInline(Attribute.italic)),
      iconButton(Icons.format_underline,
          tooltip: '下划线',
          active: _has(Attribute.underline.key),
          onTap: () => _toggleInline(Attribute.underline)),
      iconButton(Icons.format_strikethrough,
          tooltip: '删除线',
          active: _has(Attribute.strikeThrough.key),
          onTap: () => _toggleInline(Attribute.strikeThrough)),
      // 标题层级：锚定下拉菜单。收起菜单是无操作，只有选中项才
      // formatSelection——顺带修掉旧抽屉实现「下滑关闭被当作选正文、
      // 意外清除标题层级」的 bug。
      _withTooltip(
        colors,
        '标题',
        MiuixOverlayIconDropdownMenu(
          minWidth: 44,
          minHeight: 40,
          entry: MiuixDropdownEntry(items: [
            MiuixDropdownItem(
              text: '正文',
              selected: headerAttr == null,
              onClick: () => c.formatSelection(Attribute.header),
            ),
            MiuixDropdownItem(
              text: 'H1',
              selected: headerAttr?.value == 1,
              onClick: () => c.formatSelection(Attribute.h1),
            ),
            MiuixDropdownItem(
              text: 'H2',
              selected: headerAttr?.value == 2,
              onClick: () => c.formatSelection(Attribute.h2),
            ),
            MiuixDropdownItem(
              text: 'H3',
              selected: headerAttr?.value == 3,
              onClick: () => c.formatSelection(Attribute.h3),
            ),
            MiuixDropdownItem(
              text: 'H4',
              selected: headerAttr?.value == 4,
              onClick: () => c.formatSelection(Attribute.h4),
            ),
          ]),
          child: Icon(
            Icons.title,
            size: 22,
            color: colors.onSurfaceSecondary,
          ),
        ),
      ),
      iconButton(Icons.format_list_bulleted,
          tooltip: '无序列表',
          active: _has(Attribute.ul.key),
          onTap: () => _toggleBlock(Attribute.ul)),
      iconButton(Icons.format_list_numbered,
          tooltip: '有序列表',
          active: _has(Attribute.ol.key),
          onTap: () => _toggleBlock(Attribute.ol)),
      iconButton(Icons.format_quote,
          tooltip: '引用',
          active: _has(Attribute.blockQuote.key),
          onTap: () => _toggleBlock(Attribute.blockQuote)),
      iconButton(Icons.code,
          tooltip: '行内代码',
          active: _has(Attribute.inlineCode.key),
          onTap: () => _toggleInline(Attribute.inlineCode)),
      iconButton(Icons.data_object,
          tooltip: '代码块',
          active: _has(Attribute.codeBlock.key),
          onTap: () => _toggleBlock(Attribute.codeBlock)),
      iconButton(Icons.link, tooltip: '链接', onTap: _insertLink),
      iconButton(Icons.format_color_text,
          tooltip: '文字颜色/高亮', onTap: () => widget.onPickColor?.call()),
      iconButton(Icons.font_download,
          tooltip: '字体', onTap: () => widget.onPickFont?.call()),
      iconButton(Icons.format_align_left,
          tooltip: '左对齐', onTap: () => c.formatSelection(Attribute.leftAlignment)),
      iconButton(Icons.format_align_center,
          tooltip: '居中',
          onTap: () => c.formatSelection(Attribute.centerAlignment)),
      iconButton(Icons.format_align_right,
          tooltip: '右对齐',
          onTap: () => c.formatSelection(Attribute.rightAlignment)),
    ];

    return Padding(
      padding: EdgeInsets.only(bottom: extraBottom),
      child: MiuixCard(
        cornerRadius: AppTokens.radiusBar,
        insideMargin: EdgeInsets.zero,
        feedbackType: MiuixPressFeedbackType.none,
        child: SizedBox(
          height: _height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            itemCount: buttons.length,
            separatorBuilder: (_, __) => MiuixVerticalDivider(
              thickness: 0.75,
            ),
            itemBuilder: (_, i) => buttons[i],
          ),
        ),
      ),
    );
  }

  /// 与 FloatingToolbar 一致的气泡提示。
  Widget _withTooltip(MiuixColors colors, String tooltip, Widget child) {
    return MiuixTooltipBox(
      tooltip: (ctx, _) => MiuixSurface(
        color: colors.surface,
        contentColor: colors.onSurface,
        cornerRadius: AppTokens.radiusMedium,
        shadowElevation: 4,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: MiuixText(tooltip,
              style: MiuixTheme.of(ctx).textStyles.footnote1),
        ),
      ),
      child: child,
    );
  }

  Future<void> _insertLink() async {
    final ctrl = TextEditingController();
    final url = await AppDialog.show<String>(
      context: context,
      title: '插入链接',
      content: AppInput(
        controller: ctrl,
        autofocus: true,
        keyboardType: TextInputType.url,
        hintText: 'https://',
      ),
      actions: [
        MiuixTextButton('取消', onPressed: () => AppDialog.close(context)),
        MiuixButton(
          onPressed: () => AppDialog.close<String>(context, ctrl.text.trim()),
          child: const MiuixText('插入'),
        ),
      ],
    );
    if (url != null && url.isNotEmpty) {
      c.formatSelection(LinkAttribute(url));
    }
  }
}
