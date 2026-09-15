import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/providers.dart';
import '../../core/utils/totp.dart';
import 'totp_provider.dart';

/// TOTP 新建 / 编辑页：手动配置发行者、账户名、密钥、时间间隔、备注；
/// 也可经“扫码导入”解析 otpauth:// 自动填充。密钥以掩码形式展示。
class TotpEditPage extends ConsumerStatefulWidget {
  const TotpEditPage({super.key, required this.memoId});
  final String memoId;

  @override
  ConsumerState<TotpEditPage> createState() => _TotpEditPageState();
}

class _TotpEditPageState extends ConsumerState<TotpEditPage> {
  final _issuer = TextEditingController();
  final _account = TextEditingController();
  final _secret = TextEditingController();
  final _period = TextEditingController(text: '30');
  final _remark = TextEditingController();
  bool _obscure = true;
  bool _loading = true;
  String? _secretError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final memo =
        await ref.read(memoRepositoryProvider).findById(widget.memoId);
    if (!mounted) return;
    if (memo != null) {
      final cfg = totpConfigOf(memo);
      if (cfg != null) {
        _issuer.text = cfg.issuer;
        _account.text = cfg.account;
        _secret.text = cfg.secret;
        _period.text = '${cfg.period}';
      }
      _remark.text = memo.remark ?? '';
    }
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _issuer.dispose();
    _account.dispose();
    _secret.dispose();
    _period.dispose();
    _remark.dispose();
    super.dispose();
  }

  String? _validateSecret(String raw) {
    final normalized = normalizeSecret(raw);
    if (normalized.isEmpty) return '请输入 Base32 密钥';
    if (base32Decode(normalized) == null || normalized.length < 8) {
      return '密钥格式无效（应为 Base32，如 JBSWY3DPEHPK3PXP）';
    }
    return null;
  }

  Future<void> _scan() async {
    final cfg = await context.push<TotpConfig>('/memo/totp/${widget.memoId}/scan');
    if (cfg == null || !mounted) return;
    setState(() {
      _issuer.text = cfg.issuer;
      _account.text = cfg.account;
      _secret.text = cfg.secret;
      _period.text = '${cfg.period}';
      _obscure = true;
      _secretError = null;
    });
  }

  Future<void> _pasteSecret() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text?.trim() ?? '';
    if (text.isNotEmpty && mounted) {
      setState(() {
        _secret.text = text;
        _secretError = null;
      });
    }
  }

  Future<void> _save() async {
    final period = int.tryParse(_period.text.trim()) ?? 30;
    final secret = normalizeSecret(_secret.text);
    final err = _validateSecret(secret);
    if (err != null) {
      setState(() => _secretError = err);
      return;
    }
    await saveTotpConfig(
      ref,
      widget.memoId,
      TotpConfig(
        secret: secret,
        issuer: _issuer.text.trim(),
        account: _account.text.trim(),
        period: period > 0 ? period : 30,
        digits: 6,
        algorithm: 'SHA1',
      ),
      remark: _remark.text.trim().isEmpty ? null : _remark.text.trim(),
    );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_loading ? 'TOTP 配置' : '编辑 TOTP 验证码'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: const Text('保存'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                children: [
                  OutlinedButton.icon(
                    onPressed: _scan,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('扫码导入 otpauth'),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _issuer,
                    decoration: const InputDecoration(
                      labelText: '发行者（如 Google / GitHub）',
                      prefixIcon: Icon(Icons.domain_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _account,
                    decoration: const InputDecoration(
                      labelText: '账户名（如 user@gmail.com）',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _secret,
                    obscureText: _obscure,
                    autocorrect: false,
                    enableSuggestions: false,
                    maxLines: 1,
                    decoration: InputDecoration(
                      labelText: '密钥（Base32）',
                      prefixIcon: const Icon(Icons.key_outlined),
                      border: const OutlineInputBorder(),
                      errorText: _secretError,
                      helperText: '仅保存在本机，查看页不会显示',
                      helperMaxLines: 2,
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: _obscure ? '显示' : '隐藏',
                            icon: Icon(_obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                          IconButton(
                            tooltip: '粘贴',
                            icon: const Icon(Icons.content_paste_go_outlined),
                            onPressed: _pasteSecret,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _period,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '时间间隔（秒，默认 30）',
                      prefixIcon: Icon(Icons.timer_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _remark,
                    decoration: const InputDecoration(
                      labelText: '备注（可选）',
                      prefixIcon: Icon(Icons.label_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check),
                    label: const Text('保存配置'),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      '支持 Google Authenticator / Authy / 1Password 导出的 otpauth 二维码',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}