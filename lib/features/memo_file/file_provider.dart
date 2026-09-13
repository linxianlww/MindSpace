import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/utils/doc_parser.dart';
import '../../../data/models/memo.dart';

/// 文件铭记解析后的统一内容。
sealed class FileContent {
  const FileContent();
}

class PdfFile extends FileContent {
  const PdfFile(this.path);
  final String path;
}

class DocxContent extends FileContent {
  const DocxContent(this.text);
  final String text;
}

class XlsxContent extends FileContent {
  const XlsxContent(this.sheets);
  final List<SheetData> sheets;
}

class GenericFile extends FileContent {
  const GenericFile(
      {required this.path,
      required this.originalName,
      required this.sizeBytes,
      required this.ext});
  final String path;
  final String originalName;
  final int sizeBytes;
  final String ext;
}

/// 按扩展名解析文件铭记内容。
final fileContentProvider =
    FutureProvider.family<FileContent, Memo>((ref, memo) async {
  final meta = memo.metadata;
  final path = meta['path'] as String?;
  final ext = (meta['ext'] as String?) ?? '';
  if (path == null) {
    return GenericFile(
        path: '', originalName: memo.title, sizeBytes: 0, ext: ext);
  }
  final fs = ref.read(fileSystemDatasourceProvider);
  switch (ext) {
    case 'pdf':
      return PdfFile(path);
    case 'docx':
    case 'doc':
      final bytes = await fs.readBytes(path);
      return DocxContent(DocParser.parseDocx(bytes));
    case 'xlsx':
    case 'xls':
      final bytes = await fs.readBytes(path);
      return XlsxContent(DocParser.parseXlsx(bytes));
    default:
      return GenericFile(
        path: path,
        originalName: (meta['originalName'] as String?) ?? memo.title,
        sizeBytes: (meta['sizeBytes'] as int?) ?? 0,
        ext: ext,
      );
  }
});
