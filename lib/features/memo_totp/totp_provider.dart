import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/utils/totp.dart';
import '../../data/models/memo.dart';
import '../home/home_provider.dart';

/// TOTP 配置的 metadata 键（与音频铭记同模式：全部存 memo.metadata）。
class TotpKeys {
  static const secret = 'totpSecret';
  static const issuer = 'totpIssuer';
  static const account = 'totpAccount';
  static const period = 'totpPeriod';
  static const digits = 'totpDigits';
  static const algorithm = 'totpAlgorithm';
}

/// 从 Memo 元数据读取 TOTP 配置；缺少有效密钥返回 null。
TotpConfig? totpConfigOf(Memo memo) {
  final m = memo.metadata;
  final secret = m[TotpKeys.secret] as String?;
  if (secret == null || secret.trim().isEmpty) return null;
  int intOf(String key, int def) {
    final v = m[key];
    return v is num ? v.toInt() : def;
  }

  return TotpConfig(
    secret: normalizeSecret(secret),
    issuer: (m[TotpKeys.issuer] as String?) ?? '',
    account: (m[TotpKeys.account] as String?) ?? '',
    period: intOf(TotpKeys.period, 30),
    digits: intOf(TotpKeys.digits, 6),
    algorithm: (m[TotpKeys.algorithm] as String?) ?? 'SHA1',
  );
}

/// 保存 TOTP 配置：落库 metadata + 自动生成标题（发行者 · 账户名）。
Future<void> saveTotpConfig(
  WidgetRef ref,
  String memoId,
  TotpConfig config, {
  String? remark,
}) async {
  final repo = ref.read(memoRepositoryProvider);
  final memo = await repo.findById(memoId);
  if (memo == null) return;
  final issuer = config.issuer.trim();
  final account = config.account.trim();
  final title = issuer.isNotEmpty && account.isNotEmpty
      ? '$issuer · $account'
      : issuer.isNotEmpty
          ? issuer
          : account.isNotEmpty
              ? account
              : memo.title;
  final next = memo.copyWith(
    title: title,
    metadata: {
      ...memo.metadata,
      TotpKeys.secret: normalizeSecret(config.secret),
      TotpKeys.issuer: issuer,
      TotpKeys.account: account,
      TotpKeys.period: config.period,
      TotpKeys.digits: config.digits,
      TotpKeys.algorithm: config.algorithm,
    },
    remark: remark,
  );
  await repo.save(next);
  ref.invalidate(memoDetailProvider(memoId));
}

/// 全局时间滴答：每 500ms 广播一次当前时间戳，驱动 TOTP 码与进度环刷新。
final totpTickProvider = StreamProvider.autoDispose<int>((ref) {
  return Stream<int>.periodic(
    const Duration(milliseconds: 500),
    (_) => DateTime.now().millisecondsSinceEpoch,
  );
});