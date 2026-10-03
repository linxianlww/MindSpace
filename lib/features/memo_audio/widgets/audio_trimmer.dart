import 'package:mindspace/ui/design_system/app_design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/ms_date_utils.dart';
import '../audio_provider.dart';

/// 音频裁剪区间选择：拖动两端滑块选择保留区间，内嵌播放控制可直接试听。
///
/// 说明：采用"裁剪窗口"方案——播放与导出都以 trimStart/trimEnd 为准
/// （just_audio.setClip 精确试听），不做有损重编码。
///
/// 交互逻辑：
/// - 拖动两端滑块 → 设定"保留区间"（绿色区间），拖动时自动暂停播放；
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
    final theme = MiuixTheme.of(context);
    final scheme = theme.colors;
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
            child: MiuixText('裁剪音频', style: theme.textStyles.title3),
          ),
          const SizedBox(height: 4),
          Center(
            child: MiuixText(
              '拖动两端滑块，绿色区间为保留片段',
              style: theme.textStyles.body2
                  .copyWith(color: scheme.onSurfaceVariantSummary),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 28,
            child: MiuixRangeSlider(
              startValue: _start,
              endValue: _end,
              min: 0,
              max: max,
              // 无全长信息时退化为单步；有全长时连续拖动（毫秒级步进无意义）。
              steps: widget.durationMs > 0 ? 0 : 1,
              onValueChanged: (v) {
                // 拖动滑块时先暂停，避免试听进度与选区互相干扰。
                if (player.playing) notifier.pause();
                setState(() {
                  _start = v.$1;
                  _end = v.$2;
                });
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MiuixText('起点 ${MsDateUtils.formatDuration(_start.round())}',
                  style: theme.textStyles.body2),
              MiuixText('时长 ${MsDateUtils.formatDuration(selectedMs)}',
                  style: theme.textStyles.body2
                      .copyWith(color: scheme.primary)),
              MiuixText('终点 ${MsDateUtils.formatDuration(_end.round())}',
                  style: theme.textStyles.body2),
            ],
          ),
          const SizedBox(height: 16),
          // 内嵌试听：可直接播放/暂停，并实时显示试听位置。
          // MiuixSurface 承载（替代手写 ShapeDecoration 卡片）
          MiuixSurface(
            cornerRadius: AppTokens.radiusMedium,
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
              children: [
                AppTapIcon(
                  icon: HiuiIcon(
                      player.playing ? HiuiIcons.pause : HiuiIcons.play),
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
                      MiuixText(
                        player.playing ? '正在试听…' : '点击播放试听起点',
                        style: theme.textStyles.body2
                            .copyWith(color: scheme.onSurfaceVariantSummary),
                      ),
                      const SizedBox(height: 2),
                      MiuixText(
                        '${MsDateUtils.formatDuration(absPos)} / '
                        '${MsDateUtils.formatDuration(widget.durationMs)}',
                        style: theme.textStyles.body1
                            .copyWith(fontFeatures: const [
                          FontFeature.tabularFigures(),
                        ]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  variant: AppButtonStyle.outlined,
                  onPressed: () => AppSheet.close<void>(context),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HiuiIcon(HiuiIcons.close),
                      SizedBox(width: 8),
                      MiuixText('取消'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  onPressed: () {
                    widget.onApply(_start.round(), _end.round());
                    AppSheet.close<void>(context);
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HiuiIcon(HiuiIcons.cut),
                      SizedBox(width: 8),
                      MiuixText('应用裁剪'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_hasExistingTrim) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                variant: AppButtonStyle.text,
                onPressed: () {
                  widget.onApply(null, null);
                  AppSheet.close<void>(context);
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HiuiIcon(HiuiIcons.reset),
                    SizedBox(width: 8),
                    MiuixText('恢复完整音频（清除裁剪）'),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
