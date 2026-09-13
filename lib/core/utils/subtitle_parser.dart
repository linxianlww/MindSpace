import '../../data/models/subtitle_item.dart';
import 'uuid_utils.dart';

/// 字幕解析：支持 LRC / SRT / TXT，输出有序 [SubtitleItem]。
///
/// 纯函数、无副作用，便于单元测试。
class SubtitleParser {
  const SubtitleParser._();

  static List<SubtitleItem> parse(String memoId, String raw, String ext) {
    switch (ext.toLowerCase()) {
      case 'srt':
        return _parseSrt(memoId, raw);
      case 'lrc':
        return _parseLrc(memoId, raw);
      default:
        return _parseTxt(memoId, raw);
    }
  }

  /// [mm:ss.xx] 或 [mm:ss.xxx] 文本，一行可含多个时间标签。
  static List<SubtitleItem> _parseLrc(String memoId, String raw) {
    final tag = RegExp(r'\[(\d{1,2}):(\d{2})(?:[.:](\d{1,3}))?\]');
    final result = <SubtitleItem>[];
    var order = 0;
    for (final line in raw.split('\n')) {
      final matches = tag.allMatches(line).toList();
      if (matches.isEmpty) continue;
      final text = line.replaceAll(tag, '').trim();
      if (text.isEmpty) continue;
      for (final m in matches) {
        final min = int.tryParse(m.group(1) ?? '0') ?? 0;
        final sec = int.tryParse(m.group(2) ?? '0') ?? 0;
        var frac = int.tryParse(m.group(3) ?? '0') ?? 0;
        if ((m.group(3) ?? '').length == 2) frac *= 10; // 百分秒->毫秒
        final start = (min * 60 + sec) * 1000 + frac;
        result.add(SubtitleItem(
          id: UuidUtils.newId(),
          memoId: memoId,
          startMs: start,
          endMs: start + 4000,
          text: text,
          sortOrder: order++,
        ));
      }
    }
    result.sort((a, b) => a.startMs.compareTo(b.startMs));
    // 用下一条起点作为上一条终点。
    for (var i = 0; i < result.length - 1; i++) {
      result[i] = result[i].copyWith(endMs: result[i + 1].startMs);
    }
    return _reindex(result);
  }

  /// 标准 SRT：序号 / 00:00:00,000 --> 00:00:00,000 / 文本(可多行)。
  static List<SubtitleItem> _parseSrt(String memoId, String raw) {
    final blocks = raw.trim().split(RegExp(r'\n\s*\n'));
    final result = <SubtitleItem>[];
    var order = 0;
    final time = RegExp(
        r'(\d{2}):(\d{2}):(\d{2})[,.](\d{3})\s*-->\s*(\d{2}):(\d{2}):(\d{2})[,.](\d{3})');
    for (final block in blocks) {
      final m = time.firstMatch(block);
      if (m == null) continue;
      // 块结构：序号行 / 时间轴行 / 文本（可多行），因此跳过前两行。
      final text = block.split('\n').skip(2).join('\n').trim();
      if (text.isEmpty) continue;
      int ms(int h, int mm, int ss, int msx) =>
          (h * 3600 + mm * 60 + ss) * 1000 + msx;
      result.add(SubtitleItem(
        id: UuidUtils.newId(),
        memoId: memoId,
        startMs: ms(int.parse(m.group(1)!), int.parse(m.group(2)!),
            int.parse(m.group(3)!), int.parse(m.group(4)!)),
        endMs: ms(int.parse(m.group(5)!), int.parse(m.group(6)!),
            int.parse(m.group(7)!), int.parse(m.group(8)!)),
        text: text,
        sortOrder: order++,
      ));
    }
    return _reindex(result);
  }

  /// 纯文本：每行一条，无时间轴，作为可滚动文稿。
  static List<SubtitleItem> _parseTxt(String memoId, String raw) {
    final lines =
        raw.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final result = <SubtitleItem>[
      for (var i = 0; i < lines.length; i++)
        SubtitleItem(
          id: UuidUtils.newId(),
          memoId: memoId,
          startMs: 0,
          endMs: 0,
          text: lines[i],
          sortOrder: i,
        ),
    ];
    return result;
  }

  static List<SubtitleItem> _reindex(List<SubtitleItem> items) {
    return [
      for (var i = 0; i < items.length; i++) items[i].copyWith(sortOrder: i),
    ];
  }
}
