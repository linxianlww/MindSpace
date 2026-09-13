// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $FolderRowsTable extends FolderRows
    with TableInfo<$FolderRowsTable, FolderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FolderRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _parentIdMeta =
      const VerificationMeta('parentId');
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
      'parent_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, parentId, createdAt, updatedAt, sortOrder, deletedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'folder_rows';
  @override
  VerificationContext validateIntegrity(Insertable<FolderRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(_parentIdMeta,
          parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FolderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FolderRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      parentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}parent_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $FolderRowsTable createAlias(String alias) {
    return $FolderRowsTable(attachedDatabase, alias);
  }
}

class FolderRow extends DataClass implements Insertable<FolderRow> {
  final String id;
  final String name;
  final String? parentId;
  final int createdAt;
  final int updatedAt;
  final int sortOrder;
  final int? deletedAt;
  const FolderRow(
      {required this.id,
      required this.name,
      this.parentId,
      required this.createdAt,
      required this.updatedAt,
      required this.sortOrder,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  FolderRowsCompanion toCompanion(bool nullToAbsent) {
    return FolderRowsCompanion(
      id: Value(id),
      name: Value(name),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      sortOrder: Value(sortOrder),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory FolderRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FolderRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'parentId': serializer.toJson<String?>(parentId),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  FolderRow copyWith(
          {String? id,
          String? name,
          Value<String?> parentId = const Value.absent(),
          int? createdAt,
          int? updatedAt,
          int? sortOrder,
          Value<int?> deletedAt = const Value.absent()}) =>
      FolderRow(
        id: id ?? this.id,
        name: name ?? this.name,
        parentId: parentId.present ? parentId.value : this.parentId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        sortOrder: sortOrder ?? this.sortOrder,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  FolderRow copyWithCompanion(FolderRowsCompanion data) {
    return FolderRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FolderRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, name, parentId, createdAt, updatedAt, sortOrder, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FolderRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.parentId == this.parentId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.sortOrder == this.sortOrder &&
          other.deletedAt == this.deletedAt);
}

class FolderRowsCompanion extends UpdateCompanion<FolderRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> parentId;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> sortOrder;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const FolderRowsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.parentId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FolderRowsCompanion.insert({
    required String id,
    required String name,
    this.parentId = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.sortOrder = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<FolderRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? parentId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? sortOrder,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (parentId != null) 'parent_id': parentId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FolderRowsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? parentId,
      Value<int>? createdAt,
      Value<int>? updatedAt,
      Value<int>? sortOrder,
      Value<int?>? deletedAt,
      Value<int>? rowid}) {
    return FolderRowsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sortOrder: sortOrder ?? this.sortOrder,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FolderRowsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MemoRowsTable extends MemoRows with TableInfo<$MemoRowsTable, MemoRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MemoRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _folderIdMeta =
      const VerificationMeta('folderId');
  @override
  late final GeneratedColumn<String> folderId = GeneratedColumn<String>(
      'folder_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('无标题'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
      'color', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _remarkMeta = const VerificationMeta('remark');
  @override
  late final GeneratedColumn<String> remark = GeneratedColumn<String>(
      'remark', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _fontIdMeta = const VerificationMeta('fontId');
  @override
  late final GeneratedColumn<String> fontId = GeneratedColumn<String>(
      'font_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _thumbnailPathMeta =
      const VerificationMeta('thumbnailPath');
  @override
  late final GeneratedColumn<String> thumbnailPath = GeneratedColumn<String>(
      'thumbnail_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _metadataJsonMeta =
      const VerificationMeta('metadataJson');
  @override
  late final GeneratedColumn<String> metadataJson = GeneratedColumn<String>(
      'metadata_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        folderId,
        type,
        title,
        createdAt,
        updatedAt,
        color,
        remark,
        fontId,
        thumbnailPath,
        metadataJson,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'memo_rows';
  @override
  VerificationContext validateIntegrity(Insertable<MemoRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('folder_id')) {
      context.handle(_folderIdMeta,
          folderId.isAcceptableOrUnknown(data['folder_id']!, _folderIdMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    if (data.containsKey('remark')) {
      context.handle(_remarkMeta,
          remark.isAcceptableOrUnknown(data['remark']!, _remarkMeta));
    }
    if (data.containsKey('font_id')) {
      context.handle(_fontIdMeta,
          fontId.isAcceptableOrUnknown(data['font_id']!, _fontIdMeta));
    }
    if (data.containsKey('thumbnail_path')) {
      context.handle(
          _thumbnailPathMeta,
          thumbnailPath.isAcceptableOrUnknown(
              data['thumbnail_path']!, _thumbnailPathMeta));
    }
    if (data.containsKey('metadata_json')) {
      context.handle(
          _metadataJsonMeta,
          metadataJson.isAcceptableOrUnknown(
              data['metadata_json']!, _metadataJsonMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MemoRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MemoRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      folderId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}folder_id']),
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}color']),
      remark: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}remark']),
      fontId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}font_id']),
      thumbnailPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}thumbnail_path']),
      metadataJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}metadata_json'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $MemoRowsTable createAlias(String alias) {
    return $MemoRowsTable(attachedDatabase, alias);
  }
}

class MemoRow extends DataClass implements Insertable<MemoRow> {
  final String id;
  final String? folderId;
  final String type;
  final String title;
  final int createdAt;
  final int updatedAt;
  final int? color;
  final String? remark;
  final String? fontId;
  final String? thumbnailPath;
  final String metadataJson;
  final int? deletedAt;
  const MemoRow(
      {required this.id,
      this.folderId,
      required this.type,
      required this.title,
      required this.createdAt,
      required this.updatedAt,
      this.color,
      this.remark,
      this.fontId,
      this.thumbnailPath,
      required this.metadataJson,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || folderId != null) {
      map['folder_id'] = Variable<String>(folderId);
    }
    map['type'] = Variable<String>(type);
    map['title'] = Variable<String>(title);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<int>(color);
    }
    if (!nullToAbsent || remark != null) {
      map['remark'] = Variable<String>(remark);
    }
    if (!nullToAbsent || fontId != null) {
      map['font_id'] = Variable<String>(fontId);
    }
    if (!nullToAbsent || thumbnailPath != null) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath);
    }
    map['metadata_json'] = Variable<String>(metadataJson);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  MemoRowsCompanion toCompanion(bool nullToAbsent) {
    return MemoRowsCompanion(
      id: Value(id),
      folderId: folderId == null && nullToAbsent
          ? const Value.absent()
          : Value(folderId),
      type: Value(type),
      title: Value(title),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      color:
          color == null && nullToAbsent ? const Value.absent() : Value(color),
      remark:
          remark == null && nullToAbsent ? const Value.absent() : Value(remark),
      fontId:
          fontId == null && nullToAbsent ? const Value.absent() : Value(fontId),
      thumbnailPath: thumbnailPath == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailPath),
      metadataJson: Value(metadataJson),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory MemoRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MemoRow(
      id: serializer.fromJson<String>(json['id']),
      folderId: serializer.fromJson<String?>(json['folderId']),
      type: serializer.fromJson<String>(json['type']),
      title: serializer.fromJson<String>(json['title']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      color: serializer.fromJson<int?>(json['color']),
      remark: serializer.fromJson<String?>(json['remark']),
      fontId: serializer.fromJson<String?>(json['fontId']),
      thumbnailPath: serializer.fromJson<String?>(json['thumbnailPath']),
      metadataJson: serializer.fromJson<String>(json['metadataJson']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'folderId': serializer.toJson<String?>(folderId),
      'type': serializer.toJson<String>(type),
      'title': serializer.toJson<String>(title),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'color': serializer.toJson<int?>(color),
      'remark': serializer.toJson<String?>(remark),
      'fontId': serializer.toJson<String?>(fontId),
      'thumbnailPath': serializer.toJson<String?>(thumbnailPath),
      'metadataJson': serializer.toJson<String>(metadataJson),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  MemoRow copyWith(
          {String? id,
          Value<String?> folderId = const Value.absent(),
          String? type,
          String? title,
          int? createdAt,
          int? updatedAt,
          Value<int?> color = const Value.absent(),
          Value<String?> remark = const Value.absent(),
          Value<String?> fontId = const Value.absent(),
          Value<String?> thumbnailPath = const Value.absent(),
          String? metadataJson,
          Value<int?> deletedAt = const Value.absent()}) =>
      MemoRow(
        id: id ?? this.id,
        folderId: folderId.present ? folderId.value : this.folderId,
        type: type ?? this.type,
        title: title ?? this.title,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        color: color.present ? color.value : this.color,
        remark: remark.present ? remark.value : this.remark,
        fontId: fontId.present ? fontId.value : this.fontId,
        thumbnailPath:
            thumbnailPath.present ? thumbnailPath.value : this.thumbnailPath,
        metadataJson: metadataJson ?? this.metadataJson,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  MemoRow copyWithCompanion(MemoRowsCompanion data) {
    return MemoRow(
      id: data.id.present ? data.id.value : this.id,
      folderId: data.folderId.present ? data.folderId.value : this.folderId,
      type: data.type.present ? data.type.value : this.type,
      title: data.title.present ? data.title.value : this.title,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      color: data.color.present ? data.color.value : this.color,
      remark: data.remark.present ? data.remark.value : this.remark,
      fontId: data.fontId.present ? data.fontId.value : this.fontId,
      thumbnailPath: data.thumbnailPath.present
          ? data.thumbnailPath.value
          : this.thumbnailPath,
      metadataJson: data.metadataJson.present
          ? data.metadataJson.value
          : this.metadataJson,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MemoRow(')
          ..write('id: $id, ')
          ..write('folderId: $folderId, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('color: $color, ')
          ..write('remark: $remark, ')
          ..write('fontId: $fontId, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, folderId, type, title, createdAt,
      updatedAt, color, remark, fontId, thumbnailPath, metadataJson, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemoRow &&
          other.id == this.id &&
          other.folderId == this.folderId &&
          other.type == this.type &&
          other.title == this.title &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.color == this.color &&
          other.remark == this.remark &&
          other.fontId == this.fontId &&
          other.thumbnailPath == this.thumbnailPath &&
          other.metadataJson == this.metadataJson &&
          other.deletedAt == this.deletedAt);
}

class MemoRowsCompanion extends UpdateCompanion<MemoRow> {
  final Value<String> id;
  final Value<String?> folderId;
  final Value<String> type;
  final Value<String> title;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> color;
  final Value<String?> remark;
  final Value<String?> fontId;
  final Value<String?> thumbnailPath;
  final Value<String> metadataJson;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const MemoRowsCompanion({
    this.id = const Value.absent(),
    this.folderId = const Value.absent(),
    this.type = const Value.absent(),
    this.title = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.color = const Value.absent(),
    this.remark = const Value.absent(),
    this.fontId = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    this.metadataJson = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MemoRowsCompanion.insert({
    required String id,
    this.folderId = const Value.absent(),
    required String type,
    this.title = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.color = const Value.absent(),
    this.remark = const Value.absent(),
    this.fontId = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    this.metadataJson = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        type = Value(type),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<MemoRow> custom({
    Expression<String>? id,
    Expression<String>? folderId,
    Expression<String>? type,
    Expression<String>? title,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? color,
    Expression<String>? remark,
    Expression<String>? fontId,
    Expression<String>? thumbnailPath,
    Expression<String>? metadataJson,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (folderId != null) 'folder_id': folderId,
      if (type != null) 'type': type,
      if (title != null) 'title': title,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (color != null) 'color': color,
      if (remark != null) 'remark': remark,
      if (fontId != null) 'font_id': fontId,
      if (thumbnailPath != null) 'thumbnail_path': thumbnailPath,
      if (metadataJson != null) 'metadata_json': metadataJson,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MemoRowsCompanion copyWith(
      {Value<String>? id,
      Value<String?>? folderId,
      Value<String>? type,
      Value<String>? title,
      Value<int>? createdAt,
      Value<int>? updatedAt,
      Value<int?>? color,
      Value<String?>? remark,
      Value<String?>? fontId,
      Value<String?>? thumbnailPath,
      Value<String>? metadataJson,
      Value<int?>? deletedAt,
      Value<int>? rowid}) {
    return MemoRowsCompanion(
      id: id ?? this.id,
      folderId: folderId ?? this.folderId,
      type: type ?? this.type,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      color: color ?? this.color,
      remark: remark ?? this.remark,
      fontId: fontId ?? this.fontId,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      metadataJson: metadataJson ?? this.metadataJson,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (folderId.present) {
      map['folder_id'] = Variable<String>(folderId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (remark.present) {
      map['remark'] = Variable<String>(remark.value);
    }
    if (fontId.present) {
      map['font_id'] = Variable<String>(fontId.value);
    }
    if (thumbnailPath.present) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath.value);
    }
    if (metadataJson.present) {
      map['metadata_json'] = Variable<String>(metadataJson.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MemoRowsCompanion(')
          ..write('id: $id, ')
          ..write('folderId: $folderId, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('color: $color, ')
          ..write('remark: $remark, ')
          ..write('fontId: $fontId, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MediaItemRowsTable extends MediaItemRows
    with TableInfo<$MediaItemRowsTable, MediaItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaItemRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _memoIdMeta = const VerificationMeta('memoId');
  @override
  late final GeneratedColumn<String> memoId = GeneratedColumn<String>(
      'memo_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
      'path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _remarkMeta = const VerificationMeta('remark');
  @override
  late final GeneratedColumn<String> remark = GeneratedColumn<String>(
      'remark', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
      'width', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
      'height', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _durationMeta =
      const VerificationMeta('duration');
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
      'duration', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        memoId,
        path,
        type,
        remark,
        sortOrder,
        width,
        height,
        duration,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_item_rows';
  @override
  VerificationContext validateIntegrity(Insertable<MediaItemRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('memo_id')) {
      context.handle(_memoIdMeta,
          memoId.isAcceptableOrUnknown(data['memo_id']!, _memoIdMeta));
    } else if (isInserting) {
      context.missing(_memoIdMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
          _pathMeta, path.isAcceptableOrUnknown(data['path']!, _pathMeta));
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('remark')) {
      context.handle(_remarkMeta,
          remark.isAcceptableOrUnknown(data['remark']!, _remarkMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('width')) {
      context.handle(
          _widthMeta, width.isAcceptableOrUnknown(data['width']!, _widthMeta));
    }
    if (data.containsKey('height')) {
      context.handle(_heightMeta,
          height.isAcceptableOrUnknown(data['height']!, _heightMeta));
    }
    if (data.containsKey('duration')) {
      context.handle(_durationMeta,
          duration.isAcceptableOrUnknown(data['duration']!, _durationMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MediaItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaItemRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      memoId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}memo_id'])!,
      path: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}path'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      remark: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}remark']),
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      width: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}width']),
      height: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}height']),
      duration: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $MediaItemRowsTable createAlias(String alias) {
    return $MediaItemRowsTable(attachedDatabase, alias);
  }
}

class MediaItemRow extends DataClass implements Insertable<MediaItemRow> {
  final String id;
  final String memoId;
  final String path;
  final String type;
  final String? remark;
  final int sortOrder;
  final int? width;
  final int? height;
  final int? duration;
  final int createdAt;
  const MediaItemRow(
      {required this.id,
      required this.memoId,
      required this.path,
      required this.type,
      this.remark,
      required this.sortOrder,
      this.width,
      this.height,
      this.duration,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['memo_id'] = Variable<String>(memoId);
    map['path'] = Variable<String>(path);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || remark != null) {
      map['remark'] = Variable<String>(remark);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || width != null) {
      map['width'] = Variable<int>(width);
    }
    if (!nullToAbsent || height != null) {
      map['height'] = Variable<int>(height);
    }
    if (!nullToAbsent || duration != null) {
      map['duration'] = Variable<int>(duration);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  MediaItemRowsCompanion toCompanion(bool nullToAbsent) {
    return MediaItemRowsCompanion(
      id: Value(id),
      memoId: Value(memoId),
      path: Value(path),
      type: Value(type),
      remark:
          remark == null && nullToAbsent ? const Value.absent() : Value(remark),
      sortOrder: Value(sortOrder),
      width:
          width == null && nullToAbsent ? const Value.absent() : Value(width),
      height:
          height == null && nullToAbsent ? const Value.absent() : Value(height),
      duration: duration == null && nullToAbsent
          ? const Value.absent()
          : Value(duration),
      createdAt: Value(createdAt),
    );
  }

  factory MediaItemRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaItemRow(
      id: serializer.fromJson<String>(json['id']),
      memoId: serializer.fromJson<String>(json['memoId']),
      path: serializer.fromJson<String>(json['path']),
      type: serializer.fromJson<String>(json['type']),
      remark: serializer.fromJson<String?>(json['remark']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      width: serializer.fromJson<int?>(json['width']),
      height: serializer.fromJson<int?>(json['height']),
      duration: serializer.fromJson<int?>(json['duration']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'memoId': serializer.toJson<String>(memoId),
      'path': serializer.toJson<String>(path),
      'type': serializer.toJson<String>(type),
      'remark': serializer.toJson<String?>(remark),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'width': serializer.toJson<int?>(width),
      'height': serializer.toJson<int?>(height),
      'duration': serializer.toJson<int?>(duration),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  MediaItemRow copyWith(
          {String? id,
          String? memoId,
          String? path,
          String? type,
          Value<String?> remark = const Value.absent(),
          int? sortOrder,
          Value<int?> width = const Value.absent(),
          Value<int?> height = const Value.absent(),
          Value<int?> duration = const Value.absent(),
          int? createdAt}) =>
      MediaItemRow(
        id: id ?? this.id,
        memoId: memoId ?? this.memoId,
        path: path ?? this.path,
        type: type ?? this.type,
        remark: remark.present ? remark.value : this.remark,
        sortOrder: sortOrder ?? this.sortOrder,
        width: width.present ? width.value : this.width,
        height: height.present ? height.value : this.height,
        duration: duration.present ? duration.value : this.duration,
        createdAt: createdAt ?? this.createdAt,
      );
  MediaItemRow copyWithCompanion(MediaItemRowsCompanion data) {
    return MediaItemRow(
      id: data.id.present ? data.id.value : this.id,
      memoId: data.memoId.present ? data.memoId.value : this.memoId,
      path: data.path.present ? data.path.value : this.path,
      type: data.type.present ? data.type.value : this.type,
      remark: data.remark.present ? data.remark.value : this.remark,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      duration: data.duration.present ? data.duration.value : this.duration,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaItemRow(')
          ..write('id: $id, ')
          ..write('memoId: $memoId, ')
          ..write('path: $path, ')
          ..write('type: $type, ')
          ..write('remark: $remark, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('duration: $duration, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, memoId, path, type, remark, sortOrder,
      width, height, duration, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaItemRow &&
          other.id == this.id &&
          other.memoId == this.memoId &&
          other.path == this.path &&
          other.type == this.type &&
          other.remark == this.remark &&
          other.sortOrder == this.sortOrder &&
          other.width == this.width &&
          other.height == this.height &&
          other.duration == this.duration &&
          other.createdAt == this.createdAt);
}

class MediaItemRowsCompanion extends UpdateCompanion<MediaItemRow> {
  final Value<String> id;
  final Value<String> memoId;
  final Value<String> path;
  final Value<String> type;
  final Value<String?> remark;
  final Value<int> sortOrder;
  final Value<int?> width;
  final Value<int?> height;
  final Value<int?> duration;
  final Value<int> createdAt;
  final Value<int> rowid;
  const MediaItemRowsCompanion({
    this.id = const Value.absent(),
    this.memoId = const Value.absent(),
    this.path = const Value.absent(),
    this.type = const Value.absent(),
    this.remark = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.duration = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MediaItemRowsCompanion.insert({
    required String id,
    required String memoId,
    required String path,
    required String type,
    this.remark = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.duration = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        memoId = Value(memoId),
        path = Value(path),
        type = Value(type),
        createdAt = Value(createdAt);
  static Insertable<MediaItemRow> custom({
    Expression<String>? id,
    Expression<String>? memoId,
    Expression<String>? path,
    Expression<String>? type,
    Expression<String>? remark,
    Expression<int>? sortOrder,
    Expression<int>? width,
    Expression<int>? height,
    Expression<int>? duration,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (memoId != null) 'memo_id': memoId,
      if (path != null) 'path': path,
      if (type != null) 'type': type,
      if (remark != null) 'remark': remark,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (duration != null) 'duration': duration,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MediaItemRowsCompanion copyWith(
      {Value<String>? id,
      Value<String>? memoId,
      Value<String>? path,
      Value<String>? type,
      Value<String?>? remark,
      Value<int>? sortOrder,
      Value<int?>? width,
      Value<int?>? height,
      Value<int?>? duration,
      Value<int>? createdAt,
      Value<int>? rowid}) {
    return MediaItemRowsCompanion(
      id: id ?? this.id,
      memoId: memoId ?? this.memoId,
      path: path ?? this.path,
      type: type ?? this.type,
      remark: remark ?? this.remark,
      sortOrder: sortOrder ?? this.sortOrder,
      width: width ?? this.width,
      height: height ?? this.height,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (memoId.present) {
      map['memo_id'] = Variable<String>(memoId.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (remark.present) {
      map['remark'] = Variable<String>(remark.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaItemRowsCompanion(')
          ..write('id: $id, ')
          ..write('memoId: $memoId, ')
          ..write('path: $path, ')
          ..write('type: $type, ')
          ..write('remark: $remark, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('duration: $duration, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AudioSubtitleRowsTable extends AudioSubtitleRows
    with TableInfo<$AudioSubtitleRowsTable, AudioSubtitleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AudioSubtitleRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _memoIdMeta = const VerificationMeta('memoId');
  @override
  late final GeneratedColumn<String> memoId = GeneratedColumn<String>(
      'memo_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _startMsMeta =
      const VerificationMeta('startMs');
  @override
  late final GeneratedColumn<int> startMs = GeneratedColumn<int>(
      'start_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _endMsMeta = const VerificationMeta('endMs');
  @override
  late final GeneratedColumn<int> endMs = GeneratedColumn<int>(
      'end_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns =>
      [id, memoId, startMs, endMs, content, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audio_subtitle_rows';
  @override
  VerificationContext validateIntegrity(Insertable<AudioSubtitleRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('memo_id')) {
      context.handle(_memoIdMeta,
          memoId.isAcceptableOrUnknown(data['memo_id']!, _memoIdMeta));
    } else if (isInserting) {
      context.missing(_memoIdMeta);
    }
    if (data.containsKey('start_ms')) {
      context.handle(_startMsMeta,
          startMs.isAcceptableOrUnknown(data['start_ms']!, _startMsMeta));
    } else if (isInserting) {
      context.missing(_startMsMeta);
    }
    if (data.containsKey('end_ms')) {
      context.handle(
          _endMsMeta, endMs.isAcceptableOrUnknown(data['end_ms']!, _endMsMeta));
    } else if (isInserting) {
      context.missing(_endMsMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AudioSubtitleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AudioSubtitleRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      memoId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}memo_id'])!,
      startMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}start_ms'])!,
      endMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}end_ms'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
    );
  }

  @override
  $AudioSubtitleRowsTable createAlias(String alias) {
    return $AudioSubtitleRowsTable(attachedDatabase, alias);
  }
}

class AudioSubtitleRow extends DataClass
    implements Insertable<AudioSubtitleRow> {
  final String id;
  final String memoId;
  final int startMs;
  final int endMs;
  final String content;
  final int sortOrder;
  const AudioSubtitleRow(
      {required this.id,
      required this.memoId,
      required this.startMs,
      required this.endMs,
      required this.content,
      required this.sortOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['memo_id'] = Variable<String>(memoId);
    map['start_ms'] = Variable<int>(startMs);
    map['end_ms'] = Variable<int>(endMs);
    map['content'] = Variable<String>(content);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  AudioSubtitleRowsCompanion toCompanion(bool nullToAbsent) {
    return AudioSubtitleRowsCompanion(
      id: Value(id),
      memoId: Value(memoId),
      startMs: Value(startMs),
      endMs: Value(endMs),
      content: Value(content),
      sortOrder: Value(sortOrder),
    );
  }

  factory AudioSubtitleRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AudioSubtitleRow(
      id: serializer.fromJson<String>(json['id']),
      memoId: serializer.fromJson<String>(json['memoId']),
      startMs: serializer.fromJson<int>(json['startMs']),
      endMs: serializer.fromJson<int>(json['endMs']),
      content: serializer.fromJson<String>(json['content']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'memoId': serializer.toJson<String>(memoId),
      'startMs': serializer.toJson<int>(startMs),
      'endMs': serializer.toJson<int>(endMs),
      'content': serializer.toJson<String>(content),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  AudioSubtitleRow copyWith(
          {String? id,
          String? memoId,
          int? startMs,
          int? endMs,
          String? content,
          int? sortOrder}) =>
      AudioSubtitleRow(
        id: id ?? this.id,
        memoId: memoId ?? this.memoId,
        startMs: startMs ?? this.startMs,
        endMs: endMs ?? this.endMs,
        content: content ?? this.content,
        sortOrder: sortOrder ?? this.sortOrder,
      );
  AudioSubtitleRow copyWithCompanion(AudioSubtitleRowsCompanion data) {
    return AudioSubtitleRow(
      id: data.id.present ? data.id.value : this.id,
      memoId: data.memoId.present ? data.memoId.value : this.memoId,
      startMs: data.startMs.present ? data.startMs.value : this.startMs,
      endMs: data.endMs.present ? data.endMs.value : this.endMs,
      content: data.content.present ? data.content.value : this.content,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AudioSubtitleRow(')
          ..write('id: $id, ')
          ..write('memoId: $memoId, ')
          ..write('startMs: $startMs, ')
          ..write('endMs: $endMs, ')
          ..write('content: $content, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, memoId, startMs, endMs, content, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AudioSubtitleRow &&
          other.id == this.id &&
          other.memoId == this.memoId &&
          other.startMs == this.startMs &&
          other.endMs == this.endMs &&
          other.content == this.content &&
          other.sortOrder == this.sortOrder);
}

class AudioSubtitleRowsCompanion extends UpdateCompanion<AudioSubtitleRow> {
  final Value<String> id;
  final Value<String> memoId;
  final Value<int> startMs;
  final Value<int> endMs;
  final Value<String> content;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const AudioSubtitleRowsCompanion({
    this.id = const Value.absent(),
    this.memoId = const Value.absent(),
    this.startMs = const Value.absent(),
    this.endMs = const Value.absent(),
    this.content = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AudioSubtitleRowsCompanion.insert({
    required String id,
    required String memoId,
    required int startMs,
    required int endMs,
    required String content,
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        memoId = Value(memoId),
        startMs = Value(startMs),
        endMs = Value(endMs),
        content = Value(content);
  static Insertable<AudioSubtitleRow> custom({
    Expression<String>? id,
    Expression<String>? memoId,
    Expression<int>? startMs,
    Expression<int>? endMs,
    Expression<String>? content,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (memoId != null) 'memo_id': memoId,
      if (startMs != null) 'start_ms': startMs,
      if (endMs != null) 'end_ms': endMs,
      if (content != null) 'content': content,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AudioSubtitleRowsCompanion copyWith(
      {Value<String>? id,
      Value<String>? memoId,
      Value<int>? startMs,
      Value<int>? endMs,
      Value<String>? content,
      Value<int>? sortOrder,
      Value<int>? rowid}) {
    return AudioSubtitleRowsCompanion(
      id: id ?? this.id,
      memoId: memoId ?? this.memoId,
      startMs: startMs ?? this.startMs,
      endMs: endMs ?? this.endMs,
      content: content ?? this.content,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (memoId.present) {
      map['memo_id'] = Variable<String>(memoId.value);
    }
    if (startMs.present) {
      map['start_ms'] = Variable<int>(startMs.value);
    }
    if (endMs.present) {
      map['end_ms'] = Variable<int>(endMs.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AudioSubtitleRowsCompanion(')
          ..write('id: $id, ')
          ..write('memoId: $memoId, ')
          ..write('startMs: $startMs, ')
          ..write('endMs: $endMs, ')
          ..write('content: $content, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FontRowsTable extends FontRows with TableInfo<$FontRowsTable, FontRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FontRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
      'path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, name, path, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'font_rows';
  @override
  VerificationContext validateIntegrity(Insertable<FontRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
          _pathMeta, path.isAcceptableOrUnknown(data['path']!, _pathMeta));
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FontRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FontRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      path: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}path'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $FontRowsTable createAlias(String alias) {
    return $FontRowsTable(attachedDatabase, alias);
  }
}

class FontRow extends DataClass implements Insertable<FontRow> {
  final String id;
  final String name;
  final String path;
  final int createdAt;
  const FontRow(
      {required this.id,
      required this.name,
      required this.path,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['path'] = Variable<String>(path);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  FontRowsCompanion toCompanion(bool nullToAbsent) {
    return FontRowsCompanion(
      id: Value(id),
      name: Value(name),
      path: Value(path),
      createdAt: Value(createdAt),
    );
  }

  factory FontRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FontRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      path: serializer.fromJson<String>(json['path']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'path': serializer.toJson<String>(path),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  FontRow copyWith({String? id, String? name, String? path, int? createdAt}) =>
      FontRow(
        id: id ?? this.id,
        name: name ?? this.name,
        path: path ?? this.path,
        createdAt: createdAt ?? this.createdAt,
      );
  FontRow copyWithCompanion(FontRowsCompanion data) {
    return FontRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      path: data.path.present ? data.path.value : this.path,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FontRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('path: $path, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, path, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FontRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.path == this.path &&
          other.createdAt == this.createdAt);
}

class FontRowsCompanion extends UpdateCompanion<FontRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> path;
  final Value<int> createdAt;
  final Value<int> rowid;
  const FontRowsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.path = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FontRowsCompanion.insert({
    required String id,
    required String name,
    required String path,
    required int createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        path = Value(path),
        createdAt = Value(createdAt);
  static Insertable<FontRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? path,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (path != null) 'path': path,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FontRowsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? path,
      Value<int>? createdAt,
      Value<int>? rowid}) {
    return FontRowsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FontRowsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('path: $path, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TagRowsTable extends TagRows with TableInfo<$TagRowsTable, TagRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
      'color', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [id, name, color];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tag_rows';
  @override
  VerificationContext validateIntegrity(Insertable<TagRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TagRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TagRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}color']),
    );
  }

  @override
  $TagRowsTable createAlias(String alias) {
    return $TagRowsTable(attachedDatabase, alias);
  }
}

class TagRow extends DataClass implements Insertable<TagRow> {
  final String id;
  final String name;
  final int? color;
  const TagRow({required this.id, required this.name, this.color});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<int>(color);
    }
    return map;
  }

  TagRowsCompanion toCompanion(bool nullToAbsent) {
    return TagRowsCompanion(
      id: Value(id),
      name: Value(name),
      color:
          color == null && nullToAbsent ? const Value.absent() : Value(color),
    );
  }

  factory TagRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TagRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<int?>(json['color']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<int?>(color),
    };
  }

  TagRow copyWith(
          {String? id,
          String? name,
          Value<int?> color = const Value.absent()}) =>
      TagRow(
        id: id ?? this.id,
        name: name ?? this.name,
        color: color.present ? color.value : this.color,
      );
  TagRow copyWithCompanion(TagRowsCompanion data) {
    return TagRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TagRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, color);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TagRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.color == this.color);
}

class TagRowsCompanion extends UpdateCompanion<TagRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<int?> color;
  final Value<int> rowid;
  const TagRowsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TagRowsCompanion.insert({
    required String id,
    required String name,
    this.color = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name);
  static Insertable<TagRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? color,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TagRowsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<int?>? color,
      Value<int>? rowid}) {
    return TagRowsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagRowsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MemoTagRowsTable extends MemoTagRows
    with TableInfo<$MemoTagRowsTable, MemoTagRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MemoTagRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _memoIdMeta = const VerificationMeta('memoId');
  @override
  late final GeneratedColumn<String> memoId = GeneratedColumn<String>(
      'memo_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<String> tagId = GeneratedColumn<String>(
      'tag_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [memoId, tagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'memo_tag_rows';
  @override
  VerificationContext validateIntegrity(Insertable<MemoTagRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('memo_id')) {
      context.handle(_memoIdMeta,
          memoId.isAcceptableOrUnknown(data['memo_id']!, _memoIdMeta));
    } else if (isInserting) {
      context.missing(_memoIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
          _tagIdMeta, tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta));
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {memoId, tagId};
  @override
  MemoTagRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MemoTagRow(
      memoId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}memo_id'])!,
      tagId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tag_id'])!,
    );
  }

  @override
  $MemoTagRowsTable createAlias(String alias) {
    return $MemoTagRowsTable(attachedDatabase, alias);
  }
}

class MemoTagRow extends DataClass implements Insertable<MemoTagRow> {
  final String memoId;
  final String tagId;
  const MemoTagRow({required this.memoId, required this.tagId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['memo_id'] = Variable<String>(memoId);
    map['tag_id'] = Variable<String>(tagId);
    return map;
  }

  MemoTagRowsCompanion toCompanion(bool nullToAbsent) {
    return MemoTagRowsCompanion(
      memoId: Value(memoId),
      tagId: Value(tagId),
    );
  }

  factory MemoTagRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MemoTagRow(
      memoId: serializer.fromJson<String>(json['memoId']),
      tagId: serializer.fromJson<String>(json['tagId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'memoId': serializer.toJson<String>(memoId),
      'tagId': serializer.toJson<String>(tagId),
    };
  }

  MemoTagRow copyWith({String? memoId, String? tagId}) => MemoTagRow(
        memoId: memoId ?? this.memoId,
        tagId: tagId ?? this.tagId,
      );
  MemoTagRow copyWithCompanion(MemoTagRowsCompanion data) {
    return MemoTagRow(
      memoId: data.memoId.present ? data.memoId.value : this.memoId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MemoTagRow(')
          ..write('memoId: $memoId, ')
          ..write('tagId: $tagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(memoId, tagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemoTagRow &&
          other.memoId == this.memoId &&
          other.tagId == this.tagId);
}

class MemoTagRowsCompanion extends UpdateCompanion<MemoTagRow> {
  final Value<String> memoId;
  final Value<String> tagId;
  final Value<int> rowid;
  const MemoTagRowsCompanion({
    this.memoId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MemoTagRowsCompanion.insert({
    required String memoId,
    required String tagId,
    this.rowid = const Value.absent(),
  })  : memoId = Value(memoId),
        tagId = Value(tagId);
  static Insertable<MemoTagRow> custom({
    Expression<String>? memoId,
    Expression<String>? tagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (memoId != null) 'memo_id': memoId,
      if (tagId != null) 'tag_id': tagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MemoTagRowsCompanion copyWith(
      {Value<String>? memoId, Value<String>? tagId, Value<int>? rowid}) {
    return MemoTagRowsCompanion(
      memoId: memoId ?? this.memoId,
      tagId: tagId ?? this.tagId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (memoId.present) {
      map['memo_id'] = Variable<String>(memoId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<String>(tagId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MemoTagRowsCompanion(')
          ..write('memoId: $memoId, ')
          ..write('tagId: $tagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $FolderRowsTable folderRows = $FolderRowsTable(this);
  late final $MemoRowsTable memoRows = $MemoRowsTable(this);
  late final $MediaItemRowsTable mediaItemRows = $MediaItemRowsTable(this);
  late final $AudioSubtitleRowsTable audioSubtitleRows =
      $AudioSubtitleRowsTable(this);
  late final $FontRowsTable fontRows = $FontRowsTable(this);
  late final $TagRowsTable tagRows = $TagRowsTable(this);
  late final $MemoTagRowsTable memoTagRows = $MemoTagRowsTable(this);
  late final FolderDao folderDao = FolderDao(this as AppDatabase);
  late final MemoDao memoDao = MemoDao(this as AppDatabase);
  late final AssetDao assetDao = AssetDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        folderRows,
        memoRows,
        mediaItemRows,
        audioSubtitleRows,
        fontRows,
        tagRows,
        memoTagRows
      ];
}

typedef $$FolderRowsTableCreateCompanionBuilder = FolderRowsCompanion Function({
  required String id,
  required String name,
  Value<String?> parentId,
  required int createdAt,
  required int updatedAt,
  Value<int> sortOrder,
  Value<int?> deletedAt,
  Value<int> rowid,
});
typedef $$FolderRowsTableUpdateCompanionBuilder = FolderRowsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> parentId,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int> sortOrder,
  Value<int?> deletedAt,
  Value<int> rowid,
});

class $$FolderRowsTableFilterComposer
    extends Composer<_$AppDatabase, $FolderRowsTable> {
  $$FolderRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get parentId => $composableBuilder(
      column: $table.parentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));
}

class $$FolderRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $FolderRowsTable> {
  $$FolderRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get parentId => $composableBuilder(
      column: $table.parentId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$FolderRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FolderRowsTable> {
  $$FolderRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$FolderRowsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FolderRowsTable,
    FolderRow,
    $$FolderRowsTableFilterComposer,
    $$FolderRowsTableOrderingComposer,
    $$FolderRowsTableAnnotationComposer,
    $$FolderRowsTableCreateCompanionBuilder,
    $$FolderRowsTableUpdateCompanionBuilder,
    (FolderRow, BaseReferences<_$AppDatabase, $FolderRowsTable, FolderRow>),
    FolderRow,
    PrefetchHooks Function()> {
  $$FolderRowsTableTableManager(_$AppDatabase db, $FolderRowsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FolderRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FolderRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FolderRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> parentId = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FolderRowsCompanion(
            id: id,
            name: name,
            parentId: parentId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            sortOrder: sortOrder,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String?> parentId = const Value.absent(),
            required int createdAt,
            required int updatedAt,
            Value<int> sortOrder = const Value.absent(),
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FolderRowsCompanion.insert(
            id: id,
            name: name,
            parentId: parentId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            sortOrder: sortOrder,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$FolderRowsTable, FolderRow>(table),
                    BaseReferences<_$AppDatabase, $FolderRowsTable, FolderRow>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FolderRowsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FolderRowsTable,
    FolderRow,
    $$FolderRowsTableFilterComposer,
    $$FolderRowsTableOrderingComposer,
    $$FolderRowsTableAnnotationComposer,
    $$FolderRowsTableCreateCompanionBuilder,
    $$FolderRowsTableUpdateCompanionBuilder,
    (FolderRow, BaseReferences<_$AppDatabase, $FolderRowsTable, FolderRow>),
    FolderRow,
    PrefetchHooks Function()>;
typedef $$MemoRowsTableCreateCompanionBuilder = MemoRowsCompanion Function({
  required String id,
  Value<String?> folderId,
  required String type,
  Value<String> title,
  required int createdAt,
  required int updatedAt,
  Value<int?> color,
  Value<String?> remark,
  Value<String?> fontId,
  Value<String?> thumbnailPath,
  Value<String> metadataJson,
  Value<int?> deletedAt,
  Value<int> rowid,
});
typedef $$MemoRowsTableUpdateCompanionBuilder = MemoRowsCompanion Function({
  Value<String> id,
  Value<String?> folderId,
  Value<String> type,
  Value<String> title,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> color,
  Value<String?> remark,
  Value<String?> fontId,
  Value<String?> thumbnailPath,
  Value<String> metadataJson,
  Value<int?> deletedAt,
  Value<int> rowid,
});

class $$MemoRowsTableFilterComposer
    extends Composer<_$AppDatabase, $MemoRowsTable> {
  $$MemoRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get folderId => $composableBuilder(
      column: $table.folderId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get remark => $composableBuilder(
      column: $table.remark, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fontId => $composableBuilder(
      column: $table.fontId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get thumbnailPath => $composableBuilder(
      column: $table.thumbnailPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get metadataJson => $composableBuilder(
      column: $table.metadataJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));
}

class $$MemoRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $MemoRowsTable> {
  $$MemoRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get folderId => $composableBuilder(
      column: $table.folderId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get remark => $composableBuilder(
      column: $table.remark, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fontId => $composableBuilder(
      column: $table.fontId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get thumbnailPath => $composableBuilder(
      column: $table.thumbnailPath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get metadataJson => $composableBuilder(
      column: $table.metadataJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$MemoRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MemoRowsTable> {
  $$MemoRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get folderId =>
      $composableBuilder(column: $table.folderId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get remark =>
      $composableBuilder(column: $table.remark, builder: (column) => column);

  GeneratedColumn<String> get fontId =>
      $composableBuilder(column: $table.fontId, builder: (column) => column);

  GeneratedColumn<String> get thumbnailPath => $composableBuilder(
      column: $table.thumbnailPath, builder: (column) => column);

  GeneratedColumn<String> get metadataJson => $composableBuilder(
      column: $table.metadataJson, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$MemoRowsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MemoRowsTable,
    MemoRow,
    $$MemoRowsTableFilterComposer,
    $$MemoRowsTableOrderingComposer,
    $$MemoRowsTableAnnotationComposer,
    $$MemoRowsTableCreateCompanionBuilder,
    $$MemoRowsTableUpdateCompanionBuilder,
    (MemoRow, BaseReferences<_$AppDatabase, $MemoRowsTable, MemoRow>),
    MemoRow,
    PrefetchHooks Function()> {
  $$MemoRowsTableTableManager(_$AppDatabase db, $MemoRowsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MemoRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MemoRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MemoRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> folderId = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int?> color = const Value.absent(),
            Value<String?> remark = const Value.absent(),
            Value<String?> fontId = const Value.absent(),
            Value<String?> thumbnailPath = const Value.absent(),
            Value<String> metadataJson = const Value.absent(),
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MemoRowsCompanion(
            id: id,
            folderId: folderId,
            type: type,
            title: title,
            createdAt: createdAt,
            updatedAt: updatedAt,
            color: color,
            remark: remark,
            fontId: fontId,
            thumbnailPath: thumbnailPath,
            metadataJson: metadataJson,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> folderId = const Value.absent(),
            required String type,
            Value<String> title = const Value.absent(),
            required int createdAt,
            required int updatedAt,
            Value<int?> color = const Value.absent(),
            Value<String?> remark = const Value.absent(),
            Value<String?> fontId = const Value.absent(),
            Value<String?> thumbnailPath = const Value.absent(),
            Value<String> metadataJson = const Value.absent(),
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MemoRowsCompanion.insert(
            id: id,
            folderId: folderId,
            type: type,
            title: title,
            createdAt: createdAt,
            updatedAt: updatedAt,
            color: color,
            remark: remark,
            fontId: fontId,
            thumbnailPath: thumbnailPath,
            metadataJson: metadataJson,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$MemoRowsTable, MemoRow>(table),
                    BaseReferences<_$AppDatabase, $MemoRowsTable, MemoRow>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MemoRowsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MemoRowsTable,
    MemoRow,
    $$MemoRowsTableFilterComposer,
    $$MemoRowsTableOrderingComposer,
    $$MemoRowsTableAnnotationComposer,
    $$MemoRowsTableCreateCompanionBuilder,
    $$MemoRowsTableUpdateCompanionBuilder,
    (MemoRow, BaseReferences<_$AppDatabase, $MemoRowsTable, MemoRow>),
    MemoRow,
    PrefetchHooks Function()>;
typedef $$MediaItemRowsTableCreateCompanionBuilder = MediaItemRowsCompanion
    Function({
  required String id,
  required String memoId,
  required String path,
  required String type,
  Value<String?> remark,
  Value<int> sortOrder,
  Value<int?> width,
  Value<int?> height,
  Value<int?> duration,
  required int createdAt,
  Value<int> rowid,
});
typedef $$MediaItemRowsTableUpdateCompanionBuilder = MediaItemRowsCompanion
    Function({
  Value<String> id,
  Value<String> memoId,
  Value<String> path,
  Value<String> type,
  Value<String?> remark,
  Value<int> sortOrder,
  Value<int?> width,
  Value<int?> height,
  Value<int?> duration,
  Value<int> createdAt,
  Value<int> rowid,
});

class $$MediaItemRowsTableFilterComposer
    extends Composer<_$AppDatabase, $MediaItemRowsTable> {
  $$MediaItemRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get memoId => $composableBuilder(
      column: $table.memoId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get path => $composableBuilder(
      column: $table.path, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get remark => $composableBuilder(
      column: $table.remark, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get width => $composableBuilder(
      column: $table.width, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get height => $composableBuilder(
      column: $table.height, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get duration => $composableBuilder(
      column: $table.duration, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$MediaItemRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $MediaItemRowsTable> {
  $$MediaItemRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get memoId => $composableBuilder(
      column: $table.memoId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get path => $composableBuilder(
      column: $table.path, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get remark => $composableBuilder(
      column: $table.remark, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get width => $composableBuilder(
      column: $table.width, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get height => $composableBuilder(
      column: $table.height, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get duration => $composableBuilder(
      column: $table.duration, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$MediaItemRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MediaItemRowsTable> {
  $$MediaItemRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get memoId =>
      $composableBuilder(column: $table.memoId, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get remark =>
      $composableBuilder(column: $table.remark, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$MediaItemRowsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MediaItemRowsTable,
    MediaItemRow,
    $$MediaItemRowsTableFilterComposer,
    $$MediaItemRowsTableOrderingComposer,
    $$MediaItemRowsTableAnnotationComposer,
    $$MediaItemRowsTableCreateCompanionBuilder,
    $$MediaItemRowsTableUpdateCompanionBuilder,
    (
      MediaItemRow,
      BaseReferences<_$AppDatabase, $MediaItemRowsTable, MediaItemRow>
    ),
    MediaItemRow,
    PrefetchHooks Function()> {
  $$MediaItemRowsTableTableManager(_$AppDatabase db, $MediaItemRowsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaItemRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaItemRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaItemRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> memoId = const Value.absent(),
            Value<String> path = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String?> remark = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int?> width = const Value.absent(),
            Value<int?> height = const Value.absent(),
            Value<int?> duration = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MediaItemRowsCompanion(
            id: id,
            memoId: memoId,
            path: path,
            type: type,
            remark: remark,
            sortOrder: sortOrder,
            width: width,
            height: height,
            duration: duration,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String memoId,
            required String path,
            required String type,
            Value<String?> remark = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int?> width = const Value.absent(),
            Value<int?> height = const Value.absent(),
            Value<int?> duration = const Value.absent(),
            required int createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              MediaItemRowsCompanion.insert(
            id: id,
            memoId: memoId,
            path: path,
            type: type,
            remark: remark,
            sortOrder: sortOrder,
            width: width,
            height: height,
            duration: duration,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$MediaItemRowsTable, MediaItemRow>(table),
                    BaseReferences<_$AppDatabase, $MediaItemRowsTable,
                        MediaItemRow>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MediaItemRowsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MediaItemRowsTable,
    MediaItemRow,
    $$MediaItemRowsTableFilterComposer,
    $$MediaItemRowsTableOrderingComposer,
    $$MediaItemRowsTableAnnotationComposer,
    $$MediaItemRowsTableCreateCompanionBuilder,
    $$MediaItemRowsTableUpdateCompanionBuilder,
    (
      MediaItemRow,
      BaseReferences<_$AppDatabase, $MediaItemRowsTable, MediaItemRow>
    ),
    MediaItemRow,
    PrefetchHooks Function()>;
typedef $$AudioSubtitleRowsTableCreateCompanionBuilder
    = AudioSubtitleRowsCompanion Function({
  required String id,
  required String memoId,
  required int startMs,
  required int endMs,
  required String content,
  Value<int> sortOrder,
  Value<int> rowid,
});
typedef $$AudioSubtitleRowsTableUpdateCompanionBuilder
    = AudioSubtitleRowsCompanion Function({
  Value<String> id,
  Value<String> memoId,
  Value<int> startMs,
  Value<int> endMs,
  Value<String> content,
  Value<int> sortOrder,
  Value<int> rowid,
});

class $$AudioSubtitleRowsTableFilterComposer
    extends Composer<_$AppDatabase, $AudioSubtitleRowsTable> {
  $$AudioSubtitleRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get memoId => $composableBuilder(
      column: $table.memoId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startMs => $composableBuilder(
      column: $table.startMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get endMs => $composableBuilder(
      column: $table.endMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));
}

class $$AudioSubtitleRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $AudioSubtitleRowsTable> {
  $$AudioSubtitleRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get memoId => $composableBuilder(
      column: $table.memoId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startMs => $composableBuilder(
      column: $table.startMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get endMs => $composableBuilder(
      column: $table.endMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));
}

class $$AudioSubtitleRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AudioSubtitleRowsTable> {
  $$AudioSubtitleRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get memoId =>
      $composableBuilder(column: $table.memoId, builder: (column) => column);

  GeneratedColumn<int> get startMs =>
      $composableBuilder(column: $table.startMs, builder: (column) => column);

  GeneratedColumn<int> get endMs =>
      $composableBuilder(column: $table.endMs, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$AudioSubtitleRowsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AudioSubtitleRowsTable,
    AudioSubtitleRow,
    $$AudioSubtitleRowsTableFilterComposer,
    $$AudioSubtitleRowsTableOrderingComposer,
    $$AudioSubtitleRowsTableAnnotationComposer,
    $$AudioSubtitleRowsTableCreateCompanionBuilder,
    $$AudioSubtitleRowsTableUpdateCompanionBuilder,
    (
      AudioSubtitleRow,
      BaseReferences<_$AppDatabase, $AudioSubtitleRowsTable, AudioSubtitleRow>
    ),
    AudioSubtitleRow,
    PrefetchHooks Function()> {
  $$AudioSubtitleRowsTableTableManager(
      _$AppDatabase db, $AudioSubtitleRowsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AudioSubtitleRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AudioSubtitleRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AudioSubtitleRowsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> memoId = const Value.absent(),
            Value<int> startMs = const Value.absent(),
            Value<int> endMs = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AudioSubtitleRowsCompanion(
            id: id,
            memoId: memoId,
            startMs: startMs,
            endMs: endMs,
            content: content,
            sortOrder: sortOrder,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String memoId,
            required int startMs,
            required int endMs,
            required String content,
            Value<int> sortOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AudioSubtitleRowsCompanion.insert(
            id: id,
            memoId: memoId,
            startMs: startMs,
            endMs: endMs,
            content: content,
            sortOrder: sortOrder,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$AudioSubtitleRowsTable, AudioSubtitleRow>(
                        table),
                    BaseReferences<_$AppDatabase, $AudioSubtitleRowsTable,
                        AudioSubtitleRow>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AudioSubtitleRowsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AudioSubtitleRowsTable,
    AudioSubtitleRow,
    $$AudioSubtitleRowsTableFilterComposer,
    $$AudioSubtitleRowsTableOrderingComposer,
    $$AudioSubtitleRowsTableAnnotationComposer,
    $$AudioSubtitleRowsTableCreateCompanionBuilder,
    $$AudioSubtitleRowsTableUpdateCompanionBuilder,
    (
      AudioSubtitleRow,
      BaseReferences<_$AppDatabase, $AudioSubtitleRowsTable, AudioSubtitleRow>
    ),
    AudioSubtitleRow,
    PrefetchHooks Function()>;
typedef $$FontRowsTableCreateCompanionBuilder = FontRowsCompanion Function({
  required String id,
  required String name,
  required String path,
  required int createdAt,
  Value<int> rowid,
});
typedef $$FontRowsTableUpdateCompanionBuilder = FontRowsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> path,
  Value<int> createdAt,
  Value<int> rowid,
});

class $$FontRowsTableFilterComposer
    extends Composer<_$AppDatabase, $FontRowsTable> {
  $$FontRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get path => $composableBuilder(
      column: $table.path, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$FontRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $FontRowsTable> {
  $$FontRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get path => $composableBuilder(
      column: $table.path, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$FontRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FontRowsTable> {
  $$FontRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$FontRowsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FontRowsTable,
    FontRow,
    $$FontRowsTableFilterComposer,
    $$FontRowsTableOrderingComposer,
    $$FontRowsTableAnnotationComposer,
    $$FontRowsTableCreateCompanionBuilder,
    $$FontRowsTableUpdateCompanionBuilder,
    (FontRow, BaseReferences<_$AppDatabase, $FontRowsTable, FontRow>),
    FontRow,
    PrefetchHooks Function()> {
  $$FontRowsTableTableManager(_$AppDatabase db, $FontRowsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FontRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FontRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FontRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> path = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FontRowsCompanion(
            id: id,
            name: name,
            path: path,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String path,
            required int createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              FontRowsCompanion.insert(
            id: id,
            name: name,
            path: path,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$FontRowsTable, FontRow>(table),
                    BaseReferences<_$AppDatabase, $FontRowsTable, FontRow>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FontRowsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FontRowsTable,
    FontRow,
    $$FontRowsTableFilterComposer,
    $$FontRowsTableOrderingComposer,
    $$FontRowsTableAnnotationComposer,
    $$FontRowsTableCreateCompanionBuilder,
    $$FontRowsTableUpdateCompanionBuilder,
    (FontRow, BaseReferences<_$AppDatabase, $FontRowsTable, FontRow>),
    FontRow,
    PrefetchHooks Function()>;
typedef $$TagRowsTableCreateCompanionBuilder = TagRowsCompanion Function({
  required String id,
  required String name,
  Value<int?> color,
  Value<int> rowid,
});
typedef $$TagRowsTableUpdateCompanionBuilder = TagRowsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<int?> color,
  Value<int> rowid,
});

class $$TagRowsTableFilterComposer
    extends Composer<_$AppDatabase, $TagRowsTable> {
  $$TagRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnFilters(column));
}

class $$TagRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $TagRowsTable> {
  $$TagRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));
}

class $$TagRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagRowsTable> {
  $$TagRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);
}

class $$TagRowsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TagRowsTable,
    TagRow,
    $$TagRowsTableFilterComposer,
    $$TagRowsTableOrderingComposer,
    $$TagRowsTableAnnotationComposer,
    $$TagRowsTableCreateCompanionBuilder,
    $$TagRowsTableUpdateCompanionBuilder,
    (TagRow, BaseReferences<_$AppDatabase, $TagRowsTable, TagRow>),
    TagRow,
    PrefetchHooks Function()> {
  $$TagRowsTableTableManager(_$AppDatabase db, $TagRowsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int?> color = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TagRowsCompanion(
            id: id,
            name: name,
            color: color,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<int?> color = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TagRowsCompanion.insert(
            id: id,
            name: name,
            color: color,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$TagRowsTable, TagRow>(table),
                    BaseReferences<_$AppDatabase, $TagRowsTable, TagRow>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TagRowsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TagRowsTable,
    TagRow,
    $$TagRowsTableFilterComposer,
    $$TagRowsTableOrderingComposer,
    $$TagRowsTableAnnotationComposer,
    $$TagRowsTableCreateCompanionBuilder,
    $$TagRowsTableUpdateCompanionBuilder,
    (TagRow, BaseReferences<_$AppDatabase, $TagRowsTable, TagRow>),
    TagRow,
    PrefetchHooks Function()>;
typedef $$MemoTagRowsTableCreateCompanionBuilder = MemoTagRowsCompanion
    Function({
  required String memoId,
  required String tagId,
  Value<int> rowid,
});
typedef $$MemoTagRowsTableUpdateCompanionBuilder = MemoTagRowsCompanion
    Function({
  Value<String> memoId,
  Value<String> tagId,
  Value<int> rowid,
});

class $$MemoTagRowsTableFilterComposer
    extends Composer<_$AppDatabase, $MemoTagRowsTable> {
  $$MemoTagRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get memoId => $composableBuilder(
      column: $table.memoId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tagId => $composableBuilder(
      column: $table.tagId, builder: (column) => ColumnFilters(column));
}

class $$MemoTagRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $MemoTagRowsTable> {
  $$MemoTagRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get memoId => $composableBuilder(
      column: $table.memoId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tagId => $composableBuilder(
      column: $table.tagId, builder: (column) => ColumnOrderings(column));
}

class $$MemoTagRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MemoTagRowsTable> {
  $$MemoTagRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get memoId =>
      $composableBuilder(column: $table.memoId, builder: (column) => column);

  GeneratedColumn<String> get tagId =>
      $composableBuilder(column: $table.tagId, builder: (column) => column);
}

class $$MemoTagRowsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MemoTagRowsTable,
    MemoTagRow,
    $$MemoTagRowsTableFilterComposer,
    $$MemoTagRowsTableOrderingComposer,
    $$MemoTagRowsTableAnnotationComposer,
    $$MemoTagRowsTableCreateCompanionBuilder,
    $$MemoTagRowsTableUpdateCompanionBuilder,
    (MemoTagRow, BaseReferences<_$AppDatabase, $MemoTagRowsTable, MemoTagRow>),
    MemoTagRow,
    PrefetchHooks Function()> {
  $$MemoTagRowsTableTableManager(_$AppDatabase db, $MemoTagRowsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MemoTagRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MemoTagRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MemoTagRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> memoId = const Value.absent(),
            Value<String> tagId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MemoTagRowsCompanion(
            memoId: memoId,
            tagId: tagId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String memoId,
            required String tagId,
            Value<int> rowid = const Value.absent(),
          }) =>
              MemoTagRowsCompanion.insert(
            memoId: memoId,
            tagId: tagId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$MemoTagRowsTable, MemoTagRow>(table),
                    BaseReferences<_$AppDatabase, $MemoTagRowsTable,
                        MemoTagRow>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MemoTagRowsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MemoTagRowsTable,
    MemoTagRow,
    $$MemoTagRowsTableFilterComposer,
    $$MemoTagRowsTableOrderingComposer,
    $$MemoTagRowsTableAnnotationComposer,
    $$MemoTagRowsTableCreateCompanionBuilder,
    $$MemoTagRowsTableUpdateCompanionBuilder,
    (MemoTagRow, BaseReferences<_$AppDatabase, $MemoTagRowsTable, MemoTagRow>),
    MemoTagRow,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FolderRowsTableTableManager get folderRows =>
      $$FolderRowsTableTableManager(_db, _db.folderRows);
  $$MemoRowsTableTableManager get memoRows =>
      $$MemoRowsTableTableManager(_db, _db.memoRows);
  $$MediaItemRowsTableTableManager get mediaItemRows =>
      $$MediaItemRowsTableTableManager(_db, _db.mediaItemRows);
  $$AudioSubtitleRowsTableTableManager get audioSubtitleRows =>
      $$AudioSubtitleRowsTableTableManager(_db, _db.audioSubtitleRows);
  $$FontRowsTableTableManager get fontRows =>
      $$FontRowsTableTableManager(_db, _db.fontRows);
  $$TagRowsTableTableManager get tagRows =>
      $$TagRowsTableTableManager(_db, _db.tagRows);
  $$MemoTagRowsTableTableManager get memoTagRows =>
      $$MemoTagRowsTableTableManager(_db, _db.memoTagRows);
}
