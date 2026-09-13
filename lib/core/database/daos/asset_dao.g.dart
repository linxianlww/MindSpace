// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_dao.dart';

// ignore_for_file: type=lint
mixin _$AssetDaoMixin on DatabaseAccessor<AppDatabase> {
  $MediaItemRowsTable get mediaItemRows => attachedDatabase.mediaItemRows;
  $AudioSubtitleRowsTable get audioSubtitleRows =>
      attachedDatabase.audioSubtitleRows;
  $FontRowsTable get fontRows => attachedDatabase.fontRows;
  $TagRowsTable get tagRows => attachedDatabase.tagRows;
  $MemoTagRowsTable get memoTagRows => attachedDatabase.memoTagRows;
  AssetDaoManager get managers => AssetDaoManager(this);
}

class AssetDaoManager {
  final _$AssetDaoMixin _db;
  AssetDaoManager(this._db);
  $$MediaItemRowsTableTableManager get mediaItemRows =>
      $$MediaItemRowsTableTableManager(_db.attachedDatabase, _db.mediaItemRows);
  $$AudioSubtitleRowsTableTableManager get audioSubtitleRows =>
      $$AudioSubtitleRowsTableTableManager(
          _db.attachedDatabase, _db.audioSubtitleRows);
  $$FontRowsTableTableManager get fontRows =>
      $$FontRowsTableTableManager(_db.attachedDatabase, _db.fontRows);
  $$TagRowsTableTableManager get tagRows =>
      $$TagRowsTableTableManager(_db.attachedDatabase, _db.tagRows);
  $$MemoTagRowsTableTableManager get memoTagRows =>
      $$MemoTagRowsTableTableManager(_db.attachedDatabase, _db.memoTagRows);
}
