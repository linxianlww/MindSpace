/// 统一业务异常。UI 层只捕获 [AppException] 并给出友好提示，
/// 不直接把底层堆栈抛给用户。
sealed class AppException implements Exception {
  const AppException(this.message, {this.cause});

  /// 面向用户的中文友好信息。
  final String message;

  /// 原始错误，仅用于日志。
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

/// 文件不存在。
class FileNotFoundException extends AppException {
  FileNotFoundException([String path = ''])
      : super('文件不存在或已被移动${path.isEmpty ? '' : '：$path'}');
}

/// 权限不足（如麦克风被拒）。
class PermissionDeniedException extends AppException {
  PermissionDeniedException([String what = '该操作'])
      : super('$what需要的权限被拒绝，请在系统设置中开启');
}

/// 文件格式不支持。
class UnsupportedFormatException extends AppException {
  UnsupportedFormatException(String ext) : super('暂不支持 .$ext 格式的文件');
}

/// 文档解析失败（PDF/DOCX/XLSX 等）。
class ParseFailedException extends AppException {
  ParseFailedException([String detail = ''])
      : super('文件解析失败${detail.isEmpty ? '' : '：$detail'}');
}

/// 导入失败。
class ImportFailedException extends AppException {
  ImportFailedException([String detail = ''])
      : super('导入失败${detail.isEmpty ? '' : '：$detail'}');
}

/// 数据库操作失败。
class DatabaseException extends AppException {
  DatabaseException([String detail = ''])
      : super('数据读写失败${detail.isEmpty ? '' : '：$detail'}');
}

/// 其它未归类错误的兜底。
class UnknownAppException extends AppException {
  UnknownAppException([String detail = ''])
      : super('发生未知错误${detail.isEmpty ? '' : '：$detail'}');
}

/// 把任意底层错误归一化为 [AppException]，保证用户数据操作失败时不丢原文件。
AppException normalizeAppError(Object error, [StackTrace? stack]) {
  if (error is AppException) return error;
  return UnknownAppException(error.toString());
}
