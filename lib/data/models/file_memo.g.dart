// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_memo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FileMemo _$FileMemoFromJson(Map<String, dynamic> json) => _FileMemo(
      memoId: json['memoId'] as String,
      path: json['path'] as String,
      originalName: json['originalName'] as String,
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
      extension: json['extension'] as String?,
      pageCount: (json['pageCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$FileMemoToJson(_FileMemo instance) => <String, dynamic>{
      'memoId': instance.memoId,
      'path': instance.path,
      'originalName': instance.originalName,
      'sizeBytes': instance.sizeBytes,
      'extension': instance.extension,
      'pageCount': instance.pageCount,
    };
