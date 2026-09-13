import 'dart:io';

/// 文件相关通用工具：体积格式化、目录占用、安全删除等。
class FileUtils {
  FileUtils._();

  static const List<String> _units = ['B', 'KB', 'MB', 'GB', 'TB'];

  /// 字节数 -> 人类可读体积。
  static String humanSize(int bytes) {
    if (bytes <= 0) return '0 B';
    var size = bytes.toDouble();
    var unit = 0;
    while (size >= 1024 && unit < _units.length - 1) {
      size /= 1024;
      unit++;
    }
    final str = unit == 0 ? size.toStringAsFixed(0) : size.toStringAsFixed(1);
    return '$str ${_units[unit]}';
  }

  /// 递归计算目录占用字节数，不存在返回 0。
  static int dirSize(String path) {
    final dir = Directory(path);
    if (!dir.existsSync()) return 0;
    var total = 0;
    try {
      for (final entity in dir.listSync(recursive: true, followLinks: false)) {
        if (entity is File) total += entity.lengthSync();
      }
    } catch (_) {
      // 统计过程中文件被删等情况忽略，返回已统计部分。
    }
    return total;
  }

  /// 确保目录存在。
  static void ensureDir(String path) {
    final dir = Directory(path);
    if (!dir.existsSync()) dir.createSync(recursive: true);
  }

  /// 若目标已存在则自动追加 (1)(2)，用于“保留原文件”的复制场景。
  static String nonClobberPath(String targetPath) {
    if (!File(targetPath).existsSync()) return targetPath;
    final dot = targetPath.lastIndexOf('.');
    final hasExt = dot > targetPath.lastIndexOf(Platform.pathSeparator);
    final base = hasExt ? targetPath.substring(0, dot) : targetPath;
    final ext = hasExt ? targetPath.substring(dot) : '';
    var i = 1;
    while (File('$base($i)$ext').existsSync()) {
      i++;
    }
    return '$base($i)$ext';
  }
}
