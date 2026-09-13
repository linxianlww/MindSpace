import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/storage/mindspace_storage.dart';
import '../../core/utils/ms_date_utils.dart';
import '../../core/utils/uuid_utils.dart';
import '../datasources/local_database_datasource.dart';
import '../models/folder.dart';
import 'mappers.dart';

/// 文件夹仓库：数据库元数据 + 文件系统目录保持一致。
class FolderRepository {
  FolderRepository(this._db);

  final LocalDatabaseDatasource _db;

  Stream<List<Folder>> watchChildren(String? parentId) {
    return _db.folders
        .watchChildren(parentId)
        .map((rows) => rows.map(Mappers.folderRow).toList());
  }

  Future<List<Folder>> ancestorChain(String? folderId) {
    return _db.folders
        .ancestorChain(folderId)
        .then((rows) => rows.map(Mappers.folderRow).toList());
  }

  Future<Folder?> findById(String id) async {
    final row = await _db.folders.getById(id);
    return row == null ? null : Mappers.folderRow(row);
  }

  Future<List<Folder>> allFolders() async {
    final rows = await _db.folders.allFolders();
    return rows.map(Mappers.folderRow).toList();
  }

  /// 新建文件夹，同时在磁盘建立对应目录。
  Future<Folder> create(String name, {String? parentId}) async {
    final now = MsDateUtils.nowMs();
    final folder = Folder(
      id: UuidUtils.newId(),
      name: name.trim().isEmpty ? '新建文件夹' : name.trim(),
      parentId: parentId,
      createdAt: now,
      updatedAt: now,
    );
    await _db.folders.upsert(Mappers.folderToCompanion(folder));
    final dir = p.join(
      MindspaceStorage.instance.foldersDir.path,
      folder.id,
      'memos',
    );
    MindspaceStorage.instance.ensureDir(dir);
    return folder;
  }

  Future<void> rename(String id, String name) =>
      _db.folders.rename(id, name.trim(), MsDateUtils.nowMs());

  Future<void> move(String id, String? newParentId) =>
      _db.folders.move(id, newParentId, MsDateUtils.nowMs());

  /// 软删除文件夹，并把其下铭记一并软删除（可在回收站恢复）。
  Future<void> softDelete(String id) async {
    final now = MsDateUtils.nowMs();
    await _db.folders.softDelete(id, now);
    await _db.memos.softDeleteInFolder(id, now);
  }

  Future<void> restore(String id) => _db.folders.restore(id);

  /// 彻底删除：数据库记录 + 磁盘目录。
  Future<void> hardDelete(String id) async {
    final dir = Directory(
        p.join(MindspaceStorage.instance.foldersDir.path, id));
    try {
      await dir.delete(recursive: true);
    } catch (_) {
      // 目录不存在时忽略。
    }
    await _db.folders.hardDelete(id);
  }

  Future<List<Folder>> allTrash() async {
    final rows = await _db.folders.allDeleted();
    return rows.map(Mappers.folderRow).toList();
  }

  Future<int> emptyFolderTrash() => _db.folders.hardDeleteAllTrash();
}
