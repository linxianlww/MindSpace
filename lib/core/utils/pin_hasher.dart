import 'dart:convert';
import 'package:crypto/crypto.dart';

/// PIN 码哈希工具类（私密空间）。
///
/// 使用 SHA-256 + 固定盐（应用签名）做单向散列，
/// PIN 本身不落盘，只存摘要，防泄漏。
class PinHasher {
  const PinHasher._();

  /// 固定盐（拼接后做 SHA-256）。
  static const String _salt = 'MindSpace::PrivateSpace::2025';

  /// 校验 PIN 是否为合法 6 位纯数字。
  static bool isValidPin(String pin) {
    if (pin.length != 6) return false;
    return RegExp(r'^\d{6}$').hasMatch(pin);
  }

  /// 计算 PIN 的 SHA-256 摘要（hex 小写）。
  static String hash(String pin) {
    final data = utf8.encode('$_salt::$pin');
    return sha256.convert(data).toString();
  }

  /// 校验 PIN 是否匹配已存摘要。
  static bool verify(String pin, String storedHash) {
    if (!isValidPin(pin)) return false;
    return hash(pin) == storedHash;
  }
}
