import 'package:flutter/material.dart';

/// MD3E Expressive 风格开关：开启时拇指显示 ✓ 对号，关闭时显示 ✕ 叉号，
/// 符合 Material 3 Expressive 设计规范中「开关状态一目了然」的原则。
class Md3eSwitch extends StatelessWidget {
  const Md3eSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      toggled: value,
      label: value ? '开启' : '关闭',
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onChanged == null ? null : () => onChanged!(!value),
        customBorder: const StadiumBorder(),
        child: AnimatedContainer(
          width: 52,
          height: 32,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: value ? scheme.primary : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: value ? Colors.transparent : scheme.outline,
              width: 2,
            ),
          ),
          padding: const EdgeInsets.all(4),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment:
                value ? Alignment.centerRight : Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: value ? scheme.onPrimary : scheme.outline,
                shape: BoxShape.circle,
              ),
              child: Icon(
                value ? Icons.check_rounded : Icons.close_rounded,
                size: 16,
                color:
                    value ? scheme.primary : scheme.surfaceContainerHighest,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 使用 [Md3eSwitch] 的 ListTile 设置行。
class Md3eSwitchListTile extends StatelessWidget {
  const Md3eSwitchListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: Md3eSwitch(value: value, onChanged: onChanged),
    );
  }
}
