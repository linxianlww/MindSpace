import 'dart:async';
import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/di/providers.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/audio_memo_meta.dart';
import '../../data/models/subtitle_item.dart';

// —————————————————— 录音 ——————————————————
enum RecStatus { idle, recording, paused, stopped }

class RecorderValue {
  const RecorderValue(
      {this.status = RecStatus.idle, this.elapsedMs = 0, this.wave = const []});
  final RecStatus status;
  final int elapsedMs;
  final List<int> wave;

  RecorderValue copyWith(
          {RecStatus? status, int? elapsedMs, List<int>? wave}) =>
      RecorderValue(
        status: status ?? this.status,
        elapsedMs: elapsedMs ?? this.elapsedMs,
        wave: wave ?? this.wave,
      );
}

/// 录音机：开始/暂停/继续/停止 + 计时 + 实时波形（audio_waveforms 内置录音）。
class AudioRecorderNotifier extends StateNotifier<RecorderValue> {
  AudioRecorderNotifier() : super(const RecorderValue());
  final RecorderController controller = RecorderController();
  StreamSubscription<Duration>? _tick;

  /// 最近一次停止时已录制的时长（毫秒），stop() 复位后仍可读取。
  int _lastElapsedMs = 0;
  int get lastElapsedMs => _lastElapsedMs;

  /// 对外只读的已录时长（毫秒），避免外部直接访问受保护的 state。
  int get elapsedMs => state.elapsedMs;

  /// 开始录音。返回 false 表示麦克风权限未授予（插件内部会静默失败，
  /// 必须显式检查，否则界面看起来在录、实际什么都没录上）。
  Future<bool> start(String path) async {
    if (!await controller.checkPermission()) {
      return false;
    }
    try {
      await controller.record(path: path);
    } catch (_) {
      state = state.copyWith(status: RecStatus.idle);
      rethrow;
    }
    _tick?.cancel();
    _tick = controller.onCurrentDuration.listen((d) {
      state = state.copyWith(
        status: RecStatus.recording,
        elapsedMs: d.inMilliseconds,
        wave: controller.waveData
            .map((e) => (e * 1000).round().clamp(0, 1000))
            .toList(),
      );
    });
    state = state.copyWith(status: RecStatus.recording);
    return true;
  }

  Future<void> pause() async {
    await controller.pause();
    state = state.copyWith(status: RecStatus.paused);
  }

  // pause 后再次 record 即继续。
  Future<bool> resume(String path) async {
    if (!await controller.checkPermission()) {
      return false;
    }
    await controller.record(path: path);
    state = state.copyWith(status: RecStatus.recording);
    return true;
  }

  /// 停止并返回录音文件路径、波形采样与已录时长。
  ///
  /// 注意：controller.stop() 会 reset 并清空波形，且会把计时归零，
  /// 因此必须在 stop 之前先取波形与时长，否则永远是空波形 / 00:00。
  Future<({String? path, List<int> wave, int elapsedMs})> stop() async {
    final wave = controller.waveData
        .map((e) => (e * 1000).round().clamp(0, 1000))
        .toList();
    final elapsed = state.elapsedMs;
    final path = await controller.stop(false);
    controller.reset();
    _tick?.cancel();
    _lastElapsedMs = elapsed;
    state = RecorderValue(
        status: RecStatus.stopped, elapsedMs: elapsed, wave: wave);
    return (path: path, wave: wave, elapsedMs: elapsed);
  }

  Future<void> cancel() async {
    try {
      await controller.stop();
    } catch (_) {}
    state = const RecorderValue();
  }

  @override
  void dispose() {
    _tick?.cancel();
    controller.dispose();
    super.dispose();
  }
}

final recorderProvider =
    StateNotifierProvider<AudioRecorderNotifier, RecorderValue>(
        (ref) => AudioRecorderNotifier());

// —————————————————— 播放 ——————————————————
class AudioPlayerValue {
  const AudioPlayerValue({
    this.memoId = '',
    this.ready = false,
    this.positionMs = 0,
    this.durationMs = 0,
    this.fullDurationMs = 0,
    this.playing = false,
    this.speed = 1.0,
    this.looping = false,
    this.wave = const [],
    this.trimStartMs,
    this.trimEndMs,
    this.subs = const [],
    this.activeSubIndex = -1,
    this.error,
  });

  final String memoId;

  /// 播放器是否已完成加载（文件存在、时长解析成功）。
  final bool ready;

  /// 播放位置（裁剪后为 clip 内相对坐标，起点 0）。
  final int positionMs;

  /// 裁剪后的有效时长（未裁剪时等于全长）。
  final int durationMs;

  /// 文件原始全长（裁剪界面的滑块坐标始终基于全长）。
  final int fullDurationMs;

