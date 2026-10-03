// DataColumn/DataRow/DataCell 为 functional 表格组件（MIUIX 无等价物），
// 按白名单规则 show 导入。
import 'package:flutter/material.dart' show DataColumn, DataRow, DataCell;
import 'package:mindspace/ui/design_system/app_design_system.dart';

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
      return const Center(child: MiuixText('文档没有可显示的文本'));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: AppSelectableText(
        text,
        // 阅读排版：基于 body1 语义，仅调整行高与字号
        style: MiuixTheme.of(context)
            .textStyles
            .body1
            .copyWith(height: 1.6, fontSize: 15),
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

class _XlsxViewState extends State<_XlsxView> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final sheets = widget.sheets;
    if (sheets.isEmpty) {
      return const Center(child: MiuixText('工作簿为空'));
    }
    return Column(
      children: [
        AppTabStrip(
          tabs: [for (final s in sheets) s.name],
          selectedIndex: _tabIndex,
          onTabSelected: (i) => setState(() => _tabIndex = i),
        ),
        Expanded(
          child: IndexedStack(
            index: _tabIndex,
            children: [
              for (final s in sheets)
                InteractiveViewer(
                  constrained: false,
                  child: AppDataTable(
                    columns: [
                      for (var c = 0;
                          c < (s.rows.isEmpty ? 0 : s.rows.first.length);
                          c++)
                        DataColumn(label: MiuixText('${c + 1}')),
                    ],
                    rows: [
                      for (final row in s.rows)
                        DataRow(
                          cells: [
                            for (final cell in row)
                              DataCell(SizedBox(
                                width: 120,
                                child: MiuixText(cell,
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
