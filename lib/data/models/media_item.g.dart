// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MediaItem _$MediaItemFromJson(Map<String, dynamic> json) => _MediaItem(
      id: json['id'] as String,
      memoId: json['memoId'] as String,
      path: json['path'] as String,
      kind: const MediaKindConverter().fromJson(json['kind'] as String),
      remark: json['remark'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      durationMs: (json['durationMs'] as num?)?.toInt(),
      thumbPath: json['thumbPath'] as String?,
      createdAt: (json['createdAt'] as num).toInt(),
    );

Map<String, dynamic> _$MediaItemToJson(_MediaItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'memoId': instance.memoId,
      'path': instance.path,
      'kind': const MediaKindConverter().toJson(instance.kind),
      'remark': instance.remark,
      'sortOrder': instance.sortOrder,
      'width': instance.width,
      'height': instance.height,
      'durationMs': instance.durationMs,
      'thumbPath': instance.thumbPath,
      'createdAt': instance.createdAt,
    };
