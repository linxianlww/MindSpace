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
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // v2：媒体集条目增加缩略图路径列，保证主界面能显示首图缩略图。
          if (from < 2) {
            await m.addColumn(mediaItemRows, mediaItemRows.thumbPath);
          }
        },
        // 注意：当前 drift 版本不支持 onDowngrade，降级会默认抛出异常
        beforeOpen: (details) async {
          // 打开时启用外键级联（SQLite 默认关闭）。
          await customStatement('PRAGMA foreign_keys = ON');
          // 小组件配置 Activity 会启动独立 Flutter 引擎并各自建立一个 sqlite 连接。
          // 默认 rollback journal 下并发读写容易立刻返回 SQLITE_BUSY，
          // 导致配置页列表永久转圈；WAL 允许读写并发，是多连接场景的标准模式。
          // 该 pragma 需要写锁，极端并发下可能失败，失败不影响打开（best-effort）。
          try {
            await customStatement('PRAGMA journal_mode = WAL');
          } catch (_) {}
        },
      );
}
