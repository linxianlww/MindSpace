// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'folder_dao.dart';

// ignore_for_file: type=lint
mixin _$FolderDaoMixin on DatabaseAccessor<AppDatabase> {
  $FolderRowsTable get folderRows => attachedDatabase.folderRows;
  FolderDaoManager get managers => FolderDaoManager(this);
}

class FolderDaoManager {
  final _$FolderDaoMixin _db;
  FolderDaoManager(this._db);
  $$FolderRowsTableTableManager get folderRows =>
      $$FolderRowsTableTableManager(_db.attachedDatabase, _db.folderRows);
}
