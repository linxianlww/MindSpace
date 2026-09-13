// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memo_dao.dart';

// ignore_for_file: type=lint
mixin _$MemoDaoMixin on DatabaseAccessor<AppDatabase> {
  $MemoRowsTable get memoRows => attachedDatabase.memoRows;
  MemoDaoManager get managers => MemoDaoManager(this);
}

class MemoDaoManager {
  final _$MemoDaoMixin _db;
  MemoDaoManager(this._db);
  $$MemoRowsTableTableManager get memoRows =>
      $$MemoRowsTableTableManager(_db.attachedDatabase, _db.memoRows);
}
