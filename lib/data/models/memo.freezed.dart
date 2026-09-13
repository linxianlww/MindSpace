// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'memo.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Memo {
  String get id;
  String? get folderId;
  @MemoTypeConverter()
  MemoType get type;
  String get title;
  int get createdAt;
  int get updatedAt;
  int? get color;
  String? get remark;
  String? get fontId;
  String? get thumbnailPath;
  List<String> get tags;
  Map<String, dynamic> get metadata;
  int? get deletedAt;

  /// Create a copy of Memo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MemoCopyWith<Memo> get copyWith =>
      _$MemoCopyWithImpl<Memo>(this as Memo, _$identity);

  /// Serializes this Memo to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as Memo;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Memo &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.folderId, _this.folderId) ||
                other.folderId == _this.folderId) &&
            (identical(other.type, _this.type) || other.type == _this.type) &&
            (identical(other.title, _this.title) ||
                other.title == _this.title) &&
            (identical(other.createdAt, _this.createdAt) ||
                other.createdAt == _this.createdAt) &&
            (identical(other.updatedAt, _this.updatedAt) ||
                other.updatedAt == _this.updatedAt) &&
            (identical(other.color, _this.color) ||
                other.color == _this.color) &&
            (identical(other.remark, _this.remark) ||
                other.remark == _this.remark) &&
            (identical(other.fontId, _this.fontId) ||
                other.fontId == _this.fontId) &&
            (identical(other.thumbnailPath, _this.thumbnailPath) ||
                other.thumbnailPath == _this.thumbnailPath) &&
            const DeepCollectionEquality().equals(other.tags, _this.tags) &&
            const DeepCollectionEquality()
                .equals(other.metadata, _this.metadata) &&
            (identical(other.deletedAt, _this.deletedAt) ||
                other.deletedAt == _this.deletedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as Memo;
    return Object.hash(
        runtimeType,
        _this.id,
        _this.folderId,
        _this.type,
        _this.title,
        _this.createdAt,
        _this.updatedAt,
        _this.color,
        _this.remark,
        _this.fontId,
        _this.thumbnailPath,
        const DeepCollectionEquality().hash(_this.tags),
        const DeepCollectionEquality().hash(_this.metadata),
        _this.deletedAt);
  }

  @override
  String toString() {
    final _this = this as Memo;
    return 'Memo(id: ${_this.id}, folderId: ${_this.folderId}, type: ${_this.type}, title: ${_this.title}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt}, color: ${_this.color}, remark: ${_this.remark}, fontId: ${_this.fontId}, thumbnailPath: ${_this.thumbnailPath}, tags: ${_this.tags}, metadata: ${_this.metadata}, deletedAt: ${_this.deletedAt})';
  }
}

/// @nodoc
abstract mixin class $MemoCopyWith<$Res> {
  factory $MemoCopyWith(Memo value, $Res Function(Memo) _then) =
      _$MemoCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String? folderId,
      @MemoTypeConverter() MemoType type,
      String title,
      int createdAt,
      int updatedAt,
      int? color,
      String? remark,
      String? fontId,
      String? thumbnailPath,
      List<String> tags,
      Map<String, dynamic> metadata,
      int? deletedAt});
}

/// @nodoc
class _$MemoCopyWithImpl<$Res> implements $MemoCopyWith<$Res> {
  _$MemoCopyWithImpl(this._self, this._then);

  final Memo _self;
  final $Res Function(Memo) _then;

