// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'font_asset.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FontAsset {
  String get id;
  String get name;
  String get path;
  int get createdAt;

  /// Create a copy of FontAsset
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FontAssetCopyWith<FontAsset> get copyWith =>
      _$FontAssetCopyWithImpl<FontAsset>(this as FontAsset, _$identity);

  /// Serializes this FontAsset to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as FontAsset;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FontAsset &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.name, _this.name) || other.name == _this.name) &&
            (identical(other.path, _this.path) || other.path == _this.path) &&
            (identical(other.createdAt, _this.createdAt) ||
                other.createdAt == _this.createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as FontAsset;
    return Object.hash(
        runtimeType, _this.id, _this.name, _this.path, _this.createdAt);
  }

  @override
  String toString() {
    final _this = this as FontAsset;
    return 'FontAsset(id: ${_this.id}, name: ${_this.name}, path: ${_this.path}, createdAt: ${_this.createdAt})';
  }
}

/// @nodoc
abstract mixin class $FontAssetCopyWith<$Res> {
  factory $FontAssetCopyWith(FontAsset value, $Res Function(FontAsset) _then) =
      _$FontAssetCopyWithImpl;
  @useResult
  $Res call({String id, String name, String path, int createdAt});
}

/// @nodoc
class _$FontAssetCopyWithImpl<$Res> implements $FontAssetCopyWith<$Res> {
  _$FontAssetCopyWithImpl(this._self, this._then);

  final FontAsset _self;
  final $Res Function(FontAsset) _then;

  /// Create a copy of FontAsset
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? path = null,
    Object? createdAt = null,
  }) {
    return _then(FontAsset(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      path: null == path
          ? _self.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// Adds pattern-matching-related methods to [FontAsset].
extension FontAssetPatterns on FontAsset {
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
    TResult Function(_FontAsset value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FontAsset() when $default != null:
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
    TResult Function(_FontAsset value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FontAsset():
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
    TResult? Function(_FontAsset value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FontAsset() when $default != null:
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
    TResult Function(String id, String name, String path, int createdAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FontAsset() when $default != null:
        return $default(_that.id, _that.name, _that.path, _that.createdAt);
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
    TResult Function(String id, String name, String path, int createdAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FontAsset():
        return $default(_that.id, _that.name, _that.path, _that.createdAt);
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
    TResult? Function(String id, String name, String path, int createdAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FontAsset() when $default != null:
        return $default(_that.id, _that.name, _that.path, _that.createdAt);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _FontAsset implements FontAsset {
  const _FontAsset(
      {required this.id,
      required this.name,
      required this.path,
      required this.createdAt});
  factory _FontAsset.fromJson(Map<String, dynamic> json) =>
      _$FontAssetFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String path;
  @override
  final int createdAt;

  /// Create a copy of FontAsset
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$FontAssetCopyWith<_FontAsset> get copyWith =>
      __$FontAssetCopyWithImpl<_FontAsset>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$FontAssetToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _FontAsset &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(runtimeType, id, name, path, createdAt);
  }

  @override
  String toString() {
    return 'FontAsset(id: $id, name: $name, path: $path, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class _$FontAssetCopyWith<$Res>
    implements $FontAssetCopyWith<$Res> {
  factory _$FontAssetCopyWith(
          _FontAsset value, $Res Function(_FontAsset) _then) =
      __$FontAssetCopyWithImpl;
  @override
  @useResult
  $Res call({String id, String name, String path, int createdAt});
}

/// @nodoc
class __$FontAssetCopyWithImpl<$Res> implements _$FontAssetCopyWith<$Res> {
  __$FontAssetCopyWithImpl(this._self, this._then);

  final _FontAsset _self;
  final $Res Function(_FontAsset) _then;

  /// Create a copy of FontAsset
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? path = null,
    Object? createdAt = null,
  }) {
    return _then(_FontAsset(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      path: null == path
          ? _self.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

// dart format on
