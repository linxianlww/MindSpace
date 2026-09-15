import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/totp.dart';
import '../home/home_provider.dart';
import 'totp_provider.dart';

/// TOTP 验证码详情页：展示当前码 / 下一个码 / 剩余时间环，可一键复制。
///
/// 安全约定：此页面绝不渲染密钥（secret），只提示“已隐藏”。
class TotpViewPage extends ConsumerWidget {
  const TotpViewPage({super.key, required this.memoId});
  final String memoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memoAsync = ref.watch(memoDetailProvider(memoId));
    final nowMs =
        ref.watch(totpTickProvider).value ?? DateTime.now().millisecondsSinceEpoch;
    final now = DateTime.fromMillisecondsSinceEpoch(nowMs);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          memoAsync.maybeWhen(
            data: (m) => m?.title ?? 'TOTP 验证码',
            orElse: () => 'TOTP 验证码',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: '编辑',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/memo/totp/$memoId/edit'),
          ),
        ],
      ),
      body: memoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (memo) {
          if (memo == null) {
            return const Center(child: Text('铭记不存在'));
          }
          final cfg = totpConfigOf(memo);
          if (cfg == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('尚未配置 TOTP 密钥'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => context.push('/memo/totp/$memoId/edit'),
                    icon: const Icon(Icons.tune),
                    label: const Text('去配置'),
                  ),
                ],
              ),
            );
          }

          final code = totpCode(
            secretBase32: cfg.secret,
            period: cfg.period,
            digits: cfg.digits,
            algorithm: cfg.algorithm,
            now: now,
          );
          // 下一个时间段的验证码（提前预告，灰色小字）。
          final nextCode = totpCode(
            secretBase32: cfg.secret,
            period: cfg.period,
            digits: cfg.digits,
            algorithm: cfg.algorithm,
            now: now.add(Duration(seconds: cfg.period)),
          );
          final remaining =
              totpRemainingSeconds(period: cfg.period, now: now);

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
              const SizedBox(height: 8),
              // 发行者 / 账户名
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
              // 进度环 + 当前码
              Center(
                child: SizedBox(
                  width: 210,
                  height: 210,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: remaining / cfg.period,
                        strokeWidth: 6,
                        strokeCap: StrokeCap.round,
                        backgroundColor:
                            Theme.of(context).colorScheme.surfaceContainerHighest,
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
                                  '${remaining}s 后更新 · 点击复制',
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
              // 下一个验证码（灰色小字预告）
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
              // 复制按钮
              Center(
                child: FilledButton.tonalIcon(
                  onPressed: () => _copy(context, code),
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  label: const Text('复制当前验证码'),
                ),
              ),
              const SizedBox(height: 12),
              // 密钥状态（不显示内容）
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    '密钥已安全隐藏，仅在编辑页可修改',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _copy(BuildContext context, String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('验证码已复制'), duration: Duration(seconds: 1)),
      );
    }
  }
}