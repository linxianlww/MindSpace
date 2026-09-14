import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';

/// 录音时的实时波形（audio_waveforms 提供）。
class LiveWaveform extends StatelessWidget {
  const LiveWaveform({super.key, required this.controller, this.height = 80});
  final RecorderController controller;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      child: AudioWaveforms(
        size: Size(MediaQuery.sizeOf(context).width - 48, height),
        recorderController: controller,
        waveStyle: WaveStyle(
          waveColor: scheme.primary,
          scaleFactor: 120,
          showMiddleLine: false,
          extendWaveform: true,
          spacing: 4,
        ),
      ),
    );
  }
}

/// 播放时的静态波形：用预计算采样绘制，已播放部分高亮，点击/拖动可 seek。
class PlaybackWaveform extends StatelessWidget {
  const PlaybackWaveform({
    super.key,
    required this.wave,
    required this.positionMs,
    required this.durationMs,
    required this.onSeek,
    this.height = 72,
  });

  final List<int> wave;
  final int positionMs;
  final int durationMs;
  final void Function(int ms) onSeek;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          void seekAt(Offset local) {
            if (durationMs <= 0) return;
            final ratio =
                (local.dx / constraints.maxWidth).clamp(0.0, 1.0);
            onSeek((ratio * durationMs).round());
          }

          return GestureDetector(
            onTapDown: (d) => seekAt(d.localPosition),
            onHorizontalDragUpdate: (d) => seekAt(d.localPosition),
            child: CustomPaint(
              size: Size.infinite,
              painter: _WavePainter(
                wave: wave,
                progress: durationMs == 0
                    ? 0
                    : (positionMs / durationMs).clamp(0.0, 1.0),
                played: scheme.primary,
                unplayed: scheme.outlineVariant,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter(
      {required this.wave,
      required this.progress,
      required this.played,
      required this.unplayed});

  final List<int> wave;
  final double progress;
  final Color played;
  final Color unplayed;

  @override
  void paint(Canvas canvas, Size size) {
    const barWidth = 3.0;
    const gap = 2.0;
    final count = (size.width / (barWidth + gap)).floor();
    final samples = _resample(count);
    final paint = Paint()..strokeWidth = barWidth;
    final mid = size.height / 2;
    // 按峰值归一化：兼容 0..255 与 0..1000 等不同刻度，
    // 否则所有柱子会被 clamp 到同一高度（等高波形）。
    final peak = samples.fold<int>(1, (m, v) => v > m ? v : m);
    for (var i = 0; i < samples.length; i++) {
      final dx = i * (barWidth + gap);
      final norm = (samples[i] / peak).clamp(0.05, 1.0);
      final h = norm * size.height * 0.9;
      paint.color = (i / samples.length) <= progress ? played : unplayed;
      canvas.drawLine(
        Offset(dx, mid - h / 2),
        Offset(dx, mid + h / 2),
        paint,
      );
    }
  }

  List<int> _resample(int count) {
    if (wave.isEmpty) {
      // 无预计算波形时给一条平稳的占位波形。
      return List<int>.filled(count, 64);
    }
    final result = <int>[];
    final step = wave.length / count;
    for (var i = 0; i < count; i++) {
      final idx = (i * step).round().clamp(0, wave.length - 1);
      result.add(wave[idx]);
    }
    return result;
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) =>
      old.progress != progress || old.wave != wave;
}
