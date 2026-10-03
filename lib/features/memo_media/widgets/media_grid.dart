import 'package:mindspace/ui/design_system/app_design_system.dart';

import '../../../core/utils/screen_utils.dart';
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
    // 列数按实际宽度推导（每格至少约 150 逻辑像素），
    // 1:1 小屏降列、横屏平板加列，避免格子过大/过密。
    final crossAxis = ScreenUtils.columns(width, minCell: 150, maxColumns: 6);
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
              // 删除角标：MiuixPressable 补上按压反馈（原裸 GestureDetector 无反馈）。
              // 放右上角，与左上角的拖拽柄错开，避免两个手势区互相遮挡。
              Positioned(
                right: 4,
                top: 4,
                child: MiuixPressable(
                  onPressed: () => onRemove?.call(item),
                  borderRadius: BorderRadius.circular(14),
                  child: AppAvatar(
                    radius: 14,
                    backgroundColor: Colors.black54,
                    child: const HiuiIcon(HiuiIcons.close,
                        size: 16, color: Colors.white),
                  ),
                ),
              ),
            if (editMode)
              Positioned(
                left: 4,
                top: 4,
                child: AppAvatar(
                  radius: 12,
                  backgroundColor: Colors.black45,
                  child: const HiuiIcon(HiuiIcons.drag,
                      size: 16, color: Colors.white),
                ),
              ),
          ],
        );

        if (!editMode) {
          // 浏览模式：MiuixPressable 提供 sink 按压反馈，视觉不变。
          return MiuixPressable(
            onPressed: () => onTap(i),
            feedbackType: MiuixPressFeedbackType.sink,
            shape: MiuixSquircleBorder(cornerRadius: AppTokens.radiusMedium),
            child: cell,
          );
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
            builder: (context, candidate, _) => AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: ShapeDecoration(
                shape: MiuixSquircleBorder(
                  cornerRadius: AppTokens.radiusMedium,
                  side: candidate.isNotEmpty
                      ? BorderSide(
                          color: MiuixTheme.of(context).colors.primary,
                          width: 2)
                      : BorderSide.none,
                ),
              ),
              child: MiuixPressable(
                onPressed: () => onTap(i),
                feedbackType: MiuixPressFeedbackType.sink,
                shape:
                    MiuixSquircleBorder(cornerRadius: AppTokens.radiusMedium),
                child: cell,
              ),
            ),
          ),
        );
      },
    );
  }
}