  final bool playing;
  final double speed;
  final bool looping;
  final List<int> wave;
  final int? trimStartMs;
  final int? trimEndMs;
  final List<SubtitleItem> subs;
  final int activeSubIndex;

  /// 初始化失败原因（文件缺失/解码失败等），非空时 UI 可据此展示提示。
  final String? error;

  AudioPlayerValue copyWith({
    bool? ready,
    int? positionMs,
    int? durationMs,
    int? fullDurationMs,
    bool? playing,
    double? speed,
    bool? looping,
    List<int>? wave,
    int? trimStartMs,
    int? trimEndMs,
    List<SubtitleItem>? subs,
    int? activeSubIndex,
    String? error,
  }) =>
      AudioPlayerValue(
        memoId: memoId,
        ready: ready ?? this.ready,
        positionMs: positionMs ?? this.positionMs,
        durationMs: durationMs ?? this.durationMs,
        fullDurationMs: fullDurationMs ?? this.fullDurationMs,
        playing: playing ?? this.playing,
        speed: speed ?? this.speed,
        looping: looping ?? this.looping,
        wave: wave ?? this.wave,
        trimStartMs: trimStartMs ?? this.trimStartMs,
        trimEndMs: trimEndMs ?? this.trimEndMs,
        subs: subs ?? this.subs,
        activeSubIndex: activeSubIndex ?? this.activeSubIndex,
        error: error ?? this.error,
      );
}

class AudioPlayerNotifier extends StateNotifier<AudioPlayerValue> {
  AudioPlayerNotifier(this._ref, this.memoId)
      : super(AudioPlayerValue(memoId: memoId)) {
    _init();
  }

  final Ref _ref;
  final String memoId;
  final AudioPlayer _player = AudioPlayer();
  final List<StreamSubscription> _subs = [];

  /// 页面已退出、notifier 已释放后不再异步写 state（否则抛 StateError）。
  bool _disposed = false;

  Future<void> _init() async {
    state = AudioPlayerValue(memoId: memoId);
    final repo = _ref.read(memoRepositoryProvider);
    final memo = await repo.findById(memoId);
    if (memo == null) {
      if (!_disposed) {
        state = AudioPlayerValue(memoId: memoId, error: '铭记不存在');
      }
      return;
    }
    final meta = AudioMemoMeta.of(memo);
    final path = meta.originalPath;
    if (path == null || !File(path).existsSync()) {
      // 文件缺失必须进入错误态并在 UI 提示，否则用户只看到
      // “信息正确（来自 meta）但播放无效”的假象。
      appLogger.w('音频文件不存在或为空: $path');
      if (!_disposed) {
        state = AudioPlayerValue(
          memoId: memoId,
          error: path == null
              ? '元数据缺少音频文件'
              : '音频文件不存在，可能已被系统清理，请重新导入',
        );
      }
      return;
    }

    // 字幕读取单独隔离：数据库异常不应拖垮音频初始化。
    var subs = const <SubtitleItem>[];
    try {
      subs = await repo.subtitlesOf(memoId);
    } catch (e) {
      appLogger.w('读取字幕失败', e);
    }
    if (_disposed) return;

    try {
      final dur = await _player.setFilePath(path);
      final fullMs = dur?.inMilliseconds ?? 0;
      var effective = fullMs;

      // 裁剪窗口边界保护：陈旧/越界的 trim 值会导致 setClip 抛错，
      // 从而让整段音频无法播放。
      var trimStart = meta.trimStartMs;
      var trimEnd = meta.trimEndMs;
      if (fullMs > 0) {
        trimStart = trimStart?.clamp(0, fullMs);
        trimEnd = trimEnd?.clamp(trimStart ?? 0, fullMs);
      }
      if (trimStart != null || trimEnd != null) {
        try {
          final clipped = await _player.setClip(
            start:
                trimStart == null ? null : Duration(milliseconds: trimStart),
            end: trimEnd == null ? null : Duration(milliseconds: trimEnd),
          );
          // setClip 会重新加载为 ClippingAudioSource，返回裁剪后的真实时长。
          effective = clipped?.inMilliseconds ?? effective;
        } catch (e) {
          appLogger.w('应用裁剪失败，回退为完整音频', e);
          await _player.setFilePath(path);
          effective = fullMs;
          trimStart = null;
          trimEnd = null;
        }
      }
      if (_disposed) return;

      // 立即进入就绪态（波形可用 meta 中已缓存的，缺失则由下方后补），
      // 保证大文件也能尽快点开播放，而不是长时间卡在“未加载”。
      state = AudioPlayerValue(
        memoId: memoId,
        ready: true,
        durationMs: effective,
        fullDurationMs: fullMs,
        wave: meta.waveform,
        trimStartMs: trimStart,
        trimEndMs: trimEnd,
        subs: subs,
      );

      _subs.add(_player.positionStream.listen((p) => _tick(p.inMilliseconds)));
      _subs.add(_player.playerStateStream.listen((s) {
        if (!_disposed) state = state.copyWith(playing: s.playing);
      }));
      _subs.add(_player.processingStateStream.listen((ps) {
        if (!_disposed && ps == ProcessingState.completed && !state.looping) {
          state = state.copyWith(playing: false);
        }
      }));
    } catch (e) {
      // 初始化失败（解码器不支持、文件损坏等）：记录错误态而非卡在
      // “00:00 且无法播放”的中间态。
      appLogger.e('音频播放器初始化失败', e);
      if (!_disposed) {
        state = AudioPlayerValue(memoId: memoId, error: _friendlyError(e));
      }
      return;
    }

    // 波形后置提取：不阻塞“可播放”。成功则持久化并刷新 UI。
    if (state.wave.isEmpty && !_disposed) {
      final wave = await _extractWaveform(path);
      if (!_disposed && wave.isNotEmpty) {
        unawaited(_ref
            .read(memoRepositoryProvider)
            .updateMetadata(memoId, {AudioMemoMeta.kWaveform: wave}));
        state = state.copyWith(wave: wave);
      }
    }
  }

