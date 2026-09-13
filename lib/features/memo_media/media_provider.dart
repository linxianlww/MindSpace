import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';

import '../../core/constants/file_types.dart';
import '../../core/di/providers.dart';
import '../../core/storage/import_service.dart';
import '../../core/utils/ms_date_utils.dart';
import '../../core/utils/uuid_utils.dart';
import '../../data/models/media_item.dart';
import '../../data/models/memo_type.dart';

/// 媒体集条目流（按 sortOrder 排序）。
final mediaItemsProvider =
    StreamProvider.family<List<MediaItem>, String>((ref, memoId) {
  return ref.watch(memoRepositoryProvider).watchMedia(memoId);
});

/// 媒体集编辑控制器：增删、排序、备注、旋转、裁剪。
class MediaController {
  MediaController(this._ref);
  final Ref _ref;

  /// 从系统选择图片/视频并加入指定媒体集。
  Future<int> addFiles(String memoId, String? folderId) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.media,
    );
    final paths = result?.files
            .map((e) => e.path)
            .whereType<String>()
            .toList() ??
        const [];
    if (paths.isEmpty) return 0;

    final repo = _ref.read(memoRepositoryProvider);
    final service = _ref.read(importServiceProvider);
    final existing = await repo.mediaOf(memoId);
    var order = existing.length;
    for (final source in paths) {
      final placed = await service.placeFile(
        sourcePath: source,
        memoId: memoId,
        folderId: folderId,
        subDir: MemoSubDir.assets,
      );
      final kind = FileTypes.mediaKindOf(source);
      int? w;
      int? h;
      String? thumb;
      if (kind == MediaKind.image) {
        final size = service.readImageSize(placed);
        w = size?.width;
        h = size?.height;
        thumb = await service.generateImageThumb(placed, memoId);
      }
      await repo.upsertMedia(MediaItem(
        id: UuidUtils.newId(),
        memoId: memoId,
        path: placed,
        kind: kind,
        sortOrder: order++,
        width: w,
        height: h,
        thumbPath: thumb,
        createdAt: MsDateUtils.nowMs(),
      ));
    }
    await _refreshCount(memoId);
    return paths.length;
  }

  Future<void> remove(MediaItem item, {bool deleteSource = true}) async {
    final repo = _ref.read(memoRepositoryProvider);
    if (deleteSource) {
      final f = File(item.path);
      if (f.existsSync()) f.deleteSync();
    }
    await repo.removeMedia(item.id);
    await _refreshCount(item.memoId);
  }

  /// 拖拽排序：把 [from] 位置的条目移动到 [to]。
  Future<void> reorder(String memoId, List<MediaItem> ordered, int from, int to) async {
    if (from < to) to -= 1;
    final list = List<MediaItem>.from(ordered);
    final moved = list.removeAt(from);
    list.insert(to, moved);
    await _ref.read(memoRepositoryProvider).reorderMedia(memoId, list);
  }

  Future<void> setRemark(MediaItem item, String? remark) async {
    await _ref
        .read(memoRepositoryProvider)
        .upsertMedia(item.copyWith(remark: remark));
  }

  /// 顺时针旋转 90°（仅图片），覆盖原文件并刷新缩略信息。
  Future<void> rotateRight(MediaItem item) async {
    final bytes = await File(item.path).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return;
    final rotated = img.copyRotate(decoded, angle: 90);
    final ext = FileTypes.extensionOf(item.path);
    final encoded = ext == 'png'
        ? img.encodePng(rotated)
        : img.encodeJpg(rotated, quality: 92);
    await File(item.path).writeAsBytes(encoded, flush: true);
    await _ref.read(memoRepositoryProvider).upsertMedia(item.copyWith(
          width: rotated.width,
          height: rotated.height,
        ));
  }

  /// 调起系统裁剪 UI，结果覆盖原图。
  Future<String?> crop(MediaItem item) async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: item.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '裁剪图片',
          lockAspectRatio: false,
          initAspectRatio: CropAspectRatioPreset.original,
        ),
        IOSUiSettings(title: '裁剪图片'),
      ],
    );
    if (cropped == null) return null;
    final bytes = await cropped.readAsBytes();
    await File(item.path).writeAsBytes(bytes, flush: true);
    final service = _ref.read(importServiceProvider);
    final size = service.readImageSize(item.path);
    final thumb = await service.generateImageThumb(item.path, item.memoId);
    await _ref.read(memoRepositoryProvider).upsertMedia(item.copyWith(
          width: size?.width,
          height: size?.height,
          thumbPath: thumb,
        ));
    return item.path;
  }

  Future<void> _refreshCount(String memoId) async {
    final repo = _ref.read(memoRepositoryProvider);
    final items = await repo.mediaOf(memoId);
    final memo = await repo.findById(memoId);
    if (memo != null) {
      String? thumb;
      if (items.isNotEmpty) {
        final firstImage = items
            .where((e) => e.kind == MediaKind.image)
            .cast<MediaItem?>()
            .firstWhere((_) => true, orElse: () => null);
        thumb = (firstImage ?? items.first).thumbPath;
      }
      await repo.save(memo.copyWith(
        thumbnailPath: thumb,
        metadata: {...memo.metadata, 'count': items.length},
      ));
    }
  }

  /// 打包全部媒体路径，供分享。
  Future<List<String>> allPaths(String memoId) async {
    final items = await _ref.read(memoRepositoryProvider).mediaOf(memoId);
    return items.map((e) => e.path).toList();
  }
}

final mediaControllerProvider =
    Provider<MediaController>((ref) => MediaController(ref));
