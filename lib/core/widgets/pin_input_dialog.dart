import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'system_pin_channel.dart';

/// PIN 对话框类型。
enum PinDialogMode { create, confirm, verify }

/// 显示 PIN 输入对话框。
///
/// 使用 Flutter 的安全密码输入字段（obscureText + 系统数字键盘），
/// 输入时显示 ● 字符；6 位数字。
///
/// verify/confirm 模式会弹出 Android 系统 PIN/图案/密码对话框作为首选；
/// 系统 PIN 不可用时回退到内部密码输入框。
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
  /// 自定义输入框先隐藏；verify/confirm 模式等待系统 PIN 返回。
  /// 创建模式直接显示输入框。
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

  @override
  void dispose() {
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
        // 设备没有 PIN：显示内部输入框
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
        subtitle: widget.mode == PinDialogMode.verify ? '解锁私密空间' : '验证身份',
      );
      if (!mounted) return;
      if (ok) {
        // 系统 PIN 通过 → 视为本地校验通过（系统 PIN 是设备级验证）
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
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(_title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_subtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          if (!_showInputField) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    CircularProgressIndicator(strokeWidth: 2),
                    SizedBox(height: 12),
                    Text('正在调起系统密码键盘...'),
                  ],
                ),
              ),
            ),
          ] else ...[
            // 系统密码输入框
            TextField(
              controller: _pinController,
              focusNode: _focusNode,
              enabled: !_processing,
              obscureText: true,
              obscuringCharacter: '●',
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                letterSpacing: 12,
              ),
              maxLength: 6,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: InputDecoration(
                counterText: '',
                hintText: '------',
                hintStyle: TextStyle(
                  color: scheme.outlineVariant,
                  letterSpacing: 12,
                ),
                filled: true,
                fillColor: scheme.surfaceContainerLowest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: scheme.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: scheme.outlineVariant),
                ),
                errorText: _errorText.isNotEmpty ? _errorText : null,
              ),
              onChanged: (v) {
                if (v.length == 6) _onPinCompleted(v);
              },
              onSubmitted: (v) {
                if (v.length == 6) _onPinCompleted(v);
              },
            ),
          ],
        ],
      ),
      actions: [
        if (_showInputField &&
            widget.mode == PinDialogMode.verify &&
            widget.biometricEnabled)
          IconButton(
            icon: const Icon(Icons.fingerprint),
            tooltip: '生物识别',
            onPressed: _processing ? null : widget.onBiometricTap,
          ),
        if (widget.mode != PinDialogMode.create && !_showInputField)
          TextButton(
            onPressed: _processing
                ? null
                : () {
                    setState(() => _showInputField = true);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _focusNode.requestFocus();
                    });
                  },
            child: const Text('使用应用内输入'),
          ),
        TextButton(
          onPressed: _processing ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
      ],
    );
  }
}
