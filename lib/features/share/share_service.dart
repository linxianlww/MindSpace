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
      {String fileName = 'nekobox.png'}) async {
    final tmp = await getTemporaryDirectory();
    final target = p.join(tmp.path, fileName);
    await File(target).writeAsBytes(bytes, flush: true);
    await shareFile(target);
  }
}

final shareServiceProvider = Provider<ShareService>((ref) => const ShareService());
