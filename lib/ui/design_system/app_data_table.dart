import 'package:flutter/material.dart';

/// 数据表格 —— 透传 Material DataTable。
/// MIUIX 无等效组件，为功能性组件，不影响整体视觉。
class AppDataTable extends StatelessWidget {
  const AppDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.border,
    this.headingRowColor,
  });

  final List<DataColumn> columns;
  final List<DataRow> rows;
  final int? sortColumnIndex;
  final bool sortAscending;
  final TableBorder? border;
  // ignore: deprecated_member_use
  final MaterialStateProperty<Color?>? headingRowColor;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: columns,
        rows: rows,
        sortColumnIndex: sortColumnIndex,
        sortAscending: sortAscending,
        border: border,
        headingRowColor: headingRowColor,
      ),
    );
  }
}
