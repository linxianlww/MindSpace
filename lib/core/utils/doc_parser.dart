import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:xml/xml.dart';

import 'app_logger.dart';

/// 一张工作表的解析结果。
class SheetData {
  const SheetData(this.name, this.rows);
  final String name;
  final List<List<String>> rows;
}

/// 办公文档解析（纯 Dart，无原生依赖，大文件应在 isolate 调用）。
///
/// - DOCX：本质是 zip，word/document.xml 内 w:t 为文本、w:p 为段落；
/// - XLSX：使用 excel 包解码为工作表与单元格。
class DocParser {
  const DocParser._();

  /// 解析 DOCX 为带换行的纯文本（保留段落结构）。
  static String parseDocx(List<int> bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final docFile = archive.files.firstWhere(
        (f) => f.name == 'word/document.xml',
        orElse: () => throw const FormatException('缺少 word/document.xml'),
      );
      final xml = XmlDocument.parse(
          String.fromCharCodes(docFile.content as List<int>));
      final buffer = StringBuffer();
      for (final paragraph in xml.findAllElements('w:p')) {
        final texts = paragraph
            .findAllElements('w:t')
            .map((e) => e.innerText)
            .join();
        buffer.writeln(texts);
      }
      return buffer.toString().trim();
    } catch (e) {
      appLogger.w('DOCX 解析失败', e);
      rethrow;
    }
  }

  /// 解析 XLSX/XLS 为若干工作表。
  static List<SheetData> parseXlsx(List<int> bytes) {
    final excel = Excel.decodeBytes(bytes);
    final sheets = <SheetData>[];
    excel.tables.forEach((name, table) {
      final rows = <List<String>>[];
      for (final row in table.rows) {
        rows.add(row.map((cell) => cell?.value?.toString() ?? '').toList());
      }
      sheets.add(SheetData(name, rows));
    });
    return sheets;
  }
}
