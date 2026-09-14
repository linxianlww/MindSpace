import 'package:just_audio/just_audio.dart';

/// 用 just_audio 临时加载一次音频文件，探测真实时长（毫秒）。
///
/// 录音/导入后用于校准 durationMs：audio_waveforms 计时与真实解码时长
/// 之间存在编码开销误差，直接落库可能导致信息页/列表显示不准甚至 00:00。
Future<int> probeAudioDuration(String path) async {
  final player = AudioPlayer();
  try {
    final d = await player.setFilePath(path);
    return d?.inMilliseconds ?? 0;
  } catch (_) {
    return 0;
  } finally {
    await player.dispose();
  }
}