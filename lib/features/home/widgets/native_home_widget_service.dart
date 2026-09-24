import 'dart:async';

import 'package:flutter/services.dart';

/// 原生小组件桥接服务：通过 MethodChannel 与原生 Android 小组件通信。
///
/// 提供的能力完全替代原 `home_widget` Flutter 包：
/// - [saveWidgetData]：写入 SharedPreferences（HomeWidgetPreferences）
/// - [updateWidget]   ：触发指定小组件类的 APPWIDGET_UPDATE 广播
/// - [getWidgetData]   ：从 SharedPreferences 读取指定 key
/// - [initialWidgetUri]：获取冷启动时的小组件点击 URI
/// - [widgetClickStream]：小组件点击事件流（热启动/冷启动）
///
/// 架构（纯原生，无 Glance / 无 home_widget 包）：
/// ```
/// Flutter ──MethodChannel("neko.box/widget")──▶ MainActivity (Kotlin)
///                                                      │
///                                                      ▼
///                                          SharedPreferences("HomeWidgetPreferences")
///                                                      │
///                                                      ▼
///                                          AppWidgetProvider.onUpdate 读取
///                                                      │
///                                                      ▼
///                                          RemoteViews 渲染桌面小组件
///
/// 小组件点击 ──Intent(ACTION_VIEW, nekobox://widget/…)──▶ MainActivity
///                                                              │
///                              EventChannel("neko.box/widget/events")
///                                                              │
///                                                              ▼
///                                                          Flutter 端路由
/// ```
class NativeHomeWidgetService {
  NativeHomeWidgetService._();

  static final NativeHomeWidgetService instance = NativeHomeWidgetService._();

  // ── MethodChannel：Flutter → Native ──
  static const MethodChannel _methodChannel =
      MethodChannel('neko.box/widget');

  // ── EventChannel：Native → Flutter（小组件点击事件流）──
  static const EventChannel _eventChannel =
      EventChannel('neko.box/widget/events');

  Stream<String>? _widgetClickStream;

  /// 写入小组件显示数据到 SharedPreferences(HomeWidgetPreferences)。
  /// 写入后需调用 [updateWidget] 触发界面刷新。
  Future<bool> saveWidgetData(String key, String? value) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('saveWidgetData', {
        'key': key,
        'value': value,
      });
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// 触发指定小组件类的 APPWIDGET_UPDATE 广播，使其重新渲染。
  ///
/// [className] 使用 AndroidManifest 中注册的 Provider 类名（如 "QuickActionsWidgetProvider" /
/// "MemoryListWidgetProvider"），原生会补全包名 "aria.neko.box.widget."。
  Future<bool> updateWidget({required String className}) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('updateWidget', {
        'className': className,
      });
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// 从 SharedPreferences(HomeWidgetPreferences) 读取指定 key。
  Future<String?> getWidgetData(String key) async {
    try {
      return await _methodChannel
          .invokeMethod<String?>('getWidgetData', {'key': key});
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// 获取冷启动时小组件点击触发的 URI（如有）。
  /// 仅在小组件点击启动 App 时返回非 null 值。
  Future<Uri?> initialWidgetUri() async {
    try {
      final uriStr = await _methodChannel.invokeMethod<String?>(
        'getInitialWidgetUri',
      );
      if (uriStr == null) return null;
      return Uri.tryParse(uriStr);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// 小组件点击事件流（热启动场景下 App 已在后台时）。
  Stream<String> get widgetClickStream {
    _widgetClickStream ??= _eventChannel
        .receiveBroadcastStream()
        .where((event) => event is String)
        .cast<String>();
    return _widgetClickStream!;
  }
}
