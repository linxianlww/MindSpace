import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/ms_date_utils.dart';
import '../audio_provider.dart';

/// 音频裁剪区间选择：拖动两端滑块选择保留区间，内嵌播放控制可直接试听。
///
/// 说明：采用“裁剪窗口”方案——播放与导出都以 trimStart/trimEnd 为准
/// （just_audio.setClip 精确试听），不做有损重编码。
///
/// 交互逻辑：
/// - 拖动两端滑块 → 设定“保留区间”（绿色区间），拖动时自动暂停播放；
/// - 播放/暂停按钮 → 从当前起点试听，进度实时显示在下方；
/// - 应用裁剪 → 把当前区间写为裁剪窗口并落盘；
/// - 恢复完整音频 → 清除裁剪窗口（仅当当前已有裁剪时可用）。
class AudioTrimmer extends ConsumerStatefulWidget {
  const AudioTrimmer({
    super.key,
    required this.memoId,
    required this.durationMs,
    this.initialStart,
    this.initialEnd,
    required this.onApply,
  });

  final String memoId;
  /// 文件原始全长（滑块坐标始终基于全长，避免第二次裁剪时
  /// 坐标系缩到裁剪后时长导致无法再次/恢复）。
  final int durationMs;
  final int? initialStart;
  final int? initialEnd;
  final void Function(int? startMs, int? endMs) onApply;

  @override
  ConsumerState<AudioTrimmer> createState() => _AudioTrimmerState();
}

class _AudioTrimmerState extends ConsumerState<AudioTrimmer> {
  late double _start = (widget.initialStart ?? 0).toDouble();
  late double _end = (widget.initialEnd ?? widget.durationMs).toDouble();

  bool get _hasExistingTrim =>
      widget.initialStart != null || widget.initialEnd != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final max = widget.durationMs.toDouble().clamp(1, double.infinity).toDouble();
    _end = _end.clamp(0, max).toDouble();
    if (_end < _start) _end = _start;
    final selectedMs = (_end - _start).round();

    final player = ref.watch(audioPlayerProvider(widget.memoId));
    final notifier = ref.read(audioPlayerProvider(widget.memoId).notifier);
    // 播放器已裁剪时其 position 是 clip 内相对坐标（0 起点），
    // 换算回绝对坐标以对齐滑块与时长标签。
    final realStart = (player.trimStartMs ?? 0);
    final absPos = player.positionMs + realStart;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text('裁剪音频', style: theme.textTheme.titleMedium),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              '拖动两端滑块，绿色区间为保留片段',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 16),
          RangeSlider(
            values: RangeValues(_start, _end),
            min: 0,
            max: max,
            divisions: widget.durationMs > 0 ? null : 1,
            activeColor: scheme.primary,
            inactiveColor: scheme.surfaceContainerHighest,
            labels: RangeLabels(
              MsDateUtils.formatDuration(_start.round()),
              MsDateUtils.formatDuration(_end.round()),
            ),
            onChangeStart: (_) {
              // 拖动滑块时先暂停，避免试听进度与选区互相干扰。
              if (player.playing) notifier.pause();
            },
            onChanged: (v) => setState(() {
              _start = v.start;
              _end = v.end;
            }),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('起点 ${MsDateUtils.formatDuration(_start.round())}',
                  style: theme.textTheme.labelMedium),
              Text('时长 ${MsDateUtils.formatDuration(selectedMs)}',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: scheme.primary)),
              Text('终点 ${MsDateUtils.formatDuration(_end.round())}',
                  style: theme.textTheme.labelMedium),
            ],
          ),
          const SizedBox(height: 16),
          // 内嵌试听：可直接播放/暂停，并实时显示试听位置。
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                IconButton.filledTonal(
                  icon: Icon(player.playing ? Icons.pause : Icons.play_arrow),
                  tooltip: player.playing ? '暂停试听' : '从起点试听',
                  onPressed: () {
                    if (player.playing) {
                      notifier.pause();
                    } else {
                      notifier.playFrom(_start.round());
                    }
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.playing ? '正在试听…' : '点击播放试听起点',
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${MsDateUtils.formatDuration(absPos)} / '
                        '${MsDateUtils.formatDuration(widget.durationMs)}',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontFeatures: const [
                          FontFeature.tabularFigures(),
                        ]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('取消'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    widget.onApply(_start.round(), _end.round());
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.content_cut),
                  label: const Text('应用裁剪'),
                ),
              ),
            ],
          ),
          if (_hasExistingTrim) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                  widget.onApply(null, null);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.restore),
                label: const Text('恢复完整音频（清除裁剪）'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}