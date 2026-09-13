// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'media_memo.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MediaMemo {
  String get memoId;
  List<MediaItem> get items;

  /// Create a copy of MediaMemo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MediaMemoCopyWith<MediaMemo> get copyWith =>
      _$MediaMemoCopyWithImpl<MediaMemo>(this as MediaMemo, _$identity);

  /// Serializes this MediaMemo to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as MediaMemo;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MediaMemo &&
            (identical(other.memoId, _this.memoId) ||
                other.memoId == _this.memoId) &&
            const DeepCollectionEquality().equals(other.items, _this.items));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as MediaMemo;
    return Object.hash(runtimeType, _this.memoId,
        const DeepCollectionEquality().hash(_this.items));
  }

  @override
  String toString() {
    final _this = this as MediaMemo;
    return 'MediaMemo(memoId: ${_this.memoId}, items: ${_this.items})';
  }
}

/// @nodoc
abstract mixin class $MediaMemoCopyWith<$Res> {
  factory $MediaMemoCopyWith(MediaMemo value, $Res Function(MediaMemo) _then) =
      _$MediaMemoCopyWithImpl;
  @useResult
  $Res call({String memoId, List<MediaItem> items});
}

/// @nodoc
class _$MediaMemoCopyWithImpl<$Res> implements $MediaMemoCopyWith<$Res> {
  _$MediaMemoCopyWithImpl(this._self, this._then);

  final MediaMemo _self;
  final $Res Function(MediaMemo) _then;

  /// Create a copy of MediaMemo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? memoId = null,
    Object? items = null,
  }) {
    return _then(MediaMemo(
      memoId: null == memoId
          ? _self.memoId
          : memoId // ignore: cast_nullable_to_non_nullable
              as String,
      items: null == items
          ? _self.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<MediaItem>,
    ));
  }
}

/// Adds pattern-matching-related methods to [MediaMemo].
extension MediaMemoPatterns on MediaMemo {
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
    TResult Function(_MediaMemo value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MediaMemo() when $default != null:
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
    TResult Function(_MediaMemo value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MediaMemo():
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
    TResult? Function(_MediaMemo value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MediaMemo() when $default != null:
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
    TResult Function(String memoId, List<MediaItem> items)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MediaMemo() when $default != null:
        return $default(_that.memoId, _that.items);
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
    TResult Function(String memoId, List<MediaItem> items) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MediaMemo():
        return $default(_that.memoId, _that.items);
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
    TResult? Function(String memoId, List<MediaItem> items)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MediaMemo() when $default != null:
        return $default(_that.memoId, _that.items);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _MediaMemo implements MediaMemo {
  const _MediaMemo(
      {required this.memoId, List<MediaItem> items = const <MediaItem>[]})
      : _items = items;
  factory _MediaMemo.fromJson(Map<String, dynamic> json) =>
      _$MediaMemoFromJson(json);

  @override
  final String memoId;
  final List<MediaItem> _items;
  @override
  @JsonKey()
  List<MediaItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  /// Create a copy of MediaMemo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$MediaMemoCopyWith<_MediaMemo> get copyWith =>
      __$MediaMemoCopyWithImpl<_MediaMemo>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$MediaMemoToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _MediaMemo &&
            (identical(other.memoId, memoId) || other.memoId == memoId) &&
            const DeepCollectionEquality().equals(other.items, _items));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
        runtimeType, memoId, const DeepCollectionEquality().hash(_items));
  }

  @override
  String toString() {
    return 'MediaMemo(memoId: $memoId, items: $items)';
  }
}

/// @nodoc
abstract mixin class _$MediaMemoCopyWith<$Res>
    implements $MediaMemoCopyWith<$Res> {
  factory _$MediaMemoCopyWith(
          _MediaMemo value, $Res Function(_MediaMemo) _then) =
      __$MediaMemoCopyWithImpl;
  @override
  @useResult
  $Res call({String memoId, List<MediaItem> items});
}

/// @nodoc
class __$MediaMemoCopyWithImpl<$Res> implements _$MediaMemoCopyWith<$Res> {
  __$MediaMemoCopyWithImpl(this._self, this._then);

  final _MediaMemo _self;
  final $Res Function(_MediaMemo) _then;

  /// Create a copy of MediaMemo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? memoId = null,
    Object? items = null,
  }) {
    return _then(_MediaMemo(
      memoId: null == memoId
          ? _self.memoId
          : memoId // ignore: cast_nullable_to_non_nullable
              as String,
      items: null == items
          ? _self._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<MediaItem>,
    ));
  }
}

// dart format on
