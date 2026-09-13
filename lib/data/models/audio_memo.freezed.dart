// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'audio_memo.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AudioMemo {
  String get memoId;
  String get originalPath;
  String? get trimmedPath;
  int get durationMs;
  List<int> get waveform;
  List<SubtitleItem> get subtitles;
  int? get trimStartMs;
  int? get trimEndMs;

  /// Create a copy of AudioMemo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AudioMemoCopyWith<AudioMemo> get copyWith =>
      _$AudioMemoCopyWithImpl<AudioMemo>(this as AudioMemo, _$identity);

  /// Serializes this AudioMemo to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as AudioMemo;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AudioMemo &&
            (identical(other.memoId, _this.memoId) ||
                other.memoId == _this.memoId) &&
            (identical(other.originalPath, _this.originalPath) ||
                other.originalPath == _this.originalPath) &&
            (identical(other.trimmedPath, _this.trimmedPath) ||
                other.trimmedPath == _this.trimmedPath) &&
            (identical(other.durationMs, _this.durationMs) ||
                other.durationMs == _this.durationMs) &&
            const DeepCollectionEquality()
                .equals(other.waveform, _this.waveform) &&
            const DeepCollectionEquality()
                .equals(other.subtitles, _this.subtitles) &&
            (identical(other.trimStartMs, _this.trimStartMs) ||
                other.trimStartMs == _this.trimStartMs) &&
            (identical(other.trimEndMs, _this.trimEndMs) ||
                other.trimEndMs == _this.trimEndMs));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as AudioMemo;
    return Object.hash(
        runtimeType,
        _this.memoId,
        _this.originalPath,
        _this.trimmedPath,
        _this.durationMs,
        const DeepCollectionEquality().hash(_this.waveform),
        const DeepCollectionEquality().hash(_this.subtitles),
        _this.trimStartMs,
        _this.trimEndMs);
  }

  @override
  String toString() {
    final _this = this as AudioMemo;
    return 'AudioMemo(memoId: ${_this.memoId}, originalPath: ${_this.originalPath}, trimmedPath: ${_this.trimmedPath}, durationMs: ${_this.durationMs}, waveform: ${_this.waveform}, subtitles: ${_this.subtitles}, trimStartMs: ${_this.trimStartMs}, trimEndMs: ${_this.trimEndMs})';
  }
}

/// @nodoc
abstract mixin class $AudioMemoCopyWith<$Res> {
  factory $AudioMemoCopyWith(AudioMemo value, $Res Function(AudioMemo) _then) =
      _$AudioMemoCopyWithImpl;
  @useResult
  $Res call(
      {String memoId,
      String originalPath,
      String? trimmedPath,
      int durationMs,
      List<int> waveform,
      List<SubtitleItem> subtitles,
      int? trimStartMs,
      int? trimEndMs});
}

/// @nodoc
class _$AudioMemoCopyWithImpl<$Res> implements $AudioMemoCopyWith<$Res> {
  _$AudioMemoCopyWithImpl(this._self, this._then);

  final AudioMemo _self;
  final $Res Function(AudioMemo) _then;

