import 'package:flutter/material.dart';

import '../../../core/theme/md3e_tokens.dart';
import '../../../core/utils/ms_date_utils.dart';
import '../../../data/models/folder.dart';
import '../../../core/widgets/md3e_card.dart';

/// 主页瀑布流中的文件夹卡片：保持「文件夹图标 + 名称 + 更新时间」的紧凑样式，
/// 与同款铭记卡片共享 MD3E 大圆角卡片轮廓，参与瀑布流布局。
class FolderCard extends StatelessWidget {
  const FolderCard({
    super.key,
    required this.folder,
    required this.onTap,
    required this.onLongPress,
  });

  final Folder folder;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Md3eCard(
      onTap: onTap,
      onLongPress: onLongPress,
      // 品牌橙 12% 描边，轻量区分文件夹与铭记卡片，保持视觉清洁。
      borderColor: Md3eTokens.brandSeed.withValues(alpha: 0.12),
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child:
                  Icon(Icons.folder_open_rounded, color: scheme.onPrimaryContainer, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    folder.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    MsDateUtils.format(folder.updatedAt),
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: scheme.outline),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
