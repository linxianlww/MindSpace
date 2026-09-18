import 'dart:convert';

/// 单个待办条目。
class TodoItem {
  const TodoItem({
    required this.id,
    required this.text,
    this.checked = false,
    this.sortOrder = 0,
  });

  final String id;
  final String text;
  final bool checked;
  final int sortOrder;

  TodoItem copyWith({
    String? id,
    String? text,
    bool? checked,
    int? sortOrder,
  }) {
    return TodoItem(
      id: id ?? this.id,
      text: text ?? this.text,
      checked: checked ?? this.checked,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'checked': checked,
        'sortOrder': sortOrder,
      };

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['id'] as String,
      text: (json['text'] as String?) ?? '',
      checked: (json['checked'] as bool?) ?? false,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  static List<TodoItem> listFromJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(TodoItem.fromJson)
            .toList();
      }
    } catch (_) {/* parse error → empty list */}
    return [];
  }

  static String listToJson(List<TodoItem> items) => jsonEncode(
        items.map((e) => e.toJson()).toList(),
      );
}

/// 解析 / 序列化的辅助函数。
typedef TodoParse = List<TodoItem>;

extension TodoItemsX on List<TodoItem> {
  /// 已勾选 / 总条目（用于进度显示）。
  (int done, int total) get progress =>
      (where((e) => e.checked).length, length);
}
