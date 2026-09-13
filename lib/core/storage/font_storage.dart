import '../../data/datasources/file_system_datasource.dart';
import '../../data/models/font_asset.dart';
import '../constants/file_types.dart';
import '../utils/ms_date_utils.dart';
import '../utils/uuid_utils.dart';
import 'mindspace_storage.dart';

/// 字体存储：导入时复制到 data/font 并以 UUID 重命名。
///
/// 该类只负责文件层面；数据库记录由 FontRepository 写入。
class FontStorage {
  FontStorage(this._fs);

  final FileSystemDatasource _fs;

  /// 从外部路径导入字体，返回待入库的 [FontAsset]。
  Future<FontAsset> importFont(String sourcePath, String originalName) async {
    final ext = FileTypes.extensionOf(originalName).isEmpty
        ? 'ttf'
        : FileTypes.extensionOf(originalName);
    final id = UuidUtils.newId();
    final target = MindspaceStorage.instance.fontFilePath(id, ext);
    await _fs.copyIn(sourcePath, target);
    return FontAsset(
      id: id,
      name: originalName,
      path: target,
      createdAt: MsDateUtils.nowMs(),
    );
  }

  Future<void> deleteFontFile(String path) => _fs.delete(path);
}
