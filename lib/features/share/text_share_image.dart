import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../data/models/memo.dart';

/// 文本铭记「分享为长图」离线渲染器。
///
/// 通过 dart:ui 的 Canvas + TextPainter 直接排版，而非截取屏幕：
/// - 固定画布宽度与统一外边距（左右 48、上下 48），边距稳定可读；
/// - 行距 / 段距可配置（与设置页“文本排版”联动）；
/// - 支持 delta 里的标题、粗体/斜体/删除线/下划线/颜色/行内代码、
///   引用、列表、复选框、代码块、链接、对齐等富文本块；
/// - 输出高分辨率 PNG（默认 2x），不依赖窗口尺寸与 RepaintBoundary。
Future<Uint8List> renderTextMemoLongImage({
  required Memo memo,
  required List<dynamic> ops,
  double lineHeight = 1.7,
  double paragraphSpacing = 10,
  double scale = 2.0,
}) {
  return TextShareImageRenderer(
    memo: memo,
    ops: ops,
    lineHeight: lineHeight,
    paragraphSpacing: paragraphSpacing,
    scale: scale,
  ).render();
}

/// 渲染器：逻辑坐标 720 宽，外边距 48，内容宽 624。
class TextShareImageRenderer {
  TextShareImageRenderer({
    required this.memo,
    required this.ops,
    this.lineHeight = 1.7,
    this.paragraphSpacing = 10,
    this.scale = 2.0,
  });

  final Memo memo;
  final List<dynamic> ops;
  final double lineHeight;
  final double paragraphSpacing;
  final double scale;

  static const double canvasWidth = 720;
  static const double outerMargin = 48;
  static const double contentWidth = canvasWidth - outerMargin * 2;

  /// 防呆：内容过长时截断（过长 PNG 部分分享器无法解码）。
  static const double maxCanvasHeight = 16000;

  Future<Uint8List> render() async {
    final blocks = _parse();
    final scheme = ColorScheme.fromSeed(
      seedColor: memo.colorValue ?? const Color(0xFFFF6D00),
      brightness: Brightness.light,
    );

    // —— 第一遍：仅测量，累计内容高度 ——
    final measure = _Painter(null, scheme, lineHeight, paragraphSpacing);
    final layout = _PainterLayout();
    measure.drawHeader(memo.title, '${memo.type.label}铭记 · ${_dateLabel()}',
        layout);
    for (final b in blocks) {
      measure.drawBlock(b, layout);
      if (layout.y >= maxCanvasHeight) {
        measure.drawTruncated(layout);
        break;
      }
    }
    const footerH = 44.0;
    final contentBottom = layout.y;
    final canvasHeight = math.max(
      640.0,
      (contentBottom + footerH + outerMargin).clamp(0.0, maxCanvasHeight),
    );

    // —— 第二遍：正式绘制 ——
    final recorder = ui.PictureRecorder();
    final c = ui.Canvas(recorder);
    final painter = _Painter(c, scheme, lineHeight, paragraphSpacing);
    painter.drawBackdrop();
    final layout2 = _PainterLayout();
    painter.drawHeader(memo.title, '${memo.type.label}铭记 · ${_dateLabel()}',
        layout2);
    for (final b in blocks) {
      painter.drawBlock(b, layout2);
      if (layout2.y >= maxCanvasHeight) {
        painter.drawTruncated(layout2);
        break;
      }
    }
    painter.drawFooter(layout2.y, footerH, memo.type.label);
    final picture = recorder.endRecording();

    // 逻辑坐标 → 高分辨率位图（2x）。
    final scaled = ui.PictureRecorder();
    final canvas2 = ui.Canvas(scaled)..scale(scale);
    canvas2.drawPicture(picture);
    final img = await scaled.endRecording().toImage(
        (canvasWidth * scale).round(), (canvasHeight * scale).round());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  String _dateLabel() {
    final d = DateTime.fromMillisecondsSinceEpoch(memo.updatedAt);
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }

  // ———————————— 解析 delta → 块 ————————————

  List<_Block> _parse() {
    final blocks = <_Block>[];
    var cur = <_Inline>[];
    var type = _BlockType.paragraph;
    var align = TextAlign.start;
    var checked = false;
    final codeLines = <String>[];
    var inCode = false;

    void flush() {
      if (inCode) {
        blocks.add(_Block(code: true, codeLines: List.of(codeLines)));
        codeLines.clear();
        inCode = false;
      } else if (cur.isNotEmpty) {
        blocks.add(_Block(
          type: type,
          inlines: cur,
          textAlign: align,
          checked: checked,
        ));
      }
      cur = <_Inline>[];
      type = _BlockType.paragraph;
      align = TextAlign.start;
      checked = false;
    }

    for (final op in ops) {
      if (op is! Map || !op.containsKey('insert')) continue;
      final rawAttrs = op['attributes'];
      final attrs = rawAttrs is Map
          ? rawAttrs.map((k, v) => MapEntry(k.toString(), v))
          : <String, dynamic>{};
      final ins = op['insert'];

      // 内嵌对象（图片/视频等）：渲染为占位文本。
      if (ins is Map) {
        final isMedia = ins.containsKey('image') || ins.containsKey('video');
        cur.add(_Inline(isMedia ? '〔图片〕' : '〔嵌入对象〕', _InlineStyle.gray));
        continue;
      }
      if (ins is! String) continue;

      // 代码块：连续 code-block 行合并为一个代码块。
      if (attrs['code-block'] == true) {
        final line = ins.endsWith('\n')
            ? ins.substring(0, ins.length - 1)
            : ins;
        if (!inCode) flush();
        inCode = true;
        codeLines.add(line);
        continue;
      }
      if (inCode) flush();

      // 普通文本：'\n' 即块边界。
      final segs = ins.split('\n');
      for (var i = 0; i < segs.length; i++) {
        if (i > 0) flush();
        final seg = segs[i];
        if (seg.isEmpty) continue;
        if (cur.isEmpty) {
          type = _blockTypeFrom(attrs);
          align = _alignFrom(attrs);
          checked = attrs['list'] == 'checked';
        }
        cur.add(_Inline(seg, _inlineStyleFrom(attrs)));
      }
    }
    flush();
    return blocks;
  }
}

// ———————————— 解析辅助类型 ————————————

enum _BlockType { paragraph, h1, h2, h3, quote, bullet, check }

class _InlineStyle {
  const _InlineStyle._(this.bold, this.italic, this.underline, this.strike,
      this.color, this.background, this.size, this.code, this.link);

