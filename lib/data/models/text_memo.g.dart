// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'text_memo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TextMemo _$TextMemoFromJson(Map<String, dynamic> json) => _TextMemo(
      memoId: json['memoId'] as String,
      deltaJson: json['deltaJson'] as List<dynamic>? ?? const <dynamic>[],
      markdown: json['markdown'] as String? ?? '',
      plainText: json['plainText'] as String? ?? '',
      filePath: json['filePath'] as String?,
    );

Map<String, dynamic> _$TextMemoToJson(_TextMemo instance) => <String, dynamic>{
      'memoId': instance.memoId,
      'deltaJson': instance.deltaJson,
      'markdown': instance.markdown,
      'plainText': instance.plainText,
      'filePath': instance.filePath,
    };
