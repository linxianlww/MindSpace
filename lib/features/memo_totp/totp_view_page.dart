import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/providers.dart';
import '../../core/utils/totp.dart';
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
      if (mounted) setState(() => _nowMs = DateTime.now().millisecondsSinceEpoch);
    })
      ..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  Future<void> _setMemoColor(Memo? memo) async {
    if (memo == null) return;
    final r = await ColorPickerSheet.show(context, current: memo.color);
    if (r == null || !mounted) return;
    await ref
        .read(memoRepositoryProvider)
        .setAppearance(memo.id, color: r.cleared ? null : r.value);
    ref.invalidate(memoDetailProvider(memo.id));
  }

  Future<void> _editRemark(Memo? memo) async {
    if (memo == null) return;
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
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (memo) {
        if (memo == null) {
          return const Scaffold(body: Center(child: Text('铭记不存在')));
        }
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
                        .addPostFrameCallback((_) => _setMemoColor(memo)),
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
                        .addPostFrameCallback((_) => _editRemark(memo)),
                    child: const Padding(
                        padding: EdgeInsets.only(left: 28),
                        child: Text('修改标签')),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'edit',
                    onTap: () => WidgetsBinding.instance
                        .addPostFrameCallback((_) {
                      if (mounted) {
                        context.push('/memo/totp/${widget.memoId}/edit');
                      }
                    }),
                    child: const Text('编辑设置'),
                  ),
                ],
              ),
            ],
          ),
          body: _body(context, memo),
        );
      },
    );
  }

  Widget _body(BuildContext context, Memo memo) {
    final cfg = totpConfigOf(memo);
    if (cfg == null) {
      return const Center(child: CircularProgressIndicator());
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

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        const SizedBox(height: 8),
        Center(
          child: Text(
            [
              if (cfg.issuer.isNotEmpty) cfg.issuer,
              if (cfg.account.isNotEmpty) cfg.account,
            ].join(' · '),
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        if (memo.remark != null && memo.remark!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Center(
              child: Text(
                memo.remark!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
          ),
        const SizedBox(height: 28),
        Center(
          child: SizedBox(
            width: 210,
            height: 210,
            child: Stack(
              fit: StackFit.expand,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: ringFraction, end: ringFraction),
                  duration: const Duration(milliseconds: 50),
                  builder: (_, v, __) {
                    return CircularProgressIndicator(
                      value: v.clamp(0.0, 1.0),
                      strokeWidth: 6,
                      strokeCap: StrokeCap.round,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                    );
                  },
                ),
                Center(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _copy(context, code),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            code,
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 3,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${remaining}s 后更新',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant),
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
        const SizedBox(height: 20),
        Center(
          child: Column(
            children: [
              Text('下一个验证码',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline)),
              const SizedBox(height: 4),
              Text(
                nextCode,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                      letterSpacing: 2,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: FilledButton.tonalIcon(
            onPressed: () => _copy(context, code),
            icon: const Icon(Icons.copy_rounded, size: 20),
            label: const Text('复制当前验证码'),
          ),
        ),
      ],
    );
  }

  Future<void> _copy(BuildContext context, String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('验证码已复制'), duration: Duration(seconds: 1)),
      );
    }
  }
}
