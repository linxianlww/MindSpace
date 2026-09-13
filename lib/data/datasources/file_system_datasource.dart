import 'dart:convert';
import 'dart:io';

import '../../core/error/app_exception.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/file_utils.dart';

/// 文件系统数据源：所有真实内容读写的唯一底层出口。
///
/// 全部路径都位于应用私有目录，绝不触碰公共存储；
/// 写操作采用“先写临时文件再替换”的稳妥方式，失败时不破坏原文件。
class FileSystemDatasource {
  const FileSystemDatasource();

  void ensureDir(String path) => FileUtils.ensureDir(path);

  bool exists(String path) =>
      FileSystemEntity.typeSync(path) != FileSystemEntityType.notFound;

  Future<String> readString(String path) async {
    try {
      return await File(path).readAsString();
    } on FileSystemException catch (e) {
      appLogger.e('读取文本失败 $path', e);
      throw FileNotFoundException(path);
    }
  }

  Future<List<int>> readBytes(String path) async {
    try {
      return await File(path).readAsBytes();
    } on FileSystemException catch (e) {
      appLogger.e('读取字节失败 $path', e);
      throw FileNotFoundException(path);
    }
  }

  /// 安全写入字符串（先 .tmp 再 rename，避免写一半损坏原文件）。
  Future<void> writeString(String path, String content) async {
    FileUtils.ensureDir(File(path).parent.path);
    final tmp = File('$path.tmp');
    await tmp.writeAsString(content, flush: true);
    await tmp.rename(path);
  }

  Future<void> writeBytes(String path, List<int> bytes) async {
    FileUtils.ensureDir(File(path).parent.path);
    final tmp = File('$path.tmp');
    await tmp.writeAsBytes(bytes, flush: true);
    await tmp.rename(path);
  }

  /// 导入外部文件到私有目录，返回复制后的路径。不删除源文件。
  Future<String> copyIn(String sourcePath, String targetPath) async {
    FileUtils.ensureDir(File(targetPath).parent.path);
    try {
      await File(sourcePath).copy(targetPath);
      return targetPath;
    } on FileSystemException catch (e) {
      appLogger.e('复制文件失败 $sourcePath -> $targetPath', e);
      throw ImportFailedException(e.message);
    }
  }

  Future<void> delete(String path) async {
    final f = File(path);
    if (f.existsSync()) {
      try {
        await f.delete();
      } on FileSystemException catch (e) {
        appLogger.w('删除文件失败 $path', e);
      }
    }
  }

  Future<void> deleteDir(String path) async {
    final d = Directory(path);
    if (d.existsSync()) {
      try {
        await d.delete(recursive: true);
      } on FileSystemException catch (e) {
        appLogger.w('删除目录失败 $path', e);
      }
    }
  }

  // —— JSON（meta.json）便捷方法 ——
  Future<Map<String, dynamic>> readJson(String path) async {
    final raw = await readString(path);
    if (raw.trim().isEmpty) return <String, dynamic>{};
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> writeJson(String path, Map<String, dynamic> json) =>
      writeString(path, const JsonEncoder.withIndent('  ').convert(json));
}
