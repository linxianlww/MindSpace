import 'package:uuid/uuid.dart';

/// UUID 工具：文件夹、铭记、媒体、字体一律使用 v4 UUID 命名，
/// 避免重名与路径冲突。
class UuidUtils {
  UuidUtils._();

  static const Uuid _uuid = Uuid();

  /// 生成不带连字符亦可，但默认保留标准 v4 格式。
  static String newId() => _uuid.v4();

  /// 生成用于文件名的 UUID（去掉 '-'，更适合做文件名）。
  static String newFileId() => _uuid.v4().replaceAll('-', '');
}
