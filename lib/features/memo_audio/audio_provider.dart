import 'dart:async';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/di/providers.dart';
import '../../data/models/memo.dart';
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

  /// 对外只读的已录时长（毫秒），避免外部直接访问受保护的 state。
  int get elapsedMs => state.elapsedMs;

  Future<void> start(String path) async {
    await controller.record(path: path);
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
  }

  Future<void> pause() async {
    await controller.pause();
    state = state.copyWith(status: RecStatus.paused);
  }

  // pause 后再次 record 即继续。
  Future<void> resume(String path) async {
    await controller.record(path: path);
    state = state.copyWith(status: RecStatus.recording);
  }

  /// 停止并返回录音文件路径与波形采样。
  Future<({String? path, List<int> wave})> stop() async {
    final path = await controller.stop();
    final wave = controller.waveData
        .map((e) => (e * 1000).round().clamp(0, 1000))
        .toList();
    _tick?.cancel();
    state = const RecorderValue(status: RecStatus.stopped);
    return (path: path, wave: wave);
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
    required this.memo,
    required this.player,
    this.positionMs = 0,
    this.durationMs = 0,
    this.playing = false,
    this.speed = 1.0,
    this.looping = false,
    this.wave = const [],
    this.trimStartMs,
    this.trimEndMs,
    this.subs = const [],
    this.activeSubIndex = -1,
  });

  final Memo memo;
  final AudioPlayer player;
  final int positionMs;
  final int durationMs;
  final bool playing;
  final double speed;
  final bool looping;
  final List<int> wave;
  final int? trimStartMs;
  final int? trimEndMs;
  final List<SubtitleItem> subs;
  final int activeSubIndex;

  AudioPlayerValue copyWith({
    int? positionMs,
    int? durationMs,
    bool? playing,
    double? speed,
    bool? looping,
    int? activeSubIndex,
  }) =>
      AudioPlayerValue(
        memo: memo,
        player: player,
        positionMs: positionMs ?? this.positionMs,
        durationMs: durationMs ?? this.durationMs,
        playing: playing ?? this.playing,
        speed: speed ?? this.speed,
        looping: looping ?? this.looping,
        wave: wave,
        trimStartMs: trimStartMs,
        trimEndMs: trimEndMs,
        subs: subs,
        activeSubIndex: activeSubIndex ?? this.activeSubIndex,
      );
}

class AudioPlayerNotifier extends StateNotifier<AudioPlayerValue> {
  AudioPlayerNotifier(this._ref, this._memo)
      : super(AudioPlayerValue(memo: _memo, player: AudioPlayer())) {
    _init();
  }

  final Ref _ref;
  final Memo _memo;
  final List<StreamSubscription> _subs = [];

  Future<void> _init() async {
    final player = state.player;
    final path = _memo.metadata['trimmedPath'] ??
        _memo.metadata['originalPath'] as String?;
    if (path == null) return;
    final dur = await player.setFilePath(path);
    final meta = _memo.metadata;
    final wave = (meta['waveform'] as List?)?.map((e) => e as int).toList() ??
        const <int>[];
    final subs = await _ref.read(memoRepositoryProvider).subtitlesOf(_memo.id);

    final trimStart = meta['trimStartMs'] as int?;
    final trimEnd = meta['trimEndMs'] as int?;
    if (trimStart != null || trimEnd != null) {
      await player.setClip(
        start: trimStart == null ? null : Duration(milliseconds: trimStart),
        end: trimEnd == null ? null : Duration(milliseconds: trimEnd),
      );
    }

    state = AudioPlayerValue(
      memo: _memo,
      player: player,
      durationMs: dur?.inMilliseconds ?? 0,
      wave: wave,
      trimStartMs: trimStart,
      trimEndMs: trimEnd,
      subs: subs,
    );

    _subs.add(player.positionStream.listen((p) => _tick(p.inMilliseconds)));
    _subs.add(player.playerStateStream.listen((s) {
      state = state.copyWith(playing: s.playing);
    }));
    player.processingStateStream.listen((ps) {
      if (ps == ProcessingState.completed && !state.looping) {
        state = state.copyWith(playing: false);
      }
    });
  }

  void _tick(int pos) {
    var active = -1;
    for (var i = 0; i < state.subs.length; i++) {
      final s = state.subs[i];
      if (s.startMs <= pos && (s.endMs == 0 || pos < s.endMs)) active = i;
    }
    state = state.copyWith(positionMs: pos, activeSubIndex: active);
  }

  Future<void> toggle() async {
    final p = state.player;
    if (p.playing) {
      await p.pause();
    } else {
      await p.play();
    }
  }

  Future<void> seekTo(int ms) =>
      state.player.seek(Duration(milliseconds: ms));

  Future<void> setSpeed(double speed) async {
    await state.player.setSpeed(speed);
    state = state.copyWith(speed: speed);
  }

  Future<void> toggleLoop() async {
    final next = !state.looping;
    await state.player
        .setLoopMode(next ? LoopMode.one : LoopMode.off);
    state = state.copyWith(looping: next);
  }

  /// 跳转字幕。
  void jumpToSubtitle(int index) {
    final s = state.subs[index];
    seekTo(s.startMs);
  }

  /// 保存裁剪窗口（试听区间），并据此设置播放裁剪。
  Future<void> setTrimWindow(int? startMs, int? endMs) async {
    final repo = _ref.read(memoRepositoryProvider);
    final next = _memo.copyWith(metadata: {
      ..._memo.metadata,
      'trimStartMs': startMs,
      'trimEndMs': endMs,
    });
    await repo.save(next);
    await state.player.setClip(
      start: startMs == null ? null : Duration(milliseconds: startMs),
      end: endMs == null ? null : Duration(milliseconds: endMs),
    );
    state = AudioPlayerValue(
      memo: next,
      player: state.player,
      durationMs: state.durationMs,
      wave: state.wave,
      trimStartMs: startMs,
      trimEndMs: endMs,
      subs: state.subs,
    );
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    state.player.dispose();
    super.dispose();
  }
}

final audioPlayerProvider = StateNotifierProvider.family
    .autoDispose<AudioPlayerNotifier, AudioPlayerValue, Memo>(
        (ref, memo) => AudioPlayerNotifier(ref, memo));
