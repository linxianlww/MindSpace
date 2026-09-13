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
            child: Image.file(File(thumb),
                height: 130, width: double.infinity, fit: BoxFit.cover),
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
    }
  }
}
