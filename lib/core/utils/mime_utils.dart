/// 轻量 MIME 推断，用于 share_plus / open_filex 等场景。
class MimeUtils {
  MimeUtils._();

  static const Map<String, String> _map = {
    'txt': 'text/plain',
    'md': 'text/markdown',
    'rtf': 'application/rtf',
    'pdf': 'application/pdf',
    'doc': 'application/msword',
    'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'xls': 'application/vnd.ms-excel',
    'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'ppt': 'application/vnd.ms-powerpoint',
    'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'png': 'image/png',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'gif': 'image/gif',
    'webp': 'image/webp',
    'bmp': 'image/bmp',
    'mp4': 'video/mp4',
    'mov': 'video/quicktime',
    'mkv': 'video/x-matroska',
    'mp3': 'audio/mpeg',
    'wav': 'audio/wav',
    'm4a': 'audio/mp4',
    'aac': 'audio/aac',
    'flac': 'audio/flac',
    'ogg': 'audio/ogg',
    'zip': 'application/zip',
    'ttf': 'font/ttf',
    'otf': 'font/otf',
  };

  static String fromFileName(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot < 0) return 'application/octet-stream';
    final ext = fileName.substring(dot + 1).toLowerCase();
    return _map[ext] ?? 'application/octet-stream';
  }
}
