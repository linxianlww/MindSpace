/// flutter_quill 的 Delta（操作列表）与 Markdown / 纯文本之间的轻量转换。
///
/// 不引入额外 markdown 包，覆盖常用：标题、粗斜体下划线删除线、行内代码、
/// 链接、有序/无序列表、引用、代码块。复杂嵌入降级为纯文本，保证不丢字。
class MarkdownDelta {
  const MarkdownDelta._();

  static String toMarkdown(List<dynamic> ops) {
    final buf = StringBuffer();
    // quill 中块级属性附着在“换行符”那个 op 上，而文本在它之前的 op 里，
    // 因此先缓冲当前行的行内结果，遇到换行再用该行的块级前缀整体输出。
    final line = StringBuffer();
    var orderedIndex = 0;

    void flushLine(Map<String, dynamic> blockAttrs) {
      final prefix = _blockPrefix(blockAttrs, orderedIndex: orderedIndex + 1);
      buf.write('$prefix$line\n');
      line.clear();
      orderedIndex = 0;
    }

    for (final op in ops) {
      final m = op as Map;
      final text = (m['insert'] ?? '').toString();
      final attrs =
          (m['attributes'] as Map?)?.cast<String, dynamic>() ?? const {};

      final segments = text.split('\n');
      for (var i = 0; i < segments.length; i++) {
        final seg = segments[i];
        final isLineEnd = i < segments.length - 1;
        if (seg.isNotEmpty) {
          line.write(_inline(seg, attrs));
          if (attrs['list'] == 'ordered') orderedIndex++;
        }
        if (isLineEnd) flushLine(attrs);
      }
    }
    if (line.isNotEmpty) buf.write(line); // 末尾没有换行符的残余文本
    return buf.toString().trim();
  }

  static String _inline(String text, Map<String, dynamic> attrs) {
    var out = text;
    final link = attrs['link'];
    if (attrs['code'] == true) out = '`$out`';
    if (attrs['bold'] == true) out = '**$out**';
    if (attrs['italic'] == true) out = '*$out*';
    if (attrs['underline'] == true) out = '<u>$out</u>';
    if (attrs['strike'] == true) out = '~~$out~~';
    if (link != null) out = '[$out]($link)';
    return out;
  }

  static String _blockPrefix(Map<String, dynamic> attrs,
      {required int orderedIndex}) {
    final header = attrs['header'];
    if (header is int) return '${'#' * header} ';
    if (attrs['blockquote'] == true) return '> ';
    if (attrs['code-block'] == true) return '    ';
    if (attrs['list'] == 'bullet') return '- ';
    if (attrs['list'] == 'ordered') return '$orderedIndex. ';
    return '';
  }

  /// 从 Delta 提取纯文本（卡片摘要/检索用）。
  static String toPlainText(List<dynamic> ops) {
    final buf = StringBuffer();
    for (final op in ops) {
      buf.write((op as Map)['insert'] ?? '');
    }
    return buf.toString().replaceAll('\n', ' ').trim();
  }
}
