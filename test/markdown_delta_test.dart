import 'package:flutter_test/flutter_test.dart';
import 'package:mindspace/core/utils/markdown_delta.dart';

void main() {
  group('MarkdownDelta', () {
    test('纯文本提取', () {
      const ops = [
        {'insert': '第一行\n第二行\n'}
      ];
      expect(MarkdownDelta.toPlainText(ops), '第一行 第二行');
    });

    test('加粗行内标记', () {
      const ops = [
        {
          'insert': '加粗',
          'attributes': {'bold': true}
        },
        {'insert': '\n'}
      ];
      expect(MarkdownDelta.toMarkdown(ops), '**加粗**');
    });

    test('标题前缀', () {
      const ops = [
        {
          'insert': '标题',
          'attributes': {'header': 1}
        },
        {'insert': '\n', 'attributes': {'header': 1}}
      ];
      expect(MarkdownDelta.toMarkdown(ops), '# 标题');
    });

    test('无序列表前缀', () {
      const ops = [
        {'insert': '条目'},
        {
          'insert': '\n',
          'attributes': {'list': 'bullet'}
        }
      ];
      expect(MarkdownDelta.toMarkdown(ops), '- 条目');
    });
  });
}
