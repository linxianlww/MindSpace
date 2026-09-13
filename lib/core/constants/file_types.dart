import '../../data/models/memo_type.dart';

/// 扩展名 -> 铭记类型 的识别规则（与需求 5.3 导入规则完全一致）。
///
/// 纯函数、无副作用，便于单元测试覆盖。
class FileTypes {
  FileTypes._();

  static const Set<String> textExt = {
    'txt',
    'md',
    'markdown',
    'rtf',
  };

  static const Set<String> imageExt = {
    'png',
    'jpg',
    'jpeg',
    'gif',
    'webp',
    'bmp',
    'heic',
  };

  static const Set<String> videoExt = {
    'mp4',
    'mov',
    'avi',
    'mkv',
    'webm',
  };

  static const Set<String> audioExt = {
    'mp3',
    'wav',
    'aac',
    'flac',
    'ogg',
    'm4a',
  };

  /// 办公文档（可内置阅读）。
  static const Set<String> officeExt = {
    'pdf',
    'docx',
    'doc',
    'xlsx',
    'xls',
    'pptx',
    'ppt',
  };

  /// 字幕格式。
  static const Set<String> subtitleExt = {'lrc', 'srt', 'txt'};

  /// 字体格式。
  static const Set<String> fontExt = {'ttf', 'otf'};

  /// 取小写、去点的扩展名。
  static String extensionOf(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot < 0 || dot == fileName.length - 1) return '';
    return fileName.substring(dot + 1).toLowerCase();
  }

  /// 按导入规则识别应创建的铭记类型。
  /// 图片/视频统一进入“媒体集”，其余按规则归类，无法识别则为文件铭记。
  static MemoType classify(String fileName) {
    final ext = extensionOf(fileName);
    if (textExt.contains(ext)) return MemoType.text;
    if (imageExt.contains(ext) || videoExt.contains(ext)) return MemoType.media;
    if (audioExt.contains(ext)) return MemoType.audio;
    // 办公文档与其它非常规文件都归为文件铭记。
    return MemoType.file;
  }

  /// 判断媒体种类（仅对媒体集有意义）。
  static MediaKind mediaKindOf(String fileName) {
    final ext = extensionOf(fileName);
    return videoExt.contains(ext) ? MediaKind.video : MediaKind.image;
  }

  static bool isImage(String fileName) =>
      imageExt.contains(extensionOf(fileName));
  static bool isVideo(String fileName) =>
      videoExt.contains(extensionOf(fileName));
  static bool isAudio(String fileName) =>
      audioExt.contains(extensionOf(fileName));
  static bool isOffice(String fileName) =>
      officeExt.contains(extensionOf(fileName));
  static bool isFont(String fileName) =>
      fontExt.contains(extensionOf(fileName));
}
