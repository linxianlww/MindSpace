import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/utils/totp.dart';

/// 扫码导入 otpauth:// 二维码（Google Authenticator / Authy / 1Password 兼容）。
///
/// 识别成功后把 [TotpConfig] 通过 Navigator.pop 回传给编辑页自动填充。
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
        Navigator.of(context).pop(config);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('扫码导入 TOTP')),
      body: Stack(
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
                      Icon(Icons.no_photography_outlined,
                          size: 48, color: scheme.onSurfaceVariant),
                      const SizedBox(height: 12),
                      const Text('无法访问相机，请检查相机权限后重试'),
                    ],
                  ),
                ),
              );
            },
          ),
          // 顶部遮罩说明
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: scheme.inverseSurface.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  '对准 otpauth:// 二维码（发行者 · 账户名会自动填入）',
                  style: TextStyle(color: scheme.onInverseSurface),
                ),
              ),
            ),
          ),
          // 底部提示
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  '支持 Google Authenticator / Authy / 1Password 导出的二维码',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}