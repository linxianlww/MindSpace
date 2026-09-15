/// RFC 6238 TOTP 一次性验证码。
///
/// 纯 Dart 实现（base32 解码 + HMAC-SHA1/256/512），无原生依赖，
/// 与 Google Authenticator / Authy / 1Password 等标准 otpauth:// 兼容。
library;

import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// 解析出的 TOTP 配置（otpauth:// 或手动输入）。
/// 所有字段只读，构造后不可变。
class TotpConfig {
  const TotpConfig({
    required this.secret,
    this.issuer = '',
    this.account = '',
    this.period = 30,
    this.digits = 6,
    this.algorithm = 'SHA1',
  });

  /// Base32 密钥（大写、无填充、无空格）。
  final String secret;

  /// 发行者（如 Google、GitHub）。
  final String issuer;

  /// 账户名（如 user@gmail.com）。
  final String account;

  /// 时间步长（秒），默认 30。
  final int period;

  /// 验证码位数，默认 6。
  final int digits;

  /// 哈希算法：SHA1 / SHA256 / SHA512。
  final String algorithm;

  TotpConfig copyWith({
    String? secret,
    String? issuer,
    String? account,
    int? period,
    int? digits,
    String? algorithm,
  }) {
    return TotpConfig(
      secret: secret ?? this.secret,
      issuer: issuer ?? this.issuer,
      account: account ?? this.account,
      period: period ?? this.period,
      digits: digits ?? this.digits,
      algorithm: algorithm ?? this.algorithm,
    );
  }
}

/// 规范化 Base32 密钥：去除非 A-Z2-7 字符、转大写（保留有效位数）。
String normalizeSecret(String raw) => raw
    .toUpperCase()
    .replaceAll(RegExp(r'[^A-Z2-7]'), '');

/// Base32（RFC 4648，无填充）解码。非法字符/空输入返回 null。
Uint8List? base32Decode(String input) {
  const table = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  final cleaned = normalizeSecret(input);
  if (cleaned.isEmpty) return null;
  final bytes = <int>[];
  var buffer = 0;
  var bitsLeft = 0;
  for (final ch in cleaned.split('')) {
    final v = table.indexOf(ch);
    if (v < 0) return null;
    buffer = (buffer << 5) | v;
    bitsLeft += 5;
    if (bitsLeft >= 8) {
      bytes.add((buffer >> (bitsLeft - 8)) & 0xFF);
      bitsLeft -= 8;
    }
  }
  return Uint8List.fromList(bytes);
}

List<int> _hmac(List<int> key, List<int> msg, String algorithm) {
  switch (algorithm.toUpperCase()) {
    case 'SHA256':
      return Hmac(sha256, key).convert(msg).bytes;
    case 'SHA512':
      return Hmac(sha512, key).convert(msg).bytes;
    case 'SHA1':
    default:
      return Hmac(sha1, key).convert(msg).bytes;
  }
}

int _tenPow(int n) {
  var v = 1;
  for (var i = 0; i < n; i++) {
    v *= 10;
  }
  return v;
}

/// 生成当前时间步的 TOTP 码（6/7/8 位）。密钥非法时返回空字符串。
String totpCode({
  required String secretBase32,
  int period = 30,
  int digits = 6,
  String algorithm = 'SHA1',
  DateTime? now,
}) {
  final key = base32Decode(secretBase32);
  if (key == null || key.isEmpty) return '';
  final seconds = (now ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
  final counter = seconds ~/ period;

  final msg = ByteData(8)..setUint64(0, counter, Endian.big);
  final hmac = _hmac(key, msg.buffer.asUint8List(), algorithm);
  final offset = hmac[hmac.length - 1] & 0x0F;
  final binary = ((hmac[offset] & 0x7F) << 24) |
      ((hmac[offset + 1] & 0xFF) << 16) |
      ((hmac[offset + 2] & 0xFF) << 8) |
      (hmac[offset + 3] & 0xFF);
  final mod = binary % _tenPow(digits);
  return mod.toString().padLeft(digits, '0');
}

/// 当前时间步还剩余多少秒（用于进度环动画）。
int totpRemainingSeconds({int period = 30, DateTime? now}) {
  final seconds = (now ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
  return period - (seconds % period);
}

/// 解析 otpauth:// 分享链接 / 二维码内容。
///
/// 兼容：`otpauth://totp/Issuer:account?secret=...&issuer=...&period=30`、
/// `otpauth://totp/Label?secret=...`。解析失败返回 null。
TotpConfig? parseOtpauthUri(String raw) {
  final uri = Uri.tryParse(raw.trim());
  if (uri == null || uri.scheme.toLowerCase() != 'otpauth') return null;
  if (uri.host.toLowerCase() != 'totp') return null;

  final secret = normalizeSecret(uri.queryParameters['secret'] ?? '');
  if (secret.isEmpty) return null;

  // path 形如 /Issuer:account 或 /Label；pathSegments 已做百分号解码。
  final pathSeg = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
  var issuer = uri.queryParameters['issuer'] ?? '';
  var account = pathSeg;
  final colon = pathSeg.indexOf(':');
  if (colon >= 0) {
    if (issuer.isEmpty) issuer = pathSeg.substring(0, colon);
    account = pathSeg.substring(colon + 1);
  }

  final period = int.tryParse(uri.queryParameters['period'] ?? '') ?? 30;
  final digits = int.tryParse(uri.queryParameters['digits'] ?? '') ?? 6;
  final algorithm =
      (uri.queryParameters['algorithm'] ?? 'SHA1').toUpperCase();

  return TotpConfig(
    secret: secret,
    issuer: issuer,
    account: account,
    period: period > 0 ? period : 30,
    digits: (digits >= 6 && digits <= 8) ? digits : 6,
    algorithm: algorithm == 'SHA256' || algorithm == 'SHA512'
        ? algorithm
        : 'SHA1',
  );
}

/// 生成 otpauth:// URI（配置导出/迁移用）。
String buildOtpauthUri(TotpConfig config) {
  final label = config.issuer.isEmpty
      ? config.account
      : '${config.issuer}:${config.account}';
  final params = <String, String>{
    'secret': config.secret,
    if (config.issuer.isNotEmpty) 'issuer': config.issuer,
    if (config.period != 30) 'period': '${config.period}',
    if (config.digits != 6) 'digits': '${config.digits}',
    if (config.algorithm != 'SHA1') 'algorithm': config.algorithm,
  };
  final labelEncoded = Uri.encodeComponent(label);
  final query = Uri(queryParameters: params).query;
  return 'otpauth://totp/$labelEncoded?$query';
}