  final bool bold;
  final bool italic;
  final bool underline;
  final bool strike;
  final Color? color;
  final Color? background;
  final String? size; // small / large / huge
  final bool code;
  final bool link;

  static const gray = _InlineStyle._(
      false, true, false, false, null, null, null, false, false);
}

class _Inline {
  const _Inline(this.text, this.style);
  final String text;
  final _InlineStyle style;
}

class _Block {
  _Block({
    this.type = _BlockType.paragraph,
    this.inlines = const [],
    this.textAlign = TextAlign.start,
    this.checked = false,
    this.code = false,
    this.codeLines = const [],
  });

  final _BlockType type;
  final List<_Inline> inlines;
  final TextAlign textAlign;
  final bool checked;
  final bool code;
  final List<String> codeLines;
}

_BlockType _blockTypeFrom(Map<String, dynamic> attrs) {
  if (attrs['header'] == 1) return _BlockType.h1;
  if (attrs['header'] == 2) return _BlockType.h2;
  if (attrs['header'] == 3) return _BlockType.h3;
  if (attrs['blockquote'] == true) return _BlockType.quote;
  if (attrs['list'] == 'checked' || attrs['list'] == 'unchecked') {
    return _BlockType.check;
  }
  if (attrs['list'] == 'bullet' || attrs['list'] == 'ordered') {
    return _BlockType.bullet;
  }
  return _BlockType.paragraph;
}

TextAlign _alignFrom(Map<String, dynamic> attrs) {
  return switch (attrs['align']) {
    'center' => TextAlign.center,
    'right' => TextAlign.right,
    'justify' => TextAlign.justify,
    _ => TextAlign.start,
  };
}

_InlineStyle _inlineStyleFrom(Map<String, dynamic> attrs) {
  Color? color;
  if (attrs['color'] is String) color = _hexColor(attrs['color'] as String);
  Color? bg;
  if (attrs['background'] is String) {
    bg = _hexColor(attrs['background'] as String);
  }
  return _InlineStyle._(
    attrs['bold'] == true,
    attrs['italic'] == true,
    attrs['underline'] == true,
    attrs['strike'] == true,
    color,
    bg,
    attrs['size'] is String ? attrs['size'] as String : null,
    attrs['code'] == true,
    attrs['link'] is String,
  );
}

Color? _hexColor(String hex) {
  var h = hex.replaceFirst('#', '');
  if (h.length == 3) {
    h = h.split('').map((e) => '$e$e').join();
  }
  if (h.length != 6) return null;
  final v = int.tryParse(h, radix: 16);
  return v == null ? null : Color(0xFF000000 | v);
}

// ———————————— 排版 / 绘制 ————————————

class _PainterLayout {
  double y = TextShareImageRenderer.outerMargin;
}

/// 排版与绘制器：canvas 为 null 时只推进排版坐标（测量），
/// 非 null 时同时绘制，保证测量与绘制两遍布局完全一致。
class _Painter {
  _Painter(this.canvas, this.scheme, this.lineHeight, this.paragraphSpacing);

