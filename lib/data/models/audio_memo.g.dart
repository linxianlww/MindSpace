// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio_memo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AudioMemo _$AudioMemoFromJson(Map<String, dynamic> json) => _AudioMemo(
      memoId: json['memoId'] as String,
      originalPath: json['originalPath'] as String,
      trimmedPath: json['trimmedPath'] as String?,
      durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
      waveform: (json['waveform'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const <int>[],
      subtitles: (json['subtitles'] as List<dynamic>?)
              ?.map((e) => SubtitleItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <SubtitleItem>[],
      trimStartMs: (json['trimStartMs'] as num?)?.toInt(),
      trimEndMs: (json['trimEndMs'] as num?)?.toInt(),
    );

Map<String, dynamic> _$AudioMemoToJson(_AudioMemo instance) =>
    <String, dynamic>{
      'memoId': instance.memoId,
      'originalPath': instance.originalPath,
      'trimmedPath': instance.trimmedPath,
      'durationMs': instance.durationMs,
      'waveform': instance.waveform,
      'subtitles': instance.subtitles,
      'trimStartMs': instance.trimStartMs,
      'trimEndMs': instance.trimEndMs,
    };
