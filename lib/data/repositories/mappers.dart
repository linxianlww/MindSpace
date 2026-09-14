import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';
import '../models/folder.dart';
import '../models/media_item.dart';
import '../models/memo.dart';
import '../models/memo_type.dart';
import '../models/font_asset.dart';
import '../models/subtitle_item.dart';

/// Drift 行对象 <-> Freezed 领域模型 的双向映射。
///
/// UI/业务层只认识 Freezed 模型，不直接依赖 Drift 生成类。
class Mappers {
  const Mappers._();

  // —— Folder ——
  static Folder folderRow(FolderRow r) => Folder(
        id: r.id,
        name: r.name,
        parentId: r.parentId,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
        sortOrder: r.sortOrder,
        deletedAt: r.deletedAt,
      );

  static FolderRowsCompanion folderToCompanion(Folder f) =>
      FolderRowsCompanion.insert(
        id: f.id,
        name: f.name,
        parentId: Value(f.parentId),
        createdAt: f.createdAt,
        updatedAt: f.updatedAt,
        sortOrder: Value(f.sortOrder),
        deletedAt: Value(f.deletedAt),
      );

  // —— Memo ——
  static Memo memoRow(MemoRow r) {
    Map<String, dynamic> meta = const {};
    try {
      final decoded = jsonDecode(r.metadataJson);
      if (decoded is Map<String, dynamic>) meta = decoded;
    } catch (_) {
      meta = const {};
    }
    final tags = (meta['tags'] as List?)?.map((e) => '$e').toList() ??
        const <String>[];
    return Memo(
      id: r.id,
      folderId: r.folderId,
      type: MemoType.fromWire(r.type),
      title: r.title,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
      color: r.color,
      remark: r.remark,
      fontId: r.fontId,
      thumbnailPath: r.thumbnailPath,
      tags: List<String>.from(tags),
      metadata: Map<String, dynamic>.from(meta)..remove('tags'),
      deletedAt: r.deletedAt,
    );
  }

  static MemoRowsCompanion memoToCompanion(Memo m) {
    // tags 冗余进 metadataJson 一起持久化，避免频繁联表。
    final meta = Map<String, dynamic>.from(m.metadata)..['tags'] = m.tags;
    return MemoRowsCompanion.insert(
      id: m.id,
      folderId: Value(m.folderId),
      type: m.type.wire,
      title: Value(m.title),
      createdAt: m.createdAt,
      updatedAt: m.updatedAt,
      color: Value(m.color),
      remark: Value(m.remark),
      fontId: Value(m.fontId),
      thumbnailPath: Value(m.thumbnailPath),
      metadataJson: Value(jsonEncode(meta)),
      deletedAt: Value(m.deletedAt),
    );
  }

  // —— MediaItem ——
  static MediaItem mediaRow(MediaItemRow r) => MediaItem(
        id: r.id,
        memoId: r.memoId,
        path: r.path,
        kind: MediaKind.fromWire(r.type),
        remark: r.remark,
        sortOrder: r.sortOrder,
        width: r.width,
        height: r.height,
        durationMs: r.duration,
        thumbPath: r.thumbPath,
        createdAt: r.createdAt,
      );

  static MediaItemRowsCompanion mediaToCompanion(MediaItem i) =>
      MediaItemRowsCompanion.insert(
        id: i.id,
        memoId: i.memoId,
        path: i.path,
        type: i.kind.wire,
        remark: Value(i.remark),
        sortOrder: Value(i.sortOrder),
        width: Value(i.width),
        height: Value(i.height),
        duration: Value(i.durationMs),
        thumbPath: Value(i.thumbPath),
        createdAt: i.createdAt,
      );

  // —— Subtitle ——
  static SubtitleItem subtitleRow(AudioSubtitleRow r) => SubtitleItem(
        id: r.id,
        memoId: r.memoId,
        startMs: r.startMs,
        endMs: r.endMs,
        text: r.content,
        sortOrder: r.sortOrder,
      );

  // —— Font ——
  static FontAsset fontRow(FontRow r) => FontAsset(
        id: r.id,
        name: r.name,
        path: r.path,
        createdAt: r.createdAt,
      );
}
