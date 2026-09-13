import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/mindspace_tables.dart';

part 'folder_dao.g.dart';

/// 文件夹数据访问。mixin 由 app_database.g.dart 统一生成。
@DriftAccessor(tables: [FolderRows])
class FolderDao extends DatabaseAccessor<AppDatabase>
    with _$FolderDaoMixin {
  FolderDao(super.db);

  /// 监听某父文件夹下的正常子文件夹（parentId=null 即顶层）。
  Stream<List<FolderRow>> watchChildren(String? parentId) {
    final q = select(folderRows)
      ..where((t) =>
          t.deletedAt.isNull() & t.parentId.equalsNullable(parentId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.sortOrder),
        (t) => OrderingTerm(expression: t.createdAt),
      ]);
    return q.watch();
  }

  /// 全部正常文件夹（扁平，用于移动选择）。
  Future<List<FolderRow>> allFolders() {
    return (select(folderRows)..where((t) => t.deletedAt.isNull())).get();
  }

  Future<FolderRow?> getById(String id) {
    return (select(folderRows)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// 自上而下的祖先链（用于面包屑）。
  Future<List<FolderRow>> ancestorChain(String? startId) async {
    final result = <FolderRow>[];
    var current = startId;
    while (current != null) {
      final node = await getById(current);
      if (node == null) break;
      result.insert(0, node);
      current = node.parentId;
    }
    return result;
  }

  Future<void> upsert(FolderRowsCompanion entry) =>
      into(folderRows).insertOnConflictUpdate(entry);

  Future<void> rename(String id, String name, int updatedAt) {
    return (update(folderRows)..where((t) => t.id.equals(id))).write(
      FolderRowsCompanion(name: Value(name), updatedAt: Value(updatedAt)),
    );
  }

  Future<void> move(String id, String? parentId, int updatedAt) {
    return (update(folderRows)..where((t) => t.id.equals(id))).write(
      FolderRowsCompanion(
        parentId: Value(parentId),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  /// 软删除单个文件夹。
  Future<void> softDelete(String id, int at) {
    return (update(folderRows)..where((t) => t.id.equals(id))).write(
      FolderRowsCompanion(deletedAt: Value(at)),
    );
  }

  Future<void> restore(String id) {
    return (update(folderRows)..where((t) => t.id.equals(id))).write(
      const FolderRowsCompanion(deletedAt: Value(null)),
    );
  }

  Future<void> hardDelete(String id) {
    return (delete(folderRows)..where((t) => t.id.equals(id))).go();
  }

  Future<List<FolderRow>> allDeleted() {
    return (select(folderRows)..where((t) => t.deletedAt.isNotNull())).get();
  }

  Future<int> hardDeleteAllTrash() {
    return (delete(folderRows)..where((t) => t.deletedAt.isNotNull())).go();
  }
}
