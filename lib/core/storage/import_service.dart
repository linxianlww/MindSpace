import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import '../constants/file_types.dart';
import '../utils/app_logger.dart';
import '../utils/uuid_utils.dart';
import 'mindspace_storage.dart';

/// 导入过程中的底层服务：文件落位、图片尺寸读取、缩略图生成。
///
/// 纯文件操作、不碰数据库；数据库编排由 ImportRepository 负责。
class ImportService {
  const ImportService();

  /// 把外部文件复制进某个铭记的指定子目录，文件以 UUID 命名并保留扩展名。
  /// 返回私有目录内的新路径。
  Future<String> placeFile({
    required String sourcePath,
    required String memoId,
    String? folderId,
    required MemoSubDir subDir,
  }) async {
    final ext = FileTypes.extensionOf(sourcePath);
    final fileName = '${UuidUtils.newFileId()}${ext.isEmpty ? '' : '.$ext'}';
    final dir = switch (subDir) {
      MemoSubDir.assets => MindspaceStorage.instance
          .assetsDir(memoId: memoId, folderId: folderId),
      MemoSubDir.audio => MindspaceStorage.instance
          .audioDir(memoId: memoId, folderId: folderId),
      MemoSubDir.files => MindspaceStorage.instance
          .filesDir(memoId: memoId, folderId: folderId),
    };
    MindspaceStorage.instance.ensureDir(dir);
    final target = p.join(dir, fileName);
    await File(sourcePath).copy(target);
    return target;
  }

  /// 读取图片尺寸（宽、高）。失败返回 null，不阻断导入。
  ({int width, int height})? readImageSize(String path) {
    try {
      final bytes = File(path).readAsBytesSync();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;
      return (width: decoded.width, height: decoded.height);
    } catch (e) {
      appLogger.w('读取图片尺寸失败 $path', e);
      return null;
    }
  }

  /// 生成图片缩略图（最大宽 480，JPEG 质量 80），返回缓存路径。
  /// 大文件解码放到主 isolate 之外由调用方决定；此处做内存兜底保护。
  Future<String?> generateImageThumb(String sourcePath, String memoId) async {
    try {
      final Uint8List bytes = await File(sourcePath).readAsBytes();
      final decoded = await _decodeAsync(bytes);
      if (decoded == null) return null;
      // image 4.x 仅支持指定 width/height，只给宽度时等比缩放。
      final thumb = img.copyResize(decoded,
          width: decoded.width > 480 ? 480 : decoded.width);
      final out = img.encodeJpg(thumb, quality: 80);
      final dir = MindspaceStorage.instance.cacheThumbDir.path;
      MindspaceStorage.instance.ensureDir(dir);
      final target = p.join(dir, '${UuidUtils.newFileId()}.jpg');
      await File(target).writeAsBytes(out, flush: true);
      return target;
    } catch (e) {
      appLogger.w('生成缩略图失败 $sourcePath', e);
      return null;
    }
  }

  /// 使用 Isolate 解码大图，避免阻塞 UI。
  Future<img.Image?> _decodeAsync(Uint8List bytes) {
    return Future(() => img.decodeImage(bytes));
  }
}

/// 铭记内部子目录类型。
enum MemoSubDir { assets, audio, files }
