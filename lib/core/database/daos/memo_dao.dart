import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/mindspace_tables.dart';

part 'memo_dao.g.dart';

/// 铭记元数据访问。
@DriftAccessor(tables: [MemoRows])
class MemoDao extends DatabaseAccessor<AppDatabase> with _$MemoDaoMixin {
  MemoDao(super.db);

  /// 排序字段枚举，对应设置中的排序偏好。
  static const Set<String> sortableFields = {'createdAt', 'updatedAt', 'title'};

  /// 监听某文件夹下的铭记（folderId=null 为根）。
  Stream<List<MemoRow>> watchByFolder(
    String? folderId, {
    bool includeDeleted = false,
    String sortField = 'updatedAt',
    bool ascending = false,
  }) {
    final q = select(memoRows)
      ..where((t) {
        final inFolder = t.folderId.equalsNullable(folderId);
        return includeDeleted ? inFolder : inFolder & t.deletedAt.isNull();
      });
    final field = sortableFields.contains(sortField) ? sortField : 'updatedAt';
    q.orderBy([
      (t) {
        final mode = ascending ? OrderingMode.asc : OrderingMode.desc;
        switch (field) {
          case 'createdAt':
            return OrderingTerm(expression: t.createdAt, mode: mode);
          case 'title':
            return OrderingTerm(expression: t.title, mode: mode);
          default:
            return OrderingTerm(expression: t.updatedAt, mode: mode);
        }
      },
    ]);
    return q.watch();
  }

  /// 全文搜索（标题/备注，简单 LIKE 实现，纯本地）。
  Stream<List<MemoRow>> watchSearch(String keyword) {
    final like = '%$keyword%';
    final q = select(memoRows)
      ..where((t) =>
          t.deletedAt.isNull() &
          (t.title.like(like) | t.remark.like(like)))
      ..orderBy([(t) => OrderingTerm(expression: t.updatedAt)]);
    return q.watch();
  }

  /// 某类型下所有未删除铭记（用于补充扫描文件系统中的正文内容）。
  Future<List<MemoRow>> activeOfType(String type) =>
      (select(memoRows)..where((t) =>
          t.deletedAt.isNull() & t.type.equals(type))).get();

  Future<MemoRow?> getById(String id) =>
      (select(memoRows)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> upsert(MemoRowsCompanion entry) =>
      into(memoRows).insertOnConflictUpdate(entry);

  Future<void> move(String id, String? folderId, int updatedAt) {
    return (update(memoRows)..where((t) => t.id.equals(id))).write(
      MemoRowsCompanion(
        folderId: Value(folderId),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  Future<void> rename(String id, String title, int updatedAt) {
    return (update(memoRows)..where((t) => t.id.equals(id))).write(
      MemoRowsCompanion(title: Value(title), updatedAt: Value(updatedAt)),
    );
  }

  Future<void> updateAppearance(String id, {int? color, String? remark}) {
    return (update(memoRows)..where((t) => t.id.equals(id))).write(
      MemoRowsCompanion(
        color: Value(color),
        remark: Value(remark),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> writeMetadata(String id, String metadataJson, int updatedAt,
      {String? thumbnailPath}) {
    return (update(memoRows)..where((t) => t.id.equals(id))).write(
      MemoRowsCompanion(
        metadataJson: Value(metadataJson),
        thumbnailPath: Value(thumbnailPath),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  Future<void> softDelete(String id, int at) =>
      (update(memoRows)..where((t) => t.id.equals(id)))
          .write(MemoRowsCompanion(deletedAt: Value(at)));

  /// 级联软删除某文件夹下全部铭记。
  Future<void> softDeleteInFolder(String folderId, int at) =>
      (update(memoRows)..where((t) => t.folderId.equals(folderId)))
          .write(MemoRowsCompanion(deletedAt: Value(at)));

  Future<void> restore(String id) =>
      (update(memoRows)..where((t) => t.id.equals(id)))
          .write(const MemoRowsCompanion(deletedAt: Value(null)));

  Future<void> hardDelete(String id) =>
      (delete(memoRows)..where((t) => t.id.equals(id))).go();

  Stream<List<MemoRow>> watchTrash() {
    return (select(memoRows)
          ..where((t) => t.deletedAt.isNotNull())
          ..orderBy([(t) => OrderingTerm(expression: t.deletedAt)]))
        .watch();
  }

  Future<int> hardDeleteAllTrash() =>
      (delete(memoRows)..where((t) => t.deletedAt.isNotNull())).go();

  Future<int> countActive() async {
    final count = memoRows.id.count(
        filter: memoRows.deletedAt.isNull());
    final row = await (selectOnly(memoRows)..addColumns([count]))
        .getSingle();
    return row.read(count) ?? 0;
  }
}
