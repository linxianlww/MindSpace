import '../../core/database/app_database.dart';
import '../../core/storage/font_storage.dart';
import '../datasources/local_database_datasource.dart';
import '../models/font_asset.dart';
import 'mappers.dart';

/// 字体仓库：负责字体的导入（复制到 data/font 并 UUID 命名）、列表与删除。
class FontRepository {
  FontRepository(this._db, this._storage);

  final LocalDatabaseDatasource _db;
  final FontStorage _storage;

  Stream<List<FontAsset>> watchFonts() => _db.assets.watchFonts().map(
        (rows) => rows.map(Mappers.fontRow).toList(),
      );

  Future<List<FontAsset>> allFonts() async {
    final rows = await _db.assets.allFonts();
    return rows.map(Mappers.fontRow).toList();
  }

  /// 从外部路径导入字体，返回入库后的字体对象。
  Future<FontAsset> importFont(String sourcePath, String originalName) async {
    final font = await _storage.importFont(sourcePath, originalName);
    await _db.assets.upsertFont(
      FontRowsCompanion.insert(
        id: font.id,
        name: font.name,
        path: font.path,
        createdAt: font.createdAt,
      ),
    );
    return font;
  }

  Future<void> delete(FontAsset font) async {
    await _storage.deleteFontFile(font.path);
    await _db.assets.deleteFont(font.id);
  }
}
