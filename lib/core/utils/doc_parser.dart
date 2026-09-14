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
/// - XLSX：优先使用 excel 包解码；若包内崩溃（如样式表缺失导致的
///   Null check 异常），回退到自研 zip + XML 解析，保证总能给出结果。
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

  /// 解析 XLSX 为若干工作表。
  ///
  /// 自研解析器优先：excel 包对公式单元格（FormulaCellValue）的真实取值
  /// 处理不佳——普通公式只显示公式文本、共享公式直接返回空串，且部分畸形
  /// 文件内部空断言崩溃。内置解析器按 `<v>` 取缓存结果、缺缓存时回退公式
  /// 文本，并兼容 sharedStrings/inlineStr/str/共享公式，覆盖面更稳。
  static List<SheetData> parseXlsx(List<int> bytes) {
    try {
      return _parseXlsxManually(bytes);
    } catch (e) {
      // 内置解析器对极个别写法失败时，再交给 excel 包兜底。
      appLogger.w('内置 XLSX 解析失败，回退到 excel 包', e);
      return _parseXlsxWithExcel(bytes);
    }
  }

  static List<SheetData> _parseXlsxWithExcel(List<int> bytes) {
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

  /// 内置 XLSX 解析器：直接读取 zip 内的 sharedStrings / workbook / worksheets。
  static List<SheetData> _parseXlsxManually(List<int> bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    String? readEntry(String name) {
      for (final f in archive.files) {
        if (f.name == name || f.name.endsWith('/$name')) {
          return String.fromCharCodes(f.content as List<int>);
        }
      }
      return null;
    }

    // 共享字符串表。
    final shared = <String>[];
    final sharedXml = readEntry('xl/sharedStrings.xml');
    if (sharedXml != null) {
      final doc = XmlDocument.parse(sharedXml);
      for (final si in doc.findAllElements('si')) {
        // 富文本由多个 <r><t> 组成；纯文本只有一个 <t>。
        final parts = si.findAllElements('t').map((e) => e.innerText).join();
        shared.add(parts);
      }
    }

    // workbook.xml 中的 sheet 顺序，配合 rels 把 r:id 映射到实际文件。
    final targets = <String, String>{};
    final relsXml = readEntry('xl/_rels/workbook.xml.rels');
    if (relsXml != null) {
      final rels = XmlDocument.parse(relsXml);
      for (final rel in rels.findAllElements('Relationship')) {
        final id = rel.getAttribute('Id');
        final target = rel.getAttribute('Target');
        if (id != null && target != null) {
          targets[id] = target.startsWith('/') ? target.substring(1) : 'xl/$target';
        }
      }
    }

    String? workbookNameOf(XmlElement sheet) =>
        sheet.getAttribute('name');

    final workbookXml = readEntry('xl/workbook.xml');
    final sheets = <SheetData>[];
    if (workbookXml != null) {
      final wb = XmlDocument.parse(workbookXml);
      final sheetNodes = wb.findAllElements('sheet').toList();
      for (var i = 0; i < sheetNodes.length; i++) {
        final node = sheetNodes[i];
        final name = workbookNameOf(node) ?? 'Sheet${i + 1}';
        // 优先按 r:id 找到目标文件，否则按序号约定回退。
        final rid = node.getAttribute('r:id') ?? node.getAttribute('ns:r:id');
        var entryName = rid != null ? targets[rid] : null;
        entryName ??= 'xl/worksheets/sheet${i + 1}.xml';
        final sheetXml = readEntry(entryName);
        if (sheetXml == null) continue;
        sheets.add(SheetData(name, _parseSheetXml(XmlDocument.parse(sheetXml), shared)));
      }
    }
    if (sheets.isEmpty) {
      throw const FormatException('XLSX 中未找到任何工作表');
    }
    return sheets;
  }

  /// 解析单个 worksheet XML 为字符串网格。
  static List<List<String>> _parseSheetXml(XmlDocument doc, List<String> shared) {
    final rows = <List<String>>[];
    final grid = <int, Map<int, String>>{};
    var maxCol = -1;
    for (final row in doc.findAllElements('row')) {
      final rowAttr = int.tryParse(row.getAttribute('r') ?? '');
      final rowIndex = rowAttr != null ? rowAttr - 1 : grid.length;
      for (final c in row.findElements('c')) {
        final ref = c.getAttribute('r') ?? '';
        final colIndex = _colIndexFromRef(ref, maxCol + 1);
        final value = _cellValue(c, shared);
        grid.putIfAbsent(rowIndex, () => {})[colIndex] = value;
        if (colIndex > maxCol) maxCol = colIndex;
      }
    }
    final lastRow = grid.keys.isEmpty ? -1 : grid.keys.reduce((a, b) => a > b ? a : b);
    for (var r = 0; r <= lastRow; r++) {
      final rowMap = grid[r] ?? const {};
      rows.add([
        for (var c = 0; c <= maxCol; c++) rowMap[c] ?? '',
      ]);
    }
    return rows;
  }

  /// 从单元格引用（如 "BC12"）解析列下标；引用缺失时用 [fallback] 顺序填入。
  static int _colIndexFromRef(String ref, int fallback) {
    var col = 0;
    var hasLetter = false;
    for (final code in ref.codeUnits) {
      if (code >= 0x41 && code <= 0x5A) {
        col = col * 26 + (code - 0x40);
        hasLetter = true;
      } else if (code >= 0x61 && code <= 0x7A) {
        col = col * 26 + (code - 0x60);
        hasLetter = true;
      } else {
        break;
      }
    }
    return hasLetter ? col - 1 : fallback;
  }

  /// 计算单元格显示值（兼容 s/str/inlineStr/b/n 及公式）。
  static String _cellValue(XmlElement c, List<String> shared) {
    final type = c.getAttribute('t') ?? 'n';
    final inline = c.findElements('is').toList();
    if (type == 'inlineStr' && inline.isNotEmpty) {
      return inline.first.findAllElements('t').map((e) => e.innerText).join();
    }
    final vElements = c.findElements('v').toList();
    final fElements = c.findElements('f').toList();
    final isFormula = fElements.isNotEmpty;
    // 公式单元格：优先取缓存结果 <v>；无缓存结果（如 data_only=False 写出）
    // 时显示公式文本，避免公式单元格意外空白。
    if (isFormula && vElements.isEmpty) {
      final fn = fElements.first.innerText.trim();
      if (fn.isEmpty) return ''; // 共享公式且无计算结果，确实无值可显示
      return '=$fn';
    }
    if (vElements.isEmpty) return '';
    final raw = vElements.first.innerText;
    switch (type) {
      case 's': // 共享字符串
        final idx = int.tryParse(raw);
        return idx != null && idx >= 0 && idx < shared.length ? shared[idx] : '';
      case 'b':
        return raw == '1' ? 'TRUE' : 'FALSE';
      default:
        // n（数字）、str（公式的字符串结果）、e（错误值如 #DIV/0!）原样返回。
        return raw;
    }
  }
}
