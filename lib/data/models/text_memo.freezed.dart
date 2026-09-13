// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'text_memo.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TextMemo {
  String get memoId;
  List<dynamic> get deltaJson;
  String get markdown;
  String get plainText;
  String? get filePath;

  /// Create a copy of TextMemo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TextMemoCopyWith<TextMemo> get copyWith =>
      _$TextMemoCopyWithImpl<TextMemo>(this as TextMemo, _$identity);

  /// Serializes this TextMemo to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as TextMemo;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TextMemo &&
            (identical(other.memoId, _this.memoId) ||
                other.memoId == _this.memoId) &&
            const DeepCollectionEquality()
                .equals(other.deltaJson, _this.deltaJson) &&
            (identical(other.markdown, _this.markdown) ||
                other.markdown == _this.markdown) &&
            (identical(other.plainText, _this.plainText) ||
                other.plainText == _this.plainText) &&
            (identical(other.filePath, _this.filePath) ||
                other.filePath == _this.filePath));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as TextMemo;
    return Object.hash(
        runtimeType,
        _this.memoId,
        const DeepCollectionEquality().hash(_this.deltaJson),
        _this.markdown,
        _this.plainText,
        _this.filePath);
  }

  @override
  String toString() {
    final _this = this as TextMemo;
    return 'TextMemo(memoId: ${_this.memoId}, deltaJson: ${_this.deltaJson}, markdown: ${_this.markdown}, plainText: ${_this.plainText}, filePath: ${_this.filePath})';
  }
}

/// @nodoc
abstract mixin class $TextMemoCopyWith<$Res> {
  factory $TextMemoCopyWith(TextMemo value, $Res Function(TextMemo) _then) =
      _$TextMemoCopyWithImpl;
  @useResult
  $Res call(
      {String memoId,
      List<dynamic> deltaJson,
      String markdown,
      String plainText,
      String? filePath});
}

/// @nodoc
class _$TextMemoCopyWithImpl<$Res> implements $TextMemoCopyWith<$Res> {
  _$TextMemoCopyWithImpl(this._self, this._then);

  final TextMemo _self;
  final $Res Function(TextMemo) _then;

  /// Create a copy of TextMemo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? memoId = null,
    Object? deltaJson = null,
    Object? markdown = null,
    Object? plainText = null,
    Object? filePath = freezed,
  }) {
    return _then(TextMemo(
      memoId: null == memoId
          ? _self.memoId
          : memoId // ignore: cast_nullable_to_non_nullable
              as String,
      deltaJson: null == deltaJson
          ? _self.deltaJson
          : deltaJson // ignore: cast_nullable_to_non_nullable
              as List<dynamic>,
      markdown: null == markdown
          ? _self.markdown
          : markdown // ignore: cast_nullable_to_non_nullable
              as String,
      plainText: null == plainText
          ? _self.plainText
          : plainText // ignore: cast_nullable_to_non_nullable
              as String,
      filePath: freezed == filePath
          ? _self.filePath
          : filePath // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [TextMemo].
extension TextMemoPatterns on TextMemo {
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
    TResult Function(_TextMemo value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TextMemo() when $default != null:
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
    TResult Function(_TextMemo value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TextMemo():
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
    TResult? Function(_TextMemo value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TextMemo() when $default != null:
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
    TResult Function(String memoId, List<dynamic> deltaJson, String markdown,
            String plainText, String? filePath)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TextMemo() when $default != null:
        return $default(_that.memoId, _that.deltaJson, _that.markdown,
            _that.plainText, _that.filePath);
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
    TResult Function(String memoId, List<dynamic> deltaJson, String markdown,
            String plainText, String? filePath)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TextMemo():
        return $default(_that.memoId, _that.deltaJson, _that.markdown,
            _that.plainText, _that.filePath);
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
    TResult? Function(String memoId, List<dynamic> deltaJson, String markdown,
            String plainText, String? filePath)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TextMemo() when $default != null:
        return $default(_that.memoId, _that.deltaJson, _that.markdown,
            _that.plainText, _that.filePath);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _TextMemo implements TextMemo {
  const _TextMemo(
      {required this.memoId,
      List<dynamic> deltaJson = const <dynamic>[],
      this.markdown = '',
      this.plainText = '',
      this.filePath})
      : _deltaJson = deltaJson;
  factory _TextMemo.fromJson(Map<String, dynamic> json) =>
      _$TextMemoFromJson(json);

  @override
  final String memoId;
  final List<dynamic> _deltaJson;
  @override
  @JsonKey()
  List<dynamic> get deltaJson {
    if (_deltaJson is EqualUnmodifiableListView) return _deltaJson;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_deltaJson);
  }

  @override
  @JsonKey()
  final String markdown;
  @override
  @JsonKey()
  final String plainText;
  @override
  final String? filePath;

  /// Create a copy of TextMemo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TextMemoCopyWith<_TextMemo> get copyWith =>
      __$TextMemoCopyWithImpl<_TextMemo>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$TextMemoToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TextMemo &&
            (identical(other.memoId, memoId) || other.memoId == memoId) &&
            const DeepCollectionEquality()
                .equals(other.deltaJson, _deltaJson) &&
            (identical(other.markdown, markdown) ||
                other.markdown == markdown) &&
            (identical(other.plainText, plainText) ||
                other.plainText == plainText) &&
            (identical(other.filePath, filePath) ||
                other.filePath == filePath));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
        runtimeType,
        memoId,
        const DeepCollectionEquality().hash(_deltaJson),
        markdown,
        plainText,
        filePath);
  }

  @override
  String toString() {
    return 'TextMemo(memoId: $memoId, deltaJson: $deltaJson, markdown: $markdown, plainText: $plainText, filePath: $filePath)';
  }
}

/// @nodoc
abstract mixin class _$TextMemoCopyWith<$Res>
    implements $TextMemoCopyWith<$Res> {
  factory _$TextMemoCopyWith(_TextMemo value, $Res Function(_TextMemo) _then) =
      __$TextMemoCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String memoId,
      List<dynamic> deltaJson,
      String markdown,
      String plainText,
      String? filePath});
}

/// @nodoc
class __$TextMemoCopyWithImpl<$Res> implements _$TextMemoCopyWith<$Res> {
  __$TextMemoCopyWithImpl(this._self, this._then);

  final _TextMemo _self;
  final $Res Function(_TextMemo) _then;

  /// Create a copy of TextMemo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? memoId = null,
    Object? deltaJson = null,
    Object? markdown = null,
    Object? plainText = null,
    Object? filePath = freezed,
  }) {
    return _then(_TextMemo(
      memoId: null == memoId
          ? _self.memoId
          : memoId // ignore: cast_nullable_to_non_nullable
              as String,
      deltaJson: null == deltaJson
          ? _self._deltaJson
          : deltaJson // ignore: cast_nullable_to_non_nullable
              as List<dynamic>,
      markdown: null == markdown
          ? _self.markdown
          : markdown // ignore: cast_nullable_to_non_nullable
              as String,
      plainText: null == plainText
          ? _self.plainText
          : plainText // ignore: cast_nullable_to_non_nullable
              as String,
      filePath: freezed == filePath
          ? _self.filePath
          : filePath // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
