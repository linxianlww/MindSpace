import 'dart:typed_data';

import 'package:mindspace/ui/design_system/app_design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../data/models/memo_type.dart';
import '../home/home_provider.dart';
import '../memo_text/text_provider.dart';
import 'share_service.dart';
import 'text_share_image.dart';

/// 文本铭记「分享为长图」：离线渲染 delta 为高分辨率长图，
/// 支持预览 + 分享（行距/段距跟随设置页"文本排版"）。
class ShareImagePage extends ConsumerStatefulWidget {
  const ShareImagePage({super.key, required this.memoId});
  final String memoId;

  @override
  ConsumerState<ShareImagePage> createState() => _ShareImagePageState();
}

class _ShareImagePageState extends ConsumerState<ShareImagePage> {
  Uint8List? _bytes;
  Object? _error;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _generate());
  }

  Future<void> _generate() async {
    if (_generating) return;
    setState(() {
      _generating = true;
      _error = null;
    });
    try {
      final data = await ref.read(textEditorProvider(widget.memoId).future);
      final memo = data.memo;
      final ops = data.controller.document.toDelta().toJson();
      final settings = ref.read(settingsProvider);
      final bytes = await renderTextMemoLongImage(
        memo: memo,
        ops: ops,
        lineHeight: settings.lineHeight,
        paragraphSpacing: settings.paragraphSpacing,
        shareSuffix: settings.shareImageWatermarkSuffix,
      );
      if (mounted) setState(() => _bytes = bytes);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _share() async {
    final bytes = _bytes;
    if (bytes == null) return;
    final memo = ref.read(memoDetailProvider(widget.memoId)).valueOrNull;
    final name = (memo?.title ?? '铭记').replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    await ref
        .read(shareServiceProvider)
        .shareBytes(bytes, fileName: '$name.png');
  }

  @override
  Widget build(BuildContext context) {
    final memoAsync = ref.watch(memoDetailProvider(widget.memoId));
    final type = memoAsync.valueOrNull?.type;

    return AppScaffold(
      topBar: const AppHeader(title: '分享为图片'),
      content: (context, padding) => Column(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  padding.left, padding.top, padding.right, 0),
              child: Builder(builder: (context) {
                if (type != null && type != MemoType.text) {
                  return const Center(child: MiuixText('仅支持文本铭记生成长图'));
                }
                if (_error != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          HiuiIcon(HiuiIcons.error,
                              size: 40,
                              color: MiuixTheme.of(context).colors.error),
                          const SizedBox(height: 12),
                          MiuixText('生成失败：$_error'),
                          const SizedBox(height: 12),
                          AppButton(
                              onPressed: _generate,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  HiuiIcon(HiuiIcons.reset),
                                  const SizedBox(width: 8),
                                  MiuixText('重试'),
                                ],
                              )),
                        ],
                      ),
                    ),
                  );
                }
                final bytes = _bytes;
                if (bytes == null) {
                  return const Center(child: AppCircleProgress());
                }
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: ClipRRect(
                        // 长图预览圆角：取 radiusMedium（MIUIX squircle 不可用于位图裁切）
                        borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
                        clipBehavior: Clip.antiAlias,
                        child: Image.memory(bytes,
                            filterQuality: FilterQuality.high,
                            gaplessPlayback: true),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: AppButton(
                onPressed: _bytes == null ? null : _share,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HiuiIcon(HiuiIcons.share),
                    const SizedBox(width: 8),
                    MiuixText(_bytes == null ? '正在生成…' : '分享长图'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
