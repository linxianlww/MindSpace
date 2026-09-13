import 'package:freezed_annotation/freezed_annotation.dart';

part 'font_asset.freezed.dart';
part 'font_asset.g.dart';

/// 用户导入的自定义字体。文件以 UUID 命名存于 `<AppSupport>/font`。
@freezed
abstract class FontAsset with _$FontAsset {
  const factory FontAsset({
    required String id,
    required String name, // 原始字体文件名（便于展示）
    required String path, // 私有目录中的绝对路径
    required int createdAt,
  }) = _FontAsset;

  factory FontAsset.fromJson(Map<String, dynamic> json) =>
      _$FontAssetFromJson(json);
}
