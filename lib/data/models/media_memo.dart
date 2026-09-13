import 'package:freezed_annotation/freezed_annotation.dart';

import 'media_item.dart';

part 'media_memo.freezed.dart';
part 'media_memo.g.dart';

/// 媒体集铭记载荷（图片与视频混合，有序）。
@freezed
abstract class MediaMemo with _$MediaMemo {
  const factory MediaMemo({
    required String memoId,
    @Default(<MediaItem>[]) List<MediaItem> items,
  }) = _MediaMemo;

  factory MediaMemo.fromJson(Map<String, dynamic> json) =>
      _$MediaMemoFromJson(json);
}
