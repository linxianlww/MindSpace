import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/utils/mime_utils.dart';

/// 统一分享服务：文本 / 图片字节 / 单个或多个文件 / 媒体集打包。
///
/// 仅在分享瞬间把文件暴露给系统，平时数据都在私有目录。
class ShareService {
  const ShareService();

  Future<void> shareText(String text, {String? subject}) {
    return Share.share(text, subject: subject ?? 'NekoBox');
  }

  Future<void> shareFile(String path, {String? text}) async {
    await Share.shareXFiles([XFile(path, mimeType: MimeUtils.fromFileName(path))],
        subject: 'NekoBox', text: text);
  }

  Future<void> shareFiles(List<String> paths, {String? text}) async {
    final files = [
      for (final p in paths) XFile(p, mimeType: MimeUtils.fromFileName(p)),
    ];
    await Share.shareXFiles(files, subject: 'NekoBox', text: text);
  }

  /// 把截图得到的字节先写入临时目录再以图片分享。
  Future<void> shareBytes(Uint8List bytes,
      {String? fileName}) async {
    final tmp = await getTemporaryDirectory();
    // 用微秒时间戳生成唯一文件名，避免并发分享时临时文件互相覆盖。
    final name = fileName ?? 'nekobox_${DateTime.now().microsecondsSinceEpoch}.png';
    final target = p.join(tmp.path, name);
    await File(target).writeAsBytes(bytes, flush: true);
    try {
      await shareFile(target);
    } finally {
      // 分享完成（或失败后清理临时文件，避免磁盘膨胀。
      try {
        if (File(target).existsSync()) File(target).deleteSync();
      } catch (_) {/* 清理失败不影响主流程 */}
    }
  }
}

final shareServiceProvider = Provider<ShareService>((ref) => const ShareService());
