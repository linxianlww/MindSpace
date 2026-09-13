// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_memo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MediaMemo _$MediaMemoFromJson(Map<String, dynamic> json) => _MediaMemo(
      memoId: json['memoId'] as String,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <MediaItem>[],
    );

Map<String, dynamic> _$MediaMemoToJson(_MediaMemo instance) =>
    <String, dynamic>{
      'memoId': instance.memoId,
      'items': instance.items,
    };
