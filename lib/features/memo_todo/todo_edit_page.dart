import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/providers.dart';
import '../../core/utils/uuid_utils.dart';
import '../../data/models/memo.dart';
import '../memo_text/widgets/color_picker.dart';
import '../memo_text/widgets/remark_editor.dart';
import 'todo_model.dart';
import 'todo_provider.dart';

/// 待办编辑器：可增删改条目、勾选/取消、长按或拖拽手柄排序。
class TodoEditPage extends ConsumerStatefulWidget {
  const TodoEditPage({super.key, required this.memoId});

  final String memoId;

  @override
  ConsumerState<TodoEditPage> createState() => _TodoEditPageState();
}

class _TodoEditPageState extends ConsumerState<TodoEditPage> {
  final _addCtrl = TextEditingController();
  final _addFocus = FocusNode();

  @override
  void dispose() {
    _addCtrl.dispose();
    _addFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(todoEditorProvider(widget.memoId).notifier).save();
  }

  void _addItem() {
    final text = _addCtrl.text.trim().replaceAll('\n', ' ');
    if (text.isEmpty) return;
    final cur = ref.read(todoEditorProvider(widget.memoId)).valueOrNull;
    if (cur == null) return;
    final item = TodoItem(
      id: UuidUtils.newId(),
      text: text,
      sortOrder: cur.items.length,
    );
    ref
        .read(todoEditorProvider(widget.memoId).notifier)
        .replace([...cur.items, item]);
    _addCtrl.clear();
    _addFocus.requestFocus();
  }

  void _toggleCheck(String id) {
    final cur = ref.read(todoEditorProvider(widget.memoId)).valueOrNull;
    if (cur == null) return;
    final items = [
      for (final it in cur.items)
        it.id == id ? it.copyWith(checked: !it.checked) : it,
    ];
    ref.read(todoEditorProvider(widget.memoId).notifier).replace(items);
  }

  void _delete(String id) {
    final cur = ref.read(todoEditorProvider(widget.memoId)).valueOrNull;
    if (cur == null) return;
    ref.read(todoEditorProvider(widget.memoId).notifier).replace(
        cur.items.where((e) => e.id != id).toList());
  }

  void _reorder(int oldIndex, int newIndex) {
    final cur = ref.read(todoEditorProvider(widget.memoId)).valueOrNull;
    if (cur == null) return;
    var items = List<TodoItem>.from(cur.items);
    if (newIndex > oldIndex) newIndex -= 1;
    final moved = items.removeAt(oldIndex);
    items.insert(newIndex, moved);
    ref.read(todoEditorProvider(widget.memoId).notifier).replace(items);
  }

  Future<void> _setColor(Memo? memo) async {
    if (memo == null) return;
    final r = await ColorPickerSheet.show(context, current: memo.color);
    if (r == null) return;
    await ref
        .read(memoRepositoryProvider)
        .setAppearance(memo.id, color: r.value);
    ref.invalidate(todoEditorProvider(widget.memoId));
  }

  Future<void> _setRemark(Memo? memo, String? previous) async {
    if (memo == null) return;
    final r = await RemarkEditor.show(context, initial: previous ?? '');
    if (r == null) return;
    await ref
        .read(memoRepositoryProvider)
        .setAppearance(memo.id, remark: r.isEmpty ? null : r);
    ref.invalidate(todoEditorProvider(widget.memoId));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(todoEditorProvider(widget.memoId));
    return async.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('编辑待办')),
        body: Center(child: Text('加载失败：$e')),
      ),
      data: (data) {
        final memo = data.memo;
        final items = data.items;
        return PopScope(
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) _save();
          },
          child: Scaffold(
            appBar: AppBar(
              title: GestureDetector(
                onTap: () => _rename(data),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(memo.title,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    const Icon(Icons.edit, size: 16),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  tooltip: '卡片颜色',
                  icon: Icon(Icons.palette_outlined,
                      color: memo.color != null ? Color(memo.color!) : null),
                  onPressed: () => _setColor(memo),
                ),
                IconButton(
                  tooltip: '备注',
                  icon: const Icon(Icons.label_outline),
                  onPressed: () => _setRemark(memo, memo.remark),
                ),
                IconButton(
                  icon: data.saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.check),
                  onPressed: () async {
                    await _save();
                    if (context.mounted) context.pop();
                  },
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _QuickAddField(
                    controller: _addCtrl,
                    focusNode: _addFocus,
                    onAdd: _addItem,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: items.isEmpty
                        ? _EmptyHint()
                        : ReorderableListView.builder(
                            buildDefaultDragHandles: false,
                            itemCount: items.length,
                            // ignore: deprecated_member_use
                            onReorder: _reorder,
                            itemBuilder: (ctx, i) {
                              final it = items[i];
                              return _TodoRow(
                                key: ValueKey(it.id),
                                index: i,
                                item: it,
                                onToggle: () => _toggleCheck(it.id),
                                onDelete: () => _delete(it.id),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _rename(TodoEditorData data) async {
    final memo = data.memo;
    final ctrl = TextEditingController(text: memo.title);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重命名'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: '标题'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty && mounted) {
      await ref.read(memoRepositoryProvider).rename(memo.id, name);
      ref.invalidate(todoEditorProvider(widget.memoId));
    }
  }
}

/// 顶部快速添加行：输入 + 添加按钮（回车亦可提交）。
class _QuickAddField extends StatelessWidget {
  const _QuickAddField({
    required this.controller,
    required this.focusNode,
    required this.onAdd,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onAdd(),
              decoration: const InputDecoration(
                hintText: '添加新条目…',
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: '添加条目',
            icon: const Icon(Icons.add),
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

class _TodoRow extends StatelessWidget {
  const _TodoRow({
    super.key,
    required this.index,
    required this.item,
    required this.onToggle,
    required this.onDelete,
  });

  final int index;
  final TodoItem item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final checked = item.checked;
    final textStyle = TextStyle(
      color: checked ? scheme.onSurfaceVariant : scheme.onSurface,
      decoration: checked ? TextDecoration.lineThrough : null,
      decorationColor: scheme.outline,
      fontSize: 16,
    );
    return ReorderableDelayedDragStartListener(
      index: index,
      child: ListTile(
        leading: Checkbox(
          value: checked,
          onChanged: (_) => onToggle(),
        ),
        title: Text(
          item.text.isEmpty ? '（空条目）' : item.text,
          style: textStyle,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: '删除',
              icon: Icon(Icons.remove_circle_outline,
                  color: scheme.error.withValues(alpha: 0.8)),
              onPressed: onDelete,
            ),
            ReorderableDelayedDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.drag_handle),
              ),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.checklist_rtl_rounded,
              size: 64, color: scheme.outlineVariant),
          const SizedBox(height: 12),
          Text('还没有条目', style: TextStyle(color: scheme.outline)),
          const SizedBox(height: 4),
          Text('在顶部输入框添加你的第一项待办',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.outline)),
        ],
      ),
    );
  }
}
