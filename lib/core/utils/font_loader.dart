import 'dart:io';

import 'package:flutter/services.dart';

import '../../data/models/font_asset.dart';

/// 把私有目录中的字体文件动态注册进 Flutter 引擎。
///
/// family 名直接使用字体 UUID，保证唯一；已加载过的不重复加载。
class FontLoaderCache {
  FontLoaderCache._();
  static final Map<String, Future<void>> _loading = {};
  static final Set<String> _loaded = {};

  /// 确保字体可用，返回可用于 TextStyle.fontFamily 的 family 名。
  static Future<String> ensure(FontAsset font) async {
    final family = 'usr_${font.id}';
    if (_loaded.contains(family)) return family;
    final prev = _loading[family];
    if (prev != null) {
      await prev;
      return family;
    }
    final future = _load(font.path, family);
    _loading[family] = future;
    await future;
    _loaded.add(family);
    return family;
  }

  static Future<void> _load(String path, String family) async {
    final bytes = await File(path).readAsBytes();
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  }
}
