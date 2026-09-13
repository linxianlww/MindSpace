import 'package:flutter/material.dart';

import '../../../core/utils/ms_date_utils.dart';

/// 音频裁剪区间选择：拖动两端选择起止，试听后应用为裁剪窗口。
///
/// 说明：ffmpeg_kit 已从 pub.dev 退役且体积庞大，这里采用“裁剪窗口”方案——
/// 播放与导出都以 trimStart/trimEnd 为准（just_audio.setClip 精确试听），
/// 不做有损重编码；如需真正重编码，可在 onApply 处接入原生编码器。
class AudioTrimmer extends StatefulWidget {
  const AudioTrimmer({
    super.key,
    required this.durationMs,
    this.initialStart,
    this.initialEnd,
    required this.onPreview,
    required this.onApply,
  });

  final int durationMs;
  final int? initialStart;
  final int? initialEnd;
  final void Function(int startMs) onPreview;
  final void Function(int? startMs, int? endMs) onApply;

  @override
  State<AudioTrimmer> createState() => _AudioTrimmerState();
}

class _AudioTrimmerState extends State<AudioTrimmer> {
  late double _start =
      (widget.initialStart ?? 0).toDouble();
  late double _end =
      (widget.initialEnd ?? widget.durationMs).toDouble();

  @override
  Widget build(BuildContext context) {
    final max =
        widget.durationMs.toDouble().clamp(1, double.infinity).toDouble();
    _end = _end.clamp(0, max).toDouble();
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('裁剪音频', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          RangeSlider(
            values: RangeValues(_start, _end),
            min: 0,
            max: max,
            divisions: widget.durationMs > 0 ? null : 1,
            labels: RangeLabels(
              MsDateUtils.formatDuration(_start.round()),
              MsDateUtils.formatDuration(_end.round()),
            ),
            onChanged: (v) => setState(() {
              _start = v.start;
              _end = v.end;
            }),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(MsDateUtils.formatDuration(_start.round())),
              Text(MsDateUtils.formatDuration(_end.round())),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => widget.onPreview(_start.round()),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('试听起点'),
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
          TextButton(
            onPressed: () {
              widget.onApply(null, null);
              Navigator.pop(context);
            },
            child: const Text('清除裁剪，恢复完整音频'),
          ),
        ],
      ),
    );
  }
}
