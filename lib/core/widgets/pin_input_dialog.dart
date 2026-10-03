import 'package:flutter/material.dart';
import 'package:flutter_miuix/miuix.dart';

import '../../ui/design_system/hiui_icons.dart';
import 'system_pin_channel.dart';

/// PIN 对话框类型。
enum PinDialogMode { create, confirm, verify }

/// 显示 PIN 对话框 —— MIUIX 风格。
Future<void> showPinInputDialog({
  required BuildContext context,
  required PinDialogMode mode,
  Future<bool> Function(String pin)? onVerify,
  Future<void> Function(String pin)? onCreated,
  bool biometricEnabled = false,
  VoidCallback? onBiometricTap,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: mode != PinDialogMode.verify,
    builder: (ctx) => _PinInputDialog(
      mode: mode,
      onVerify: onVerify,
      onCreated: onCreated,
      biometricEnabled: biometricEnabled,
      onBiometricTap: onBiometricTap,
    ),
  );
}

/// 关闭 PIN 对话框（白名单组件自身的管理入口）。
///
/// 本对话框由原生 Material showDialog 路由承载（安全组件豁免，见
/// docs/UI_GUIDELINES.md 第 4 节），页面层关闭它统一走这里，
/// 不要直接 Navigator.pop。
class PinInputDialog {
  const PinInputDialog._();

  static void close(BuildContext context) => Navigator.of(context).pop();
}

class _PinInputDialog extends StatefulWidget {
  const _PinInputDialog({
    required this.mode,
    this.onVerify,
    this.onCreated,
    this.biometricEnabled = false,
    this.onBiometricTap,
  });

  final PinDialogMode mode;
  final Future<bool> Function(String pin)? onVerify;
  final Future<void> Function(String pin)? onCreated;
  final bool biometricEnabled;
  final VoidCallback? onBiometricTap;

  @override
  State<_PinInputDialog> createState() => _PinInputDialogState();
}

class _PinInputDialogState extends State<_PinInputDialog> {
  String _firstPin = '';
  bool _confirming = false;
  String _errorText = '';
  bool _processing = false;
  bool _showInputField = false;

  final _pinController = TextEditingController();
  final _focusNode = FocusNode();

  String get _title {
    switch (widget.mode) {
      case PinDialogMode.create:
        return _confirming ? '确认 PIN 码' : '创建私密空间 PIN 码';
      case PinDialogMode.confirm:
        return '确认当前 PIN 码';
      case PinDialogMode.verify:
        return '输入 PIN 码';
    }
  }

  String get _subtitle {
    switch (widget.mode) {
      case PinDialogMode.create:
        return _confirming ? '请再次输入以确认' : '设置 6 位数字 PIN 码';
      case PinDialogMode.confirm:
        return '请输入当前 PIN 码';
      case PinDialogMode.verify:
        return '输入私密空间 PIN 码解锁';
    }
  }

  @override
  void initState() {
    super.initState();
    _pinController.addListener(_onPinChanged);
    if (widget.mode == PinDialogMode.create) {
      _showInputField = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _trySystemPin();
      });
    }
  }

  /// 输入达到 6 位时自动提交。
  void _onPinChanged() {
    if (_processing) return;
    if (_pinController.text.length >= 6) {
      _onPinCompleted(_pinController.text.substring(0, 6));
    }
  }

  @override
  void dispose() {
    _pinController.removeListener(_onPinChanged);
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _trySystemPin() async {
    if (_processing) return;
    setState(() {
      _processing = true;
      _errorText = '';
    });
    try {
      final available = await SystemPinChannel.isAvailable();
      if (!available) {
        if (mounted) {
          setState(() {
            _showInputField = true;
            _processing = false;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _focusNode.requestFocus();
          });
        }
        return;
      }
      final ok = await SystemPinChannel.show(
        title: _title,
        subtitle: widget.mode == PinDialogMode.verify
            ? '解锁私密空间'
            : '验证身份',
      );
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop();
      } else {
        setState(() {
          _showInputField = true;
          _processing = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _focusNode.requestFocus();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _showInputField = true;
          _errorText = '系统 PIN 调用失败';
          _processing = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _focusNode.requestFocus();
        });
      }
    }
  }

  Future<void> _onPinCompleted(String pin) async {
    if (_processing) return;
    if (_pinController.text.length != 6) return;

    setState(() {
      _errorText = '';
      _processing = true;
    });

    try {
      switch (widget.mode) {
        case PinDialogMode.create:
          if (_confirming) {
            if (pin == _firstPin) {
              await widget.onCreated?.call(pin);
              if (mounted) Navigator.of(context).pop();
            } else {
              setState(() {
                _errorText = '两次输入不一致，请重新输入';
                _firstPin = '';
                _confirming = false;
              });
            }
          } else {
            _firstPin = pin;
            _pinController.clear();
            setState(() => _confirming = true);
          }
        case PinDialogMode.confirm:
        case PinDialogMode.verify:
          final ok = await widget.onVerify?.call(pin) ?? false;
          if (ok) {
            if (mounted) Navigator.of(context).pop();
          } else {
            _pinController.clear();
            setState(() => _errorText = 'PIN 码错误');
          }
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ts = MiuixTheme.of(context).textStyles;
    final colors = MiuixTheme.of(context).colors;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: MiuixSurface(
        child: MiuixCard(
          cornerRadius: 32,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(_title, style: ts.title4),
                const SizedBox(height: 8),
                Text(_subtitle, style: ts.body1),
                const SizedBox(height: 24),
                if (!_showInputField) ...[
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        children: [
                          MiuixCircularProgressIndicator(strokeWidth: 2),
                          SizedBox(height: 12),
                          Text('正在调起系统密码键盘...'),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  MiuixTextField(
                    controller: _pinController,
                    focusNode: _focusNode,
                    enabled: !_processing,
                    obscureText: true,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    useLabelAsPlaceholder: true,
                    label: '------',
                    textStyle: TextStyle(
                      fontSize: 24,
                      letterSpacing: 12,
                      color: colors.onSurface,
                    ),
                  ),
                  if (_errorText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _errorText,
                        style: ts.footnote1.copyWith(color: colors.primary),
                      ),
                    ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_showInputField &&
                        widget.mode == PinDialogMode.verify &&
                        widget.biometricEnabled)
                      MiuixIconButton(
                        onPressed:
                            _processing ? null : widget.onBiometricTap,
                        child: const HiuiIcon(HiuiIcons.fingerprint),
                      ),
                    if (widget.mode != PinDialogMode.create && !_showInputField)
                      MiuixButton(
                        onPressed: _processing
                            ? null
                            : () {
                                setState(
                                    () => _showInputField = true);
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  if (mounted) _focusNode.requestFocus();
                                });
                              },
                        child: const Text('使用应用内输入'),
                      ),
                    MiuixButton(
                      onPressed: _processing
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('取消'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
