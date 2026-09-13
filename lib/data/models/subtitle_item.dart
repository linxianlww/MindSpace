import 'package:freezed_annotation/freezed_annotation.dart';

part 'subtitle_item.freezed.dart';
part 'subtitle_item.g.dart';

/// 音频字幕条目（由 lrc/srt/txt 解析得到），播放时自动滚动、点击可跳转。
@freezed
abstract class SubtitleItem with _$SubtitleItem {
  const factory SubtitleItem({
    required String id,
    required String memoId,
    required int startMs,
    required int endMs,
    required String text,
    @Default(0) int sortOrder,
  }) = _SubtitleItem;

  factory SubtitleItem.fromJson(Map<String, dynamic> json) =>
      _$SubtitleItemFromJson(json);
}
