import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mindspace/ui/design_system/app_design_system.dart';

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
    final miuixTheme = MiuixTheme.of(context);

    return AppScaffold(
      topBar: AppHeader(title: '私密空间'),
      content: (context, padding) => ListView(
        padding: padding,
        children: [
          // PIN 码设置
          MiuixSmallTitle('PIN 码保护'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: MiuixSurface(
              cornerRadius: AppTokens.radiusMedium,
              color: miuixTheme.colors.surfaceContainer,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppSettingsRow(
                    title: hasPin ? '修改 PIN 码' : '创建 PIN 码',
                    summary: hasPin ? '已设置 6 位 PIN 码' : '私密空间将使用 PIN 码保护',
                    startAction: HiuiIcon(HiuiIcons.pin),
                    onClick: () => _onPinTap(context, ref, service),
                  ),
                  if (hasPin)
                    // 即时动作（非页面跳转），不用带箭头的 ArrowPreference
                    MiuixBasicComponent(
                      title: '立即锁定',
                      summary: '清空已解锁会话',
                      startAction: HiuiIcon(HiuiIcons.unlock,
                          color: miuixTheme.colors.onSurfaceVariantSummary),
                      onClick: () async {
                        await service.lock();
                        if (context.mounted) {
                          AppSnackbar.show(context, message: '私密空间已锁定');
                        }
                      },
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 生物识别
          MiuixSmallTitle('生物识别解锁'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: MiuixSurface(
              cornerRadius: AppTokens.radiusMedium,
              color: miuixTheme.colors.surfaceContainer,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MiuixSwitchPreference(
                    value: biometricEnabled,
                    onChanged: canUseBiometric
                        ? (v) => _onBiometricToggle(context, ref, service, v)
                        : (v) {},
                    title: '生物识别解锁',
                    summary: _biometricSubtitle(service, canUseBiometric),
                    startAction: HiuiIcon(HiuiIcons.fingerprint),
                  ),
                  if (!canUseBiometric)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: MiuixText(
                        '当前设备不支持或未注册生物识别',
                        style: miuixTheme.textStyles.footnote1.copyWith(
                            color: miuixTheme.colors.onSurfaceVariantSummary),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 截屏保护
          MiuixSmallTitle('截屏保护'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: MiuixSurface(
              cornerRadius: AppTokens.radiusMedium,
              color: miuixTheme.colors.surfaceContainer,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MiuixSwitchPreference(
                    value: service.screenshotProtectionEnabled,
                    onChanged: hasPin
                        ? (v) => _onScreenshotToggle(context, service, v)
                        : (v) {},
                    title: '私密空间禁止截屏',
                    summary: '开启后，私密空间解锁期间本应用不可截屏/录屏',
                    startAction: HiuiIcon(HiuiIcons.screenshot),
                  ),
                  if (!hasPin)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: MiuixText(
                        '请先创建 PIN 码后再启用',
                        style: miuixTheme.textStyles.footnote1.copyWith(
                            color: miuixTheme.colors.onSurfaceVariantSummary),
                      ),
                    ),
                ],
              ),
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

  Future<void> _onPinTap(
      BuildContext context, WidgetRef ref, PrivateSpaceService service) async {
    if (service.hasPin) {
      // 修改模式：先验证旧 PIN，再创建新 PIN
      await showPinInputDialog(
        context: context,
        mode: PinDialogMode.confirm,
        onVerify: (pin) async {
          final ok = service.verifyPin(pin);
          if (!ok && context.mounted) {
            AppSnackbar.show(context, message: '当前 PIN 码错误');
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
          AppSnackbar.show(context,
              message: oldPin != null ? 'PIN 码已更新' : 'PIN 码已创建');
        }
      },
    );
  }

  Future<void> _onBiometricToggle(BuildContext context, WidgetRef ref,
      PrivateSpaceService service, bool enable) async {
    if (!enable) {
      await service.disableBiometric();
      if (context.mounted) {
        AppSnackbar.show(context, message: '已关闭生物识别');
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
            AppSnackbar.show(context, message: '生物识别已启用');
          } else {
            AppSnackbar.show(context, message: '启用失败，请检查设备支持');
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
      AppSnackbar.show(context, message: enable ? '已开启截屏保护' : '已关闭截屏保护');
    }
  }
}
