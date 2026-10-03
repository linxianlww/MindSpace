import 'package:mindspace/ui/design_system/app_design_system.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/providers.dart';
import '../../data/models/memo.dart';
import '../desktop_shortcut/add_to_desktop.dart';
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
      loading: () => const AppScaffold(
        body: Center(child: AppCircleProgress()),
      ),
      error: (e, _) => AppScaffold(body: Center(child: MiuixText('$e'))),
      data: (memo) {
        if (memo == null) {
          return const AppScaffold(body: Center(child: MiuixText('铭记不存在')));
        }
        final cfg = AnniversaryConfig.fromMemo(memo);
        final calc = computeAnniversary(cfg);
        return AppScaffold(
          topBar: AppHeader(
            title: memo.title,
            alwaysSmall: true,
            actions: [
              // 顶栏子树的 context：菜单动作的弹层（选色/备注/桌面快捷方式）
              // 需要 MiuixScaffold 之下的宿主 context。
              Builder(builder: (menuCtx) {
                final colors = MiuixTheme.of(menuCtx).colors;
                return MiuixOverlayIconDropdownMenu(
                  entry: MiuixDropdownEntry(items: [
                    MiuixDropdownItem(
                      text: '重命名',
                      icon: const HiuiIcon(HiuiIcons.edit, size: 18),
                      onClick: () => _rename(menuCtx, ref, memo),
                    ),
                    MiuixDropdownItem(
                      text: '修改颜色',
                      icon: HiuiIcon(HiuiIcons.skin,
                          size: 18,
                          color: memo.color != null
                              ? Color(memo.color!)
                              : colors.primary),
                      onClick: () => _setMemoColor(menuCtx, ref, memo),
                    ),
                    MiuixDropdownItem(
                      text: '清除颜色',
                      enabled: memo.color != null,
                      icon: HiuiIcon(HiuiIcons.clear,
                          size: 18,
                          color: memo.color == null
                              ? colors.disabledOnSurface
                              : colors.onSurface),
                      onClick: memo.color == null
                          ? null
                          : () => _clearMemoColor(ref, memo),
                    ),
                    MiuixDropdownItem(
                      text: '修改标签',
                      icon: const HiuiIcon(HiuiIcons.edit, size: 18),
                      onClick: () => _editRemark(menuCtx, ref, memo),
                    ),
                    MiuixDropdownItem(
                      text: '编辑卡片文本',
                      icon: const HiuiIcon(HiuiIcons.document, size: 18),
                      // 修复：原实现误调 _setMemoColor（复制粘贴错误），
                      // 编辑卡片文本即编辑备注标签。
                      onClick: () => _editRemark(menuCtx, ref, memo),
                    ),
                    MiuixDropdownItem(
                      text: '编辑设置',
                      icon: const HiuiIcon(HiuiIcons.settings, size: 18),
                      onClick: () =>
                          menuCtx.push('/memo/anniversary/$memoId/edit'),
                    ),
                    MiuixDropdownItem(
                      text: '添加到桌面',
                      icon: const HiuiIcon(HiuiIcons.export, size: 18),
                      onClick: () => addMemoToDesktop(menuCtx, ref, memo),
                    ),
                  ]),
                  child: const HiuiIcon(HiuiIcons.more),
                );
              }),
            ],
          ),
          content: (context, padding) =>
              _body(context, ref, memo, calc, padding),
        );
      },
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, Memo memo,
      AnniversaryCalc calc, EdgeInsets padding) {
    final colors = MiuixTheme.of(context).colors;

    // 天数格式化：>0"还有 N 天"，=0"就是今天！"，<0"已过 N 天"。
    final countText = calc.isToday
        ? '今'
        : '${calc.absCount}';
    final unitText = calc.isToday ? '' : '天';
    final hintText = calc.count > 0
        ? '还有'
        : (calc.count < 0 ? '已过' : '');
    final accentColor = memo.colorValue ?? colors.primary;

    return ListView(
      padding: padding.add(const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
      children: [
        const SizedBox(height: 12),
        // 备注标签（可点击编辑）：MiuixSurface 单层承载，避免嵌套自绘。
        if (memo.remark != null && memo.remark!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Center(
              child: MiuixSurface(
                cornerRadius: AppTokens.radiusSmall,
                color: colors.secondaryContainer.withValues(alpha: 0.55),
                onPressed: () => _editRemark(context, ref, memo),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MiuixText(
                        memo.remark!,
                        style: MiuixTheme.of(context)
                            .textStyles
                            .footnote1
                            .copyWith(color: colors.onSecondaryContainer),
                      ),
                      const SizedBox(width: 4),
                      HiuiIcon(HiuiIcons.edit,
                          size: 14,
                          color: colors.onSecondaryContainer
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
          child: MiuixText(
            hintText,
            style: MiuixTheme.of(context).textStyles.title3.copyWith(
                color: colors.onSurfaceVariantSummary, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 8),
        // 大字天数
        Center(
          child: AppAnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: Row(
              key: ValueKey<int>(calc.count),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                MiuixText(
                  countText,
                  style: MiuixTheme.of(context).textStyles.title1.copyWith(
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: calc.isToday
                            ? accentColor
                            : colors.onSurface,
                        height: 1.05,
                      ),
                ),
                if (unitText.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  MiuixText(
                    unitText,
                    style: MiuixTheme.of(context).textStyles.title2.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colors.onSurfaceVariantSummary,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // 目标日期 / 重复规则信息行
        Center(
          child: MiuixCard(
            cornerRadius: AppTokens.radiusChip,
            insideMargin:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: MiuixBasicComponent(
              title: calc.targetLabel,
              summary: calc.repeatLabel.isNotEmpty &&
                      calc.repeatLabel != '不重复'
                  ? calc.repeatLabel
                  : null,
              insideMargin: EdgeInsets.zero,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Center(
          child: MiuixCard(
            cornerRadius: AppTokens.radiusBar,
            insideMargin:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            onPressed: () => _copy(context, memo, calc),
            feedbackType: MiuixPressFeedbackType.sink,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const HiuiIcon(HiuiIcons.copy, size: 20),
                const SizedBox(width: 8),
                MiuixText('复制天数'),
              ],
            ),
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
      AppSnackbar.show(context, message: '已复制');
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

  static Future<void> _clearMemoColor(WidgetRef ref, Memo memo) async {
    await ref.read(memoRepositoryProvider).setAppearance(memo.id, color: null);
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

  static Future<void> _rename(
      BuildContext context, WidgetRef ref, Memo memo) async {
    final ctrl = TextEditingController(text: memo.title);
    try {
      final result = await AppDialog.show<String>(
        context: context,
        title: '重命名',
        content: AppInput(
          controller: ctrl,
          onChanged: (_) {},
          hintText: '输入新标题',
        ),
        actions: [
          AppButton(
              variant: AppButtonStyle.text,
              onPressed: () => AppDialog.close(context),
              child: const MiuixText('取消')),
          AppButton(
              onPressed: () =>
                  AppDialog.close<String>(context, ctrl.text.trim()),
              child: const MiuixText('确定')),
        ],
      );
      if (result != null && result.isNotEmpty && result != memo.title) {
        await ref.read(memoRepositoryProvider).rename(memo.id, result);
        ref.invalidate(memoDetailProvider(memo.id));
      }
    } finally {
      ctrl.dispose();
    }
  }
}
