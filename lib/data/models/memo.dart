import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'memo_type.dart';

part 'memo.freezed.dart';
part 'memo.g.dart';

/// MemoType <-> wire 字符串转换器（持久化稳定，不依赖枚举序号）。
class MemoTypeConverter
    implements JsonConverter<MemoType, String> {
  const MemoTypeConverter();
  @override
  MemoType fromJson(String json) => MemoType.fromWire(json);
  @override
  String toJson(MemoType object) => object.wire;
}

/// 铭记的通用元数据（四类铭记共享）。类型专属内容见 text/media/audio/file 模型。
@freezed
abstract class Memo with _$Memo {
  const Memo._();

  const factory Memo({
    required String id,
    String? folderId, // null 表示位于根
    @MemoTypeConverter() required MemoType type,
    @Default('无标题') String title,
    required int createdAt,
    required int updatedAt,
    int? color, // ARGB
    String? remark, // 备注标签
    String? fontId, // 文本铭记选用的自定义字体
    String? thumbnailPath,
    @Default(<String>[]) List<String> tags,
    @Default(<String, dynamic>{}) Map<String, dynamic> metadata,
    int? deletedAt,
  }) = _Memo;

  factory Memo.fromJson(Map<String, dynamic> json) => _$MemoFromJson(json);

  bool get isDeleted => deletedAt != null;

  /// 便于 UI 使用的颜色对象（null 表示未设置颜色）。
  Color? get colorValue => color == null ? null : Color(color!);
}
