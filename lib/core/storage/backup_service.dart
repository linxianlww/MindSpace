import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import '../error/app_exception.dart';
import '../utils/app_logger.dart';
import 'mindspace_storage.dart';

/// 备份与恢复：把 mindspace 数据目录、font 目录与本地数据库打包为 zip，
/// 或从 zip 安全还原。
///
/// 安全约束：解压时对每个条目做路径校验（拒绝 `..`/绝对路径/盘符前缀），
/// 确保写入目标始终位于应用私有 supportDir 之内（防 ZipSlip 越目录写）。
class BackupService {
  const BackupService();

  /// 导出为 zip 字节（不落盘），由调用方决定如何保存（如 SAF 保存对话框）。
  Future<Uint8List> exportZipBytes() async {
    final storage = MindspaceStorage.instance;
    final archive = Archive();
    _addDir(archive, storage.baseDir.path, 'mindspace');
    _addDir(archive, storage.fontDir.path, 'font');
    _addDbFiles(archive, storage.supportDir.path);
    final bytes = ZipEncoder().encode(archive);
    if (bytes == null) {
      throw UnknownAppException('压缩编码失败');
    }
    return Uint8List.fromList(bytes);
  }

  /// 导出到 [outputPath]，返回文件大小（字节）。
  Future<int> exportZip(String outputPath) async {
    final bytes = await exportZipBytes();
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

  /// 把 drift 数据库（sqlite + wal/shm，如存在）一并打包，统一放进
  /// `_db/` 前缀下，保证备份产物完整（含元数据/文件夹）。
  void _addDbFiles(Archive archive, String supportDir) {
    for (final name in const [
      'mindspace.sqlite',
      'mindspace.sqlite-wal',
      'mindspace.sqlite-shm',
    ]) {
      for (final parent in const ['', 'databases']) {
        final f = File(parent.isEmpty
            ? p.join(supportDir, name)
            : p.join(supportDir, parent, name));
        if (!f.existsSync()) continue;
        final data = f.readAsBytesSync();
        archive.addFile(ArchiveFile('_db/$name', data.length, data));
        break; // 同一文件只打一份（根与 databases 二选一）
      }
    }
  }

  /// 从 zip 恢复：解压覆盖到应用私有目录（不触碰公共存储）。
  ///
  /// - 普通条目：校验目标路径必须位于 supportDir 之内，拒绝越界条目
  ///   （ZipSlip：条目名为 `../x`、绝对路径或含盘符时直接跳过）；
  /// - `_db/` 条目：仅当本地数据库主文件尚不存在时落库，避免与运行中的
  ///   Drift 连接相互覆盖损坏（同机恢复只覆盖内容文件，数据库不受影响）。
  Future<void> importZip(String zipPath) async {
    try {
      final bytes = await File(zipPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final storage = MindspaceStorage.instance;
      final support = storage.supportDir.path;
      final supportNorm = p.normalize(support);
      for (final file in archive.files) {
        if (!file.isFile) continue;
        final name = file.name.replaceAll('\\', '/');
        if (name.isEmpty) continue;
        var rel = name;
        var isDbEntry = false;
        if (name.startsWith('_db/')) {
          isDbEntry = true;
          rel = name.substring(4);
        }
        // 归一化后必须仍落在 supportDir 内，杜绝 ".." / 绝对路径 / 盘符逃逸。
        final target = p.normalize(p.join(support, rel));
        final inside = target == supportNorm ||
            target.startsWith(supportNorm + p.separator);
        if (!inside) {
          appLogger.w('跳过越界备份条目（防路径穿越）: $name');
          continue;
        }
        final targetFile = File(target);
        if (isDbEntry &&
            targetFile.path.endsWith('.sqlite') &&
            targetFile.existsSync()) {
          appLogger.w('跳过数据库恢复（本地数据库已存在）: $name');
          continue;
        }
        targetFile.parent.createSync(recursive: true);
        targetFile.writeAsBytesSync(file.content as List<int>, flush: true);
      }
    } catch (e, st) {
      appLogger.e('恢复备份失败', e, st);
      throw ImportFailedException(e.toString());
    }
  }
}