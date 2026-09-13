// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'media_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MediaItem {
  String get id;
  String get memoId;
  String get path;
  @MediaKindConverter()
  MediaKind get kind;
  String? get remark;
  int get sortOrder;
  int? get width;
  int? get height;
  int? get durationMs;
  String? get thumbPath;
  int get createdAt;

  /// Create a copy of MediaItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MediaItemCopyWith<MediaItem> get copyWith =>
      _$MediaItemCopyWithImpl<MediaItem>(this as MediaItem, _$identity);

  /// Serializes this MediaItem to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as MediaItem;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MediaItem &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.memoId, _this.memoId) ||
                other.memoId == _this.memoId) &&
            (identical(other.path, _this.path) || other.path == _this.path) &&
            (identical(other.kind, _this.kind) || other.kind == _this.kind) &&
            (identical(other.remark, _this.remark) ||
                other.remark == _this.remark) &&
            (identical(other.sortOrder, _this.sortOrder) ||
                other.sortOrder == _this.sortOrder) &&
            (identical(other.width, _this.width) ||
                other.width == _this.width) &&
            (identical(other.height, _this.height) ||
                other.height == _this.height) &&
            (identical(other.durationMs, _this.durationMs) ||
                other.durationMs == _this.durationMs) &&
            (identical(other.thumbPath, _this.thumbPath) ||
                other.thumbPath == _this.thumbPath) &&
            (identical(other.createdAt, _this.createdAt) ||
                other.createdAt == _this.createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as MediaItem;
    return Object.hash(
        runtimeType,
        _this.id,
        _this.memoId,
        _this.path,
        _this.kind,
        _this.remark,
        _this.sortOrder,
        _this.width,
        _this.height,
        _this.durationMs,
        _this.thumbPath,
        _this.createdAt);
  }

  @override
  String toString() {
    final _this = this as MediaItem;
    return 'MediaItem(id: ${_this.id}, memoId: ${_this.memoId}, path: ${_this.path}, kind: ${_this.kind}, remark: ${_this.remark}, sortOrder: ${_this.sortOrder}, width: ${_this.width}, height: ${_this.height}, durationMs: ${_this.durationMs}, thumbPath: ${_this.thumbPath}, createdAt: ${_this.createdAt})';
  }
}

/// @nodoc
abstract mixin class $MediaItemCopyWith<$Res> {
  factory $MediaItemCopyWith(MediaItem value, $Res Function(MediaItem) _then) =
      _$MediaItemCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String memoId,
      String path,
      @MediaKindConverter() MediaKind kind,
      String? remark,
      int sortOrder,
      int? width,
      int? height,
      int? durationMs,
      String? thumbPath,
      int createdAt});
}

/// @nodoc
class _$MediaItemCopyWithImpl<$Res> implements $MediaItemCopyWith<$Res> {
  _$MediaItemCopyWithImpl(this._self, this._then);

  final MediaItem _self;
  final $Res Function(MediaItem) _then;

