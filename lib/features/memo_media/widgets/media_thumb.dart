import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/theme/md3e_tokens.dart';
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
          icon: Icons.broken_image_outlined,
          caption: null,
        );
      }
    } else {
      // 视频：播放占位 + 时长，右上角再叠加摄像头角标。
      content = _placeholder(
        context,
        icon: Icons.play_circle_fill_rounded,
        caption: item.durationMs != null
            ? MsDateUtils.formatDuration(item.durationMs!)
            : null,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: content,
        ),
        if (item.remark != null && item.remark!.isNotEmpty)
          Positioned(
            left: 6,
            bottom: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(Md3eTokens.radiusChip),
              ),
              child: Text(
                item.remark!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
        if (item.kind == MediaKind.video)
          const Center(
            child: Icon(Icons.videocam_rounded, color: Colors.white70, size: 20),
          ),
      ],
    );
  }

  Widget _placeholder(
    BuildContext context, {
    required IconData icon,
    required String? caption,
  }) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36, color: theme.colorScheme.primary),
          if (caption != null) Text(caption, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}
