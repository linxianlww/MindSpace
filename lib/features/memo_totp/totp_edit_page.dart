import 'package:mindspace/ui/design_system/app_design_system.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/providers.dart';
import '../../core/utils/totp.dart';
import 'totp_provider.dart';

/// TOTP 新建 / 编辑页：手动配置发行者、账户名、密钥、时间间隔、备注；
/// 也可经"扫码导入"解析 otpauth:// 自动填充。密钥以掩码形式展示。
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
    final memo = await ref.read(memoRepositoryProvider).findById(widget.memoId);
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
    final cfg =
        await context.push<TotpConfig>('/memo/totp/${widget.memoId}/scan');
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
    return AppScaffold(
      // 保存按钮固定在表单底部；顶栏不重复放置保存入口。
      topBar: AppHeader(
        title: _loading ? 'TOTP 配置' : '编辑 TOTP 验证码',
      ),
      content: (context, padding) {
        if (_loading) {
          return Padding(
            padding: padding,
            child: const Center(child: AppCircleProgress()),
          );
        }
        return ListView(
          // 含输入框的页面：MiuixScaffold 不做键盘避让，把 viewInsets
          // 并入底部 padding，键盘弹出时末尾内容可滚动至可见。
          padding: padding.add(const EdgeInsets.fromLTRB(24, 12, 24, 24)).add(
              EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom)),
          children: _form(context),
        );
      },
    );
  }

  /// AppInput 图标内边距：MIUIX [MiuixTextField] 在有 leading / trailing
  /// 图标时会取消 insideMargin 的水平边距，导致图标贴住边框、文字贴住图标。
  /// 这里手动补齐：图标与边框 ≥12px、图标与文字 ≥8px。
  Widget _leadingIcon(String icon) => Padding(
        padding: const EdgeInsets.only(left: 12, right: 8),
        child: HiuiIcon(icon),
      );

  Widget _trailingIcon(Widget child) => Padding(
        padding: const EdgeInsets.only(left: 8, right: 12),
        child: child,
      );

  List<Widget> _form(BuildContext context) {
    final colors = MiuixTheme.of(context).colors;
    return [
      AppButton(
        variant: AppButtonStyle.outlined,
        onPressed: _scan,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HiuiIcon(HiuiIcons.qrCode, color: colors.primary),
            const SizedBox(width: 8),
            MiuixText('扫码导入 otpauth', style: TextStyle(color: colors.primary)),
          ],
        ),
      ),
      const SizedBox(height: 20),
      AppInput(
        controller: _issuer,
        leadingIcon: _leadingIcon(HiuiIcons.building),
        label: '发行者（如 Google / GitHub）',
      ),
      const SizedBox(height: 14),
      AppInput(
        controller: _account,
        leadingIcon: _leadingIcon(HiuiIcons.user),
        label: '账户名（如 user@gmail.com）',
      ),
      const SizedBox(height: 14),
      AppInput(
        controller: _secret,
        obscureText: _obscure,
        leadingIcon: _leadingIcon(HiuiIcons.key),
        label: '密钥（Base32）',
        errorText: _secretError,
        helperText: '仅保存在本机，查看页不会显示',
        trailingIcon: _trailingIcon(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTapIcon(
                tooltip: _obscure ? '显示' : '隐藏',
                icon: HiuiIcon(_obscure ? HiuiIcons.eye : HiuiIcons.eyeOff),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              AppTapIcon(
                tooltip: '粘贴',
                icon: const HiuiIcon(HiuiIcons.paste),
                onPressed: _pasteSecret,
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 14),
      AppInput(
        controller: _period,
        keyboardType: TextInputType.number,
        leadingIcon: _leadingIcon(HiuiIcons.time),
        label: '时间间隔（秒，默认 30）',
      ),
      const SizedBox(height: 14),
      AppInput(
        controller: _remark,
        leadingIcon: _leadingIcon(HiuiIcons.tag),
        label: '备注（可选）',
      ),
      const SizedBox(height: 24),
      AppButton(
        onPressed: _save,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HiuiIcon(HiuiIcons.check, color: colors.onPrimary),
            const SizedBox(width: 8),
            MiuixText('保存配置', style: TextStyle(color: colors.onPrimary)),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Center(
        child: MiuixText(
          '支持 Google Authenticator / Authy / 1Password 导出的 otpauth 二维码',
          style: MiuixTheme.of(context).textStyles.footnote2.copyWith(
              color: MiuixTheme.of(context).colors.onSurfaceVariantSummary),
        ),
      ),
    ];
  }
}
