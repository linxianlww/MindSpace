import 'package:flutter/widgets.dart';
import 'package:flutter_miuix/miuix.dart';

import 'hiui_icons.dart';

/// 空态：插画图标 + 标题 + 副标题 + 可选操作按钮。
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.icon = HiuiIcons.inbox,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final ts = MiuixTheme.of(context).textStyles;
    final colors = MiuixTheme.of(context).colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HiuiIcon(icon,
                size: 72, color: colors.primary.withValues(alpha: 0.7)),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: ts.title4),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: ts.body1.copyWith(color: colors.onSurfaceSecondary),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              MiuixButton(
                onPressed: onAction,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const HiuiIcon(HiuiIcons.add, size: 18),
                    const SizedBox(width: 4),
                    Text(actionLabel!),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 加载态：HyperOS 轨道点旋转指示器。
class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.hint});

  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiuixCircularProgressIndicator(strokeWidth: 3),
          if (hint != null) ...[
            const SizedBox(height: 12),
            Text(hint!, style: MiuixTheme.of(context).textStyles.body1),
          ],
        ],
      ),
    );
  }
}

/// 错误态：可重试。
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final ts = MiuixTheme.of(context).textStyles;
    final colors = MiuixTheme.of(context).colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HiuiIcon(HiuiIcons.error, size: 64, color: colors.primary),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: ts.title4),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              MiuixButton(
                onPressed: onRetry,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const HiuiIcon(HiuiIcons.reset, size: 18),
                    const SizedBox(width: 4),
                    const Text('重试'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
