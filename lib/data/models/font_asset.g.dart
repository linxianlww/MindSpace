// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'font_asset.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FontAsset _$FontAssetFromJson(Map<String, dynamic> json) => _FontAsset(
      id: json['id'] as String,
      name: json['name'] as String,
      path: json['path'] as String,
      createdAt: (json['createdAt'] as num).toInt(),
    );

Map<String, dynamic> _$FontAssetToJson(_FontAsset instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'path': instance.path,
      'createdAt': instance.createdAt,
    };
