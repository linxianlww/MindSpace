import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/theme/md3e_tokens.dart';
import '../../../core/utils/ms_date_utils.dart';
import '../../../data/models/memo.dart';
import '../../../data/models/memo_type.dart';
import '../../../core/widgets/md3e_card.dart';

/// 主页瀑布流中的铭记卡片，按 [MemoType] 呈现不同内容。
class MemoCard extends StatelessWidget {
  const MemoCard({
    super.key,
    required this.memo,
    required this.onTap,
    required this.onLongPress,
  });

  final Memo memo;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = memo.color != null ? Color(memo.color!) : null;

    return Md3eCard(
      onTap: onTap,
      onLongPress: onLongPress,
      borderColor: color?.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPreview(context),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_leadingIcon, size: 16, color: scheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        memo.title,
                        maxLines: 1,
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
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (memo.remark != null && memo.remark!.isNotEmpty)
                      Expanded(
                        child: LabelChip(
                          icon: Icons.label_outline,
                          label: memo.remark!,
                          color: color,
                        ),
                      )
                    else
                      const Spacer(),
                    Text(
                      MsDateUtils.format(memo.updatedAt),
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: scheme.outline),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData get _leadingIcon => switch (memo.type) {
        MemoType.text => Icons.notes_rounded,
        MemoType.media => Icons.photo_library_rounded,
        MemoType.audio => Icons.graphic_eq_rounded,
        MemoType.file => Icons.description_outlined,
        MemoType.totp => Icons.pin_outlined,
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
        if (issuer != null && issuer.isNotEmpty && account != null && account.isNotEmpty) {
          return '$issuer · $account';
        }
        return '动态验证码（不显示密钥）';
    }
  }

  Widget _buildPreview(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (memo.type) {
      case MemoType.media:
        final thumb = memo.thumbnailPath;
        if (thumb != null && File(thumb).existsSync()) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(Md3eTokens.radiusCard)),
            child: RepaintBoundary(
              child: Image.file(
                File(thumb),
                height: 130,
                width: double.infinity,
                fit: BoxFit.cover,
                // 缩略图按 260px 解码即可满足卡片尺寸，避免解码原图
                // 浪费内存与 CPU（瀑布流大量图片同时解码时会掉帧）。
                cacheWidth: 260,
                gaplessPlayback: true,
              ),
            ),
          );
        }
        return Container(
          height: 90,
          color: scheme.secondaryContainer,
          child: Center(
            child: Icon(Icons.photo_library_rounded,
                size: 36, color: scheme.onSecondaryContainer),
          ),
        );
      case MemoType.audio:
        return Container(
          height: 64,
          color: scheme.tertiaryContainer,
          alignment: Alignment.center,
          child: Icon(Icons.graphic_eq_rounded,
              color: scheme.onTertiaryContainer, size: 32),
        );
      case MemoType.text:
        if (memo.color != null) {
          return Container(
            height: 8,
            color: Color(memo.color!).withValues(alpha: 0.7),
          );
        }
        return const SizedBox.shrink();
      case MemoType.file:
        return Container(
          height: 64,
          color: scheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: Icon(Icons.insert_drive_file_outlined,
              color: scheme.primary, size: 32),
        );
      case MemoType.totp:
        return Container(
          height: 64,
          color: scheme.primaryContainer,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pin_outlined,
                  color: scheme.onPrimaryContainer, size: 22),
              const SizedBox(width: 8),
              Text(
                'TIME-BASED OTP',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(
                        color: scheme.onPrimaryContainer,
                        letterSpacing: 1.2),
              ),
            ],
          ),
        );
    }
  }
}
