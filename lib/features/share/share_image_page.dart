import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot/screenshot.dart';

import '../../data/models/memo.dart';
import '../home/home_provider.dart';
import 'share_service.dart';

/// 把铭记渲染为卡片图片并分享（RepaintBoundary + screenshot）。
class ShareImagePage extends ConsumerStatefulWidget {
  const ShareImagePage({super.key, required this.memoId});
  final String memoId;

  @override
  ConsumerState<ShareImagePage> createState() => _ShareImagePageState();
}

class _ShareImagePageState extends ConsumerState<ShareImagePage> {
  final _controller = ScreenshotController();
  bool _saving = false;

  Future<void> _captureAndShare(Memo memo) async {
    setState(() => _saving = true);
    try {
      final Uint8List? bytes = await _controller.capture();
      if (bytes != null) {
        await ref
            .read(shareServiceProvider)
            .shareBytes(bytes, fileName: '${memo.title}.png');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final memoAsync = ref.watch(memoDetailProvider(widget.memoId));
    return Scaffold(
      appBar: AppBar(title: const Text('分享为图片')),
      body: memoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (memo) {
          if (memo == null) return const Center(child: Text('铭记不存在'));
          return Column(
            children: [
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Screenshot(
                      controller: _controller,
                      child: _ShareCard(memo: memo),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52)),
                  onPressed: _saving ? null : () => _captureAndShare(memo),
                  icon: const Icon(Icons.ios_share),
                  label: Text(_saving ? '正在生成…' : '生成并分享图片'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ShareCard extends StatelessWidget {
  const _ShareCard({required this.memo});
  final Memo memo;

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: memo.colorValue ?? Colors.indigo,
      brightness: Theme.of(context).brightness,
    );
    final excerpt = memo.metadata['excerpt'] as String? ?? memo.remark ?? '';
    return Container(
      width: 360,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primaryContainer, scheme.surface],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_alt, color: scheme.primary),
              const SizedBox(width: 8),
              Text('MindSpace',
                  style: TextStyle(
                      color: scheme.primary, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          Text(memo.title,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface)),
          const SizedBox(height: 12),
          if (excerpt.isNotEmpty)
            Text(excerpt,
                maxLines: 8,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: scheme.onSurfaceVariant)),
          const SizedBox(height: 24),
          Text('${memo.type.label}铭记',
              style: TextStyle(color: scheme.primary)),
        ],
      ),
    );
  }
}