  /// Create a copy of Memo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? folderId = freezed,
    Object? type = null,
    Object? title = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? color = freezed,
    Object? remark = freezed,
    Object? fontId = freezed,
    Object? thumbnailPath = freezed,
    Object? tags = null,
    Object? metadata = null,
    Object? deletedAt = freezed,
  }) {
    return _then(Memo(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      folderId: freezed == folderId
          ? _self.folderId
          : folderId // ignore: cast_nullable_to_non_nullable
              as String?,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as MemoType,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as int,
      updatedAt: null == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as int,
      color: freezed == color
          ? _self.color
          : color // ignore: cast_nullable_to_non_nullable
              as int?,
      remark: freezed == remark
          ? _self.remark
          : remark // ignore: cast_nullable_to_non_nullable
              as String?,
      fontId: freezed == fontId
          ? _self.fontId
          : fontId // ignore: cast_nullable_to_non_nullable
              as String?,
      thumbnailPath: freezed == thumbnailPath
          ? _self.thumbnailPath
          : thumbnailPath // ignore: cast_nullable_to_non_nullable
              as String?,
      tags: null == tags
          ? _self.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      metadata: null == metadata
          ? _self.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      deletedAt: freezed == deletedAt
          ? _self.deletedAt
          : deletedAt // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// Adds pattern-matching-related methods to [Memo].
extension MemoPatterns on Memo {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_Memo value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Memo() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_Memo value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Memo():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_Memo value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Memo() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            String id,
            String? folderId,
            @MemoTypeConverter() MemoType type,
            String title,
            int createdAt,
            int updatedAt,
            int? color,
            String? remark,
            String? fontId,
            String? thumbnailPath,
            List<String> tags,
            Map<String, dynamic> metadata,
            int? deletedAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Memo() when $default != null:
        return $default(
            _that.id,
            _that.folderId,
            _that.type,
            _that.title,
            _that.createdAt,
            _that.updatedAt,
            _that.color,
            _that.remark,
            _that.fontId,
            _that.thumbnailPath,
            _that.tags,
            _that.metadata,
            _that.deletedAt);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            String id,
            String? folderId,
            @MemoTypeConverter() MemoType type,
            String title,
            int createdAt,
            int updatedAt,
            int? color,
            String? remark,
            String? fontId,
            String? thumbnailPath,
            List<String> tags,
            Map<String, dynamic> metadata,
            int? deletedAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Memo():
        return $default(
            _that.id,
            _that.folderId,
            _that.type,
            _that.title,
            _that.createdAt,
            _that.updatedAt,
            _that.color,
            _that.remark,
            _that.fontId,
            _that.thumbnailPath,
            _that.tags,
            _that.metadata,
            _that.deletedAt);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            String id,
            String? folderId,
            @MemoTypeConverter() MemoType type,
            String title,
            int createdAt,
            int updatedAt,
            int? color,
            String? remark,
            String? fontId,
            String? thumbnailPath,
            List<String> tags,
            Map<String, dynamic> metadata,
            int? deletedAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Memo() when $default != null:
        return $default(
            _that.id,
            _that.folderId,
            _that.type,
            _that.title,
            _that.createdAt,
            _that.updatedAt,
            _that.color,
            _that.remark,
            _that.fontId,
            _that.thumbnailPath,
            _that.tags,
            _that.metadata,
            _that.deletedAt);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _Memo extends Memo {
  const _Memo(
      {required this.id,
      this.folderId,
      @MemoTypeConverter() required this.type,
      this.title = '无标题',
      required this.createdAt,
      required this.updatedAt,
      this.color,
      this.remark,
      this.fontId,
      this.thumbnailPath,
      List<String> tags = const <String>[],
      Map<String, dynamic> metadata = const <String, dynamic>{},
      this.deletedAt})
      : _tags = tags,
        _metadata = metadata,
        super._();
  factory _Memo.fromJson(Map<String, dynamic> json) => _$MemoFromJson(json);

  @override
  final String id;
  @override
  final String? folderId;
  @override
  @MemoTypeConverter()
  final MemoType type;
  @override
  @JsonKey()
  final String title;
  @override
  final int createdAt;
  @override
  final int updatedAt;
  @override
  final int? color;
  @override
  final String? remark;
  @override
  final String? fontId;
  @override
  final String? thumbnailPath;
  final List<String> _tags;
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  final Map<String, dynamic> _metadata;
  @override
  @JsonKey()
  Map<String, dynamic> get metadata {
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_metadata);
  }

  @override
  final int? deletedAt;

  /// Create a copy of Memo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$MemoCopyWith<_Memo> get copyWith =>
      __$MemoCopyWithImpl<_Memo>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$MemoToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Memo &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.folderId, folderId) ||
                other.folderId == folderId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.remark, remark) || other.remark == remark) &&
            (identical(other.fontId, fontId) || other.fontId == fontId) &&
            (identical(other.thumbnailPath, thumbnailPath) ||
                other.thumbnailPath == thumbnailPath) &&
            const DeepCollectionEquality().equals(other.tags, _tags) &&
            const DeepCollectionEquality().equals(other.metadata, _metadata) &&
            (identical(other.deletedAt, deletedAt) ||
                other.deletedAt == deletedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
        runtimeType,
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
        const DeepCollectionEquality().hash(_tags),
        const DeepCollectionEquality().hash(_metadata),
        deletedAt);
  }

  @override
  String toString() {
    return 'Memo(id: $id, folderId: $folderId, type: $type, title: $title, createdAt: $createdAt, updatedAt: $updatedAt, color: $color, remark: $remark, fontId: $fontId, thumbnailPath: $thumbnailPath, tags: $tags, metadata: $metadata, deletedAt: $deletedAt)';
  }
}

/// @nodoc
abstract mixin class _$MemoCopyWith<$Res> implements $MemoCopyWith<$Res> {
  factory _$MemoCopyWith(_Memo value, $Res Function(_Memo) _then) =
      __$MemoCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String? folderId,
      @MemoTypeConverter() MemoType type,
      String title,
      int createdAt,
      int updatedAt,
      int? color,
      String? remark,
      String? fontId,
      String? thumbnailPath,
      List<String> tags,
      Map<String, dynamic> metadata,
      int? deletedAt});
}

/// @nodoc
class __$MemoCopyWithImpl<$Res> implements _$MemoCopyWith<$Res> {
  __$MemoCopyWithImpl(this._self, this._then);

  final _Memo _self;
  final $Res Function(_Memo) _then;

  /// Create a copy of Memo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? folderId = freezed,
    Object? type = null,
    Object? title = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? color = freezed,
    Object? remark = freezed,
    Object? fontId = freezed,
    Object? thumbnailPath = freezed,
    Object? tags = null,
    Object? metadata = null,
    Object? deletedAt = freezed,
  }) {
    return _then(_Memo(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      folderId: freezed == folderId
          ? _self.folderId
          : folderId // ignore: cast_nullable_to_non_nullable
              as String?,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as MemoType,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as int,
      updatedAt: null == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as int,
      color: freezed == color
          ? _self.color
          : color // ignore: cast_nullable_to_non_nullable
              as int?,
      remark: freezed == remark
          ? _self.remark
          : remark // ignore: cast_nullable_to_non_nullable
              as String?,
      fontId: freezed == fontId
          ? _self.fontId
          : fontId // ignore: cast_nullable_to_non_nullable
              as String?,
      thumbnailPath: freezed == thumbnailPath
          ? _self.thumbnailPath
          : thumbnailPath // ignore: cast_nullable_to_non_nullable
              as String?,
      tags: null == tags
          ? _self._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      metadata: null == metadata
          ? _self._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      deletedAt: freezed == deletedAt
          ? _self.deletedAt
          : deletedAt // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

// dart format on
