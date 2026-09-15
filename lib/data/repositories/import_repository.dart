import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/constants/file_types.dart';
import '../../core/storage/import_service.dart';
import '../../core/storage/mindspace_storage.dart';
import '../../core/utils/audio_probe.dart';
import '../../core/utils/ms_date_utils.dart';
import '../../core/utils/uuid_utils.dart';
import '../datasources/file_system_datasource.dart';
import '../models/media_item.dart';
import '../models/memo.dart';
import '../models/memo_type.dart';
import 'memo_repository.dart';

/// 导入编排：识别类型 -> 建铭记目录 -> 复制文件 -> 提取元数据/缩略图 -> 落库。
///
/// 对应需求 5.3 的七步导入流程；任何一步失败都不删除用户源文件。
class ImportRepository {
  ImportRepository(this._memos, this._service, this._fs);

  final MemoRepository _memos;
  final ImportService _service;
  final FileSystemDatasource _fs;

  /// 一次可导入多个文件：图片/视频合并为一个媒体集，其余各自成铭记。
  Future<List<Memo>> importFiles(
    List<String> paths, {
    String? folderId,
  }) async {
    final result = <Memo>[];
    final mediaPaths = paths
        .where((e) => FileTypes.classify(e) == MemoType.media)
        .toList();
    if (mediaPaths.isNotEmpty) {
      result.add(await _importMediaSet(mediaPaths, folderId));
    }
    for (final path in paths) {
      if (FileTypes.classify(path) == MemoType.media) continue;
      result.add(await _importSingle(path, folderId));
    }
    return result;
  }

  Future<Memo> importOne(String path, {String? folderId}) =>
      _importSingle(path, folderId);

  /// 用 just_audio 临时加载一次音频文件，探测真实时长（毫秒）。
  Future<int> _probeAudioDuration(String path) => probeAudioDuration(path);

  // —— 单文件：文本 / 音频 / 文件 ——
  Future<Memo> _importSingle(String source, String? folderId) async {
    final type = FileTypes.classify(source);
    final title = p.basenameWithoutExtension(source);
    final memo =
        await _memos.createBlank(type, folderId: folderId, title: title);
    final storage = MindspaceStorage.instance;

    switch (type) {
      case MemoType.text:
        final content = await _fs.readString(source);
        final ext = FileTypes.extensionOf(source);
        final dir = storage.memoDir(memoId: memo.id, folderId: folderId);
        _fs.ensureDir(dir);
        // 统一为富文本唯一正本 content.delta.json：不再保留 txt/md/rtf
        // 副本，避免同一份正文在磁盘上重复存储（分享/导出时按需转换）。
        final target = p.join(dir, 'content.delta.json');
        await _fs.writeString(target, jsonEncode([{'insert': '$content\n'}]));
        await _memos.save(memo.copyWith(
          metadata: {'filePath': target, 'sourceFormat': ext},
        ));

      case MemoType.audio:
        final placed = await _service.placeFile(
          sourcePath: source,
          memoId: memo.id,
          folderId: folderId,
          subDir: MemoSubDir.audio,
        );
        await _memos.save(memo.copyWith(
          metadata: {
            'originalPath': placed,
            // 补存文件名供展示（不暴露内部完整路径）。
            'originalName': p.basename(source),
            'ext': FileTypes.extensionOf(source),
            // 导入时即解码一次时长，否则列表与信息页显示 00:00。
            'durationMs': await _probeAudioDuration(placed),
          },
        ));

      case MemoType.file:
        final filesDir =
            storage.filesDir(memoId: memo.id, folderId: folderId);
        _fs.ensureDir(filesDir);
        // 保留原始文件名，便于“文件信息”展示与外部打开。
        final target = p.join(filesDir, p.basename(source));
        await _fs.copyIn(source, target);
        final size = File(target).lengthSync();
        await _memos.save(memo.copyWith(
          metadata: {
            'path': target,
            'originalName': p.basename(source),
            'sizeBytes': size,
            'ext': FileTypes.extensionOf(source),
          },
        ));

      case MemoType.media:
        break; // 多图场景走 _importMediaSet
      case MemoType.totp:
        break; // TOTP 不走文件导入（二维码扫码单独入口）
    }
    return (await _memos.findById(memo.id))!;
  }

  // —— 媒体集 ——
  Future<Memo> _importMediaSet(
      List<String> sources, String? folderId) async {
    final memo = await _memos.createBlank(
      MemoType.media,
      folderId: folderId,
      title: '媒体集 ${MsDateUtils.format(MsDateUtils.nowMs())}',
    );
    String? firstThumb;
    for (var i = 0; i < sources.length; i++) {
      final source = sources[i];
      final placed = await _service.placeFile(
        sourcePath: source,
        memoId: memo.id,
        folderId: folderId,
        subDir: MemoSubDir.assets,
      );
      final kind = FileTypes.mediaKindOf(source);
      int? w;
      int? h;
      String? thumb;
      if (kind == MediaKind.image) {
        final size = await _service.readImageSize(placed);
        w = size?.width;
        h = size?.height;
        thumb = await _service.generateImageThumb(placed, memo.id);
        firstThumb ??= thumb;
      }
      await _memos.upsertMedia(MediaItem(
        id: UuidUtils.newId(),
        memoId: memo.id,
        path: placed,
        kind: kind,
        sortOrder: i,
        width: w,
        height: h,
        thumbPath: thumb,
        createdAt: MsDateUtils.nowMs(),
      ));
    }
    return _memos.save(memo.copyWith(
      thumbnailPath: firstThumb,
      metadata: {'count': sources.length},
    ));
  }
}
