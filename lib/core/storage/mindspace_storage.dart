import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../constants/app_constants.dart';
import '../utils/app_logger.dart';

/// 统一管理“文件系统即真相”的目录布局。
///
/// `<ApplicationSupportDirectory>/`
/// ├─ mindspace/
/// │  ├─ root/`<memoId>`/...
/// │  └─ folders/`<folderId>`/memos/`<memoId>`/...
/// └─ font/`<fontUuid>`.ttf
class MindspaceStorage {
  MindspaceStorage._();
  static final MindspaceStorage instance = MindspaceStorage._();

  late Directory supportDir;
  late Directory baseDir; // mindspace
  late Directory rootDir; // 根级铭记
  late Directory foldersDir; // 文件夹铭记
  late Directory fontDir; // 字体
  late Directory cacheThumbDir; // 缩略图缓存

  bool _initialized = false;
  bool get isInitialized => _initialized;

  Future<void> init() async {
    if (_initialized) return;
    supportDir = await getApplicationSupportDirectory();
    baseDir = Directory(p.join(supportDir.path, AppConstants.mindspaceDirName));
    rootDir = Directory(p.join(baseDir.path, AppConstants.rootDirName));
    foldersDir =
        Directory(p.join(baseDir.path, AppConstants.foldersDirName));
    fontDir = Directory(p.join(supportDir.path, AppConstants.fontDirName));
    cacheThumbDir = Directory(p.join(supportDir.path, 'cache', 'thumb'));
    for (final d in [baseDir, rootDir, foldersDir, fontDir, cacheThumbDir]) {
      if (!d.existsSync()) d.createSync(recursive: true);
    }
    _initialized = true;
    appLogger.i('MindspaceStorage 初始化于 ${baseDir.path}');
  }

  /// 递归确保目录存在（传入的是路径字符串）。
  void ensureDir(String path) {
    final dir = Directory(path);
    if (!dir.existsSync()) dir.createSync(recursive: true);
  }

  /// 判断 [path] 是否位于应用私有 supportDir 之内。
  ///
  /// 用于防越权：meta.json / 备份数据可能被篡改，读取、分享、导入前
  /// 校验路径归属，避免把系统任意路径的文件读入应用或分享出去。
  bool isWithinSupport(String path) {
    try {
      final root = p.normalize(supportDir.path);
      final target = p.normalize(path);
      return target == root || target.startsWith(root + p.separator);
    } catch (_) {
      return false;
    }
  }

  /// 某个铭记所在目录（根铭记或文件夹铭记）。
  String memoDir({required String memoId, String? folderId}) {
    if (folderId == null) {
      return p.join(rootDir.path, memoId);
    }
    return p.join(
      foldersDir.path,
      folderId,
      'memos',
      memoId,
    );
  }

  String assetsDir({required String memoId, String? folderId}) => p.join(
      memoDir(memoId: memoId, folderId: folderId),
      AppConstants.assetsDirName);

  String audioDir({required String memoId, String? folderId}) => p.join(
      memoDir(memoId: memoId, folderId: folderId),
      AppConstants.audioDirName);

  String filesDir({required String memoId, String? folderId}) => p.join(
      memoDir(memoId: memoId, folderId: folderId),
      AppConstants.filesDirName);

  String metaPath({required String memoId, String? folderId}) =>
      p.join(memoDir(memoId: memoId, folderId: folderId),
          AppConstants.metaFileName);

  /// 铭记从一个文件夹移动到另一个（或根）时，整体迁移目录并返回新目录。
  Future<String> moveMemoDirectory({
    required String memoId,
    String? fromFolderId,
    String? toFolderId,
  }) async {
    final src = memoDir(memoId: memoId, folderId: fromFolderId);
    final dst = memoDir(memoId: memoId, folderId: toFolderId);
    final srcDir = Directory(src);
    if (!srcDir.existsSync()) {
      Directory(dst).createSync(recursive: true);
      return dst;
    }
    Directory(p.dirname(dst)).createSync(recursive: true);
    await srcDir.rename(dst);
    return dst;
  }

  /// 删除某个铭记的整个目录（硬删除时使用）；目录不存在时安全忽略。
  Future<void> deleteMemoDirectory(
      {required String memoId, String? folderId}) async {
    final dir = Directory(memoDir(memoId: memoId, folderId: folderId));
    try {
      await dir.delete(recursive: true);
    } catch (_) {
      // 目录已不存在等情况：忽略，保证硬删除幂等。
    }
  }

  String fontFilePath(String fontId, String ext) =>
      p.join(fontDir.path, '$fontId.$ext');
}
