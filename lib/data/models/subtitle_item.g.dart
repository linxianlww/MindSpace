// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subtitle_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SubtitleItem _$SubtitleItemFromJson(Map<String, dynamic> json) =>
    _SubtitleItem(
      id: json['id'] as String,
      memoId: json['memoId'] as String,
      startMs: (json['startMs'] as num).toInt(),
      endMs: (json['endMs'] as num).toInt(),
      text: json['text'] as String,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$SubtitleItemToJson(_SubtitleItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'memoId': instance.memoId,
      'startMs': instance.startMs,
      'endMs': instance.endMs,
      'text': instance.text,
      'sortOrder': instance.sortOrder,
    };
