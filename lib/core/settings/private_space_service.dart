import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_logger.dart';
import '../utils/pin_hasher.dart';

/// 私密空间服务：PIN 码管理、生物识别绑定、会话状态、截屏保护。
///
/// 所有状态持久化在 SharedPreferences：
/// - pinHash: SHA-256 摘要（hex），空串表示未设置
/// - biometricEnabled: 是否启用生物识别
/// - sessionUnlocked: 当前会话是否已解锁（仅内存 + 持久化标志，重启后需重新解锁）
/// - screenshotProtectionEnabled: 私密空间解锁后是否对 Activity 设置 FLAG_SECURE 禁止截屏
class PrivateSpaceService extends ChangeNotifier {
  PrivateSpaceService(this._prefs) {
    _load();
  }

  final SharedPreferences _prefs;

  static const String _kPinHash = 'private_space.pin_hash';
  static const String _kBiometricEnabled = 'private_space.biometric_enabled';
  static const String _kSessionUnlocked = 'private_space.session_unlocked';
  static const String _kScreenshotProtection =
      'private_space.screenshot_protection';

  static const MethodChannel _channel =
      MethodChannel('neko.box/secure_flags');

  /// PIN 摘要（空串 = 未设置）。
  String _pinHash = '';

  /// 已启用生物识别。
  bool _biometricEnabled = false;

  /// 当前会话已解锁私密空间。
  bool _sessionUnlocked = false;

  /// 是否在私密空间解锁后禁止截屏（需同时满足 hasPin 才生效）。
  bool _screenshotProtectionEnabled = false;

  /// 生物识别硬件是否可用（有指纹/面容传感器 + 已注册）。
  bool _canCheckBiometrics = false;
  List<BiometricType> _availableBiometrics = const [];

  final LocalAuthentication _localAuth = LocalAuthentication();

  String get pinHash => _pinHash;
  bool get hasPin => _pinHash.isNotEmpty;
  bool get biometricEnabled => _biometricEnabled;
  bool get sessionUnlocked => _sessionUnlocked;
  bool get canCheckBiometrics => _canCheckBiometrics;
  List<BiometricType> get availableBiometrics => _availableBiometrics;
  bool get screenshotProtectionEnabled => _screenshotProtectionEnabled;

  void _load() {
    _pinHash = _prefs.getString(_kPinHash) ?? '';
    _biometricEnabled = _prefs.getBool(_kBiometricEnabled) ?? false;
    _sessionUnlocked = _prefs.getBool(_kSessionUnlocked) ?? false;
    _screenshotProtectionEnabled = _prefs.getBool(_kScreenshotProtection) ?? false;
    _refreshBiometricAvailability();
  }

  /// 检测生物识别硬件能力。
  Future<void> _refreshBiometricAvailability() async {
    try {
      _canCheckBiometrics = await _localAuth.canCheckBiometrics;
      _availableBiometrics = await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      appLogger.w('local_auth 可用性检测失败', e);
      _canCheckBiometrics = false;
      _availableBiometrics = const [];
    }
  }

  /// 切换「禁止截屏」开关（需先设置 PIN）。
  /// 同时立即刷新 Activity FLAG_SECURE：开关打开 + 已解锁 → 设置；否则清除。
  Future<void> setScreenshotProtectionEnabled(bool enabled) async {
    _screenshotProtectionEnabled = enabled;
    await _prefs.setBool(_kScreenshotProtection, enabled);
    notifyListeners();
    // 写入后立即同步 FLAG_SECURE 状态
    await _syncScreenshotProtection();
  }

  /// 通知 Activity 端设置或清除 FLAG_SECURE。
  Future<void> _syncScreenshotProtection() async {
    if (!hasPin) return;
    final shouldProtect = _sessionUnlocked && _screenshotProtectionEnabled;
    try {
      await _channel.invokeMethod<bool>(
          shouldProtect ? 'enableSecureFlags' : 'disableSecureFlags');
    } on PlatformException catch (e) {
      appLogger.w('syncScreenshotProtection 失败', e);
    } on MissingPluginException {
      // debug 模式下 Android 端未注册、或纯 Flutter 桌面平台忽略
    }
  }

  /// 校验输入的 PIN 是否正确。
  bool verifyPin(String pin) {
    if (!PinHasher.isValidPin(pin)) return false;
    return PinHasher.verify(pin, _pinHash);
  }

  /// 创建/修改 PIN。
  ///
  /// [oldPin] 为 null 时创建新 PIN；不为 null 时校验旧 PIN 通过后更新。
  /// 返回 true 表示成功。
  Future<bool> setPin(String newPin, {String? oldPin}) async {
    if (!PinHasher.isValidPin(newPin)) return false;

    // 修改模式：先校验旧 PIN
    if (oldPin != null) {
      if (!verifyPin(oldPin)) return false;
    }

    _pinHash = PinHasher.hash(newPin);
    await _prefs.setString(_kPinHash, _pinHash);
    // 新 PIN 设置后自动解锁当前会话
    await _setSessionUnlocked(true);
    notifyListeners();
    return true;
  }

  /// 解锁私密空间（PIN 验证）。
  /// 解锁后若已启用截屏保护，自动为 Activity 设置 FLAG_SECURE。
  Future<bool> unlock(String pin) async {
    if (!verifyPin(pin)) return false;
    await _setSessionUnlocked(true);
    await _syncScreenshotProtection();
    return true;
  }

  /// 系统凭证（设备指纹/面容/系统 PIN）验证通过后的解锁。
  ///
  /// 设备级验证已由 SystemPinChannel 完成（系统凭证视为本地校验通过），
  /// 这里与 [unlock] 的成功后置动作保持一致：置位会话并同步 FLAG_SECURE。
  Future<void> unlockWithSystemCredential() async {
    await _setSessionUnlocked(true);
    await _syncScreenshotProtection();
  }

  /// 生物识别解锁。
  ///
  /// 必须先有 PIN 且生物识别已绑定；成功后同样解锁会话并同步 FLAG_SECURE。
  Future<bool> unlockWithBiometric() async {
    if (!hasPin || !_biometricEnabled) return false;
    try {
      final ok = await _localAuth.authenticate(
        localizedReason: '验证身份以解锁私密空间',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (ok) {
        await _setSessionUnlocked(true);
        await _syncScreenshotProtection();
      }
      return ok;
    } on PlatformException catch (e) {
      appLogger.w('生物识别失败', e);
      return false;
    }
  }

  /// 启用生物识别（需先通过一轮 PIN 验证）。
  Future<bool> enableBiometric(String pin) async {
    if (!verifyPin(pin)) return false;
    if (!_canCheckBiometrics || _availableBiometrics.isEmpty) return false;

    _biometricEnabled = true;
    await _prefs.setBool(_kBiometricEnabled, true);
    notifyListeners();
    return true;
  }

  /// 关闭生物识别。
  Future<void> disableBiometric() async {
    _biometricEnabled = false;
    await _prefs.setBool(_kBiometricEnabled, false);
    notifyListeners();
  }

  /// 锁定私密空间（失去焦点或手动触发）。锁定后自动清除 FLAG_SECURE。
  Future<void> lock() async {
    await _setSessionUnlocked(false);
    await _syncScreenshotProtection();
  }

  Future<void> _setSessionUnlocked(bool value) async {
    _sessionUnlocked = value;
    await _prefs.setBool(_kSessionUnlocked, value);
    notifyListeners();
  }
}
