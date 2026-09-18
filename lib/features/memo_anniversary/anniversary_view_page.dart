import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/providers.dart';
import '../../data/models/memo.dart';
import '../home/home_provider.dart';
import '../memo_text/widgets/color_picker.dart';
import '../memo_text/widgets/remark_editor.dart';
import 'anniversary_provider.dart';

/// 纪念日查看页：居中展示大字"还有 N 天" / "已过 N 天" / 目标日期。
/// 仿 TOTP 查看页布局：置顶显示天数 → 目标日期标签 → 重复信息 → 操作按钮。
class AnniversaryViewPage extends ConsumerWidget {
  const AnniversaryViewPage({super.key, required this.memoId});
  final String memoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memoAsync = ref.watch(memoDetailProvider(memoId));

    return memoAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (memo) {
        if (memo == null) {
          return const Scaffold(body: Center(child: Text('铭记不存在')));
        }
        final cfg = AnniversaryConfig.fromMemo(memo);
        final calc = computeAnniversary(cfg);
        return Scaffold(
          appBar: AppBar(
            title: Text(memo.title,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: [
              PopupMenuButton<String>(
                tooltip: '更多',
                itemBuilder: (_) => [
                  PopupMenuItem(
                      value: 'color',
                      enabled: false,
                      child: Row(
                        children: [
                          Icon(Icons.palette_outlined,
                              size: 18,
                              color: memo.color != null
                                  ? Color(memo.color!)
                                  : Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 10),
                          const Text('卡片颜色'),
                        ],
                      )),
                  PopupMenuItem(
                    value: 'set_color',
                    onTap: () => WidgetsBinding.instance
                        .addPostFrameCallback((_) => _setMemoColor(context, ref, memo)),
                    child: const Padding(
                        padding: EdgeInsets.only(left: 28),
                        child: Text('修改颜色')),
                  ),
                  PopupMenuItem(
                    value: 'clear_color',
                    enabled: memo.color != null,
                    onTap: () => WidgetsBinding.instance
                        .addPostFrameCallback((_) async {
                      await ref
                          .read(memoRepositoryProvider)
                          .setAppearance(memo.id, color: null);
                      ref.invalidate(memoDetailProvider(memo.id));
                    }),
                    child: const Padding(
                        padding: EdgeInsets.only(left: 28),
                        child: Text('清除颜色')),
                  ),
                  PopupMenuItem(
                      value: 'label',
                      enabled: false,
                      child: Row(
                        children: [
                          const Icon(Icons.label_outline, size: 18),
                          const SizedBox(width: 10),
                          Text(memo.remark?.isNotEmpty == true
                              ? memo.remark!
                              : '备注标签'),
                        ],
                      )),
                  PopupMenuItem(
                    value: 'edit_label',
                    onTap: () => WidgetsBinding.instance
                        .addPostFrameCallback(
                            (_) => _editRemark(context, ref, memo)),
                    child: const Padding(
                        padding: EdgeInsets.only(left: 28),
                        child: Text('修改标签')),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'edit_text',
                    onTap: () => WidgetsBinding.instance
                        .addPostFrameCallback(
                            (_) => _editRemark(context, ref, memo)),
                    child: const Text('编辑卡片文本'),
                  ),
                  PopupMenuItem(
                    value: 'edit',
                    onTap: () => WidgetsBinding.instance
                        .addPostFrameCallback((_) {
                      if (context.mounted) {
                        context.push('/memo/anniversary/$memoId/edit');
                      }
                    }),
                    child: const Text('编辑设置'),
                  ),
                ],
              ),
            ],
          ),
          body: _body(context, ref, memo, calc),
        );
      },
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, Memo memo, AnniversaryCalc calc) {
    final scheme = Theme.of(context).colorScheme;

    // 天数格式化：>0"还有 N 天"，=0"就是今天！"，<0"已过 N 天"。
    final countText = calc.isToday
        ? '今'
        : '${calc.absCount}';
    final unitText = calc.isToday ? '' : '天';
    final hintText = calc.count > 0
        ? '还有'
        : (calc.count < 0 ? '已过' : '');
    final accentColor = memo.colorValue ?? scheme.primary;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        const SizedBox(height: 12),
        // 备注标签（可点击编辑）
        if (memo.remark != null && memo.remark!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _editRemark(context, ref, memo),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        memo.remark!,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: scheme.onSecondaryContainer),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.edit,
                          size: 14,
                          color: scheme.onSecondaryContainer
                              .withValues(alpha: 0.6)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 24),
        // 顶数词：「还有」/「已过」
        Center(
          child: Text(
            hintText,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: scheme.onSurfaceVariant, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 8),
        // 大字天数
        Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: Row(
              key: ValueKey<int>(calc.count),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  countText,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: calc.isToday
                            ? accentColor
                            : scheme.onSurface,
                        height: 1.05,
                      ),
                ),
                if (unitText.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(
                    unitText,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // 目标日期
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
            ),
            child: Column(
              children: [
                Text(
                  calc.targetLabel,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: scheme.onSurface, fontWeight: FontWeight.w600),
                ),
                if (calc.repeatLabel.isNotEmpty &&
                    calc.repeatLabel != '不重复') ...[
                  const SizedBox(height: 2),
                  Text(
                    calc.repeatLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        Center(
          child: FilledButton.tonalIcon(
            onPressed: () => _copy(context, memo, calc),
            icon: const Icon(Icons.copy_rounded, size: 20),
            label: const Text('复制天数'),
          ),
        ),
      ],
    );
  }

  Future<void> _copy(
      BuildContext context, Memo memo, AnniversaryCalc calc) async {
    final cfg = AnniversaryConfig.fromMemo(memo);
    final calLabel = cfg.calendar == 'lunar' ? '农历 ' : '';
    final text = '${memo.title} ${calc.isToday ? "就是今天" : (calc.isUpcoming ? "还有 ${calc.count} 天" : "已过 ${calc.absCount} 天")} · $calLabel${calc.targetLabel}';
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已复制'), duration: Duration(seconds: 1)),
      );
    }
  }

  static Future<void> _setMemoColor(
      BuildContext context, WidgetRef ref, Memo memo) async {
    final r = await ColorPickerSheet.show(context, current: memo.color);
    if (r == null) return;
    await ref
        .read(memoRepositoryProvider)
        .setAppearance(memo.id, color: r.cleared ? null : r.value);
    ref.invalidate(memoDetailProvider(memo.id));
  }

  static Future<void> _editRemark(
      BuildContext context, WidgetRef ref, Memo memo) async {
    final r = await RemarkEditor.show(context, initial: memo.remark);
    if (r != null) {
      await ref
          .read(memoRepositoryProvider)
          .setAppearance(memo.id, remark: r.isEmpty ? null : r);
      ref.invalidate(memoDetailProvider(memo.id));
    }
  }
}
