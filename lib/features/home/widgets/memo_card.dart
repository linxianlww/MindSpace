import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindspace/ui/design_system/app_design_system.dart';

import '../../../core/theme/memo_scoped_theme.dart';
import '../../../core/utils/ms_date_utils.dart';
import '../../../core/utils/totp.dart';
import '../../../data/models/memo.dart';
import '../../../data/models/memo_type.dart';
import '../../memo_anniversary/anniversary_provider.dart';
import '../../memo_totp/totp_provider.dart';

/// 主页瀑布流中的铭记卡片（现 MemoTile），按 [MemoType] 呈现不同内容。
///
/// - 标题允许 2 行（超出两行省略）。
/// - 若铭记设置了颜色，卡片主题色自动跟随该颜色；否则沿用全局主题。
/// - 颜色 / 备注标签操作已移至长按弹出 [MemoActions.show] 中。
/// - TOTP 卡片分为两区：顶部 TOTP 区点击复制、底部信息区点击进入查看页。
class MemoTile extends ConsumerWidget {
  const MemoTile({
    super.key,
    required this.memo,
    required this.onTap,
    required this.onLongPress,
  });

  final Memo memo;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  String get _leadingIcon => switch (memo.type) {
        MemoType.text => HiuiIcons.document,
        MemoType.media => HiuiIcons.image,
        MemoType.audio => HiuiIcons.waveform,
        MemoType.file => HiuiIcons.document,
        MemoType.totp => HiuiIcons.pin,
        MemoType.todo => HiuiIcons.checkSquare,
        MemoType.anniversary => HiuiIcons.calendar,
      };

  String? get _subtitle {
    switch (memo.type) {
      case MemoType.text:
        return (memo.metadata['excerpt'] as String?) ?? '文本铭记';
      case MemoType.media:
        final count = memo.metadata['count'];
        return count == null ? '媒体集' : '$count 个媒体';
      case MemoType.audio:
        final dur = memo.metadata['durationMs'] as int?;
        return dur == null ? '音频铭记' : '时长 ${MsDateUtils.formatDuration(dur)}';
      case MemoType.file:
        return (memo.metadata['originalName'] as String?) ?? '文件铭记';
      case MemoType.totp:
        final issuer = memo.metadata['totpIssuer'] as String?;
        final account = memo.metadata['totpAccount'] as String?;
        if (issuer != null &&
            issuer.isNotEmpty &&
            account != null &&
            account.isNotEmpty) {
          return '$issuer · $account';
        }
        return '动态验证码（不显示密钥）';
      case MemoType.todo:
        return (memo.metadata['excerpt'] as String?) ?? '待办列表';
      case MemoType.anniversary:
        return (memo.metadata['anniversaryNote'] as String?) ?? '纪念日';
    }
  }

