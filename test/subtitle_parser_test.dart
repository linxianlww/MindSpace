import 'package:flutter_test/flutter_test.dart';
import 'package:mindspace/core/utils/subtitle_parser.dart';

void main() {
  const memoId = 'm1';

  group('SubtitleParser', () {
    test('LRC：解析时间与文本并按时间排序', () {
      const raw = '[00:05.00]第二句\n[00:01.00]第一句\n';
      final subs = SubtitleParser.parse(memoId, raw, 'lrc');
      expect(subs.length, 2);
      expect(subs[0].text, '第一句');
      expect(subs[0].startMs, 1000);
      expect(subs[1].startMs, 5000);
      // 上一条终点取下一条起点。
      expect(subs[0].endMs, 5000);
      expect(subs[0].sortOrder, 0);
    });

    test('LRC：百分秒两位补齐为毫秒', () {
      final subs = SubtitleParser.parse(memoId, '[00:02.50]半秒', 'lrc');
      expect(subs.single.startMs, 2500);
    });

    test('SRT：解析时/分/秒/毫秒区间', () {
      const raw =
          '1\n00:00:01,500 --> 00:00:03,000\n你好世界\n\n2\n00:00:04,000 --> 00:00:05,250\n第二行\n';
      final subs = SubtitleParser.parse(memoId, raw, 'srt');
      expect(subs.length, 2);
      expect(subs[0].text, '你好世界');
      expect(subs[0].startMs, 1500);
      expect(subs[0].endMs, 3000);
      expect(subs[1].endMs, 5250);
    });

    test('TXT：每行一条、无时间轴', () {
      final subs =
          SubtitleParser.parse(memoId, '第一行\n\n第二行\n', 'txt');
      expect(subs.length, 2);
      expect(subs[0].text, '第一行');
      expect(subs[1].startMs, 0);
    });
  });
}
