import 'package:flutter/material.dart';

/// 可复制文本 —— 保持 Material SelectableText。
/// MIUIX 无等效组件，且为功能性组件（复制选择），不影响整体视觉风格。
class AppSelectableText extends StatelessWidget {
  const AppSelectableText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.focusNode,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return SelectableText(
      text,
      style: style,
      textAlign: textAlign,
      focusNode: focusNode,
      maxLines: maxLines,
    );
  }
}
