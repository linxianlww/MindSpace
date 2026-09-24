import 'package:flutter/services.dart';

/// 系统安全 PIN/密码键盘的 MethodChannel。
///
/// 通过调用 Android 系统级 [BiometricPrompt] 配合 DEVICE_CREDENTIAL，
/// 弹出用户在系统设置里预设的 PIN/图案/密码验证界面。
///
/// 返回：
///   - true：用户成功输入系统凭证
///   - false：用户取消或失败
class SystemPinChannel {
  SystemPinChannel._();

  static const MethodChannel _channel =
      MethodChannel('neko.box/secure_pin');

  /// 是否可以在设备上弹出系统凭证界面（锁屏已设置）。
  static Future<bool> isAvailable() async {
    try {
      final r = await _channel.invokeMethod<bool>('isAvailable');
      return r ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// 显示系统凭证界面。
  ///
  /// [title]/[subtitle] 用于 Android 系统对话框上显示的提示文案。
  /// [userPin] 非空时 Android 侧会先核对用户输入是否与该 PIN 一致，
  ///   不一致则直接当作失败返回 false（私密空间验证/确认场景复用此入口）。
  /// [userPin] 为空表示纯粹请求系统凭证（创建模式的第一次输入无法匹配）。
  ///
  /// 返回 true 表示用户通过了系统凭证校验（且 PIN 一致（若指定））。
  static Future<bool> show({
    required String title,
    String? subtitle,
    String? userPin,
  }) async {
    try {
      final ok = await _channel.invokeMethod<bool>('showSystemPin', {
        'title': title,
        'subtitle': subtitle ?? '',
        'expectedPin': userPin ?? '',
      });
      return ok ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
