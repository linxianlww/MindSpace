import 'package:flutter/material.dart';

import '../../../data/models/media_item.dart';
import 'media_thumb.dart';

/// 媒体网格：浏览模式点击查看；编辑模式可长按拖拽排序、删除。
class MediaGrid extends StatelessWidget {
  const MediaGrid({
    super.key,
    required this.items,
    required this.onTap,
    required this.onReorder,
    this.editMode = false,
    this.onRemove,
  });

  final List<MediaItem> items;
  final void Function(int index) onTap;
  final void Function(int from, int to) onReorder;
  final bool editMode;
  final void Function(MediaItem item)? onRemove;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxis = width >= 800 ? 4 : 3;
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxis,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        final cell = Stack(
          children: [
            Positioned.fill(child: MediaThumb(item: item, editMode: editMode)),
            if (editMode)
              Positioned(
                right: 4,
                top: 4,
                child: GestureDetector(
                  onTap: () => onRemove?.call(item),
                  child: const CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
              ),
            if (editMode)
              const Positioned(
                left: 4,
                top: 4,
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.black45,
                  child: Icon(Icons.drag_indicator,
                      size: 16, color: Colors.white),
                ),
              ),
          ],
        );

        if (!editMode) {
          return GestureDetector(onTap: () => onTap(i), child: cell);
        }
        // 编辑模式：长按拖拽排序。
        return LongPressDraggable<MediaItem>(
          data: item,
          delay: const Duration(milliseconds: 200),
          feedback: SizedBox(
            width: 90,
            height: 90,
            child: Opacity(opacity: 0.85, child: MediaThumb(item: item)),
          ),
          childWhenDragging: Opacity(opacity: 0.3, child: cell),
          child: DragTarget<MediaItem>(
            onWillAcceptWithDetails: (d) => d.data.id != item.id,
            onAcceptWithDetails: (d) {
              final from = items.indexWhere((e) => e.id == d.data.id);
              if (from >= 0) onReorder(from, i);
            },
            builder: (context, candidate, _) => GestureDetector(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: candidate.isNotEmpty
                      ? Border.all(
                          color: Theme.of(context).colorScheme.primary, width: 2)
                      : null,
                ),
                child: cell,
              ),
            ),
          ),
        );
      },
    );
  }
}
