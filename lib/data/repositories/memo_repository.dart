import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../core/database/app_database.dart';
import '../../core/storage/mindspace_storage.dart';
import '../../core/utils/markdown_delta.dart';
import '../../core/utils/ms_date_utils.dart';
import '../../core/utils/uuid_utils.dart';
import '../datasources/file_system_datasource.dart';
import '../datasources/local_database_datasource.dart';
import '../models/media_item.dart';
import '../models/memo.dart';
import '../models/memo_type.dart';
import '../models/subtitle_item.dart';
import 'mappers.dart';

/// 铭记仓库：统一维护 Drift 元数据、meta.json 与类型专属内容。
class MemoRepository {
  MemoRepository(this._db, this._fs);

  final LocalDatabaseDatasource _db;
  final FileSystemDatasource _fs;

  // —————— 列表 / 查询 ——————
  Stream<List<Memo>> watchByFolder(
    String? folderId, {
    String sortField = 'updatedAt',
    bool ascending = false,
  }) {
    return _db.memos
        .watchByFolder(folderId,
            sortField: sortField, ascending: ascending)
        .map((rows) => rows.map(Mappers.memoRow).toList());
  }

  Stream<List<Memo>> watchSearch(String keyword) {
    final kw = keyword.trim();
    return _db.memos.watchSearch(kw).asyncMap((rows) async {
      final found = <String, Memo>{
        for (final r in rows) r.id: Mappers.memoRow(r),
      };
      // 文本型铭记的正文存于磁盘（content.md / content.txt），不在数据库
      // 列中，这里补充扫描正文内容，保证全文搜索能命中正文。
      final textRows =
          await _db.memos.activeOfType(MemoType.text.wire);
      for (final r in textRows) {
        if (found.containsKey(r.id)) continue;
        final memo = Mappers.memoRow(r);
        final content = await _textContent(memo);
        if (content.toLowerCase().contains(kw.toLowerCase())) {
          found[memo.id] = memo;
        }
      }
      final list = found.values.toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    });
  }

  /// 读取文本型铭记的正文（优先 content.delta.json 实时转纯文本，
  /// 兼容旧数据的 content.md/content.txt，最后回退摘要）。
  Future<String> _textContent(Memo memo) async {
    final dir = MindspaceStorage.instance
        .memoDir(memoId: memo.id, folderId: memo.folderId);
    final deltaPath = p.join(dir, 'content.delta.json');
    if (_fs.exists(deltaPath)) {
      try {
        final raw = await _fs.readString(deltaPath);
        final decoded = jsonDecode(raw);
        if (decoded is List<dynamic>) {
          return MarkdownDelta.toPlainText(decoded);
        }
      } catch (_) {
        // delta 损坏则继续尝试旧文件。
      }
    }
    for (final name in const ['content.md', 'content.txt']) {
      final path = p.join(dir, name);
      if (_fs.exists(path)) {
        try {
          return await _fs.readString(path);
        } catch (_) {
          // 读取失败则尝试下一个文件。
        }
      }
    }
    final excerpt = memo.metadata['excerpt'];
    return excerpt is String ? excerpt : '';
  }

  Stream<List<Memo>> watchTrash() => _db.memos
      .watchTrash()
      .map((rows) => rows.map(Mappers.memoRow).toList());

  Future<Memo?> findById(String id) async {
    final row = await _db.memos.getById(id);
    return row == null ? null : Mappers.memoRow(row);
  }

  /// 某类型下所有未删除铭记（如扫描媒体集缩略图时使用）。
  Future<List<Memo>> activeByType(MemoType type) async {
    final rows = await _db.memos.activeOfType(type.wire);
    return rows.map(Mappers.memoRow).toList();
  }

  // —————— 创建 / 保存 ——————

  /// 创建一个空白铭记：建目录、写 meta.json、写数据库。
  Future<Memo> createBlank(
    MemoType type, {
    String? folderId,
    String title = '无标题',
  }) async {
    final now = MsDateUtils.nowMs();
    final memo = Memo(
      id: UuidUtils.newId(),
      folderId: folderId,
      type: type,
      title: title,
      createdAt: now,
      updatedAt: now,
    );
    final dir = MindspaceStorage.instance
        .memoDir(memoId: memo.id, folderId: folderId);
    _fs.ensureDir(dir);
    await _persistMeta(memo);
    await _db.memos.upsert(Mappers.memoToCompanion(memo));
    return memo;
  }

  /// 保存元数据改动（同步刷新 meta.json 与数据库）。
  Future<Memo> save(Memo memo) async {
    final updated = memo.copyWith(updatedAt: MsDateUtils.nowMs());
    await _persistMeta(updated);
    await _db.memos.upsert(Mappers.memoToCompanion(updated));
    return updated;
  }

  Future<void> rename(String id, String title) async {
    await _db.memos.rename(id, title, MsDateUtils.nowMs());
    final memo = await findById(id);
    if (memo != null) await _persistMeta(memo.copyWith(title: title));
  }

