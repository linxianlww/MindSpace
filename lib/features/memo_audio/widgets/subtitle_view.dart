import 'package:flutter/material.dart';

import '../../../data/models/subtitle_item.dart';

/// 滚动字幕：当前句高亮并自动滚动到可见位置，点击跳转。
class SubtitleView extends StatefulWidget {
  const SubtitleView({
    super.key,
    required this.subs,
    required this.activeIndex,
    required this.onTap,
  });

  final List<SubtitleItem> subs;
  final int activeIndex;
  final void Function(int index) onTap;

  @override
  State<SubtitleView> createState() => _SubtitleViewState();
}

class _SubtitleViewState extends State<SubtitleView> {
  final _scroll = ScrollController();

  /// item 构建时登记其 BuildContext，供自动滚动定位。
  ///
  /// 不能依赖 GlobalKey：在 build 中每次 new GlobalKey 会在下一帧
  /// 被卸载/重挂，postFrame 回调里取到的 key 没有 currentContext，
  /// 导致 `Scrollable.ensureVisible` 静默失效（字幕从不自动滚动）。
  final _ctxByIndex = <int, BuildContext?>{};

  @override
  void didUpdateWidget(covariant SubtitleView old) {
    super.didUpdateWidget(old);
    if (widget.activeIndex != old.activeIndex &&
        widget.activeIndex >= 0 &&
        widget.activeIndex < widget.subs.length) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _ensureVisible(widget.activeIndex));
    }
  }

  void _ensureVisible(int index) {
    final ctx = _ctxByIndex[index];
    if (ctx != null && ctx.mounted) {
      Scrollable.ensureVisible(ctx,
          duration: const Duration(milliseconds: 280),
          alignment: 0.3,
          curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.subs.isEmpty) {
      return const Center(child: Text('暂无字幕，可在下方导入 lrc/srt/txt'));
    }
    final scheme = Theme.of(context).colorScheme;
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: widget.subs.length,
      itemBuilder: (context, i) {
        final s = widget.subs[i];
        final active = i == widget.activeIndex;
        _ctxByIndex[i] = context;
        return GestureDetector(
          onTap: () => widget.onTap(i),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  color: active
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                  fontSize: active ? 18 : 15,
                ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(s.text),
            ),
          ),
        );
      },
    );
  }
}