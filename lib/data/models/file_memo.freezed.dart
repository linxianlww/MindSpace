// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'file_memo.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FileMemo {
  String get memoId;
  String get path;
  String get originalName;
  int get sizeBytes;
  String? get extension;
  int? get pageCount;

  /// Create a copy of FileMemo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FileMemoCopyWith<FileMemo> get copyWith =>
      _$FileMemoCopyWithImpl<FileMemo>(this as FileMemo, _$identity);

  /// Serializes this FileMemo to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as FileMemo;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FileMemo &&
            (identical(other.memoId, _this.memoId) ||
                other.memoId == _this.memoId) &&
            (identical(other.path, _this.path) || other.path == _this.path) &&
            (identical(other.originalName, _this.originalName) ||
                other.originalName == _this.originalName) &&
            (identical(other.sizeBytes, _this.sizeBytes) ||
                other.sizeBytes == _this.sizeBytes) &&
            (identical(other.extension, _this.extension) ||
                other.extension == _this.extension) &&
            (identical(other.pageCount, _this.pageCount) ||
                other.pageCount == _this.pageCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as FileMemo;
    return Object.hash(runtimeType, _this.memoId, _this.path,
        _this.originalName, _this.sizeBytes, _this.extension, _this.pageCount);
  }

  @override
  String toString() {
    final _this = this as FileMemo;
    return 'FileMemo(memoId: ${_this.memoId}, path: ${_this.path}, originalName: ${_this.originalName}, sizeBytes: ${_this.sizeBytes}, extension: ${_this.extension}, pageCount: ${_this.pageCount})';
  }
}

/// @nodoc
abstract mixin class $FileMemoCopyWith<$Res> {
  factory $FileMemoCopyWith(FileMemo value, $Res Function(FileMemo) _then) =
      _$FileMemoCopyWithImpl;
  @useResult
  $Res call(
      {String memoId,
      String path,
      String originalName,
      int sizeBytes,
      String? extension,
      int? pageCount});
}

/// @nodoc
class _$FileMemoCopyWithImpl<$Res> implements $FileMemoCopyWith<$Res> {
  _$FileMemoCopyWithImpl(this._self, this._then);

  final FileMemo _self;
  final $Res Function(FileMemo) _then;

  /// Create a copy of FileMemo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? memoId = null,
    Object? path = null,
    Object? originalName = null,
    Object? sizeBytes = null,
    Object? extension = freezed,
    Object? pageCount = freezed,
  }) {
    return _then(FileMemo(
      memoId: null == memoId
          ? _self.memoId
          : memoId // ignore: cast_nullable_to_non_nullable
              as String,
      path: null == path
          ? _self.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      originalName: null == originalName
          ? _self.originalName
          : originalName // ignore: cast_nullable_to_non_nullable
              as String,
      sizeBytes: null == sizeBytes
          ? _self.sizeBytes
          : sizeBytes // ignore: cast_nullable_to_non_nullable
              as int,
      extension: freezed == extension
          ? _self.extension
          : extension // ignore: cast_nullable_to_non_nullable
              as String?,
      pageCount: freezed == pageCount
          ? _self.pageCount
          : pageCount // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// Adds pattern-matching-related methods to [FileMemo].
extension FileMemoPatterns on FileMemo {
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
    TResult Function(_FileMemo value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FileMemo() when $default != null:
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
    TResult Function(_FileMemo value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FileMemo():
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
    TResult? Function(_FileMemo value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FileMemo() when $default != null:
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
    TResult Function(String memoId, String path, String originalName,
            int sizeBytes, String? extension, int? pageCount)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FileMemo() when $default != null:
        return $default(_that.memoId, _that.path, _that.originalName,
            _that.sizeBytes, _that.extension, _that.pageCount);
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
    TResult Function(String memoId, String path, String originalName,
            int sizeBytes, String? extension, int? pageCount)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FileMemo():
        return $default(_that.memoId, _that.path, _that.originalName,
            _that.sizeBytes, _that.extension, _that.pageCount);
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
    TResult? Function(String memoId, String path, String originalName,
            int sizeBytes, String? extension, int? pageCount)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FileMemo() when $default != null:
        return $default(_that.memoId, _that.path, _that.originalName,
            _that.sizeBytes, _that.extension, _that.pageCount);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _FileMemo implements FileMemo {
  const _FileMemo(
      {required this.memoId,
      required this.path,
      required this.originalName,
      this.sizeBytes = 0,
      this.extension,
      this.pageCount});
  factory _FileMemo.fromJson(Map<String, dynamic> json) =>
      _$FileMemoFromJson(json);

  @override
  final String memoId;
  @override
  final String path;
  @override
  final String originalName;
  @override
  @JsonKey()
  final int sizeBytes;
  @override
  final String? extension;
  @override
  final int? pageCount;

  /// Create a copy of FileMemo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$FileMemoCopyWith<_FileMemo> get copyWith =>
      __$FileMemoCopyWithImpl<_FileMemo>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$FileMemoToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _FileMemo &&
            (identical(other.memoId, memoId) || other.memoId == memoId) &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.originalName, originalName) ||
                other.originalName == originalName) &&
            (identical(other.sizeBytes, sizeBytes) ||
                other.sizeBytes == sizeBytes) &&
            (identical(other.extension, extension) ||
                other.extension == extension) &&
            (identical(other.pageCount, pageCount) ||
                other.pageCount == pageCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(runtimeType, memoId, path, originalName, sizeBytes,
        extension, pageCount);
  }

  @override
  String toString() {
    return 'FileMemo(memoId: $memoId, path: $path, originalName: $originalName, sizeBytes: $sizeBytes, extension: $extension, pageCount: $pageCount)';
  }
}

/// @nodoc
abstract mixin class _$FileMemoCopyWith<$Res>
    implements $FileMemoCopyWith<$Res> {
  factory _$FileMemoCopyWith(_FileMemo value, $Res Function(_FileMemo) _then) =
      __$FileMemoCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String memoId,
      String path,
      String originalName,
      int sizeBytes,
      String? extension,
      int? pageCount});
}

/// @nodoc
class __$FileMemoCopyWithImpl<$Res> implements _$FileMemoCopyWith<$Res> {
  __$FileMemoCopyWithImpl(this._self, this._then);

  final _FileMemo _self;
  final $Res Function(_FileMemo) _then;

  /// Create a copy of FileMemo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? memoId = null,
    Object? path = null,
    Object? originalName = null,
    Object? sizeBytes = null,
    Object? extension = freezed,
    Object? pageCount = freezed,
  }) {
    return _then(_FileMemo(
      memoId: null == memoId
          ? _self.memoId
          : memoId // ignore: cast_nullable_to_non_nullable
              as String,
      path: null == path
          ? _self.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      originalName: null == originalName
          ? _self.originalName
          : originalName // ignore: cast_nullable_to_non_nullable
              as String,
      sizeBytes: null == sizeBytes
          ? _self.sizeBytes
          : sizeBytes // ignore: cast_nullable_to_non_nullable
              as int,
      extension: freezed == extension
          ? _self.extension
          : extension // ignore: cast_nullable_to_non_nullable
              as String?,
      pageCount: freezed == pageCount
          ? _self.pageCount
          : pageCount // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

// dart format on
