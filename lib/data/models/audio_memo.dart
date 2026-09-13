import 'package:freezed_annotation/freezed_annotation.dart';

import 'subtitle_item.dart';

part 'audio_memo.freezed.dart';
part 'audio_memo.g.dart';

/// 音频铭记载荷：原始音频、裁剪后音频、时长、波形采样与字幕。
@freezed
abstract class AudioMemo with _$AudioMemo {
  const factory AudioMemo({
    required String memoId,
    required String originalPath,
    String? trimmedPath,
    @Default(0) int durationMs,
    @Default(<int>[]) List<int> waveform, // 归一化峰值 0~255，预计算缓存
    @Default(<SubtitleItem>[]) List<SubtitleItem> subtitles,
    int? trimStartMs,
    int? trimEndMs,
  }) = _AudioMemo;

  factory AudioMemo.fromJson(Map<String, dynamic> json) =>
      _$AudioMemoFromJson(json);

  /// 当前播放使用的文件（裁剪后优先）。
}

extension AudioMemoX on AudioMemo {
  String get playPath => trimmedPath ?? originalPath;
}
