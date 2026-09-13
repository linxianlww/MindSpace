import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/mindspace_tables.dart';

part 'asset_dao.g.dart';

/// 资产类数据访问：媒体条目、音频字幕、字体、标签。
@DriftAccessor(tables: [
  MediaItemRows,
  AudioSubtitleRows,
  FontRows,
  TagRows,
  MemoTagRows,
])
class AssetDao extends DatabaseAccessor<AppDatabase> with _$AssetDaoMixin {
  AssetDao(super.db);

  // —————— 媒体条目 ——————
  Stream<List<MediaItemRow>> watchMedia(String memoId) {
    return (select(mediaItemRows)
          ..where((t) => t.memoId.equals(memoId))
          ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
        .watch();
  }

  Future<List<MediaItemRow>> mediaOf(String memoId) {
    return (select(mediaItemRows)
          ..where((t) => t.memoId.equals(memoId))
          ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
        .get();
  }

  Future<void> upsertMedia(MediaItemRowsCompanion entry) =>
      into(mediaItemRows).insertOnConflictUpdate(entry);

  Future<void> deleteMedia(String id) =>
      (delete(mediaItemRows)..where((t) => t.id.equals(id))).go();

  Future<void> deleteMediaOfMemo(String memoId) =>
      (delete(mediaItemRows)..where((t) => t.memoId.equals(memoId))).go();

  // —————— 音频字幕 ——————
  Future<List<AudioSubtitleRow>> subtitlesOf(String memoId) {
    return (select(audioSubtitleRows)
          ..where((t) => t.memoId.equals(memoId))
          ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
        .get();
  }

  /// 整组替换字幕（解析新字幕后调用，事务保证原子）。
  Future<void> replaceSubtitles(
      String memoId, List<AudioSubtitleRowsCompanion> rows) {
    return transaction(() async {
      await (delete(audioSubtitleRows)
            ..where((t) => t.memoId.equals(memoId)))
          .go();
      for (final r in rows) {
        await into(audioSubtitleRows).insertOnConflictUpdate(r);
      }
    });
  }

  // —————— 字体 ——————
  Stream<List<FontRow>> watchFonts() {
    return (select(fontRows)
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
        .watch();
  }

  Future<List<FontRow>> allFonts() => select(fontRows).get();

  Future<void> upsertFont(FontRowsCompanion entry) =>
      into(fontRows).insertOnConflictUpdate(entry);

  Future<void> deleteFont(String id) =>
      (delete(fontRows)..where((t) => t.id.equals(id))).go();

  // —————— 标签 ——————
  Future<List<TagRow>> allTags() => select(tagRows).get();

  Future<void> upsertTag(TagRowsCompanion entry) =>
      into(tagRows).insertOnConflictUpdate(entry);

  Future<void> deleteTag(String id) => transaction(() async {
        await (delete(memoTagRows)..where((t) => t.tagId.equals(id))).go();
        await (delete(tagRows)..where((t) => t.id.equals(id))).go();
      });

  Future<void> setMemoTags(String memoId, List<String> tagIds) =>
      transaction(() async {
        await (delete(memoTagRows)..where((t) => t.memoId.equals(memoId))).go();
        for (final tagId in tagIds) {
          await into(memoTagRows).insertOnConflictUpdate(
            MemoTagRowsCompanion(memoId: Value(memoId), tagId: Value(tagId)),
          );
        }
      });

  Future<List<TagRow>> tagsOfMemo(String memoId) {
    final q = select(tagRows).join([
      innerJoin(memoTagRows, memoTagRows.tagId.equalsExp(tagRows.id)),
    ])
      ..where(memoTagRows.memoId.equals(memoId));
    return q.map((r) => r.readTable(tagRows)).get();
  }
}
