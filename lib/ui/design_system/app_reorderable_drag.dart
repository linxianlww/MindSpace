import 'package:flutter/widgets.dart';

/// 拖拽重排序句柄 —— 包装 ReorderableDelayedDragStartListener。
/// Flutter 框架组件，不分风格。
class AppReorderableDragHandle extends StatelessWidget {
  const AppReorderableDragHandle({
    super.key,
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ReorderableDelayedDragStartListener(
      index: index,
      child: child,
    );
  }
}
