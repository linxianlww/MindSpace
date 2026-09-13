import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'daos/asset_dao.dart';
import 'daos/folder_dao.dart';
import 'daos/memo_dao.dart';
import 'tables/mindspace_tables.dart';

part 'app_database.g.dart';

/// MindSpace 本地数据库。
///
/// “文件系统即真相”：数据库只保存元数据与索引，正文、媒体、音频、文件本体
/// 全部存于应用私有目录。使用 drift_flutter，其内置 sqlite 原生库支持 arm64-v8a。
@DriftDatabase(
  tables: [
    FolderRows,
    MemoRows,
    MediaItemRows,
    AudioSubtitleRows,
    FontRows,
    TagRows,
    MemoTagRows,
  ],
  daos: [FolderDao, MemoDao, AssetDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'mindspace'));

  /// 测试可注入自定义 executor。
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // 后续版本在此按版本号增量迁移，保证用户数据不丢。
          // 示例：if (from < 2) await m.addColumn(memoRows, memoRows.xxx);
        },
        beforeOpen: (details) async {
          // 打开时启用外键级联（SQLite 默认关闭）。
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
