import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../core/di/providers.dart';
import '../../core/storage/mindspace_storage.dart';
import '../../data/models/memo.dart';
import 'todo_model.dart';

/// 待办编辑器运行时数据。
class TodoEditorData {
  const TodoEditorData({
    required this.memo,
    required this.items,
    this.saving = false,
  });

  final Memo memo;
  final List<TodoItem> items;
  final bool saving;

  TodoEditorData copyWith({
    Memo? memo,
    List<TodoItem>? items,
    bool? saving,
  }) {
    return TodoEditorData(
      memo: memo ?? this.memo,
      items: items ?? this.items,
      saving: saving ?? this.saving,
    );
  }
}

class TodoEditorNotifier
    extends FamilyAsyncNotifier<TodoEditorData, String> {
  static const _fileName = 'content.todo.json';

  /// 加载时的 items JSON 签名。
  String? _initialItemsSignature;

  @override
  Future<TodoEditorData> build(String memoId) async {
    final memoRepo = ref.read(memoRepositoryProvider);
    final memo = await memoRepo.findById(memoId);
    if (memo == null) throw StateError('铭记不存在: $memoId');

    final storage = MindspaceStorage.instance;
    final dir = storage.memoDir(memoId: memoId, folderId: memo.folderId);
    final fs = ref.read(fileSystemDatasourceProvider);
    final path = p.join(dir, _fileName);

    List<TodoItem> items = [];
    if (fs.exists(path)) {
      try {
        final raw = await fs.readString(path);
        items = TodoItem.listFromJson(raw);
      } catch (_) {/* 损坏则重置为空列表 */}
    }

    // 记录加载时的 items 签名。
    _initialItemsSignature = TodoItem.listToJson(items);

    return TodoEditorData(memo: memo, items: items);
  }

  /// 当前 items 是否相对加载时发生了变化。
  bool hasUnsavedChanges() {
    final cur = state.value;
    if (cur == null) return false;
    final curSig = TodoItem.listToJson(cur.items);
    return curSig != (_initialItemsSignature ?? curSig);
  }

  /// 整体替换列表（条目顺序即用户拖拽结果）。
  void replace(List<TodoItem> items) {
    final cur = state.value;
    if (cur == null) return;
    state = AsyncData(cur.copyWith(items: items));
  }

  Future<void> save() async {
    // 内容未实质变更则跳过保存，避免仅查看后返回也刷新 updatedAt。
    if (!hasUnsavedChanges()) return;
    final cur = state.value;
    if (cur == null) return;
    state = AsyncData(cur.copyWith(saving: true));

    // 保持 sortOrder 与当前顺序一致，便于下一次编辑或拖拽后持久化顺序。
    final ordered = [
      for (var i = 0; i < cur.items.length; i++)
        cur.items[i].copyWith(sortOrder: i),
    ];

    final storage = MindspaceStorage.instance;
    final dir = storage.memoDir(
      memoId: cur.memo.id,
      folderId: cur.memo.folderId,
    );
    final fs = ref.read(fileSystemDatasourceProvider);
    fs.ensureDir(dir);
    final path = p.join(dir, _fileName);
    await fs.writeString(path, TodoItem.listToJson(ordered));

    // metadata 落一份摘要：用来在主页卡片预览里显示进度，不用每次读文件。
    final summary = _summaryText(ordered);
    final next = cur.memo.copyWith(metadata: {
      ...cur.memo.metadata,
      'filePath': path,
      'excerpt': summary,
      'todoTotal': ordered.length,
      'todoDone': ordered.where((e) => e.checked).length,
    });
    final saved = await ref.read(memoRepositoryProvider).save(next);
    state = AsyncData(cur.copyWith(memo: saved, saving: false));
  }

  String _summaryText(List<TodoItem> items) {
    if (items.isEmpty) return '空列表';
    final done = items.where((e) => e.checked).length;
    return '已完成 $done / ${items.length} 项';
  }
}

final todoEditorProvider = AsyncNotifierProvider.family<TodoEditorNotifier,
    TodoEditorData, String>(TodoEditorNotifier.new);
