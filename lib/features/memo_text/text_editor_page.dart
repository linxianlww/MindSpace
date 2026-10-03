import 'dart:convert';

import 'package:mindspace/ui/design_system/app_design_system.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/providers.dart';
import '../../core/utils/markdown_delta.dart';
import '../desktop_shortcut/add_to_desktop.dart';
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
          const AppScaffold(body: Center(child: AppCircleProgress())),
      error: (e, _) => AppScaffold(
        topBar: const AppHeader(),
        body: Center(child: MiuixText('加载失败：$e')),
      ),
      data: (data) {
        final settings = ref.watch(settingsProvider);
        final memo = data.memo;
        return PopScope(
          // 返回时自动保存，避免内容丢失。
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) _save();
          },
          child: AppScaffold(
            topBar: AppHeader(
              title: memo.title,
              alwaysSmall: true,
              actions: [
                // 顶栏子树的 context：菜单动作的弹层（选色/备注/字体/
                // 桌面快捷方式）需要 MiuixScaffold 之下的宿主 context。
                Builder(builder: (menuCtx) {
                  return MiuixOverlayIconDropdownMenu(
                    entry: MiuixDropdownEntry(items: [
                      MiuixDropdownItem(
                        text: '重命名',
                        icon: const HiuiIcon(HiuiIcons.edit, size: 18),
                        onClick: () => _rename(menuCtx, data),
                      ),
                      MiuixDropdownItem(
                        text: '修改颜色',
                        icon: HiuiIcon(HiuiIcons.skin,
                            size: 18,
                            color: memo.color != null
                                ? Color(memo.color!)
                                : MiuixTheme.of(menuCtx).colors.primary),
                        onClick: () => _setMemoColor(menuCtx, data),
                      ),
                      MiuixDropdownItem(
                        text: '清除颜色',
                        enabled: memo.color != null,
                        icon: HiuiIcon(HiuiIcons.clear,
                            size: 18,
                            color: memo.color == null
                                ? MiuixTheme.of(menuCtx).colors.disabledOnSurface
                                : MiuixTheme.of(menuCtx).colors.onSurface),
                        onClick: memo.color == null
                            ? null
                            : () => _clearMemoColor(data),
                      ),
                      MiuixDropdownItem(
                        text: memo.remark == null ? '设置标签' : '修改标签',
                        icon: const HiuiIcon(HiuiIcons.tag, size: 18),
                        onClick: () => _editRemark(menuCtx, data),
                      ),
                      MiuixDropdownItem(
                        text: '字体',
                        icon: const HiuiIcon(HiuiIcons.font,
                            size: 18),
                        onClick: () => _pickFont(menuCtx, data),
                      ),
                      MiuixDropdownItem(
                        text: '分享为文本',
                        icon: const HiuiIcon(HiuiIcons.document, size: 18),
                        onClick: () => _menuAction('share_text', data),
                      ),
                      MiuixDropdownItem(
                        text: '分享为图片',
                        icon: const HiuiIcon(HiuiIcons.image, size: 18),
                        onClick: () => _menuAction('share_image', data),
                      ),
                      MiuixDropdownItem(
                        text: '分享为文件',
                        icon: const HiuiIcon(HiuiIcons.document,
                            size: 18),
                        onClick: () => _menuAction('share_file', data),
                      ),
                      MiuixDropdownItem(
                        text: '添加到桌面',
                        icon: const HiuiIcon(HiuiIcons.export, size: 18),
                        onClick: () => addMemoToDesktop(menuCtx, ref, memo),
                      ),
                    ]),
                    child: const HiuiIcon(HiuiIcons.more),
                  );
                }),
                AppTapIcon(
                  icon: data.saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: AppCircleProgress())
                      : const HiuiIcon(HiuiIcons.check),
                  onPressed: () async {
                    await _save();
                    if (context.mounted) context.pop();
                  },
                ),
              ],
            ),
            content: (context, padding) {
              // MiuixScaffold 不会自动做键盘避让：顶栏高度由 padding.top
              // 消化，键盘高度由 viewInsets.bottom 消化（工具栏自身不再补）。
              return Padding(
                padding: EdgeInsets.only(
                  top: padding.top,
                  bottom: MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        // 横屏平板等宽屏下限制正文宽度并居中，避免行长过长影响阅读；
                        // 1:1 小屏/竖屏手机时自动占满可用宽度。
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 840),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: QuillEditor.basic(
                              focusNode: _focus,
                              controller: data.controller,
                              config: QuillEditorConfig(
                                expands: true,
                                placeholder: '开始书写…',
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12),
                                customStyles: _styles(context, data.fontFamily,
                                    settings.lineHeight,
                                    settings.paragraphSpacing),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    RichToolbar(
                      controller: data.controller,
                      onPickColor: () => _textColor(context, data),
                      onPickFont: () => _pickFont(context, data),
                    ),
                  ],
                ),
              );
            },
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
      color: MiuixTheme.of(context).colors.onSurface,
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

  /// [context] 必须位于 AppScaffold 子树内（顶栏/content 子树的 context），
  /// 供选色抽屉找到弹层宿主。
  Future<void> _setMemoColor(BuildContext context, TextEditorData data) async {
    final r = await ColorPickerSheet.show(context, current: data.memo.color);
    if (r == null) return;
    await ref
        .read(textEditorProvider(widget.memoId).notifier)
        .setColor(r.cleared ? null : r.value);
  }

  Future<void> _clearMemoColor(TextEditorData data) async {
    await ref.read(textEditorProvider(widget.memoId).notifier).setColor(null);
  }

  Future<void> _rename(BuildContext context, TextEditorData data) async {
    final memo = data.memo;
    final ctrl = TextEditingController(text: memo.title);
    try {
      final result = await AppDialog.show<String>(
        context: context,
        title: '重命名',
        content: AppInput(
          controller: ctrl,
          onChanged: (_) {},
          hintText: '输入新标题',
        ),
        actions: [
          AppButton(
              variant: AppButtonStyle.text,
              onPressed: () => AppDialog.close(context),
              child: const MiuixText('取消')),
          AppButton(
              onPressed: () =>
                  AppDialog.close<String>(context, ctrl.text.trim()),
              child: const MiuixText('确定')),
        ],
      );
      if (result != null && result.isNotEmpty && result != memo.title) {
        await ref.read(memoRepositoryProvider).rename(memo.id, result);
        ref.invalidate(textEditorProvider(widget.memoId));
      }
    } finally {
      ctrl.dispose();
    }
  }

  /// [context] 必须位于 AppScaffold 子树内。
  Future<void> _editRemark(BuildContext context, TextEditorData data) async {
    final r = await RemarkEditor.show(context, initial: data.memo.remark);
    if (r != null) {
      await ref
          .read(textEditorProvider(widget.memoId).notifier)
          .setRemark(r.isEmpty ? null : r);
    }
  }

  /// [context] 必须位于 AppScaffold 子树内。
  Future<void> _textColor(BuildContext context, TextEditorData data) async {
    final r = await ColorPickerSheet.show(context);
    // 取消（null）不做任何处理。
    if (r == null) return;
    if (r.cleared) {
      // "清除颜色"：移除选中区域上的 color 属性。
      data.controller.formatSelection(Attribute.clone(Attribute.color, null));
      return;
    }
    final hex = '#${(r.value! & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    data.controller.formatSelection(ColorAttribute(hex));
  }

  /// [context] 必须位于 AppScaffold 子树内。
  Future<void> _pickFont(
      BuildContext context, TextEditorData data) async {
    await FontPicker.show(context, ref,
        currentFontId: data.memo.fontId,
        onPicked: (font) => ref
            .read(textEditorProvider(widget.memoId).notifier)
            .applyFont(font));
  }

  Future<void> _menuAction(String value, TextEditorData data) async {
    final share = ref.read(shareServiceProvider);
    switch (value) {
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
