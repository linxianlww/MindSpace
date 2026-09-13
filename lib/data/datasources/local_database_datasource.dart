import '../../core/database/app_database.dart';
import '../../core/database/daos/asset_dao.dart';
import '../../core/database/daos/folder_dao.dart';
import '../../core/database/daos/memo_dao.dart';

/// 数据库数据源：对外屏蔽 AppDatabase 细节，Repository 只依赖它。
class LocalDatabaseDatasource {
  LocalDatabaseDatasource(this.db);

  final AppDatabase db;

  FolderDao get folders => db.folderDao;
  MemoDao get memos => db.memoDao;
  AssetDao get assets => db.assetDao;

  Future<T> transaction<T>(Future<T> Function() action) =>
      db.transaction(action);
}
