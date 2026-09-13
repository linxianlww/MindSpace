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
    final scheme = Theme.of(context).colorScheme;
    final imgPath = item.thumbPath ?? item.path;
    Widget content;
    if (item.kind == MediaKind.image && File(imgPath).existsSync()) {
      content = Image.file(File(imgPath), fit: BoxFit.cover, width: double.infinity);
    } else {
      content = Container(
        color: scheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_circle_fill_rounded,
                size: 36, color: scheme.primary),
            if (item.durationMs != null)
              Text(MsDateUtils.formatDuration(item.durationMs!),
                  style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
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
}
