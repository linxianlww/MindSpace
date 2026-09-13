/// 铭记的四大类型。存储时用 [wire] 字符串落库/落盘，避免枚举序号变化带来兼容问题。
enum MemoType {
  text('text'),
  media('media'),
  audio('audio'),
  file('file');

  const MemoType(this.wire);

  /// 持久化使用的稳定字符串。
  final String wire;

  /// 面向用户的中文类型名。
  String get label => switch (this) {
        MemoType.text => '文本',
        MemoType.media => '媒体集',
        MemoType.audio => '音频',
        MemoType.file => '文件',
      };

  static MemoType fromWire(String? value) {
    return MemoType.values.firstWhere(
      (t) => t.wire == value,
      orElse: () => MemoType.file,
    );
  }
}

/// 媒体集内部单个媒体的种类。
enum MediaKind {
  image('image'),
  video('video');

  const MediaKind(this.wire);
  final String wire;

  static MediaKind fromWire(String? value) =>
      value == 'video' ? MediaKind.video : MediaKind.image;
}
