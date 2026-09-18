import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/md3e_tokens.dart';

/// 新建目标类型。
enum CreateTarget { text, media, audio, file, folder, totp, todo, anniversary }

/// MD3E 展开式 FAB：点击后在主按钮上方展开横向瀑布流新建入口。
///
/// 设计要点：
/// - 主按钮**始终可见**：展开 / 收起动画仅驱动叠加在遮罩上的新建入口列表，
///   Scaffold FAB 槽位内主按钮始终存在（避免主按钮「短暂消失」再出现）。
/// - 展开时新建入口**逐个出现**、收起时**逐个消失**，总时长 < 0.5s。
/// - 使用 Stack 定位：浮动层与主按钮右上角对齐，主按钮位于 Scaffold slot。
///
/// 展开态：[OverlayEntry] 承载（含半透明暗色遮罩 + Wrap 入口列表），
/// 主按钮由 Scaffold 自身管理并始终显示在屏幕右下角。
class CreateFab extends StatefulWidget {
  const CreateFab({super.key, required this.onSelect, this.onOpenChanged});

  final void Function(CreateTarget target) onSelect;
  final void Function(bool open)? onOpenChanged;

  @override
  State<CreateFab> createState() => CreateFabState();
}

/// 暴露给主页，用于返回键拦截时主动收起。
class CreateFabState extends State<CreateFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );
  bool _open = false;
  OverlayEntry? _scrimEntry;

  // 条目定义: (target, icon, label, accent)
  static const _items = <(CreateTarget, IconData, String, Color)>[
    (CreateTarget.folder, Icons.create_new_folder_outlined, '新建文件夹', Color(0xFF8B5E3C)),
    (CreateTarget.todo, Icons.fact_check_rounded, '新建待办', Color(0xFF3B6B2E)),
    (CreateTarget.text, Icons.notes_rounded, '新建文本', Color(0xFF5B5BD6)),
    (CreateTarget.media, Icons.photo_library_outlined, '新建媒体集', Color(0xFF0F7B6C)),
    (CreateTarget.audio, Icons.mic_none_rounded, '新建音频', Color(0xFFB0005B)),
    (CreateTarget.file, Icons.upload_file_outlined, '导入文件', Color(0xFF3B6B2E)),
    (CreateTarget.totp, Icons.pin_outlined, 'TOTP 验证码', Color(0xFF6A1B9A)),
    (CreateTarget.anniversary, Icons.event_outlined, '纪念日', Color(0xFFE64A19)),
  ];

  // 单个入口动画时长占总时长的比例。
  static const double _itemSpan = 0.4;
  // 相邻两个入口启动间隔占总时长的比例。
  static const double _stagger = 0.08;

  // 第 i 个入口对应的区间动画。
  Animation<double> _itemAnimation(int i) {
    final start = (i * _stagger).clamp(0.0, 1.0 - _itemSpan);
    final end = (start + _itemSpan).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _ctrl,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  void _toggle() {
    setState(() => _open = !_open);
    _open ? _ctrl.forward() : _ctrl.reverse();
    if (_open) {
      _showScrim();
    } else {
      // 收起时不立即移除遮罩，等最后一个入口消失后再清理。
      final lastStart = ((_items.length - 1) * _stagger).clamp(0.0, 1.0 - _itemSpan);
      Future.delayed(Duration(milliseconds: (480 * (lastStart + _itemSpan)).round()), () {
        if (mounted && !_open) _hideScrim();
      });
    }
    widget.onOpenChanged?.call(_open);
  }

  /// 外部请求收起（主界面返回键用）。
  void close() {
    if (_open) _toggle();
  }

  bool get isOpen => _open;

  void _showScrim() {
    _hideScrim();
    final overlayState = Overlay.of(context);
    _scrimEntry = OverlayEntry(builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      final barrierColor = isDark ? Colors.white24 : Colors.black54;
      return IgnorePointer(
        ignoring: false,
        child: _ScrimStack(
          barrierColor: barrierColor,
          onBarrierTap: _toggle,
          child: Positioned(
            right: 16,
            // 主按钮高度约 56 + 底边距 16 + 8 间距
            bottom: 80,
            child: Material(
              type: MaterialType.transparency,
              child: _buildPillList(),
            ),
          ),
        ),
      );
    });
    overlayState.insert(_scrimEntry!);
  }

  void _hideScrim() {
    _scrimEntry?.remove();
    _scrimEntry = null;
  }

  @override
  void initState() {
    super.initState();
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.dismissed && mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _hideScrim();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 主按钮始终可见：展开态只由 Overlay 承载入口列表，不隐藏主按钮。
    return _buildFab();
  }

  /// 主浮动按钮（收起 + 展开态均显示）。
  Widget _buildFab() {
    return FloatingActionButton.extended(
      onPressed: _toggle,
      icon: AnimatedRotation(
        turns: _open ? 0.125 : 0,
        duration: Md3eTokens.medium,
        curve: Md3eTokens.emphasized,
        child: Icon(_open ? Icons.close : Icons.add),
      ),
      label: Text(_open ? '收起' : '新建'),
    );
  }

  /// 入口列表：逐个出现 / 逐个消失。
  Widget _buildPillList() {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final panelWidth = math.min(screenWidth * 0.85, 420).toDouble();
    return SizedBox(
      width: panelWidth,
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < _items.length; i++)
            _AnimatedPill(
              animation: _itemAnimation(i),
              icon: _items[i].$2,
              label: _items[i].$3,
              accent: _items[i].$4,
              onTap: () {
                _toggle();
                widget.onSelect(_items[i].$1);
              },
            ),
        ],
      ),
    );
  }
}

/// 带弹性级联动画的入口按钮：随 Interval 动画渐显 + 上浮。
class _AnimatedPill extends StatelessWidget {
  const _AnimatedPill({
    required this.animation,
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final Animation<double> animation;
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final v = animation.value;
        return Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 8 * (1 - v)),
            child: Transform.scale(
              scale: 0.8 + 0.2 * v,
              child: child,
            ),
          ),
        );
      },
      child: _PillContent(
        icon: icon,
        label: label,
        accent: accent,
        onTap: onTap,
      ),
    );
  }
}

/// 静态入口按钮内容（无动画）。
class _PillContent extends StatefulWidget {
  const _PillContent({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  State<_PillContent> createState() => _PillContentState();
}

class _PillContentState extends State<_PillContent> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedScale(
      scale: _pressed ? 0.94 : 1,
      duration: const Duration(milliseconds: 120),
      child: Material(
        color: scheme.surfaceContainerHigh,
        elevation: 2,
        borderRadius: BorderRadius.circular(Md3eTokens.radiusFab),
        child: InkWell(
          borderRadius: BorderRadius.circular(Md3eTokens.radiusFab),
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, color: widget.accent, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 遮罩 Stack：底层可点击的暗色遮罩；上层浮动展开内容。
class _ScrimStack extends StatelessWidget {
  const _ScrimStack({
    required this.barrierColor,
    required this.onBarrierTap,
    required this.child,
  });

  final Color barrierColor;
  final VoidCallback onBarrierTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onBarrierTap,
            child: ColoredBox(color: barrierColor),
          ),
        ),
        child,
      ],
    );
  }
}
