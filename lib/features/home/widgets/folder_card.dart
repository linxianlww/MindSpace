import 'package:mindspace/ui/design_system/app_design_system.dart';

import '../../../core/utils/ms_date_utils.dart';
import '../../../data/models/folder.dart';

/// 主页瀑布流中的文件夹卡片（FolderTile）：保持「文件夹图标 + 名称 + 更新时间」的紧凑样式，
/// 与同款铭记卡片共享 MiuixCard 卡片轮廓（HyperOS 大圆角），参与瀑布流布局。
class FolderTile extends StatelessWidget {
  const FolderTile({
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
    final colors = MiuixTheme.of(context).colors;
    final ts = MiuixTheme.of(context).textStyles;
    return MiuixCard(
      onPressed: onTap,
      onLongPress: onLongPress,
      feedbackType: MiuixPressFeedbackType.sink,
      cornerRadius: AppTokens.radiusCard,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            // 图标底座：AppAvatar（squircle 裁切，radius 18 → 36px）
            AppAvatar(
              radius: 18,
              borderRadius: 10,
              backgroundColor: colors.primaryContainer,
              child: HiuiIcon(HiuiIcons.folderOpen,
                  color: colors.onPrimaryContainer, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MiuixText(
                    folder.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ts.body1.copyWith(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  MiuixText(
                    MsDateUtils.format(folder.updatedAt),
                    style: ts.footnote1
                        .copyWith(color: colors.onSurfaceVariantSummary),
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