  Future<void> setAppearance(String id, {int? color, String? remark}) =>
      _db.memos.updateAppearance(id, color: color, remark: remark);

  /// 仅刷新类型专属元数据（如时长、页数、波形等）。
  Future<void> updateMetadata(
      String id, Map<String, dynamic> metadata,
      {String? thumbnailPath}) async {
    final memo = await findById(id);
    if (memo == null) return;
    final merged = Map<String, dynamic>.from(memo.metadata)..addAll(metadata);
    final next = memo.copyWith(
      metadata: merged,
      thumbnailPath: thumbnailPath ?? memo.thumbnailPath,
    );
    await save(next);
  }

  Future<void> _persistMeta(Memo memo) async {
    final path = MindspaceStorage.instance.metaPath(
      memoId: memo.id,
      folderId: memo.folderId,
    );
    final json = {
      'id': memo.id,
      'type': memo.type.wire,
      'title': memo.title,
      'createdAt': memo.createdAt,
      'updatedAt': memo.updatedAt,
      'color': memo.color,
      'remark': memo.remark,
      'fontId': memo.fontId,
      'tags': memo.tags,
      ...memo.metadata,
    };
    await _fs.writeJson(path, json);
  }

  // —————— 移动 / 删除 ——————

  /// 移动到另一文件夹（或根）：数据库改 folderId，磁盘目录整体迁移。
  Future<void> moveToFolder(String id, String? targetFolderId) async {
    final memo = await findById(id);
    if (memo == null) return;
    if (memo.folderId == targetFolderId) return;
    await MindspaceStorage.instance.moveMemoDirectory(
      memoId: id,
      fromFolderId: memo.folderId,
      toFolderId: targetFolderId,
    );
    await _db.memos.move(id, targetFolderId, MsDateUtils.nowMs());
  }

  Future<void> softDelete(String id) =>
      _db.memos.softDelete(id, MsDateUtils.nowMs());

  Future<void> restore(String id) => _db.memos.restore(id);

  /// 彻底删除：数据库 + 磁盘目录。
  Future<void> hardDelete(String id) async {
    final memo = await findById(id);
    await _db.assets.deleteMediaOfMemo(id);
    if (memo != null) {
      await MindspaceStorage.instance.deleteMemoDirectory(
        memoId: id,
        folderId: memo.folderId,
      );
    }
    await _db.memos.hardDelete(id);
  }

  Future<int> emptyMemoTrash() async {
    // 先把回收站铭记的磁盘目录清掉，再批量删库。
    final trash = await _db.memos.watchTrash().first;
    for (final row in trash) {
      await MindspaceStorage.instance.deleteMemoDirectory(
        memoId: row.id,
        folderId: row.folderId,
      );
    }
    return _db.memos.hardDeleteAllTrash();
  }

  // —————— 媒体条目 ——————
  Stream<List<MediaItem>> watchMedia(String memoId) =>
      _db.assets.watchMedia(memoId).map(
            (rows) => rows.map(Mappers.mediaRow).toList(),
          );

  Future<List<MediaItem>> mediaOf(String memoId) async {
    final rows = await _db.assets.mediaOf(memoId);
    return rows.map(Mappers.mediaRow).toList();
  }

  Future<void> upsertMedia(MediaItem item) =>
      _db.assets.upsertMedia(Mappers.mediaToCompanion(item));

  Future<void> removeMedia(String mediaId) =>
      _db.assets.deleteMedia(mediaId);

  /// 拖拽排序后整体重写 sortOrder。
  Future<void> reorderMedia(String memoId, List<MediaItem> ordered) async {
    for (var i = 0; i < ordered.length; i++) {
      await upsertMedia(ordered[i].copyWith(sortOrder: i));
    }
  }

  // —————— 字幕 ——————
  Future<List<SubtitleItem>> subtitlesOf(String memoId) async {
    final rows = await _db.assets.subtitlesOf(memoId);
    return rows.map(Mappers.subtitleRow).toList();
  }

  Future<void> replaceSubtitles(List<SubtitleItem> items) async {
    final companions = [
      for (final s in items)
        AudioSubtitleRowsCompanion.insert(
          id: s.id,
          memoId: s.memoId,
          startMs: s.startMs,
          endMs: s.endMs,
          content: s.text,
          sortOrder: Value(s.sortOrder),
        ),
    ];
    if (items.isEmpty) return;
    await _db.assets.replaceSubtitles(items.first.memoId, companions);
  }

  /// 确保音频目录存在（字幕/裁剪文件落盘前调用）。
  Future<void> ensureAudioDir(Memo memo) async {
    final path = MindspaceStorage.instance
        .audioDir(memoId: memo.id, folderId: memo.folderId);
    _fs.ensureDir(path);
  }

  // 便于备份模块读取 meta 原文。
  String encodeMeta(Map<String, dynamic> json) => jsonEncode(json);
}
