import 'package:freezed_annotation/freezed_annotation.dart';

part 'folder.freezed.dart';
part 'folder.g.dart';

/// 文件夹（支持无限层级，parentId 为 null 表示顶层）。
@freezed
abstract class Folder with _$Folder {
  const factory Folder({
    required String id,
    required String name,
    String? parentId,
    required int createdAt,
    required int updatedAt,
    @Default(0) int sortOrder,
    int? deletedAt, // 软删除时间戳，null 表示正常
  }) = _Folder;

  factory Folder.fromJson(Map<String, dynamic> json) => _$FolderFromJson(json);
}
