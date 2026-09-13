// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'folder.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Folder {
  String get id;
  String get name;
  String? get parentId;
  int get createdAt;
  int get updatedAt;
  int get sortOrder;
  int? get deletedAt;

  /// Create a copy of Folder
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FolderCopyWith<Folder> get copyWith =>
      _$FolderCopyWithImpl<Folder>(this as Folder, _$identity);

  /// Serializes this Folder to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as Folder;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Folder &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.name, _this.name) || other.name == _this.name) &&
            (identical(other.parentId, _this.parentId) ||
                other.parentId == _this.parentId) &&
            (identical(other.createdAt, _this.createdAt) ||
                other.createdAt == _this.createdAt) &&
            (identical(other.updatedAt, _this.updatedAt) ||
                other.updatedAt == _this.updatedAt) &&
            (identical(other.sortOrder, _this.sortOrder) ||
                other.sortOrder == _this.sortOrder) &&
            (identical(other.deletedAt, _this.deletedAt) ||
                other.deletedAt == _this.deletedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as Folder;
    return Object.hash(runtimeType, _this.id, _this.name, _this.parentId,
        _this.createdAt, _this.updatedAt, _this.sortOrder, _this.deletedAt);
  }

  @override
  String toString() {
    final _this = this as Folder;
    return 'Folder(id: ${_this.id}, name: ${_this.name}, parentId: ${_this.parentId}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt}, sortOrder: ${_this.sortOrder}, deletedAt: ${_this.deletedAt})';
  }
}

/// @nodoc
abstract mixin class $FolderCopyWith<$Res> {
  factory $FolderCopyWith(Folder value, $Res Function(Folder) _then) =
      _$FolderCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String name,
      String? parentId,
      int createdAt,
      int updatedAt,
      int sortOrder,
      int? deletedAt});
}

/// @nodoc
class _$FolderCopyWithImpl<$Res> implements $FolderCopyWith<$Res> {
  _$FolderCopyWithImpl(this._self, this._then);

  final Folder _self;
  final $Res Function(Folder) _then;

  /// Create a copy of Folder
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? parentId = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? sortOrder = null,
    Object? deletedAt = freezed,
  }) {
    return _then(Folder(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      parentId: freezed == parentId
          ? _self.parentId
          : parentId // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as int,
      updatedAt: null == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as int,
      sortOrder: null == sortOrder
          ? _self.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      deletedAt: freezed == deletedAt
          ? _self.deletedAt
          : deletedAt // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// Adds pattern-matching-related methods to [Folder].
extension FolderPatterns on Folder {
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
    TResult Function(_Folder value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Folder() when $default != null:
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
    TResult Function(_Folder value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Folder():
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
    TResult? Function(_Folder value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Folder() when $default != null:
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
    TResult Function(String id, String name, String? parentId, int createdAt,
            int updatedAt, int sortOrder, int? deletedAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Folder() when $default != null:
        return $default(_that.id, _that.name, _that.parentId, _that.createdAt,
            _that.updatedAt, _that.sortOrder, _that.deletedAt);
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
    TResult Function(String id, String name, String? parentId, int createdAt,
            int updatedAt, int sortOrder, int? deletedAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Folder():
        return $default(_that.id, _that.name, _that.parentId, _that.createdAt,
            _that.updatedAt, _that.sortOrder, _that.deletedAt);
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
    TResult? Function(String id, String name, String? parentId, int createdAt,
            int updatedAt, int sortOrder, int? deletedAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Folder() when $default != null:
        return $default(_that.id, _that.name, _that.parentId, _that.createdAt,
            _that.updatedAt, _that.sortOrder, _that.deletedAt);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _Folder implements Folder {
  const _Folder(
      {required this.id,
      required this.name,
      this.parentId,
      required this.createdAt,
      required this.updatedAt,
      this.sortOrder = 0,
      this.deletedAt});
  factory _Folder.fromJson(Map<String, dynamic> json) => _$FolderFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? parentId;
  @override
  final int createdAt;
  @override
  final int updatedAt;
  @override
  @JsonKey()
  final int sortOrder;
  @override
  final int? deletedAt;

  /// Create a copy of Folder
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$FolderCopyWith<_Folder> get copyWith =>
      __$FolderCopyWithImpl<_Folder>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$FolderToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Folder &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.parentId, parentId) ||
                other.parentId == parentId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            (identical(other.deletedAt, deletedAt) ||
                other.deletedAt == deletedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(runtimeType, id, name, parentId, createdAt, updatedAt,
        sortOrder, deletedAt);
  }

  @override
  String toString() {
    return 'Folder(id: $id, name: $name, parentId: $parentId, createdAt: $createdAt, updatedAt: $updatedAt, sortOrder: $sortOrder, deletedAt: $deletedAt)';
  }
}

/// @nodoc
abstract mixin class _$FolderCopyWith<$Res> implements $FolderCopyWith<$Res> {
  factory _$FolderCopyWith(_Folder value, $Res Function(_Folder) _then) =
      __$FolderCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String? parentId,
      int createdAt,
      int updatedAt,
      int sortOrder,
      int? deletedAt});
}

/// @nodoc
class __$FolderCopyWithImpl<$Res> implements _$FolderCopyWith<$Res> {
  __$FolderCopyWithImpl(this._self, this._then);

  final _Folder _self;
  final $Res Function(_Folder) _then;

  /// Create a copy of Folder
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? parentId = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? sortOrder = null,
    Object? deletedAt = freezed,
  }) {
    return _then(_Folder(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      parentId: freezed == parentId
          ? _self.parentId
          : parentId // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as int,
      updatedAt: null == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as int,
      sortOrder: null == sortOrder
          ? _self.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      deletedAt: freezed == deletedAt
          ? _self.deletedAt
          : deletedAt // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

// dart format on
