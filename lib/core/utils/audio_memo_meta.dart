import '../../data/models/memo.dart';

/// 音频铭记元数据（memo.metadata 键值）的集中读写与类型安全封装。
///
/// 统一从这里读写音频相关字段，避免各页面散落字符串键 + 手工类型转换，
/// 杜绝字段名拼错、类型不符（如时长存成 String）等问题。
class AudioMemoMeta {
  const AudioMemoMeta(this._meta);
  final Map<String, dynamic> _meta;

  factory AudioMemoMeta.of(Memo memo) => AudioMemoMeta(memo.metadata);

  static const kOriginalPath = 'originalPath';
  static const kOriginalName = 'originalName';
  static const kExt = 'ext';
  static const kDurationMs = 'durationMs';
  static const kOriginalDurationMs = 'originalDurationMs';
  static const kTrimStartMs = 'trimStartMs';
  static const kTrimEndMs = 'trimEndMs';
  static const kWaveform = 'waveform';

  /// 原始音频文件路径（可能存在旧版本的 trimmedPath 残留，一律以此为准）。
  String? get originalPath => _str(kOriginalPath);

  /// 原始文件名（仅展示用，不暴露内部完整路径）。
  String? get originalName => _str(kOriginalName);

  String? get ext => _str(kExt);

  /// 裁剪后的有效时长（未裁剪时约为全长）。
  int? get durationMs => _int(kDurationMs);

  /// 首次裁剪时记录的原始全长（供恢复/信息页展示）。
  int? get originalDurationMs => _int(kOriginalDurationMs);

  /// 裁剪窗口（null 表示未裁剪）。
  int? get trimStartMs => _int(kTrimStartMs);
  int? get trimEndMs => _int(kTrimEndMs);

  /// 波形采样（0..255），缺失时返回空列表。
  List<int> get waveform {
    final raw = _meta[kWaveform];
    if (raw is List) {
      return raw.map((e) => (e as num?)?.toInt() ?? 0).toList();
    }
    return const [];
  }

  /// 是否存在可播放的音频文件。
  bool get hasAudio => originalPath != null;

  String? _str(String key) {
    final v = _meta[key];
    return v is String && v.isNotEmpty ? v : null;
  }

  int? _int(String key) {
    final v = _meta[key];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return null;
  }
}