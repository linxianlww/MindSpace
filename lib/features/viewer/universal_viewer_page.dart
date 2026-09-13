import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/memo_type.dart';
import '../home/home_provider.dart';
import '../memo_audio/audio_player_page.dart';
import '../memo_file/file_viewer_page.dart';
import '../memo_media/media_viewer_page.dart';
import '../memo_text/text_viewer_page.dart';

/// 通用查看器：按铭记类型分发到对应详情页。
class UniversalViewerPage extends ConsumerWidget {
  const UniversalViewerPage({super.key, required this.memoId});
  final String memoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Dispatcher(memoId: memoId);
  }
}

class _Dispatcher extends ConsumerWidget {
  const _Dispatcher({required this.memoId});
  final String memoId;

  Widget _byType(MemoType type) {
    switch (type) {
      case MemoType.text:
        return TextViewerPage(memoId: memoId);
      case MemoType.media:
        return MediaViewerPage(memoId: memoId);
      case MemoType.audio:
        return AudioPlayerPage(memoId: memoId);
      case MemoType.file:
        return FileViewerPage(memoId: memoId);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 各详情页内部自行 watch memoDetail，这里直接按路由已知类型不可得，
    // 因此先读取一次元数据再分发。
    final memoAsync = ref.watch(memoDetailProvider(memoId));
    return memoAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (memo) {
        if (memo == null) {
          return const Scaffold(body: Center(child: Text('铭记不存在')));
        }
        return _byType(memo.type);
      },
    );
  }
}
