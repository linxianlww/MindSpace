import 'package:flutter/material.dart';

import '../../../core/utils/doc_parser.dart';
import 'file_provider.dart';

/// 办公文档内置阅读：DOCX 文本、XLSX 工作表表格。
class OfficeContentView extends StatelessWidget {
  const OfficeContentView({super.key, required this.content});
  final FileContent content;

  @override
  Widget build(BuildContext context) {
    final c = content;
    if (c is DocxContent) {
      return _DocxView(text: c.text);
    }
    if (c is XlsxContent) {
      return _XlsxView(sheets: c.sheets);
    }
    return const SizedBox.shrink();
  }
}

class _DocxView extends StatelessWidget {
  const _DocxView({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) {
      return const Center(child: Text('文档没有可显示的文本'));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: SelectableText(
        text,
        style: const TextStyle(height: 1.6, fontSize: 15),
      ),
    );
  }
}

class _XlsxView extends StatefulWidget {
  const _XlsxView({required this.sheets});
  final List<SheetData> sheets;

  @override
  State<_XlsxView> createState() => _XlsxViewState();
}

class _XlsxViewState extends State<_XlsxView>
    with SingleTickerProviderStateMixin {
  late final TabController _tab =
      TabController(length: widget.sheets.length, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sheets.isEmpty) {
      return const Center(child: Text('工作簿为空'));
    }
    return Column(
      children: [
        TabBar(
          isScrollable: true,
          tabs: [for (final s in widget.sheets) Tab(text: s.name)],
          controller: _tab,
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              for (final s in widget.sheets)
                InteractiveViewer(
                  constrained: false,
                  child: DataTable(
                    columns: [
                      for (var c = 0;
                          c < (s.rows.isEmpty ? 0 : s.rows.first.length);
                          c++)
                        DataColumn(label: Text('${c + 1}')),
                    ],
                    rows: [
                      for (final row in s.rows)
                        DataRow(
                          cells: [
                            for (final cell in row)
                              DataCell(SizedBox(
                                width: 120,
                                child: Text(cell,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                              )),
                          ],
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
