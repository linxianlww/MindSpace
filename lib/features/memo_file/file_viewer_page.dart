import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../core/widgets/state_views.dart';
import '../home/home_provider.dart';
import 'file_provider.dart';
import 'office_viewer_page.dart';
import 'widgets/file_info_card.dart';
import 'widgets/open_with_button.dart';

/// 文件铭记查看页：PDF 内置阅读，DOCX/XLSX 内置渲染，其余外部打开。
class FileViewerPage extends ConsumerWidget {
  const FileViewerPage({super.key, required this.memoId});
  final String memoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memoAsync = ref.watch(memoDetailProvider(memoId));
    return Scaffold(
      appBar: AppBar(
        title: Text(memoAsync.maybeWhen(
            data: (m) => m?.title ?? '文件', orElse: () => '文件')),
      ),
      body: memoAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(message: '$e'),
        data: (memo) {
          if (memo == null) return const ErrorState(message: '文件不存在');
          final content = ref.watch(fileContentProvider(memo));
          return content.when(
            loading: () => const LoadingState(hint: '正在解析文件…'),
            error: (e, _) => ErrorState(
              message: '解析失败：$e',
              onRetry: () => ref.invalidate(fileContentProvider(memo)),
            ),
            data: (c) {
              switch (c) {
                case PdfFile(:final path):
                  return PdfViewer.file(path);
                case DocxContent():
                case XlsxContent():
                  return OfficeContentView(content: c);
                case GenericFile():
                  return _GenericView(content: c);
              }
            },
          );
        },
      ),
    );
  }
}

class _GenericView extends StatelessWidget {
  const _GenericView({required this.content});
  final GenericFile content;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          FileInfoCard(
            name: content.originalName,
            path: content.path,
            sizeBytes: content.sizeBytes,
            ext: content.ext,
          ),
          const SizedBox(height: 20),
          if (content.path.isNotEmpty) OpenWithButton(path: content.path),
        ],
      ),
    );
  }
}
