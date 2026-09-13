import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
                    final p = data.memo.metadata['filePath'] as String?;
                    if (p != null) share.shareFile(p);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'text', child: Text('分享为文本')),
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
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: QuillEditor.basic(
              controller: data.controller,
              config: QuillEditorConfig(
                expands: false,
                padding: EdgeInsets.zero,
                showCursor: false,
                customStyles: data.fontFamily == null
                    ? null
                    : DefaultStyles(
                        paragraph: DefaultTextBlockStyle(
                          TextStyle(
                              fontFamily: data.fontFamily,
                              fontSize: 16,
                              height: 1.5),
                          const HorizontalSpacing(0, 0),
                          const VerticalSpacing(0, 4),
                          const VerticalSpacing(0, 0),
                          null,
                        ),
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
