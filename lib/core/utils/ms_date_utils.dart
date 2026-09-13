import 'package:intl/intl.dart';

/// 时间统一以“毫秒时间戳(int)”持久化，展示层在此格式化。
class MsDateUtils {
  MsDateUtils._();

  static DateTime toDateTime(int ms) =>
      DateTime.fromMillisecondsSinceEpoch(ms);

  static int nowMs() => DateTime.now().millisecondsSinceEpoch;

  static final DateFormat _ymdhmm = DateFormat('yyyy-MM-dd HH:mm');
  static final DateFormat _mdhm = DateFormat('MM-dd HH:mm');

  /// 列表/卡片使用的紧凑格式。
  static String format(int? ms) {
    if (ms == null) return '';
    final dt = toDateTime(ms);
    final now = DateTime.now();
    if (dt.year == now.year) return _mdhm.format(dt);
    return _ymdhmm.format(dt);
  }

  /// 详情页完整格式。
  static String formatFull(int? ms) {
    if (ms == null) return '';
    return _ymdhmm.format(toDateTime(ms));
  }

  /// 毫秒 -> mm:ss（音频时长）。
  static String formatDuration(int totalMs) {
    final totalSec = totalMs ~/ 1000;
    final m = (totalSec ~/ 60).toString().padLeft(2, '0');
    final s = (totalSec % 60).toString().padLeft(2, '0');
    final h = totalSec ~/ 3600;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:$m:$s';
    }
    return '$m:$s';
  }
}
