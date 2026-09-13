import 'package:freezed_annotation/freezed_annotation.dart';

import 'memo_type.dart';

part 'media_item.freezed.dart';
part 'media_item.g.dart';

class MediaKindConverter
    implements JsonConverter<MediaKind, String> {
  const MediaKindConverter();
  @override
  MediaKind fromJson(String json) => MediaKind.fromWire(json);
  @override
  String toJson(MediaKind object) => object.wire;
}

/// 媒体集内的单个图片/视频条目。
@freezed
abstract class MediaItem with _$MediaItem {
  const factory MediaItem({
    required String id,
    required String memoId,
    required String path,
    @MediaKindConverter() required MediaKind kind,
    String? remark,
    @Default(0) int sortOrder,
    int? width,
    int? height,
    int? durationMs,
    String? thumbPath,
    required int createdAt,
  }) = _MediaItem;

  factory MediaItem.fromJson(Map<String, dynamic> json) =>
      _$MediaItemFromJson(json);
}