  /// Create a copy of MediaItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? memoId = null,
    Object? path = null,
    Object? kind = null,
    Object? remark = freezed,
    Object? sortOrder = null,
    Object? width = freezed,
    Object? height = freezed,
    Object? durationMs = freezed,
    Object? thumbPath = freezed,
    Object? createdAt = null,
  }) {
    return _then(MediaItem(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      memoId: null == memoId
          ? _self.memoId
          : memoId // ignore: cast_nullable_to_non_nullable
              as String,
      path: null == path
          ? _self.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _self.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as MediaKind,
      remark: freezed == remark
          ? _self.remark
          : remark // ignore: cast_nullable_to_non_nullable
              as String?,
      sortOrder: null == sortOrder
          ? _self.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      width: freezed == width
          ? _self.width
          : width // ignore: cast_nullable_to_non_nullable
              as int?,
      height: freezed == height
          ? _self.height
          : height // ignore: cast_nullable_to_non_nullable
              as int?,
      durationMs: freezed == durationMs
          ? _self.durationMs
          : durationMs // ignore: cast_nullable_to_non_nullable
              as int?,
      thumbPath: freezed == thumbPath
          ? _self.thumbPath
          : thumbPath // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// Adds pattern-matching-related methods to [MediaItem].
extension MediaItemPatterns on MediaItem {
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
    TResult Function(_MediaItem value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MediaItem() when $default != null:
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
    TResult Function(_MediaItem value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MediaItem():
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
    TResult? Function(_MediaItem value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MediaItem() when $default != null:
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
            String memoId,
            String path,
            @MediaKindConverter() MediaKind kind,
            String? remark,
            int sortOrder,
            int? width,
            int? height,
            int? durationMs,
            String? thumbPath,
            int createdAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MediaItem() when $default != null:
        return $default(
            _that.id,
            _that.memoId,
            _that.path,
            _that.kind,
            _that.remark,
            _that.sortOrder,
            _that.width,
            _that.height,
            _that.durationMs,
            _that.thumbPath,
            _that.createdAt);
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
            String memoId,
            String path,
            @MediaKindConverter() MediaKind kind,
            String? remark,
            int sortOrder,
            int? width,
            int? height,
            int? durationMs,
            String? thumbPath,
            int createdAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MediaItem():
        return $default(
            _that.id,
            _that.memoId,
            _that.path,
            _that.kind,
            _that.remark,
            _that.sortOrder,
            _that.width,
            _that.height,
            _that.durationMs,
            _that.thumbPath,
            _that.createdAt);
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
            String memoId,
            String path,
            @MediaKindConverter() MediaKind kind,
            String? remark,
            int sortOrder,
            int? width,
            int? height,
            int? durationMs,
            String? thumbPath,
            int createdAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MediaItem() when $default != null:
        return $default(
            _that.id,
            _that.memoId,
            _that.path,
            _that.kind,
            _that.remark,
            _that.sortOrder,
            _that.width,
            _that.height,
            _that.durationMs,
            _that.thumbPath,
            _that.createdAt);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _MediaItem implements MediaItem {
  const _MediaItem(
      {required this.id,
      required this.memoId,
      required this.path,
      @MediaKindConverter() required this.kind,
      this.remark,
      this.sortOrder = 0,
      this.width,
      this.height,
      this.durationMs,
      this.thumbPath,
      required this.createdAt});
  factory _MediaItem.fromJson(Map<String, dynamic> json) =>
      _$MediaItemFromJson(json);

  @override
  final String id;
  @override
  final String memoId;
  @override
  final String path;
  @override
  @MediaKindConverter()
  final MediaKind kind;
  @override
  final String? remark;
  @override
  @JsonKey()
  final int sortOrder;
  @override
  final int? width;
  @override
  final int? height;
  @override
  final int? durationMs;
  @override
  final String? thumbPath;
  @override
  final int createdAt;

  /// Create a copy of MediaItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$MediaItemCopyWith<_MediaItem> get copyWith =>
      __$MediaItemCopyWithImpl<_MediaItem>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$MediaItemToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _MediaItem &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.memoId, memoId) || other.memoId == memoId) &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.remark, remark) || other.remark == remark) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.durationMs, durationMs) ||
                other.durationMs == durationMs) &&
            (identical(other.thumbPath, thumbPath) ||
                other.thumbPath == thumbPath) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(runtimeType, id, memoId, path, kind, remark, sortOrder,
        width, height, durationMs, thumbPath, createdAt);
  }

  @override
  String toString() {
    return 'MediaItem(id: $id, memoId: $memoId, path: $path, kind: $kind, remark: $remark, sortOrder: $sortOrder, width: $width, height: $height, durationMs: $durationMs, thumbPath: $thumbPath, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class _$MediaItemCopyWith<$Res>
    implements $MediaItemCopyWith<$Res> {
  factory _$MediaItemCopyWith(
          _MediaItem value, $Res Function(_MediaItem) _then) =
      __$MediaItemCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String memoId,
      String path,
      @MediaKindConverter() MediaKind kind,
      String? remark,
      int sortOrder,
      int? width,
      int? height,
      int? durationMs,
      String? thumbPath,
      int createdAt});
}

/// @nodoc
class __$MediaItemCopyWithImpl<$Res> implements _$MediaItemCopyWith<$Res> {
  __$MediaItemCopyWithImpl(this._self, this._then);

  final _MediaItem _self;
  final $Res Function(_MediaItem) _then;

  /// Create a copy of MediaItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? memoId = null,
    Object? path = null,
    Object? kind = null,
    Object? remark = freezed,
    Object? sortOrder = null,
    Object? width = freezed,
    Object? height = freezed,
    Object? durationMs = freezed,
    Object? thumbPath = freezed,
    Object? createdAt = null,
  }) {
    return _then(_MediaItem(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      memoId: null == memoId
          ? _self.memoId
          : memoId // ignore: cast_nullable_to_non_nullable
              as String,
      path: null == path
          ? _self.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _self.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as MediaKind,
      remark: freezed == remark
          ? _self.remark
          : remark // ignore: cast_nullable_to_non_nullable
              as String?,
      sortOrder: null == sortOrder
          ? _self.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      width: freezed == width
          ? _self.width
          : width // ignore: cast_nullable_to_non_nullable
              as int?,
      height: freezed == height
          ? _self.height
          : height // ignore: cast_nullable_to_non_nullable
              as int?,
      durationMs: freezed == durationMs
          ? _self.durationMs
          : durationMs // ignore: cast_nullable_to_non_nullable
              as int?,
      thumbPath: freezed == thumbPath
          ? _self.thumbPath
          : thumbPath // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

// dart format on
