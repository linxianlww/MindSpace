import 'package:drift/drift.dart';

/// Drift 表定义。
///
/// 设计要点：
/// - 主键统一为 TEXT(UUID)；
/// - 时间统一为 INTEGER（毫秒时间戳），与 Freezed 模型一致；
/// - 显式 [DataClassName]，避免 drift 名单数化与 UI 的 Font/Tag 等类型撞名；
/// - 所有“删除”默认写 deletedAt 软删除，设置里可彻底清理。

/// 文件夹表。
@DataClassName('FolderRow')
class FolderRows extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get parentId => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 铭记表（通用元数据；正文/媒体等真实内容在文件系统）。
@DataClassName('MemoRow')
class MemoRows extends Table {
  TextColumn get id => text()();
  TextColumn get folderId => text().nullable()();
  TextColumn get type => text()(); // MemoType.wire
  TextColumn get title => text().withDefault(const Constant('无标题'))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get color => integer().nullable()();
  TextColumn get remark => text().nullable()();
  TextColumn get fontId => text().nullable()();
  TextColumn get thumbnailPath => text().nullable()();
  TextColumn get metadataJson => text().withDefault(const Constant('{}'))();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 媒体集条目表。
@DataClassName('MediaItemRow')
class MediaItemRows extends Table {
  TextColumn get id => text()();
  TextColumn get memoId => text()();
  TextColumn get path => text()();
  TextColumn get type => text()(); // MediaKind.wire
  TextColumn get remark => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get width => integer().nullable()();
  IntColumn get height => integer().nullable()();
  IntColumn get duration => integer().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 音频字幕表。
@DataClassName('AudioSubtitleRow')
class AudioSubtitleRows extends Table {
  TextColumn get id => text()();
  TextColumn get memoId => text()();
  IntColumn get startMs => integer()();
  IntColumn get endMs => integer()();
  // 注意：不能命名为 text，否则会遮蔽 drift DSL 的 text() 构建方法。
  TextColumn get content => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// 字体表。
@DataClassName('FontRow')
class FontRows extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get path => text()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 标签表。
@DataClassName('TagRow')
class TagRows extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get color => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 铭记-标签 多对多关联表。
@DataClassName('MemoTagRow')
class MemoTagRows extends Table {
  TextColumn get memoId => text()();
  TextColumn get tagId => text()();

  @override
  Set<Column> get primaryKey => {memoId, tagId};
}
