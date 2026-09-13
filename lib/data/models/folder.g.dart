// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'folder.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Folder _$FolderFromJson(Map<String, dynamic> json) => _Folder(
      id: json['id'] as String,
      name: json['name'] as String,
      parentId: json['parentId'] as String?,
      createdAt: (json['createdAt'] as num).toInt(),
      updatedAt: (json['updatedAt'] as num).toInt(),
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      deletedAt: (json['deletedAt'] as num?)?.toInt(),
    );

Map<String, dynamic> _$FolderToJson(_Folder instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'parentId': instance.parentId,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'sortOrder': instance.sortOrder,
      'deletedAt': instance.deletedAt,
    };