  final ui.Canvas? canvas;
  final ColorScheme scheme;
  final double lineHeight;
  final double paragraphSpacing;

  static const double _w = TextShareImageRenderer.canvasWidth;
  static const double _m = TextShareImageRenderer.outerMargin;
  static const double _cw = TextShareImageRenderer.contentWidth;

  /// 背景：底色 + 顶部品牌渐变 + 右上装饰圆。
  void drawBackdrop() {
    final c = canvas;
    if (c == null) return;
    c.drawRect(Rect.fromLTWH(0, 0, _w, 800), Paint()..color = scheme.surface);
    final rect = Rect.fromLTWH(0, 0, _w, 900);
    c.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            scheme.primaryContainer.withValues(alpha: 0.55),
            scheme.primaryContainer.withValues(alpha: 0.14),
            scheme.surface,
          ],
          stops: const [0, 0.35, 1],
        ).createShader(rect),
    );
    c.drawCircle(
      Offset(_w - 40, 30),
      180,
      Paint()..color = scheme.primary.withValues(alpha: 0.06),
    );
  }

  /// 顶部品牌胶囊 + 标题 + 元信息 + 分隔线，并把排版游标推进到正文起点。
  /// canvas 为 null 时仅计算高度（测量）。
  void drawHeader(String title, String meta, _PainterLayout l) {
    final titleTp = TextPainter(
      text: TextSpan(
        text: title.isEmpty ? '无标题' : title,
        style: TextStyle(
            fontSize: 28,
            height: 1.35,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: _cw);

    final metaTp = TextPainter(
      text: TextSpan(
        text: meta,
        style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: _cw);

    final c = canvas;
    if (c != null) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(48, 48, 118, 34),
          const Radius.circular(17),
        ),
        Paint()..color = scheme.primaryContainer,
      );
      final brand = TextPainter(
        text: TextSpan(
          text: 'NekoBox',
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: scheme.primary),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      brand.paint(c, Offset(48 + 18, 48 + (34 - brand.height) / 2));

      titleTp.paint(c, Offset(_m, _m + 52));
      final dividerY = _m + 52 + titleTp.height + 36;
      metaTp.paint(c, Offset(_m, dividerY + 12));
      c.drawLine(
        Offset(_m, dividerY),
        Offset(_w - _m, dividerY),
        Paint()
          ..color = scheme.outlineVariant.withValues(alpha: 0.8)
          ..strokeWidth = 1,
      );
    }
    // 正文起点 = 元信息行底 + 20
    l.y = _m + 52 + titleTp.height + 36 + 12 + metaTp.height + 20;
  }

  void drawFooter(double y, double footerH, String typeLabel) {
    final c = canvas;
    if (c == null) return;
    c.drawLine(
      Offset(_m, y + 8),
      Offset(_w - _m, y + 8),
      Paint()
        ..color = scheme.outlineVariant.withValues(alpha: 0.7)
        ..strokeWidth = 1,
    );
    final tp = TextPainter(
      text: TextSpan(
        text: 'NekoBox · $typeLabel',
        style: TextStyle(
            fontSize: 13,
            color: scheme.onSurfaceVariant,
            letterSpacing: 0.3),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(_m, y + 20));
  }

  void drawTruncated(_PainterLayout l) {
    final c = canvas;
    if (c == null) {
      l.y += 34;
      return;
    }
    final tp = TextPainter(
      text: TextSpan(
        text: '…… 内容过长，长图已截断 ……',
        style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(_m, l.y));
    l.y += tp.height + 12;
  }

  void drawBlock(_Block b, _PainterLayout l) {
    switch (b.type) {
      case _BlockType.h1:
      case _BlockType.h2:
      case _BlockType.h3:
        _drawParagraph(b, l, isHeader: true);
      case _BlockType.quote:
        _drawQuote(b, l);
      case _BlockType.bullet:
        _drawBullet(b, l);
      case _BlockType.check:
        _drawCheck(b, l);
      case _BlockType.paragraph:
        _drawParagraph(b, l, isHeader: false);
    }
    if (b.code) _drawCode(b, l);
    l.y += paragraphSpacing;
  }

  void _drawParagraph(_Block b, _PainterLayout l, {required bool isHeader}) {
    final size = switch (b.type) {
      _BlockType.h1 => 26.0,
      _BlockType.h2 => 21.0,
      _BlockType.h3 => 18.0,
      _ => 17.0,
    };
    if (isHeader) l.y += paragraphSpacing + 8;
    final span = TextSpan(
      style: TextStyle(
        fontSize: size,
        height: isHeader ? 1.4 : lineHeight,
        fontWeight: isHeader ? FontWeight.w700 : FontWeight.w400,
        color: scheme.onSurface,
      ),
      children: [
        for (final inl in b.inlines) TextSpan(text: inl.text, style: _span(inl)),
      ],
    );
    final tp = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
      textAlign: b.textAlign,
    )..layout(maxWidth: _cw);
    final c = canvas;
    if (c != null) tp.paint(c, Offset(_m, l.y));
    l.y += tp.height;
  }

  void _drawQuote(_Block b, _PainterLayout l) {
    l.y += 4;
    final c = canvas;
    if (c != null) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(_m, l.y, 4, 24),
          const Radius.circular(2),
        ),
        Paint()..color = scheme.primary,
      );
    }
    final span = TextSpan(
      style: TextStyle(
        fontSize: 16,
        height: lineHeight,
        fontStyle: FontStyle.italic,
        color: scheme.onSurfaceVariant,
      ),
      children: [
        for (final inl in b.inlines) TextSpan(text: inl.text, style: _span(inl)),
      ],
    );
    final tp = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
      textAlign: b.textAlign,
    )..layout(maxWidth: _cw - 26);
    if (c != null) tp.paint(c, Offset(_m + 18, l.y));
    l.y += tp.height;
  }

  void _drawBullet(_Block b, _PainterLayout l) {
    final c = canvas;
    if (c != null) {
      c.drawCircle(Offset(_m + 7, l.y + 12), 3.5, Paint()..color = scheme.primary);
    }
    final span = TextSpan(
      style: TextStyle(fontSize: 17, height: lineHeight, color: scheme.onSurface),
      children: [
        for (final inl in b.inlines) TextSpan(text: inl.text, style: _span(inl)),
      ],
    );
    final tp = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
      textAlign: b.textAlign,
    )..layout(maxWidth: _cw - 24);
    if (c != null) tp.paint(c, Offset(_m + 24, l.y));
    l.y += tp.height;
  }

  void _drawCheck(_Block b, _PainterLayout l) {
    final c = canvas;
    if (c != null) {
      final box = Rect.fromLTWH(_m, l.y + 2, 15, 15);
      if (b.checked) {
        c.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(4)),
            Paint()..color = scheme.primary);
        final tick = TextPainter(
          text: TextSpan(
            text: '✓',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: scheme.onPrimary),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tick.paint(c, Offset(box.left + (15 - tick.width) / 2, box.top + 1.5));
      } else {
        c.drawRRect(
            RRect.fromRectAndRadius(box, const Radius.circular(4)),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.4
              ..color = scheme.outline);
      }
    }
    final span = TextSpan(
      style: TextStyle(fontSize: 17, height: lineHeight, color: scheme.onSurface),
      children: [
        for (final inl in b.inlines) TextSpan(text: inl.text, style: _span(inl)),
      ],
    );
    final tp = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
      textAlign: b.textAlign,
    )..layout(maxWidth: _cw - 32);
    if (c != null) tp.paint(c, Offset(_m + 32, l.y));
    l.y += tp.height;
  }

  void _drawCode(_Block b, _PainterLayout l) {
    final c = canvas;
    TextPainter layoutLine(String line) {
      final tp = TextPainter(
        text: TextSpan(
          text: line.isEmpty ? ' ' : line,
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            fontFamily: 'monospace',
            color: scheme.onSurface,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: _cw - 32);
      return tp;
    }

    if (b.codeLines.isEmpty) return;
    l.y += paragraphSpacing + 6;
    final lineTps = [for (final ln in b.codeLines) layoutLine(ln)];
    final blockH = lineTps.fold<double>(0, (s, tp) => s + tp.height) + 20;
    if (c != null) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(_m, l.y, _cw, blockH),
          const Radius.circular(12),
        ),
        Paint()
          ..color = scheme.surfaceContainerHighest.withValues(alpha: 0.55),
      );
    }
    var ty = l.y + 10;
    for (final tp in lineTps) {
      if (c != null) tp.paint(c, Offset(_m + 16, ty));
      ty += tp.height;
    }
    l.y += blockH;
  }

  TextStyle? _span(_Inline inl) {
    final s = inl.style;
    final f = s.size == 'small'
        ? 15.0
        : s.size == 'large'
            ? 20.0
            : s.size == 'huge'
                ? 24.0
                : null;
    final deco = s.underline
        ? (s.strike ? TextDecoration.lineThrough : TextDecoration.underline)
        : (s.strike ? TextDecoration.lineThrough : null);
    return TextStyle(
      fontSize: f,
      fontWeight: s.bold ? FontWeight.w700 : null,
      fontStyle: s.italic ? FontStyle.italic : null,
      decoration: deco,
      decorationColor: s.color ?? scheme.onSurface,
      color: s.link ? scheme.primary : s.color,
      fontFamily: s.code ? 'monospace' : null,
      backgroundColor: s.code
          ? scheme.secondaryContainer.withValues(alpha: 0.45)
          : s.background,
    );
  }
}