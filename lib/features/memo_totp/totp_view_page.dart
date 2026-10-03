import 'package:mindspace/ui/design_system/app_design_system.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/providers.dart';
import '../../core/utils/totp.dart';
import '../desktop_shortcut/add_to_desktop.dart';
import '../../../data/models/memo.dart';
import '../home/home_provider.dart';
import '../memo_text/widgets/color_picker.dart';
import '../memo_text/widgets/remark_editor.dart';
import 'totp_provider.dart';

/// TOTP 验证码详情页：展示当前码 / 下一个码 / 平滑剩余时间环，可一键复制。
/// 右上角三点菜单包含编辑 / 颜色 / 备注标签操作。
class TotpViewPage extends ConsumerStatefulWidget {
  const TotpViewPage({super.key, required this.memoId});
  final String memoId;

  @override
  ConsumerState<TotpViewPage> createState() => _TotpViewPageState();
}

class _TotpViewPageState extends ConsumerState<TotpViewPage>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  int _nowMs = DateTime.now().millisecondsSinceEpoch;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      if (mounted) {
        setState(() => _nowMs = DateTime.now().millisecondsSinceEpoch);
      }
    })
      ..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  Future<void> _setMemoColor(BuildContext context, Memo? memo) async {
    if (memo == null || !mounted) return;
    final r = await ColorPickerSheet.show(context, current: memo.color);
    if (r == null || !mounted) return;
    await ref
        .read(memoRepositoryProvider)
        .setAppearance(memo.id, color: r.cleared ? null : r.value);
    ref.invalidate(memoDetailProvider(memo.id));
  }

  /// 清除卡片颜色：纯数据操作，无需弹层宿主 context。
  Future<void> _clearMemoColor(Memo memo) async {
    if (!mounted) return;
    await ref.read(memoRepositoryProvider).setAppearance(memo.id, color: null);
    ref.invalidate(memoDetailProvider(memo.id));
  }

  Future<void> _rename(BuildContext context, Memo? memo) async {
    if (memo == null || !mounted) return;
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

  Future<void> _editRemark(BuildContext context, Memo? memo) async {
    if (memo == null || !mounted) return;
    final r = await RemarkEditor.show(context, initial: memo.remark);
    if (r != null && mounted) {
      await ref
          .read(memoRepositoryProvider)
          .setAppearance(memo.id, remark: r.isEmpty ? null : r);
      ref.invalidate(memoDetailProvider(memo.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final memoAsync = ref.watch(memoDetailProvider(widget.memoId));

    return memoAsync.when(
      loading: () => const AppScaffold(
        body: Center(child: AppCircleProgress()),
      ),
      error: (e, _) => AppScaffold(body: Center(child: MiuixText('$e'))),
      data: (memo) {
        if (memo == null) {
          return const AppScaffold(body: Center(child: MiuixText('铭记不存在')));
        }
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
                      onClick: () => _rename(menuCtx, memo),
                    ),
                    MiuixDropdownItem(
                      text: '修改颜色',
                      icon: HiuiIcon(HiuiIcons.skin,
                          size: 18,
                          color: memo.color != null
                              ? Color(memo.color!)
                              : colors.primary),
                      onClick: () => _setMemoColor(menuCtx, memo),
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
                          : () => _clearMemoColor(memo),
                    ),
                    MiuixDropdownItem(
                      text: '修改标签',
                      icon: const HiuiIcon(HiuiIcons.edit, size: 18),
                      onClick: () => _editRemark(menuCtx, memo),
                    ),
                    MiuixDropdownItem(
                      text: '编辑设置',
                      icon: const HiuiIcon(HiuiIcons.settings, size: 18),
                      onClick: () =>
                          menuCtx.push('/memo/totp/${widget.memoId}/edit'),
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
          content: (context, padding) => _body(context, memo, padding),
        );
      },
    );
  }

  Widget _body(BuildContext context, Memo memo, EdgeInsets padding) {
    final cfg = totpConfigOf(memo);
    if (cfg == null) {
      return const Center(child: AppCircleProgress());
    }
    final now = DateTime.fromMillisecondsSinceEpoch(_nowMs);
    final code = totpCode(
      secretBase32: cfg.secret,
      period: cfg.period,
      digits: cfg.digits,
      algorithm: cfg.algorithm,
      now: now,
    );
    final nextCode = totpCode(
      secretBase32: cfg.secret,
      period: cfg.period,
      digits: cfg.digits,
      algorithm: cfg.algorithm,
      now: now.add(Duration(seconds: cfg.period)),
    );
    final remaining = totpRemainingSeconds(period: cfg.period, now: now);

    final periodMs = cfg.period * 1000;
    final elapsed = _nowMs % periodMs;
    final ringFraction = 1.0 - elapsed / periodMs;

    final colors = MiuixTheme.of(context).colors;

    return ListView(
      padding:
          padding.add(const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
      children: [
        const SizedBox(height: 8),
        Center(
          child: MiuixText(
            [
              if (cfg.issuer.isNotEmpty) cfg.issuer,
              if (cfg.account.isNotEmpty) cfg.account,
            ].join(' · '),
            textAlign: TextAlign.center,
            style: MiuixTheme.of(context)
                .textStyles
                .title3
                .copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        if (memo.remark != null && memo.remark!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Center(
              child: MiuixText(
                memo.remark!,
                style: MiuixTheme.of(context)
                    .textStyles
                    .body2
                    .copyWith(color: colors.onSurfaceVariantSummary),
              ),
            ),
          ),
        const SizedBox(height: 28),
        // 验证码主卡：大圆角 Surface 承载倒计时环与验证码大字。
        Center(
          child: MiuixSurface(
            cornerRadius: AppTokens.radiusLarge,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: SizedBox(
                width: 210,
                height: 210,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween:
                          Tween<double>(begin: ringFraction, end: ringFraction),
                      duration: const Duration(milliseconds: 50),
                      builder: (_, v, __) {
                        return MiuixCircularProgressIndicator(
                          progress: v.clamp(0.0, 1.0),
                          size: 210,
                          strokeWidth: 6,
                          colors: MiuixProgressIndicatorColors(
                            foregroundColor: colors.primary,
                            disabledForegroundColor: colors.disabledPrimary,
                            backgroundColor: colors.surfaceContainerHighest,
                          ),
                        );
                      },
                    ),
                    Center(
                      child: MiuixSurface(
                        cornerRadius: AppTokens.radiusMedium,
                        color: Colors.transparent,
                        onPressed: () => _copy(context, code),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              MiuixText(
                                code,
                                style: MiuixTheme.of(context)
                                    .textStyles
                                    .title1
                                    .copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 3,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              MiuixText(
                                '${remaining}s 后更新',
                                style: MiuixTheme.of(context)
                                    .textStyles
                                    .footnote2
                                    .copyWith(
                                        color: colors.onSurfaceVariantSummary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Column(
            children: [
              MiuixText('下一个验证码',
                  style: MiuixTheme.of(context)
                      .textStyles
                      .footnote2
                      .copyWith(color: colors.onSurfaceVariantSummary)),
              const SizedBox(height: 4),
              MiuixText(
                nextCode,
                style: MiuixTheme.of(context).textStyles.body2.copyWith(
                  color: colors.onSurfaceVariantSummary,
                  letterSpacing: 2,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: MiuixButton(
            onPressed: () => _copy(context, code),
            colors: MiuixButtonDefaults.buttonColorsPrimary(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HiuiIcon(HiuiIcons.copy, size: 20, color: colors.onPrimary),
                const SizedBox(width: 8),
                MiuixText('复制当前验证码', style: TextStyle(color: colors.onPrimary)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _copy(BuildContext context, String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (context.mounted) {
      AppSnackbar.show(context, message: '验证码已复制');
    }
  }
}