  /// Create a copy of AudioMemo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? memoId = null,
    Object? originalPath = null,
    Object? trimmedPath = freezed,
    Object? durationMs = null,
    Object? waveform = null,
    Object? subtitles = null,
    Object? trimStartMs = freezed,
    Object? trimEndMs = freezed,
  }) {
    return _then(AudioMemo(
      memoId: null == memoId
          ? _self.memoId
          : memoId // ignore: cast_nullable_to_non_nullable
              as String,
      originalPath: null == originalPath
          ? _self.originalPath
          : originalPath // ignore: cast_nullable_to_non_nullable
              as String,
      trimmedPath: freezed == trimmedPath
          ? _self.trimmedPath
          : trimmedPath // ignore: cast_nullable_to_non_nullable
              as String?,
      durationMs: null == durationMs
          ? _self.durationMs
          : durationMs // ignore: cast_nullable_to_non_nullable
              as int,
      waveform: null == waveform
          ? _self.waveform
          : waveform // ignore: cast_nullable_to_non_nullable
              as List<int>,
      subtitles: null == subtitles
          ? _self.subtitles
          : subtitles // ignore: cast_nullable_to_non_nullable
              as List<SubtitleItem>,
      trimStartMs: freezed == trimStartMs
          ? _self.trimStartMs
          : trimStartMs // ignore: cast_nullable_to_non_nullable
              as int?,
      trimEndMs: freezed == trimEndMs
          ? _self.trimEndMs
          : trimEndMs // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// Adds pattern-matching-related methods to [AudioMemo].
extension AudioMemoPatterns on AudioMemo {
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
    TResult Function(_AudioMemo value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AudioMemo() when $default != null:
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
    TResult Function(_AudioMemo value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AudioMemo():
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
    TResult? Function(_AudioMemo value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AudioMemo() when $default != null:
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
            String memoId,
            String originalPath,
            String? trimmedPath,
            int durationMs,
            List<int> waveform,
            List<SubtitleItem> subtitles,
            int? trimStartMs,
            int? trimEndMs)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AudioMemo() when $default != null:
        return $default(
            _that.memoId,
            _that.originalPath,
            _that.trimmedPath,
            _that.durationMs,
            _that.waveform,
            _that.subtitles,
            _that.trimStartMs,
            _that.trimEndMs);
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
            String memoId,
            String originalPath,
            String? trimmedPath,
            int durationMs,
            List<int> waveform,
            List<SubtitleItem> subtitles,
            int? trimStartMs,
            int? trimEndMs)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AudioMemo():
        return $default(
            _that.memoId,
            _that.originalPath,
            _that.trimmedPath,
            _that.durationMs,
            _that.waveform,
            _that.subtitles,
            _that.trimStartMs,
            _that.trimEndMs);
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
            String memoId,
            String originalPath,
            String? trimmedPath,
            int durationMs,
            List<int> waveform,
            List<SubtitleItem> subtitles,
            int? trimStartMs,
            int? trimEndMs)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AudioMemo() when $default != null:
        return $default(
            _that.memoId,
            _that.originalPath,
            _that.trimmedPath,
            _that.durationMs,
            _that.waveform,
            _that.subtitles,
            _that.trimStartMs,
            _that.trimEndMs);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _AudioMemo implements AudioMemo {
  const _AudioMemo(
      {required this.memoId,
      required this.originalPath,
      this.trimmedPath,
      this.durationMs = 0,
      List<int> waveform = const <int>[],
      List<SubtitleItem> subtitles = const <SubtitleItem>[],
      this.trimStartMs,
      this.trimEndMs})
      : _waveform = waveform,
        _subtitles = subtitles;
  factory _AudioMemo.fromJson(Map<String, dynamic> json) =>
      _$AudioMemoFromJson(json);

  @override
  final String memoId;
  @override
  final String originalPath;
  @override
  final String? trimmedPath;
  @override
  @JsonKey()
  final int durationMs;
  final List<int> _waveform;
  @override
  @JsonKey()
  List<int> get waveform {
    if (_waveform is EqualUnmodifiableListView) return _waveform;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_waveform);
  }

  final List<SubtitleItem> _subtitles;
  @override
  @JsonKey()
  List<SubtitleItem> get subtitles {
    if (_subtitles is EqualUnmodifiableListView) return _subtitles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_subtitles);
  }

  @override
  final int? trimStartMs;
  @override
  final int? trimEndMs;

  /// Create a copy of AudioMemo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AudioMemoCopyWith<_AudioMemo> get copyWith =>
      __$AudioMemoCopyWithImpl<_AudioMemo>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$AudioMemoToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AudioMemo &&
            (identical(other.memoId, memoId) || other.memoId == memoId) &&
            (identical(other.originalPath, originalPath) ||
                other.originalPath == originalPath) &&
            (identical(other.trimmedPath, trimmedPath) ||
                other.trimmedPath == trimmedPath) &&
            (identical(other.durationMs, durationMs) ||
                other.durationMs == durationMs) &&
            const DeepCollectionEquality().equals(other.waveform, _waveform) &&
            const DeepCollectionEquality()
                .equals(other.subtitles, _subtitles) &&
            (identical(other.trimStartMs, trimStartMs) ||
                other.trimStartMs == trimStartMs) &&
            (identical(other.trimEndMs, trimEndMs) ||
                other.trimEndMs == trimEndMs));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
        runtimeType,
        memoId,
        originalPath,
        trimmedPath,
        durationMs,
        const DeepCollectionEquality().hash(_waveform),
        const DeepCollectionEquality().hash(_subtitles),
        trimStartMs,
        trimEndMs);
  }

  @override
  String toString() {
    return 'AudioMemo(memoId: $memoId, originalPath: $originalPath, trimmedPath: $trimmedPath, durationMs: $durationMs, waveform: $waveform, subtitles: $subtitles, trimStartMs: $trimStartMs, trimEndMs: $trimEndMs)';
  }
}

/// @nodoc
abstract mixin class _$AudioMemoCopyWith<$Res>
    implements $AudioMemoCopyWith<$Res> {
  factory _$AudioMemoCopyWith(
          _AudioMemo value, $Res Function(_AudioMemo) _then) =
      __$AudioMemoCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String memoId,
      String originalPath,
      String? trimmedPath,
      int durationMs,
      List<int> waveform,
      List<SubtitleItem> subtitles,
      int? trimStartMs,
      int? trimEndMs});
}

/// @nodoc
class __$AudioMemoCopyWithImpl<$Res> implements _$AudioMemoCopyWith<$Res> {
  __$AudioMemoCopyWithImpl(this._self, this._then);

  final _AudioMemo _self;
  final $Res Function(_AudioMemo) _then;

  /// Create a copy of AudioMemo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? memoId = null,
    Object? originalPath = null,
    Object? trimmedPath = freezed,
    Object? durationMs = null,
    Object? waveform = null,
    Object? subtitles = null,
    Object? trimStartMs = freezed,
    Object? trimEndMs = freezed,
  }) {
    return _then(_AudioMemo(
      memoId: null == memoId
          ? _self.memoId
          : memoId // ignore: cast_nullable_to_non_nullable
              as String,
      originalPath: null == originalPath
          ? _self.originalPath
          : originalPath // ignore: cast_nullable_to_non_nullable
              as String,
      trimmedPath: freezed == trimmedPath
          ? _self.trimmedPath
          : trimmedPath // ignore: cast_nullable_to_non_nullable
              as String?,
      durationMs: null == durationMs
          ? _self.durationMs
          : durationMs // ignore: cast_nullable_to_non_nullable
              as int,
      waveform: null == waveform
          ? _self._waveform
          : waveform // ignore: cast_nullable_to_non_nullable
              as List<int>,
      subtitles: null == subtitles
          ? _self._subtitles
          : subtitles // ignore: cast_nullable_to_non_nullable
              as List<SubtitleItem>,
      trimStartMs: freezed == trimStartMs
          ? _self.trimStartMs
          : trimStartMs // ignore: cast_nullable_to_non_nullable
              as int?,
      trimEndMs: freezed == trimEndMs
          ? _self.trimEndMs
          : trimEndMs // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

// dart format on