  /// 把底层异常转成用户能理解的中文提示。
  String _friendlyError(Object e) {
    final s = e.toString().toLowerCase();
    if (s.contains('unrecognizedinputformat') ||
        s.contains('unsupported') ||
        s.contains('invalidtrack') ||
        s.contains('cannotload') ||
        s.contains('no decoder') ||
        (s.contains('illegalstate') && s.contains('decoder'))) {
      return '该音频格式不受支持，请转成 mp3/wav/m4a 后重试';
    }
    if (s.contains('not found') || s.contains('no such file')) {
      return '音频文件不可用，可能已被系统清理';
    }
    return '$e';
  }

  /// 出错的播放器重新初始化（已修复/文件已重新导入等场景）。
  Future<void> retry() async {
    if (_disposed) return;
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    try {
      await _player.stop();
    } catch (_) {}
    await _init();
  }

  /// 用 audio_waveforms 解码提取波形振幅（0..255）。异常时返回空列表。
  Future<List<int>> _extractWaveform(String path) async {
    final extractor = PlayerController();
    try {
      final data =
          await extractor.extractWaveformData(path: path, noOfSamples: 256);
      return data.map((e) => (e * 255).round().clamp(0, 255)).toList();
    } catch (e) {
      appLogger.w('波形提取失败，使用占位波形', e);
      return const [];
    } finally {
      extractor.dispose();
    }
  }

  void _tick(int pos) {
    // 有序字幕：倒序找最后一个 start<=pos 的条目（跳过 fallback 判等，
    // 只在节点变化时重建 state，降低高频 position 监听的开销）。
    var active = -1;
    for (var i = state.subs.length - 1; i >= 0; i--) {
      final s = state.subs[i];
      if (s.startMs <= pos && (s.endMs == 0 || pos < s.endMs)) {
        active = i;
        break;
      }
    }
    if (pos == state.positionMs && active == state.activeSubIndex) return;
    state = state.copyWith(positionMs: pos, activeSubIndex: active);
  }

  Future<void> toggle() async {
    // 未就绪（加载中/出错/无源）时忽略点击，避免在空 source 上 play 无反馈。
    if (!state.ready || state.error != null) return;
    try {
      if (!_player.playing) {
        await _player.play();
      } else {
        await _player.pause();
      }
    } catch (e) {
      appLogger.w('播放/暂停失败', e);
    }
  }

  /// 从指定绝对位置开始播放，用于裁剪试听/字幕跳转。
  ///
  /// 播放器已裁剪时其坐标系是 clip 内相对坐标（0 起点），此处统一
  /// 接收“绝对时间轴”毫秒并内部换算为 clip 内位置，避免越界。
  Future<void> playFrom(int absMs) async {
    try {
      final rel = absMs - (state.trimStartMs ?? 0);
      await _player.seek(
        Duration(milliseconds: rel.clamp(0, state.durationMs)),
      );
      await _player.play();
    } catch (e) {
      appLogger.w('试听失败', e);
    }
  }

