import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/di/providers.dart';
import '../../core/settings/private_space_service.dart';
import '../../core/widgets/pin_input_dialog.dart';

/// 私密空间设置页：创建/修改 PIN、管理生物识别。
class PrivateSpaceSettingsPage extends ConsumerWidget {
  const PrivateSpaceSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(privateSpaceServiceProvider);
    final hasPin = service.hasPin;
    final biometricEnabled = service.biometricEnabled;
    final canUseBiometric = service.canCheckBiometrics;

    return Scaffold(
      appBar: AppBar(title: const Text('私密空间')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // PIN 码设置
          _SectionHeader('PIN 码保护'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.pin_outlined),
                  title: Text(hasPin ? '修改 PIN 码' : '创建 PIN 码'),
                  subtitle: Text(hasPin ? '已设置 6 位 PIN 码' : '私密空间将使用 PIN 码保护'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _onPinTap(context, ref, service),
                ),
                if (hasPin) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.lock_open_outlined,
                        color: Theme.of(context).colorScheme.outline),
                    title: const Text('立即锁定'),
                    subtitle: const Text('清空已解锁会话'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await service.lock();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('私密空间已锁定')),
                        );
                      }
                    },
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 生物识别
          _SectionHeader('生物识别解锁'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.fingerprint),
                  title: const Text('生物识别解锁'),
                  subtitle: Text(_biometricSubtitle(service, canUseBiometric)),
                  value: biometricEnabled,
                  onChanged: canUseBiometric
                      ? (v) => _onBiometricToggle(context, ref, service, v)
                      : null,
                ),
                if (!canUseBiometric)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(
                      '当前设备不支持或未注册生物识别',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 截屏保护
          _SectionHeader('截屏保护'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.screenshot_outlined),
                  title: const Text('私密空间禁止截屏'),
                  subtitle: const Text('开启后，私密空间解锁期间本应用不可截屏/录屏'),
                  value: service.screenshotProtectionEnabled,
                  onChanged: hasPin
                      ? (v) => _onScreenshotToggle(context, service, v)
                      : null,
                ),
                if (!hasPin)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(
                      '请先创建 PIN 码后再启用',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _biometricSubtitle(PrivateSpaceService service, bool available) {
    if (!service.hasPin) return '请先创建 PIN 码后再启用';
    if (!available) return '设备不可用';
    final types = service.availableBiometrics;
    final names = <String>[];
    if (types.contains(BiometricType.fingerprint)) names.add('指纹');
    if (types.contains(BiometricType.face)) names.add('面容');
    if (types.contains(BiometricType.iris)) names.add('虹膜');
    return names.isEmpty ? '可用' : names.join(' / ');
  }

  Future<void> _onPinTap(BuildContext context, WidgetRef ref,
      PrivateSpaceService service) async {
    if (service.hasPin) {
      // 修改模式：先验证旧 PIN，再创建新 PIN
      await showPinInputDialog(
        context: context,
        mode: PinDialogMode.confirm,
        onVerify: (pin) async {
          final ok = service.verifyPin(pin);
          if (!ok && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('当前 PIN 码错误')),
            );
          }
          return ok;
        },
        onCreated: (pin) async {
          if (context.mounted) {
            await _promptNewPin(context, service, oldPin: pin);
          }
        },
      );
    } else {
      // 创建模式：直接引导
      await _promptNewPin(context, service);
    }
  }

  Future<void> _promptNewPin(BuildContext context, PrivateSpaceService service,
      {String? oldPin}) async {
    await showPinInputDialog(
      context: context,
      mode: PinDialogMode.create,
      onCreated: (pin) async {
        final ok = await service.setPin(pin, oldPin: oldPin);
        if (ok && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(oldPin != null ? 'PIN 码已更新' : 'PIN 码已创建')),
          );
        }
      },
    );
  }

  Future<void> _onBiometricToggle(BuildContext context, WidgetRef ref,
      PrivateSpaceService service, bool enable) async {
    if (!enable) {
      await service.disableBiometric();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已关闭生物识别')),
        );
      }
      return;
    }

    // 启用生物识别前先验证 PIN
    await showPinInputDialog(
      context: context,
      mode: PinDialogMode.confirm,
      onVerify: (pin) async {
        final ok = await service.enableBiometric(pin);
        if (context.mounted) {
          if (ok) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('生物识别已启用')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('启用失败，请检查设备支持')),
            );
          }
        }
        return ok;
      },
    );
  }

  Future<void> _onScreenshotToggle(
      BuildContext context, PrivateSpaceService service, bool enable) async {
    await service.setScreenshotProtectionEnabled(enable);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(enable ? '已开启截屏保护' : '已关闭截屏保护')),
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
