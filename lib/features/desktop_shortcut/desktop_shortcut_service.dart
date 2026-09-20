import 'package:flutter/services.dart';

import '../../data/models/memo_type.dart';

/// 桌面快捷方式服务：调用原生 Android ShortcutManager 创建桌面快捷图标。
///
/// 使用场景：用户长按铭记卡片弹窗/详情页右上角菜单点「添加到桌面」。
/// 桌面快捷方式通过自定义 URI scheme `nekobox://memo/{type}/{id}`，让启动器
/// 点击快捷图标时直达对应的铭记详情页。
///
/// 图标来源二选一：
/// 1. 用户自选图片（Bytes）
/// 2. 传 null 后由原生侧用铭记标题首字符生成彩色背景图标
class DesktopShortcutService {
  DesktopShortcutService._();

  static const _channel = MethodChannel('neko.box/share');

  /// 创建桌面快捷方式。
  ///
  /// 返回值：
  /// - true: 创建成功（或已请求系统确认，由系统弹出「添加快捷方式」面板）
  /// - false: 不支持或创建失败
  ///
  /// 参数：
  /// - [memoType]: 铭记类型（路由分发用）
  /// - [title]: 快捷方式的显示名称（同时用于首字符图标备选）
  /// - [iconBytes]: 自定义图标（JPEG/PNG 字节），为 null 时由原生侧首字符生成
  /// - [bgColor]: 首字符图标的背景色（ARGB int），为 null 时用默认紫色
  static Future<bool> create({
    required String memoId,
    required MemoType memoType,
    required String title,
    Uint8List? iconBytes,
    int? bgColor,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('createDesktopShortcut', {
        'memoId': memoId,
        'memoType': memoType.wire,
        'title': title,
        'iconBytes': iconBytes,
        'bgColor': bgColor,
      });
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      // 非 Android 平台（如 Web / macOS）fallback 失败。
      return false;
    }
  }

  /// 获取冷启动时的 deep link URI（来自桌面快捷方式点击启动）。
  ///
  /// 返回形如 `"nekobox://memo/text/abc123"` 的字符串，若无则返回 null。
  /// 仅取一次（取走后原生侧清零）。
  static Future<String?> getInitialDeepLink() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getInitialDeepLink');
      if (result == null) return null;
      return result['uri'] as String?;
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// 解析 deep link URI 为路由路径。
  ///
  /// 输入：`nekobox://memo/text/abc123` → 输出：`/memo/text/abc123`
  /// 返回 null 表示不是合法的铭记 deep link。
  static String? parseDeepLinkToRoute(String uri) {
    final parsed = Uri.tryParse(uri);
    if (parsed == null) return null;
    if (parsed.scheme != 'nekobox' || parsed.host != 'memo') return null;
    // path: /{type}/{id}
    final segs = parsed.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segs.length < 2) return null;
    final type = segs[0];
    final id = segs[1];
    // 校验类型是否合法
    if (MemoType.values.every((t) => t.wire != type)) return null;
    return '/memo/$type/$id';
  }
}
