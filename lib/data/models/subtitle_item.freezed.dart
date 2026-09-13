// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subtitle_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SubtitleItem {
  String get id;
  String get memoId;
  int get startMs;
  int get endMs;
  String get text;
  int get sortOrder;

  /// Create a copy of SubtitleItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SubtitleItemCopyWith<SubtitleItem> get copyWith =>
      _$SubtitleItemCopyWithImpl<SubtitleItem>(
          this as SubtitleItem, _$identity);

  /// Serializes this SubtitleItem to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as SubtitleItem;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SubtitleItem &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.memoId, _this.memoId) ||
                other.memoId == _this.memoId) &&
            (identical(other.startMs, _this.startMs) ||
                other.startMs == _this.startMs) &&
            (identical(other.endMs, _this.endMs) ||
                other.endMs == _this.endMs) &&
            (identical(other.text, _this.text) || other.text == _this.text) &&
            (identical(other.sortOrder, _this.sortOrder) ||
                other.sortOrder == _this.sortOrder));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as SubtitleItem;
    return Object.hash(runtimeType, _this.id, _this.memoId, _this.startMs,
        _this.endMs, _this.text, _this.sortOrder);
  }

  @override
  String toString() {
    final _this = this as SubtitleItem;
    return 'SubtitleItem(id: ${_this.id}, memoId: ${_this.memoId}, startMs: ${_this.startMs}, endMs: ${_this.endMs}, text: ${_this.text}, sortOrder: ${_this.sortOrder})';
  }
}

/// @nodoc
abstract mixin class $SubtitleItemCopyWith<$Res> {
  factory $SubtitleItemCopyWith(
          SubtitleItem value, $Res Function(SubtitleItem) _then) =
      _$SubtitleItemCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String memoId,
      int startMs,
      int endMs,
      String text,
      int sortOrder});
}

/// @nodoc
class _$SubtitleItemCopyWithImpl<$Res> implements $SubtitleItemCopyWith<$Res> {
  _$SubtitleItemCopyWithImpl(this._self, this._then);

  final SubtitleItem _self;
  final $Res Function(SubtitleItem) _then;

  /// Create a copy of SubtitleItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? memoId = null,
    Object? startMs = null,
    Object? endMs = null,
    Object? text = null,
    Object? sortOrder = null,
  }) {
    return _then(SubtitleItem(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      memoId: null == memoId
          ? _self.memoId
          : memoId // ignore: cast_nullable_to_non_nullable
              as String,
      startMs: null == startMs
          ? _self.startMs
          : startMs // ignore: cast_nullable_to_non_nullable
              as int,
      endMs: null == endMs
          ? _self.endMs
          : endMs // ignore: cast_nullable_to_non_nullable
              as int,
      text: null == text
          ? _self.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      sortOrder: null == sortOrder
          ? _self.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// Adds pattern-matching-related methods to [SubtitleItem].
extension SubtitleItemPatterns on SubtitleItem {
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
    TResult Function(_SubtitleItem value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SubtitleItem() when $default != null:
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
    TResult Function(_SubtitleItem value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SubtitleItem():
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
    TResult? Function(_SubtitleItem value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SubtitleItem() when $default != null:
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
    TResult Function(String id, String memoId, int startMs, int endMs,
            String text, int sortOrder)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SubtitleItem() when $default != null:
        return $default(_that.id, _that.memoId, _that.startMs, _that.endMs,
            _that.text, _that.sortOrder);
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
    TResult Function(String id, String memoId, int startMs, int endMs,
            String text, int sortOrder)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SubtitleItem():
        return $default(_that.id, _that.memoId, _that.startMs, _that.endMs,
            _that.text, _that.sortOrder);
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
    TResult? Function(String id, String memoId, int startMs, int endMs,
            String text, int sortOrder)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SubtitleItem() when $default != null:
        return $default(_that.id, _that.memoId, _that.startMs, _that.endMs,
            _that.text, _that.sortOrder);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _SubtitleItem implements SubtitleItem {
  const _SubtitleItem(
      {required this.id,
      required this.memoId,
      required this.startMs,
      required this.endMs,
      required this.text,
      this.sortOrder = 0});
  factory _SubtitleItem.fromJson(Map<String, dynamic> json) =>
      _$SubtitleItemFromJson(json);

  @override
  final String id;
  @override
  final String memoId;
  @override
  final int startMs;
  @override
  final int endMs;
  @override
  final String text;
  @override
  @JsonKey()
  final int sortOrder;

  /// Create a copy of SubtitleItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SubtitleItemCopyWith<_SubtitleItem> get copyWith =>
      __$SubtitleItemCopyWithImpl<_SubtitleItem>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$SubtitleItemToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SubtitleItem &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.memoId, memoId) || other.memoId == memoId) &&
            (identical(other.startMs, startMs) || other.startMs == startMs) &&
            (identical(other.endMs, endMs) || other.endMs == endMs) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
        runtimeType, id, memoId, startMs, endMs, text, sortOrder);
  }

  @override
  String toString() {
    return 'SubtitleItem(id: $id, memoId: $memoId, startMs: $startMs, endMs: $endMs, text: $text, sortOrder: $sortOrder)';
  }
}

/// @nodoc
abstract mixin class _$SubtitleItemCopyWith<$Res>
    implements $SubtitleItemCopyWith<$Res> {
  factory _$SubtitleItemCopyWith(
          _SubtitleItem value, $Res Function(_SubtitleItem) _then) =
      __$SubtitleItemCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String memoId,
      int startMs,
      int endMs,
      String text,
      int sortOrder});
}

/// @nodoc
class __$SubtitleItemCopyWithImpl<$Res>
    implements _$SubtitleItemCopyWith<$Res> {
  __$SubtitleItemCopyWithImpl(this._self, this._then);

  final _SubtitleItem _self;
  final $Res Function(_SubtitleItem) _then;

  /// Create a copy of SubtitleItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? memoId = null,
    Object? startMs = null,
    Object? endMs = null,
    Object? text = null,
    Object? sortOrder = null,
  }) {
    return _then(_SubtitleItem(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      memoId: null == memoId
          ? _self.memoId
          : memoId // ignore: cast_nullable_to_non_nullable
              as String,
      startMs: null == startMs
          ? _self.startMs
          : startMs // ignore: cast_nullable_to_non_nullable
              as int,
      endMs: null == endMs
          ? _self.endMs
          : endMs // ignore: cast_nullable_to_non_nullable
              as int,
      text: null == text
          ? _self.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      sortOrder: null == sortOrder
          ? _self.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

// dart format on
