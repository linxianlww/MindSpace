import 'package:flutter_test/flutter_test.dart';
import 'package:mindspace/core/constants/file_types.dart';
import 'package:mindspace/data/models/memo_type.dart';

void main() {
  group('FileTypes.classify 导入类型识别', () {
    test('文本扩展名 -> text', () {
      expect(FileTypes.classify('a.txt'), MemoType.text);
      expect(FileTypes.classify('b.md'), MemoType.text);
      expect(FileTypes.classify('c.rtf'), MemoType.text);
    });

    test('图片/视频 -> media', () {
      expect(FileTypes.classify('a.png'), MemoType.media);
      expect(FileTypes.classify('a.JPG'), MemoType.media); // 大小写不敏感
      expect(FileTypes.classify('a.mp4'), MemoType.media);
      expect(FileTypes.classify('a.mov'), MemoType.media);
    });

    test('音频 -> audio', () {
      expect(FileTypes.classify('a.mp3'), MemoType.audio);
      expect(FileTypes.classify('a.m4a'), MemoType.audio);
      expect(FileTypes.classify('a.flac'), MemoType.audio);
    });

    test('办公文档与非常规文件 -> file', () {
      expect(FileTypes.classify('a.pdf'), MemoType.file);
      expect(FileTypes.classify('a.docx'), MemoType.file);
      expect(FileTypes.classify('a.xlsx'), MemoType.file);
      expect(FileTypes.classify('a.bin'), MemoType.file);
    });

    test('无扩展名 -> file 兜底', () {
      expect(FileTypes.classify('README'), MemoType.file);
    });

    test('mediaKindOf 正确区分图片/视频', () {
      expect(FileTypes.mediaKindOf('a.mp4'), MediaKind.video);
      expect(FileTypes.mediaKindOf('a.jpg'), MediaKind.image);
    });

    test('extensionOf 去点转小写', () {
      expect(FileTypes.extensionOf('A/B.C.MP4'), 'mp4');
      expect(FileTypes.extensionOf('noext'), '');
    });
  });
}
