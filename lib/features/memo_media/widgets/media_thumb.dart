import 'dart:io';

import 'package:mindspace/ui/design_system/app_design_system.dart';

import '../../../core/utils/ms_date_utils.dart';
import '../../../data/models/media_item.dart';
import '../../../data/models/memo_type.dart';

/// 单个媒体缩略图：图片显示缩略图，视频显示占位与时长。
class MediaThumb extends StatelessWidget {
  const MediaThumb({super.key, required this.item, this.editMode = false});

  final MediaItem item;
  final bool editMode;

  @override
  Widget build(BuildContext context) {
    final thumbExists =
        item.thumbPath != null && File(item.thumbPath!).existsSync();
    Widget content;
    if (item.kind == MediaKind.image) {
      // 图片：优先缩略图；缩略图缺失（如缓存被清除）时回退原图，避免
      // 在图片上错误呈现播放按钮。
      final imagePath = thumbExists ? item.thumbPath! : item.path;
      if (File(imagePath).existsSync()) {
        content = Image.file(File(imagePath),
            fit: BoxFit.cover, width: double.infinity);
      } else {
        content = _placeholder(
          context,
          icon: HiuiIcons.noPhoto,
          caption: null,
        );
      }
    } else {
      // 视频：播放占位 + 时长，右上角再叠加摄像头角标。
      content = _placeholder(
        context,
        icon: HiuiIcons.play,
        caption: item.durationMs != null
            ? MsDateUtils.formatDuration(item.durationMs!)
            : null,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          // 缩略图圆角：卡片内第三级裁切，取 radiusMedium
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          child: content,
        ),
        if (item.remark != null && item.remark!.isNotEmpty)
          Positioned(
            left: 6,
            bottom: 6,
            right: 6,
            // 图片上的备注角标：黑底白字保证任何缩略图上的可读性
            // （黑/白为叠加层的功能性硬编码，媒体查看器同规则）。
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: ShapeDecoration(
                color: Colors.black54,
                shape: MiuixSquircleBorder(
                    cornerRadius: AppTokens.radiusChip),
              ),
              child: MiuixText(
                item.remark!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: MiuixTheme.of(context)
                    .textStyles
                    .footnote2
                    .copyWith(color: Colors.white),
              ),
            ),
          ),
        if (item.kind == MediaKind.video)
          const Center(
            child: HiuiIcon(HiuiIcons.video, color: Colors.white70, size: 20),
          ),
      ],
    );
  }

  Widget _placeholder(
    BuildContext context, {
    required String icon,
    required String? caption,
  }) {
    final theme = MiuixTheme.of(context);
    return Container(
      color: theme.colors.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HiuiIcon(icon, size: 36, color: theme.colors.primary),
          if (caption != null) MiuixText(caption, style: theme.textStyles.footnote2),
        ],
      ),
    );
  }
}
