import 'package:freezed_annotation/freezed_annotation.dart';

part 'file_memo.freezed.dart';
part 'file_memo.g.dart';

/// 文件铭记载荷：办公文档或非常规文件。
@freezed
abstract class FileMemo with _$FileMemo {
  const factory FileMemo({
    required String memoId,
    required String path, // 私有目录内的真实文件
    required String originalName,
    @Default(0) int sizeBytes,
    String? extension, // 小写、无点
    int? pageCount, // PDF 页数 / 工作表数等
  }) = _FileMemo;

  factory FileMemo.fromJson(Map<String, dynamic> json) =>
      _$FileMemoFromJson(json);
}