  Future<void> seekTo(int absMs) async {
    try {
      final rel = absMs - (state.trimStartMs ?? 0);
      await _player.seek(
        Duration(milliseconds: rel.clamp(0, state.durationMs)),
      );
    } catch (e) {
      appLogger.w('seek 失败', e);
    }
  }

  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (_) {}
  }

  Future<void> setSpeed(double speed) async {
    try {
      await _player.setSpeed(speed);
      if (!_disposed) state = state.copyWith(speed: speed);
    } catch (e) {
      appLogger.w('设置倍速失败', e);
    }
  }

  Future<void> toggleLoop() async {
    final next = !state.looping;
    try {
      await _player.setLoopMode(next ? LoopMode.one : LoopMode.off);
      if (!_disposed) state = state.copyWith(looping: next);
    } catch (e) {
      appLogger.w('切换循环失败', e);
    }
  }

  /// 跳转字幕。
  void jumpToSubtitle(int index) {
    final s = state.subs[index];
    playFrom(s.startMs);
  }

  /// 重新从数据库加载字幕（导入/替换字幕成功后调用）。
  Future<void> reloadSubtitles() async {
    final items = await _ref.read(memoRepositoryProvider).subtitlesOf(memoId);
    if (_disposed) return;
    state = state.copyWith(subs: items, activeSubIndex: -1);
  }

  /// 保存裁剪窗口（试听区间），并据此设置播放裁剪。
  ///
  /// ① 先重新加载原始文件再 setClip：just_audio 的 setClip 是在“当前
  /// source”上再包一层 ClippingAudioSource，若沿用上一次裁剪后的 source
  /// 会不断嵌套，导致第二次裁剪坐标错乱、无法真正恢复完整音频。
  /// ② 裁剪以 [memoId] 为 provider key，保存 meta 不会触发播放器重建。
  Future<void> setTrimWindow(int? startMs, int? endMs) async {
    final repo = _ref.read(memoRepositoryProvider);
    final memo = await repo.findById(memoId);
    if (memo == null || _disposed) return;
    final path = AudioMemoMeta.of(memo).originalPath;
    if (path == null || !File(path).existsSync()) return;

    final fullMs = state.fullDurationMs;
    try {
      // ① 重新加载原始文件，彻底移除可能存在的旧裁剪。
      final dur = await _player.setFilePath(path);
      final actualFull = dur?.inMilliseconds ?? fullMs;
      if (actualFull <= 0 || _disposed) return;

      // ② 裁剪窗口边界保护：越界值会让 setClip 抛错。
      var s = startMs;
      var e = endMs;
      if (s != null) s = s.clamp(0, actualFull);
      if (e != null) e = e.clamp(s ?? 0, actualFull);

      // ③ 按需应用新裁剪窗口。
      var effective = actualFull;
      if (s != null || e != null) {
        final clipped = await _player.setClip(
          start: s == null ? null : Duration(milliseconds: s),
          end: e == null ? null : Duration(milliseconds: e),
        );
        final end = e ?? actualFull;
        effective = clipped?.inMilliseconds ??
            ((end - (s ?? 0)).clamp(0, actualFull)).toInt();
      }
      if (_disposed) return;

      // ④ 持久化裁剪元数据。
      final nextMeta = Map<String, dynamic>.from(memo.metadata)
        ..[AudioMemoMeta.kTrimStartMs] = s
        ..[AudioMemoMeta.kTrimEndMs] = e
        ..[AudioMemoMeta.kDurationMs] = effective;
      // 仅在有裁剪时记录原始全长（清除裁剪后无需保留）。
      if (s != null || e != null) {
        nextMeta[AudioMemoMeta.kOriginalDurationMs] =
            AudioMemoMeta.of(memo).originalDurationMs ?? actualFull;
      }
      await repo.save(memo.copyWith(metadata: nextMeta));

      // ⑤ setClip 后 position 是 clip 内相对坐标（0 起点），
      // seek 绝对毫秒会越界到末尾；直接归零并从裁剪起点开始。
      await _player.seek(Duration.zero);
      if (_disposed) return;
      state = AudioPlayerValue(
        memoId: memoId,
        ready: true,
        positionMs: 0,
        durationMs: effective,
        fullDurationMs: actualFull,
        wave: state.wave,
        trimStartMs: s,
        trimEndMs: e,
        subs: state.subs,
        speed: state.speed,
        looping: state.looping,
      );
    } catch (err) {
      // 失败时回退到完整音频，避免 setClip 嵌套使后续裁剪坐标错乱。
      appLogger.e('设置裁剪窗口失败', err);
      try {
        await _player.setFilePath(path);
        await _player.seek(Duration.zero);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _disposed = true;
    for (final s in _subs) {
      s.cancel();
    }
    _player.dispose();
    super.dispose();
  }
}

final audioPlayerProvider = StateNotifierProvider.family
    .autoDispose<AudioPlayerNotifier, AudioPlayerValue, String>(
        (ref, memoId) => AudioPlayerNotifier(ref, memoId));