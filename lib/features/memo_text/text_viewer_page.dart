import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/utils/markdown_delta.dart';
import '../../../core/widgets/state_views.dart';
import '../share/share_service.dart';
import 'text_provider.dart';

/// 文本铭记只读查看页，右上角可进入编辑。
class TextViewerPage extends ConsumerWidget {
  const TextViewerPage({super.key, required this.memoId});
  final String memoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(textEditorProvider(memoId));
    return async.when(
      loading: () => const Scaffold(body: LoadingState()),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorState(message: '$e'),
      ),
      data: (data) {
        final settings = ref.watch(settingsProvider);
        return Scaffold(
          appBar: AppBar(
            title: Text(data.memo.title,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: [
              PopupMenuButton<String>(
                onSelected: (v) async {
                  final share = ref.read(shareServiceProvider);
                  if (v == 'text') {
                    share.shareText(data.controller.document.toPlainText());
                  } else if (v == 'file') {
                    // 正文仅存 delta.json：分享为文件时实时转 Markdown。
                    final ops = data.controller.document.toDelta().toJson();
                    final md = MarkdownDelta.toMarkdown(ops);
                    share.shareBytes(utf8.encode(md),
                        fileName: '$memoId.md');
                  } else if (v == 'image') {
                    context.push('/share/image/$memoId');
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'text', child: Text('分享为文本')),
                  PopupMenuItem(value: 'image', child: Text('分享为图片')),
                  PopupMenuItem(value: 'file', child: Text('分享为文件')),
                ],
              ),
              IconButton(
                tooltip: '编辑',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.push('/memo/text/$memoId/edit'),
              ),
            ],
          ),
          body: Center(
            // 横屏平板等宽屏下限制正文宽度并居中，避免行长过长。
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 840),
              child: Padding(
                padding: const EdgeInsets.all(16),
                // 使用独立的只读渲染，而不是复用编辑器 provider 的同一个
                // QuillController——否则查看页与编辑页两个 QuillEditor 同时
                // 挂载到同一 controller 上，编辑页会因输入连接被占用而无法输入。
                child: _ReadOnlyQuillView(
                  delta: data.controller.document.toDelta().toJson(),
                  fontFamily: data.fontFamily,
                  lineHeight: settings.lineHeight,
                  paragraphSpacing: settings.paragraphSpacing,
                ),
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/memo/text/$memoId/edit'),
            icon: const Icon(Icons.edit),
            label: const Text('编辑'),
          ),
        );
      },
    );
  }
}

/// 基于独立 controller 的只读富文本渲染。
class _ReadOnlyQuillView extends StatefulWidget {
  const _ReadOnlyQuillView({
    required this.delta,
    this.fontFamily,
    this.lineHeight = 1.7,
    this.paragraphSpacing = 10,
  });

  final List<dynamic> delta;
  final String? fontFamily;
  final double lineHeight;
  final double paragraphSpacing;

  @override
  State<_ReadOnlyQuillView> createState() => _ReadOnlyQuillViewState();
}

class _ReadOnlyQuillViewState extends State<_ReadOnlyQuillView> {
  late final QuillController _controller;

  @override
  void initState() {
    super.initState();
    _controller = QuillController(
      document: Document.fromJson(widget.delta),
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );
  }

  @override
  void didUpdateWidget(covariant _ReadOnlyQuillView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 编辑器保存后共享 provider 的文档变化会以新 delta 触发本组件重建，
    // 这里同步替换内部只读控制器，否则查看页永远停留在修改前的内容。
    if (!listEquals(oldWidget.delta, widget.delta)) {
      try {
        final newDoc = Document.fromJson(widget.delta);
        _controller.document.replace(
          0,
          _controller.document.length,
          newDoc.toDelta(),
        );
        _controller.updateSelection(
          const TextSelection.collapsed(offset: 0),
          ChangeSource.local,
        );
      } catch (_) {/* delta 损坏则保持现状 */}
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return QuillEditor.basic(
      controller: _controller,
      config: QuillEditorConfig(
        expands: false,
        padding: EdgeInsets.zero,
        showCursor: false,
        customStyles: _styles(context, widget.fontFamily),
      ),
    );
  }

  DefaultStyles? _styles(BuildContext context, String? family) {
    if (family == null) return null;
    // 与编辑页一致：自定义样式必须显式带上主题前景色，
    // 否则浅色模式下正文会意外变白。
    final base = TextStyle(
      fontFamily: family,
      fontSize: 16,
      height: widget.lineHeight,
      color: Theme.of(context).colorScheme.onSurface,
    );
    return DefaultStyles(
      paragraph: DefaultTextBlockStyle(
        base,
        const HorizontalSpacing(0, 0),
        VerticalSpacing(0, widget.paragraphSpacing),
        const VerticalSpacing(0, 0),
        null,
      ),
    );
  }
}
