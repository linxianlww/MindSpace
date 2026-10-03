import 'package:mindspace/ui/design_system/app_design_system.dart';
// ReorderableListView 为拖拽排序框架、TextInputAction 为键盘行为常量
// （MIUIX 无等价物），按白名单规则 show 导入。
import 'package:flutter/material.dart'
    show ReorderableListView, TextInputAction;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/providers.dart';
import '../../core/utils/uuid_utils.dart';
import '../../data/models/memo.dart';
import '../desktop_shortcut/add_to_desktop.dart';
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

  /// AppScaffold 子树内的宿主 context。
  ///
  /// 弹层 API（AppDialog/AppSheet/AppSnackbar）通过
  /// `AppScaffold.maybeOf` 向上查找脚手架宿主；content 闭包的
  /// context 已在脚手架子树内，在闭包开头赋值到这里供各处理器使用。
  BuildContext? _hostCtx;

  /// 页面级弹层调用的宿主 context；未就绪时返回 null。
  BuildContext? get _pageCtx {
    final ctx = _hostCtx;
    return (ctx != null && ctx.mounted) ? ctx : null;
  }

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

  Future<void> _delete(String id) async {
    final ctx = _pageCtx;
    if (ctx == null) return;
    final confirmed = await AppDialog.show<bool>(
      context: ctx,
      title: '删除条目',
      message: '删除后不可恢复，确定删除该待办条目？',
      actions: [
        MiuixTextButton('取消', onPressed: () => AppDialog.close(ctx)),
        // 破坏性操作：主题错误色文字按钮（禁止硬编码 Colors.red）
        AppButton(
          variant: AppButtonStyle.text,
          onPressed: () => AppDialog.close(ctx, true),
          child: MiuixText('删除',
              style: TextStyle(color: MiuixTheme.of(ctx).colors.error)),
        ),
      ],
    );
    if (confirmed != true) return;
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
    final ctx = _pageCtx;
    if (memo == null || ctx == null) return;
    final r = await ColorPickerSheet.show(ctx, current: memo.color);
    if (r == null) return;
    await ref
        .read(memoRepositoryProvider)
        .setAppearance(memo.id, color: r.value);
    ref.invalidate(todoEditorProvider(widget.memoId));
  }

  Future<void> _setRemark(Memo? memo, String? previous) async {
    final ctx = _pageCtx;
    if (memo == null || ctx == null) return;
    final r = await RemarkEditor.show(ctx, initial: previous ?? '');
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
          const AppScaffold(body: Center(child: AppCircleProgress())),
      error: (e, _) => AppScaffold(
        topBar: const AppHeader(title: '编辑待办'),
        body: Center(child: MiuixText('加载失败：$e')),
      ),
      data: (data) {
        final memo = data.memo;
        final items = data.items;
        return PopScope(
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) _save();
          },
          child: AppScaffold(
            topBar: AppHeader(
              title: memo.title,
              actions: [
                AppTapIcon(
                  tooltip: '重命名',
                  icon: const HiuiIcon(HiuiIcons.edit, size: 16),
                  onPressed: () => _rename(data),
                ),
                AppTapIcon(
                  tooltip: '卡片颜色',
                  icon: HiuiIcon(HiuiIcons.skin,
                      color: memo.color != null ? Color(memo.color!) : null),
                  onPressed: () => _setColor(memo),
                ),
                AppTapIcon(
                  tooltip: '备注',
                  icon: const HiuiIcon(HiuiIcons.tag),
                  onPressed: () => _setRemark(memo, memo.remark),
                ),
                AppTapIcon(
                  icon: data.saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: AppCircleProgress())
                      : const HiuiIcon(HiuiIcons.check),
                  onPressed: () async {
                    await _save();
                    if (context.mounted) context.pop();
                  },
                ),
                AppTapIcon(
                  tooltip: '添加到桌面',
                  icon: const HiuiIcon(HiuiIcons.export),
                  onPressed: () {
                    final ctx = _pageCtx;
                    if (ctx != null) addMemoToDesktop(ctx, ref, memo);
                  },
                ),
              ],
            ),
            content: (context, padding) {
              // content 闭包的 context 已在 MiuixScaffold 子树内（设计系统
              // 修复后直接有效），供页面级弹层（AppDialog 等）查找宿主。
              _hostCtx = context;
              // MiuixScaffold 不会自动做键盘避让：顶栏高度由 padding.top
              // 消化，键盘高度由 viewInsets.bottom 消化。
              return Padding(
                padding: EdgeInsets.only(
                  top: padding.top,
                  bottom: MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Padding(
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
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _rename(TodoEditorData data) async {
    final ctx = _pageCtx;
    if (ctx == null) return;
    final memo = data.memo;
    final ctrl = TextEditingController(text: memo.title);
    final name = await AppDialog.show<String>(
      context: ctx,
      title: '重命名',
      content: AppInput(
        controller: ctrl,
        autofocus: true,
        hintText: '标题',
      ),
      actions: [
        MiuixTextButton('取消', onPressed: () => AppDialog.close(ctx)),
        MiuixButton(
          onPressed: () => AppDialog.close<String>(ctx, ctrl.text.trim()),
          child: const MiuixText('确定'),
        ),
      ],
    );
    if (name != null && name.isNotEmpty && mounted) {
      await ref.read(memoRepositoryProvider).rename(memo.id, name);
      ref.invalidate(todoEditorProvider(widget.memoId));
    }
  }
}

/// 顶部快速添加行：输入 + 添加按钮（回车亦可提交）。
class _QuickAddField extends StatefulWidget {
  const _QuickAddField({
    required this.controller,
    required this.focusNode,
    required this.onAdd,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onAdd;

  @override
  State<_QuickAddField> createState() => _QuickAddFieldState();
}

class _QuickAddFieldState extends State<_QuickAddField> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.isNotEmpty;
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final has = widget.controller.text.isNotEmpty;
    if (has != _hasText) {
      setState(() => _hasText = has);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: AppInput(
              controller: widget.controller,
              focusNode: widget.focusNode,
              textInputAction: TextInputAction.done,
              // 有内容时清除 hintText，MIUIX 的 useLabelAsPlaceholder 切换
              // 依赖动画过渡，会导致提示文字无法立刻消失。
              hintText: _hasText ? null : '添加新条目…',
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 紧邻输入框的添加触发用主题色图标按钮（轻量 affordance）
              AppTapIcon(
                tooltip: '添加',
                icon: HiuiIcon(HiuiIcons.add,
                    color: MiuixTheme.of(context).colors.primary, size: 26),
                onPressed: widget.onAdd,
              ),
            ],
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
    final colors = MiuixTheme.of(context).colors;
    final checked = item.checked;
    // 待办文字样式：基于 body1 语义，覆盖颜色/删除线/字号
    final textStyle = MiuixTheme.of(context).textStyles.body1.copyWith(
          color: checked ? colors.onSurfaceVariantSummary : colors.onSurface,
          decoration: checked ? TextDecoration.lineThrough : null,
          decorationColor: colors.outline,
          fontSize: 16,
        );
    return AppReorderableDragHandle(
      index: index,
      child: AppListRow(
        leading: MiuixCheckbox(
          value: checked,
          onChanged: (_) => onToggle(),
        ),
        title: MiuixText(
          item.text.isEmpty ? '（空条目）' : item.text,
          style: textStyle,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTapIcon(
              tooltip: '删除',
              icon: HiuiIcon(HiuiIcons.minusSquare,
                  color: colors.error.withValues(alpha: 0.8)),
              onPressed: onDelete,
            ),
            AppReorderableDragHandle(
              index: index,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: const HiuiIcon(HiuiIcons.drag),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = MiuixTheme.of(context).colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HiuiIcon(HiuiIcons.checkSquare,
              size: 64, color: colors.onSurfaceVariantSummary),
          const SizedBox(height: 12),
          MiuixText('还没有条目',
              style: MiuixTheme.of(context)
                  .textStyles
                  .body1
                  .copyWith(color: colors.outline)),
          const SizedBox(height: 4),
          MiuixText('在顶部输入框添加你的第一项待办',
              style: MiuixTheme.of(context)
                  .textStyles
                  .body2
                  .copyWith(color: colors.outline)),
        ],
      ),
    );
  }
}
