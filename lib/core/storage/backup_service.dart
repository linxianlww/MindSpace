import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import '../error/app_exception.dart';
import '../utils/app_logger.dart';
import 'mindspace_storage.dart';

/// 备份与恢复：把 mindspace 数据目录与 font 目录打包为 zip，或从 zip 还原。
class BackupService {
  const BackupService();

  /// 导出到 [outputPath]，返回文件大小（字节）。
  Future<int> exportZip(String outputPath) async {
    final storage = MindspaceStorage.instance;
    final archive = Archive();
    _addDir(archive, storage.baseDir.path, 'mindspace');
    _addDir(archive, storage.fontDir.path, 'font');
    final bytes = ZipEncoder().encode(archive);
    if (bytes == null) {
      throw UnknownAppException('压缩编码失败');
    }
    await File(outputPath).writeAsBytes(bytes, flush: true);
    return bytes.length;
  }

  void _addDir(Archive archive, String dirPath, String rootName) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return;
    for (final entity in dir.listSync(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final relative = p.relative(entity.path, from: p.dirname(dirPath));
      final data = entity.readAsBytesSync();
      archive.addFile(ArchiveFile(relative, data.length, data));
    }
  }

  /// 从 zip 恢复：解压覆盖到应用私有目录（不触碰公共存储）。
  Future<void> importZip(String zipPath) async {
    try {
      final bytes = await File(zipPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final support = MindspaceStorage.instance.supportDir.path;
      for (final file in archive.files) {
        if (file.isFile) {
          final target = File(p.join(support, file.name));
          target.parent.createSync(recursive: true);
          target.writeAsBytesSync(file.content as List<int>, flush: true);
        }
      }
    } catch (e, st) {
      appLogger.e('恢复备份失败', e, st);
      throw ImportFailedException(e.toString());
    }
  }
}
