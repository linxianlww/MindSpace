// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Memo _$MemoFromJson(Map<String, dynamic> json) => _Memo(
      id: json['id'] as String,
      folderId: json['folderId'] as String?,
      type: const MemoTypeConverter().fromJson(json['type'] as String),
      title: json['title'] as String? ?? '无标题',
      createdAt: (json['createdAt'] as num).toInt(),
      updatedAt: (json['updatedAt'] as num).toInt(),
      color: (json['color'] as num?)?.toInt(),
      remark: json['remark'] as String?,
      fontId: json['fontId'] as String?,
      thumbnailPath: json['thumbnailPath'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const <String>[],
      metadata: json['metadata'] as Map<String, dynamic>? ??
          const <String, dynamic>{},
      deletedAt: (json['deletedAt'] as num?)?.toInt(),
    );

Map<String, dynamic> _$MemoToJson(_Memo instance) => <String, dynamic>{
      'id': instance.id,
      'folderId': instance.folderId,
      'type': const MemoTypeConverter().toJson(instance.type),
      'title': instance.title,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'color': instance.color,
      'remark': instance.remark,
      'fontId': instance.fontId,
      'thumbnailPath': instance.thumbnailPath,
      'tags': instance.tags,
      'metadata': instance.metadata,
      'deletedAt': instance.deletedAt,
    };
