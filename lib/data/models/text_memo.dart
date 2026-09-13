import 'package:freezed_annotation/freezed_annotation.dart';

part 'text_memo.freezed.dart';
part 'text_memo.g.dart';

/// 文本铭记的正文载荷。
///
/// [deltaJson] 为 flutter_quill 的 Delta（富文本真源）；
/// [markdown]/[plainText] 为导出/检索用的冗余文本，随保存一并刷新。
@freezed
abstract class TextMemo with _$TextMemo {
  const factory TextMemo({
    required String memoId,
    // 使用 List<dynamic> 承载 quill Delta，规避 freezed 对嵌套 Map 泛型默认值的生成缺陷。
    @Default(<dynamic>[]) List<dynamic> deltaJson,
    @Default('') String markdown,
    @Default('') String plainText,
    String? filePath, // content.md / .rtf / .txt 的实际落盘路径
  }) = _TextMemo;

  factory TextMemo.fromJson(Map<String, dynamic> json) =>
      _$TextMemoFromJson(json);
}
