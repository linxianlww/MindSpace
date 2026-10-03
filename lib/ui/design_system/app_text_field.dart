import 'package:flutter/services.dart'
    show TextInputType, TextInputAction, TextCapitalization;
import 'package:flutter/widgets.dart';
import 'package:flutter_miuix/miuix.dart';

/// 统一文本输入框 —— 直接暴露 [MiuixTextField] 原生 MIUIX 风格。
///
/// `hintText` 自动映射到 `label` + `useLabelAsPlaceholder`（不输入时作为占位显示）；
/// `errorText` / `helperText` 以底部文字方式呈现。
class AppInput extends StatelessWidget {
  const AppInput({
    super.key,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.label = '',
    this.hintText,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.style,
    this.textAlign = TextAlign.start,
    this.leadingIcon,
    this.trailingIcon,
    this.errorText,
    this.helperText,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String label;
  final String? hintText;
  final bool enabled;
  final bool readOnly;
  final bool obscureText;
  final bool autofocus;
  final int? maxLines;
  final int? minLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final TextStyle? style;
  final TextAlign textAlign;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final String? errorText;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final colors = MiuixTheme.of(context).colors;

    // hintText 优先：自动作为占位显示；否则使用 label。
    final effectiveLabel = hintText ?? label;
    final usePlaceholder = hintText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        MiuixTextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          label: effectiveLabel,
          useLabelAsPlaceholder: usePlaceholder,
          enabled: enabled,
          readOnly: readOnly,
          obscureText: obscureText,
          autofocus: autofocus,
          maxLines: maxLines,
          minLines: minLines,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          textStyle: style,
          leadingIcon: leadingIcon,
          trailingIcon: trailingIcon,
        ),
        if (errorText != null && errorText!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              errorText!,
              style: TextStyle(color: colors.error, fontSize: 12),
            ),
          ),
        if (helperText != null &&
            errorText == null &&
            helperText!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              helperText!,
              style: TextStyle(
                  color: colors.onSurfaceSecondary, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