  bool get _hasPreview => switch (memo.type) {
        MemoType.media ||
        MemoType.audio ||
        MemoType.text ||
        MemoType.file ||
        MemoType.totp ||
        MemoType.todo ||
        MemoType.anniversary =>
          true,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = MiuixTheme.of(context).brightness;
    const useMd3e = true;

    final color = memo.color != null ? Color(memo.color!) : null;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_hasPreview) _buildPreview(context, ref),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  HiuiIcon(_leadingIcon,
                      size: 16,
                      color: color ?? MiuixTheme.of(context).colors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: MiuixText(
                      memo.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: MiuixTheme.of(context)
                          .textStyles
                          .body1
                          .copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              if (_subtitle != null) ...[
                const SizedBox(height: 4),
                MiuixText(
                  _subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: MiuixTheme.of(context).textStyles.body2.copyWith(
                      color: MiuixTheme.of(context)
                          .colors
                          .onSurfaceVariantSummary),
                ),
              ],
              if (memo.remark != null && memo.remark!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  // 备注标签：静态展示，用 MiuixSurface 轻量承载（替代手写 Container）
                  child: MiuixSurface(
                    cornerRadius: AppTokens.radiusSmall,
                    color: MiuixTheme.of(context)
                        .colors
                        .secondaryContainer
                        .withValues(alpha: 0.6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      child: MiuixText(
                        memo.remark!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MiuixTheme.of(context)
                            .textStyles
                            .footnote2
                            .copyWith(
                                color: MiuixTheme.of(context)
                                    .colors
                                    .onSecondaryContainer),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: MiuixText(
                  MsDateUtils.format(memo.updatedAt),
                  style: MiuixTheme.of(context)
                      .textStyles
                      .footnote2
                      .copyWith(color: MiuixTheme.of(context).colors.outline),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final card = MiuixCard(
      onPressed: onTap,
      onLongPress: onLongPress,
      feedbackType: MiuixPressFeedbackType.sink,
      cornerRadius: AppTokens.radiusCard,
      child: body,
    );

    return MemoScopedTheme(
      colorValue: memo.color,
      brightness: brightness,
      useMd3eDualSeed: useMd3e,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
          boxShadow: [
            BoxShadow(
              color: const Color(0x08000000),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: card,
      ),
    );
  }

  Widget _buildPreview(BuildContext context, WidgetRef ref) {
    switch (memo.type) {
      case MemoType.media:
        final thumb = memo.thumbnailPath;
        if (thumb != null && File(thumb).existsSync()) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTokens.radiusCard)),
            child: RepaintBoundary(
              child: Image.file(File(thumb),
                  height: 130,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  cacheWidth: 260,
                  gaplessPlayback: true),
            ),
          );
        }
        return _placeholder(context, HiuiIcons.image,
            MiuixTheme.of(context).colors.surfaceContainerHighest);
      case MemoType.audio:
        return _placeholder(context, HiuiIcons.waveform,
            MiuixTheme.of(context).colors.surfaceContainerHighest);
      case MemoType.text:
        if (memo.color != null) {
          return Container(
            height: 6,
            color: Color(memo.color!).withValues(alpha: 0.7),
          );
        }
        return const SizedBox.shrink();
      case MemoType.file:
        return _placeholder(context, HiuiIcons.document,
            MiuixTheme.of(context).colors.surfaceContainerHighest);
      case MemoType.totp:
        return _totpPreviewBand(context, ref);
      case MemoType.todo:
        return _todoPreviewBand(context);
      case MemoType.anniversary:
        return _anniversaryPreviewBand(context);
    }
  }

  Widget _placeholder(BuildContext context, String icon, Color container) {
    final colors = MiuixTheme.of(context).colors;
    return Container(
      height: 64,
      color: container,
      alignment: Alignment.center,
      child: HiuiIcon(icon,
          color: container == colors.surfaceContainerHighest
              ? colors.primary
              : colors.onSecondaryContainer,
          size: 32),
    );
  }

  Widget _totpPreviewBand(BuildContext context, WidgetRef ref) {
    final colors = MiuixTheme.of(context).colors;
    final nowMs = ref.watch(totpTickProvider).value ??
        DateTime.now().millisecondsSinceEpoch;
    final cfg = totpConfigOf(memo);
    final Color bandBg = memo.color != null
        ? Color(memo.color!).withAlpha(28)
        : colors.primaryContainer;
    final Color bandFg =
        memo.color != null ? Color(memo.color!) : colors.primary;
    Widget content;
    if (cfg != null) {
      final code = totpCode(
        secretBase32: cfg.secret,
        period: cfg.period,
        digits: cfg.digits,
        algorithm: cfg.algorithm,
        now: DateTime.fromMillisecondsSinceEpoch(nowMs),
      );
      final ts = MiuixTheme.of(context).textStyles;
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MiuixText(code,
              style: ts.title2.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: bandFg,
              )),
          const SizedBox(height: 2),
          MiuixText('点击复制',
              style:
                  ts.footnote2.copyWith(color: bandFg.withValues(alpha: 0.7))),
        ],
      );
    } else {
      final ts = MiuixTheme.of(context).textStyles;
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HiuiIcon(HiuiIcons.pin, size: 22, color: bandFg),
          const SizedBox(height: 2),
          MiuixText('点击配置',
              style:
                  ts.footnote2.copyWith(color: bandFg.withValues(alpha: 0.7))),
        ],
      );
    }
    if (cfg == null) {
      return Container(
        height: 72,
        color: bandBg,
        alignment: Alignment.center,
        child: content,
      );
    }
    // TOTP 色带：MiuixSurface 提供按压反馈（点击复制验证码）
    return MiuixSurface(
      onPressed: () async {
        await Clipboard.setData(ClipboardData(
            text: totpCode(
          secretBase32: cfg.secret,
          period: cfg.period,
          digits: cfg.digits,
          algorithm: cfg.algorithm,
          now: DateTime.fromMillisecondsSinceEpoch(nowMs),
        )));
        if (context.mounted) {
          AppSnackbar.show(context, message: '验证码已复制');
        }
      },
      cornerRadius: 0,
      squircleEnabled: false,
      color: bandBg,
      child: SizedBox(
        height: 72,
        width: double.infinity,
        child: Center(child: content),
      ),
    );
  }

  Widget _todoPreviewBand(BuildContext context) {
    final colors = MiuixTheme.of(context).colors;
    final total = (memo.metadata['todoTotal'] as num?)?.toInt() ?? 0;
    final done = (memo.metadata['todoDone'] as num?)?.toInt() ?? 0;
    final ratio = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);
    final color = memo.color != null ? Color(memo.color!) : colors.primary;
    final ts = MiuixTheme.of(context).textStyles;
    return Column(
      children: [
        // 待办进度：MIUIX 线性进度条（替代手写分数条）
        MiuixLinearProgressIndicator(
          progress: ratio,
          height: 6,
          colors: MiuixProgressIndicatorColors(
            foregroundColor: color.withValues(alpha: 0.8),
            disabledForegroundColor: color.withValues(alpha: 0.4),
            backgroundColor: colors.surfaceContainerHighest,
          ),
        ),
        if (total == 0)
          Container(
            height: 64,
            alignment: Alignment.center,
            child: HiuiIcon(HiuiIcons.checkSquare,
                color: colors.dividerLine, size: 32),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                HiuiIcon(HiuiIcons.checkCircle,
                    size: 16, color: color.withValues(alpha: 0.85)),
                const SizedBox(width: 6),
                MiuixText('$done / $total',
                    style: ts.footnote2.copyWith(
                        color: colors.primary, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _anniversaryPreviewBand(BuildContext context) {
    final colors = MiuixTheme.of(context).colors;
    final ts = MiuixTheme.of(context).textStyles;
    final cfg = AnniversaryConfig.fromMemo(memo);
    final hasConfig = cfg.date.isNotEmpty;
    final Color bandBg = memo.color != null
        ? Color(memo.color!).withAlpha(28)
        : colors.primaryContainer;
    final Color bandFg =
        memo.color != null ? Color(memo.color!) : colors.primary;

    Widget content;
    if (hasConfig) {
      final calc = computeAnniversary(cfg);
      final isToday = calc.isToday;
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MiuixText(
            isToday ? '今' : '${calc.absCount}',
            style: ts.title2.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: bandFg,
            ),
          ),
          const SizedBox(height: 2),
          MiuixText(
            isToday ? '就是今天' : (calc.isUpcoming ? '天后' : '天前'),
            style: ts.footnote2.copyWith(color: bandFg.withValues(alpha: 0.7)),
          ),
        ],
      );
    } else {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HiuiIcon(HiuiIcons.calendar, size: 22, color: bandFg),
          const SizedBox(height: 2),
          MiuixText('点击配置',
              style:
                  ts.footnote2.copyWith(color: bandFg.withValues(alpha: 0.7))),
        ],
      );
    }

    return Container(
      height: 72,
      color: bandBg,
      alignment: Alignment.center,
      child: content,
    );
  }
}
