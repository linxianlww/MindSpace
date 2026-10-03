import 'package:mindspace/ui/design_system/app_design_system.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/totp.dart';

/// 扫码导入 otpauth:// 二维码（Google Authenticator / Authy / 1Password 兼容）。
///
/// 识别成功后把 [TotpConfig] 通过 context.pop 回传给编辑页自动填充。
class TotpScanPage extends StatefulWidget {
  const TotpScanPage({super.key});

  @override
  State<TotpScanPage> createState() => _TotpScanPageState();
}

class _TotpScanPageState extends State<TotpScanPage> {
  final _controller = MobileScannerController(
    formats: [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.normal,
  );
  bool _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final b in capture.barcodes) {
      final raw = b.rawValue;
      if (raw == null) continue;
      final config = parseOtpauthUri(raw);
      if (config != null) {
        _done = true;
        _controller.stop();
        context.pop(config);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      // 沉浸式取景：黑色底 + 相机满屏，顶栏悬浮在画面之上。
      containerColor: Colors.black,
      topBar: const AppHeader(title: '扫码导入 TOTP'),
      content: (context, padding) => Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HiuiIcon(HiuiIcons.noPhoto,
                          size: 48,
                          color: MiuixTheme.of(context)
                              .colors
                              .onSurfaceVariantSummary),
                      const SizedBox(height: 12),
                      MiuixText('无法访问相机，请检查相机权限后重试'),
                    ],
                  ),
                ),
              );
            },
          ),
          // 顶部遮罩说明（contentPadding 已含顶栏高度与安全区）
          Positioned(
            top: padding.top + 16,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.topCenter,
              // 相机遮罩提示条：MiuixSurface 承载（替代手写 ShapeDecoration）
              child: MiuixSurface(
                cornerRadius: AppTokens.radiusLarge,
                color: MiuixTheme.of(context)
                    .colors
                    .onSurface
                    .withValues(alpha: 0.85),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: MiuixText(
                    '对准 otpauth:// 二维码（发行者 · 账户名会自动填入）',
                    style: TextStyle(
                        color: MiuixTheme.of(context).colors.surface),
                  ),
                ),
              ),
            ),
          ),
          // 底部提示
          Positioned(
            bottom: padding.bottom + 24,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: MiuixText(
                '支持 Google Authenticator / Authy / 1Password 导出的二维码',
                textAlign: TextAlign.center,
                style: MiuixTheme.of(context)
                    .textStyles
                    .footnote1
                    .copyWith(
                        color: MiuixTheme.of(context)
                            .colors
                            .onSurfaceVariantSummary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
