import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/md3e_tokens.dart';
import '../../../core/theme/memo_scoped_theme.dart';
import '../../../core/utils/ms_date_utils.dart';
import '../../../core/utils/totp.dart';
import '../../../core/widgets/md3e_card.dart';
import '../../../data/models/memo.dart';
import '../../../data/models/memo_type.dart';
import '../../memo_anniversary/anniversary_provider.dart';
import '../../memo_totp/totp_provider.dart';

/// 主页瀑布流中的铭记卡片，按 [MemoType] 呈现不同内容。
///
/// - 标题允许 2 行（超出两行省略）。
/// - 若铭记设置了颜色，卡片主题色自动跟随该颜色；否则沿用全局主题。
/// - 颜色 / 备注标签操作已移至长按弹出 [MemoActions.show] 中。
/// - TOTP 卡片分为两区：顶部 TOTP 区点击复制、底部信息区点击进入查看页。
class MemoCard extends ConsumerWidget {
  const MemoCard({
    super.key,
    required this.memo,
    required this.onTap,
    required this.onLongPress,
  });

  final Memo memo;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  IconData get _leadingIcon => switch (memo.type) {
        MemoType.text => Icons.notes_rounded,
        MemoType.media => Icons.photo_library_rounded,
        MemoType.audio => Icons.graphic_eq_rounded,
        MemoType.file => Icons.description_outlined,
        MemoType.totp => Icons.pin_outlined,
        MemoType.todo => Icons.fact_check_rounded,
        MemoType.anniversary => Icons.event_outlined,
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
    final brightness = Theme.of(context).brightness;
    // 没有全局动态 / 自定义种子时使用 MD3E 双种子取色，
    // 此时铭记色覆盖也应遵循 MD3E 双种子风格。
    final useMd3e = true;

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
              // 标题占两行，右侧不再提供三点菜单。
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(_leadingIcon, size: 16,
                      color: color ?? Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      memo.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              if (_subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  _subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
              if (memo.remark != null && memo.remark!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .secondaryContainer
                          .withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      memo.remark!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  MsDateUtils.format(memo.updatedAt),
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: Theme.of(context).colorScheme.outline),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final card = Md3eCard(
      onTap: onTap,
      onLongPress: onLongPress,
      borderColor: color?.withValues(alpha: 0.5),
      child: body,
    );

    // 若铭记已设置颜色，用铭记色覆盖整个卡片的主题（包括描边、强调色等）。
    return MemoScopedTheme(
      colorValue: memo.color,
      brightness: brightness,
      useMd3eDualSeed: useMd3e,
      child: card,
    );
  }

  Widget _buildPreview(BuildContext context, WidgetRef ref) {
    switch (memo.type) {
      case MemoType.media:
        final thumb = memo.thumbnailPath;
        if (thumb != null && File(thumb).existsSync()) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(Md3eTokens.radiusCard)),
            child: RepaintBoundary(
              child: Image.file(File(thumb),
                  height: 130, width: double.infinity, fit: BoxFit.cover,
                  cacheWidth: 260, gaplessPlayback: true),
            ),
          );
        }
        return _placeholder(context, Icons.photo_library_rounded,
            Theme.of(context).colorScheme.secondaryContainer);
      case MemoType.audio:
        return _placeholder(context, Icons.graphic_eq_rounded,
            Theme.of(context).colorScheme.tertiaryContainer);
      case MemoType.text:
        if (memo.color != null) {
          return Container(
            height: 6,
            color: Color(memo.color!).withValues(alpha: 0.7),
          );
        }
        return const SizedBox.shrink();
      case MemoType.file:
        return _placeholder(context, Icons.insert_drive_file_outlined,
            Theme.of(context).colorScheme.surfaceContainerHighest);
      case MemoType.totp:
        return _totpPreviewBand(context, ref);
      case MemoType.todo:
        return _todoPreviewBand(context);
      case MemoType.anniversary:
        return _anniversaryPreviewBand(context);
    }
  }

  Widget _placeholder(BuildContext context, IconData icon, Color container) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 64,
      color: container,
      alignment: Alignment.center,
      child: Icon(icon,
          color: container == scheme.surfaceContainerHighest
              ? scheme.primary
              : scheme.onSecondaryContainer,
          size: 32),
    );
  }

  Widget _totpPreviewBand(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final nowMs =
        ref.watch(totpTickProvider).value ?? DateTime.now().millisecondsSinceEpoch;
    final cfg = totpConfigOf(memo);
    // 缩略图底色：未设颜色时用 primaryContainer（全局主题），
    // 已设颜色时用主色强化着色（跟随铭记色，可见度更高）。
    final Color bandBg = memo.color != null
        ? Color(memo.color!).withAlpha(28)
        : scheme.primaryContainer;
    final Color bandFg = memo.color != null
        ? Color(memo.color!)
        : scheme.primary;
    Widget content;
    if (cfg != null) {
      final code = totpCode(
        secretBase32: cfg.secret,
        period: cfg.period,
        digits: cfg.digits,
        algorithm: cfg.algorithm,
        now: DateTime.fromMillisecondsSinceEpoch(nowMs),
      );
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(code,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: bandFg,
                  )),
          const SizedBox(height: 2),
          Text('点击复制',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: bandFg.withValues(alpha: 0.7))),
        ],
      );
    } else {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.pin_outlined, size: 22, color: bandFg),
          const SizedBox(height: 2),
          Text('点击配置',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: bandFg.withValues(alpha: 0.7))),
        ],
      );
    }
    return Container(
      height: 72,
      color: bandBg,
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: cfg == null
            ? null
            : () async {
                await Clipboard.setData(ClipboardData(text: totpCode(
                  secretBase32: cfg.secret,
                  period: cfg.period,
                  digits: cfg.digits,
                  algorithm: cfg.algorithm,
                  now: DateTime.fromMillisecondsSinceEpoch(nowMs),
                )));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('验证码已复制'),
                      duration: Duration(seconds: 1)));
                }
              },
        child: content,
      ),
    );
  }

  Widget _todoPreviewBand(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = (memo.metadata['todoTotal'] as num?)?.toInt() ?? 0;
    final done = (memo.metadata['todoDone'] as num?)?.toInt() ?? 0;
    final ratio = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);
    final color = memo.color != null ? Color(memo.color!) : scheme.primary;
    return Column(
      children: [
        Container(
          height: 6,
          width: double.infinity,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(Md3eTokens.radiusCard)),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: ratio,
            child: Container(color: color.withValues(alpha: 0.8)),
          ),
        ),
        if (total == 0)
          Container(
            height: 64,
            alignment: Alignment.center,
            child: Icon(Icons.fact_check_rounded,
                color: scheme.outlineVariant, size: 32),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                Icon(Icons.check_circle,
                    size: 16, color: color.withValues(alpha: 0.85)),
                const SizedBox(width: 6),
                Text('$done / $total',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.primary, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
      ],
    );
  }

  /// 纪念日卡片缩略图：大字显示「还有/已过 N 天」，底色跟随铭记色。
  Widget _anniversaryPreviewBand(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cfg = AnniversaryConfig.fromMemo(memo);
    final hasConfig = cfg.date.isNotEmpty;
    // 缩略图底色：未设颜色时用 primaryContainer（全局主题），
    // 已设颜色时用主色强化着色（跟随铭记色，可见度更高）。
    final Color bandBg = memo.color != null
        ? Color(memo.color!).withAlpha(28)
        : scheme.primaryContainer;
    final Color bandFg = memo.color != null
        ? Color(memo.color!)
        : scheme.primary;

    Widget content;
    if (hasConfig) {
      final calc = computeAnniversary(cfg);
      final isToday = calc.isToday;
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isToday ? '今' : '${calc.absCount}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: bandFg,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            isToday ? '就是今天' : (calc.isUpcoming ? '天后' : '天前'),
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: bandFg.withValues(alpha: 0.7)),
          ),
        ],
      );
    } else {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_outlined, size: 22, color: bandFg),
          const SizedBox(height: 2),
          Text('点击配置',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: bandFg.withValues(alpha: 0.7))),
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
