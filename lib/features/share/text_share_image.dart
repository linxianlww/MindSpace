import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../data/models/memo.dart';

/// 文本铭记「分享为长图」离线渲染器（V2 重写）。
///
/// 通过 dart:ui 的 Canvas + TextPainter 直接排版（非截屏），输出高分辨率 PNG。
///
/// V2 相对 V1 的关键修复：
/// 1. 单遍布局：测量与绘制共用同一份绘制指令列表（[_Op]），每个指令在创建时
///    即记录自己的 top / height，绘制阶段只按序执行指令。彻底消除 V1 中
///    「测量与绘制两套逻辑不对称」导致的长文本被截断 / 部分内容丢失的问题。
/// 2. 页脚水印（分隔线 + 「分享自 xxx」）作为独立的绘制指令参与排版，
///    保证长图底部水印总是显示。
/// 3. 引用块左侧竖条高度随段落实际高度（V1 固定 24 逻辑像素，多行引用会缺短）。
Future<Uint8List> renderTextMemoLongImage({
  required Memo memo,
  required List<dynamic> ops,
  double lineHeight = 1.7,
  double paragraphSpacing = 10,
  double scale = 2.0,
  String shareSuffix = 'NekoBox',
}) {
  return TextShareImageRenderer(
    memo: memo,
    ops: ops,
    lineHeight: lineHeight,
    paragraphSpacing: paragraphSpacing,
    scale: scale,
    shareSuffix: shareSuffix,
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
    this.shareSuffix = 'NekoBox',
  });

  final Memo memo;
  final List<dynamic> ops;
  final double lineHeight;
  final double paragraphSpacing;
  final double scale;
  final String shareSuffix;

  static const double canvasWidth = 720;
  static const double outerMargin = 48;
  static const double contentWidth = canvasWidth - outerMargin * 2;

  // 防呆上限：逻辑像素。单图物理尺寸≈ 1440×(2×limit)，约 1.6 亿像素；
  // 足以容纳数千行文本，同时避免失控的 OOM。
  static const double maxCanvasHeight = 100000;

  Future<Uint8List> render() async {
    final blocks = _parse();
    final scheme = ColorScheme.fromSeed(
      seedColor: memo.colorValue ?? const Color(0xFFFF6D00),
      brightness: Brightness.light,
    );

    // —— 单遍排版：构建绘制指令（测量与绘制共用同一份数据）——
    final composer = _Composer(
      scheme: scheme,
      lineHeight: lineHeight,
      paragraphSpacing: paragraphSpacing,
    )..addHeader(memo);

    for (final b in blocks) {
      if (composer.y >= maxCanvasHeight) {
        composer.addTruncated();
        break;
      }
      composer.addBlock(b);
    }
    composer.addFooter(shareSuffix);

    // 画布高度 = 内容底部 + 底部留白；背景指令会覆盖整张画布。
    final totalH = math.max(
      640.0,
      (composer.y + outerMargin).clamp(0.0, maxCanvasHeight),
    );
    composer.addBackdrop(totalH);

    // —— 绘制：Canvas 构造传入完整裁剪区域 + 整体缩放，避免空白/偏移 ——
    //
    // 裁剪区域传物理像素尺寸（逻辑×scale），再对画布做 scale 变换，使
    // 裁剪区与最终 toImage 的物理尺寸严格一致：任何绘制坐标都不会越过
    // 裁剪边界，杜绝「长图下半部分被裁切/空白」的问题。
    final recorder = ui.PictureRecorder();
    final physicalW = (canvasWidth * scale).round();
    final physicalH = (totalH * scale).round();
    final c = ui.Canvas(
      recorder,
      Rect.fromLTWH(0, 0, physicalW.toDouble(), physicalH.toDouble()),
    );
    c.scale(scale, scale);
    for (final op in composer.ops) {
      op.paint(c);
    }
    final picture = recorder.endRecording();
    final img = await picture.toImage(physicalW, physicalH);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  // ———————————— delta 解析（把 quill ops 转成块模型）————————————

  /// 逐行扫描 delta，把每一「行」转成一个块。
  ///
  /// 兼容 quill 的三种真实属性附着方式（flutter_quill 序列化时块级属性
  /// header/list/blockquote/code-block/align 可能位于不同 op）：
  /// - A. 文本与换行合并：`{insert:'文本\n', attributes:{header:1}}`
  /// - B. 属性在行首文本 op：`{insert:'文本', attributes:{header:1}}, {insert:'\n'}`
  /// - C. 属性在行尾换行 op：`{insert:'文本'}, {insert:'\n', attributes:{header:1}}`
  /// 块属性 = 行尾换行 op 的属性优先，缺失时回退行首文本 op 的属性。
  List<_Block> _parse() {
    final blocks = <_Block>[];
    var cur = <_Inline>[];
    Map<String, dynamic> lineFirst = {};
    final codeLines = <String>[];

    void flushLine(Map<String, dynamic> endAttrs) {
      final merged = {..._blockAttrsOf(lineFirst), ..._blockAttrsOf(endAttrs)};
      if (merged['code-block'] == true) {
        // 代码行：收集文本，等非代码行出现再整体落块。
        codeLines.add(cur.map((e) => e.text).join());
      } else {
        if (codeLines.isNotEmpty) {
          blocks.add(_Block(code: true, codeLines: List.of(codeLines)));
          codeLines.clear();
        }
        if (cur.isNotEmpty) {
          blocks.add(_Block(
            type: _blockTypeFrom(merged),
            inlines: cur,
            textAlign: _alignFrom(merged),
            checked: merged['list'] == 'checked',
          ));
        }
      }
      cur = <_Inline>[];
      lineFirst = <String, dynamic>{};
    }

    for (final op in ops) {
      if (op is! Map || !op.containsKey('insert')) continue;
      final rawAttrs = op['attributes'];
      final attrs = rawAttrs is Map
          ? rawAttrs.map((k, v) => MapEntry(k.toString(), v))
          : <String, dynamic>{};
      final ins = op['insert'];

      if (ins is Map) {
        final isMedia = ins.containsKey('image') || ins.containsKey('video');
        if (cur.isEmpty && lineFirst.isEmpty) lineFirst = attrs;
        cur.add(_Inline(isMedia ? '〔图片〕' : '〔嵌入对象〕', _InlineStyle.gray));
        continue;
      }
      if (ins is! String) continue;

      final segs = ins.split('\n');
      for (var i = 0; i < segs.length; i++) {
        final seg = segs[i];
        final isLineEnd = i < segs.length - 1;
        if (seg.isNotEmpty) {
          if (cur.isEmpty && lineFirst.isEmpty) lineFirst = attrs;
          cur.add(_Inline(seg, _inlineStyleFrom(attrs)));
        }
        if (isLineEnd) flushLine(attrs);
      }
    }

    // 文档末尾：无换行结尾的残余行（沿用行首属性）。
    if (cur.isNotEmpty || codeLines.isNotEmpty) {
      if (codeLines.isNotEmpty) {
        if (cur.isNotEmpty) codeLines.add(cur.map((e) => e.text).join());
        blocks.add(_Block(code: true, codeLines: List.of(codeLines)));
      } else if (cur.isNotEmpty) {
        final merged = {..._blockAttrsOf(lineFirst), ..._blockAttrsOf({})};
        blocks.add(_Block(
          type: _blockTypeFrom(merged),
          inlines: cur,
          textAlign: _alignFrom(merged),
          checked: merged['list'] == 'checked',
        ));
      }
    }
    return blocks;
  }

  /// 测试/诊断：返回解析出的块摘要（类型 + 行数），便于验证 delta 解析结果。
  @visibleForTesting
  String debugDescribeBlocks() {
    return _parse().map((b) {
      if (b.code) return 'code(${b.codeLines.length})';
      final t = b.inlines.map((e) => e.text).join().replaceAll('\n', ' ');
      return '${b.type.name}[${t.length}字]';
    }).join(' | ');
  }
}

// ———————————— 绘制指令（单遍布局的核心）————————————

/// 一条绘制指令：创建时确定内容与位置，绘制时直接执行。
/// 指令列表的顺序即绘制顺序，也即排版顺序（y 坐标单调递增）。
class _Op {
  const _Op(this.paint);

  final void Function(ui.Canvas c) paint;
}

/// 排版器：把 header / 正文块 / footer 转成 [_Op] 指令序列。
/// 每 push 一个指令，内部 y 游标即推进其高度——测量与绘制天然一致。
class _Composer {
  _Composer({
    required this.scheme,
    required this.lineHeight,
    required this.paragraphSpacing,
  }) : y = TextShareImageRenderer.outerMargin;

  final ColorScheme scheme;
  final double lineHeight;
  final double paragraphSpacing;

  final List<_Op> ops = <_Op>[];

  /// 当前排版游标（下一个内容的 top）。
  double y;

  double get canW => TextShareImageRenderer.canvasWidth;
  double get margin => TextShareImageRenderer.outerMargin;
  double get contentW => TextShareImageRenderer.contentWidth;

  /// 空档：只推进 y，不产生绘制内容。
  void addGap(double h) => y += h;

  /// 追加一条指令并推进 y。
  void push(double height, void Function(ui.Canvas c) paint) {
    ops.add(_Op(paint));
    y += height;
  }

  // ———————————— 背景（最后插入到首位，盖满整张画布）————————————

  void addBackdrop(double totalH) {
    final w = canW;
    final prim = scheme.primary;
    final primC = scheme.primaryContainer;
    final surface = scheme.surface;
    ops.insert(
      0,
      _Op((c) {
        c.drawRect(
          Rect.fromLTWH(0, 0, w, totalH),
          Paint()..color = surface,
        );
        final rect = Rect.fromLTWH(0, 0, w, math.min(totalH, 900));
        c.drawRect(
          rect,
          Paint()
            ..shader = ui.Gradient.linear(
              Offset.zero,
              Offset(0, rect.height),
              [
                primC.withValues(alpha: 0.55),
                primC.withValues(alpha: 0.14),
                surface,
              ],
              [0, 0.35, 1],
            ),
        );
        c.drawCircle(
          Offset(w - 40, 30),
          180,
          Paint()..color = prim.withValues(alpha: 0.06),
        );
      }),
    );
  }

  // ———————————— 顶部品牌区 ————————————

  void addHeader(Memo memo) {
    final m = margin;
    final w = canW;
    final cw = contentW;

    final titleTp = TextPainter(
      text: TextSpan(
        text: memo.title.isEmpty ? '无标题' : memo.title,
        style: TextStyle(
          fontSize: 28,
          height: 1.35,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: cw);

    final metaTp = TextPainter(
      text: TextSpan(
        text: '${memo.type.label}铭记 · ${_dateLabel(memo.updatedAt)}',
        style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: cw);

    final brandTp = TextPainter(
      text: TextSpan(
        text: 'NekoBox',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: scheme.primary,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final top = y;
    final headerH = 52 + titleTp.height + 36 + 12 + metaTp.height + 20;
    push(headerH, (c) {
      // 品牌胶囊
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(m, top, 118, 34),
          const Radius.circular(17),
        ),
        Paint()..color = scheme.primaryContainer,
      );
      brandTp.paint(c, Offset(m + 18, top + (34 - brandTp.height) / 2));
      // 标题
      final titleTop = top + 52;
      titleTp.paint(c, Offset(m, titleTop));
      // 分隔线
      final dividerY = titleTop + titleTp.height + 36;
      c.drawLine(
        Offset(m, dividerY),
        Offset(w - m, dividerY),
        Paint()
          ..color = scheme.outlineVariant.withValues(alpha: 0.8)
          ..strokeWidth = 1,
      );
      // 元信息
      metaTp.paint(c, Offset(m, dividerY + 12));
    });
  }

  // ———————————— 正文块 ————————————

  void addBlock(_Block b) {
    switch (b.type) {
      case _BlockType.h1:
      case _BlockType.h2:
      case _BlockType.h3:
        addGap(paragraphSpacing + 8);
        _pushParagraph(b, isHeader: true);
        break;
      case _BlockType.quote:
        addGap(4);
        _pushQuote(b);
        break;
      case _BlockType.bullet:
        _pushBullet(b);
        break;
      case _BlockType.check:
        _pushCheck(b);
        break;
      case _BlockType.paragraph:
        if (!b.code) _pushParagraph(b, isHeader: false);
        break;
    }
    if (b.code) _pushCode(b);
    addGap(paragraphSpacing);
  }

  TextPainter _buildParagraphTp(
    _Block b, {
    required bool isHeader,
    double offset = 0,
    bool italic = false,
  }) {
    final size = switch (b.type) {
      _BlockType.h1 => 26.0,
      _BlockType.h2 => 21.0,
      _BlockType.h3 => 18.0,
      _ => 17.0,
    };
    return TextPainter(
      text: TextSpan(
        style: TextStyle(
          fontSize: size,
          height: isHeader ? 1.4 : lineHeight,
          fontWeight: isHeader ? FontWeight.w700 : FontWeight.w400,
          fontStyle: italic ? FontStyle.italic : null,
          color: italic ? scheme.onSurfaceVariant : scheme.onSurface,
        ),
        children: [
          for (final inl in b.inlines)
            TextSpan(text: inl.text, style: _inlineTextStyle(inl, scheme)),
        ],
      ),
      textDirection: TextDirection.ltr,
      textAlign: b.textAlign,
    )..layout(maxWidth: contentW - offset);
  }

  void _pushParagraph(
    _Block b, {
    required bool isHeader,
    double offset = 0,
    bool italic = false,
  }) {
    final tp = _buildParagraphTp(b, isHeader: isHeader, offset: offset, italic: italic);
    final top = y;
    final x = margin + offset;
    final maxW = contentW - offset;
    // 外层强行裁剪：即使 TextPainter 测量有问题，像素也绝不会越过
    // 左侧 x/右侧 x+maxW，杜绝折行后落到右边框外。
    push(tp.height, (c) {
      c.save();
      c.clipRect(Rect.fromLTWH(x, top, maxW, tp.height));
      tp.paint(c, Offset(x, top));
      c.restore();
    });
  }

  void _pushQuote(_Block b) {
    final tp = _buildParagraphTp(b, isHeader: false, offset: 18, italic: true);
    final top = y;
    final barH = math.max(tp.height, 24.0);
    push(tp.height, (c) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(margin, top, 4, barH),
          const Radius.circular(2),
        ),
        Paint()..color = scheme.primary,
      );
      tp.paint(c, Offset(margin + 18, top));
    });
  }

  void _pushBullet(_Block b) {
    final tp = _buildParagraphTp(b, isHeader: false, offset: 24);
    final top = y;
    push(tp.height, (c) {
      c.drawCircle(
        Offset(margin + 7, top + 12),
        3.5,
        Paint()..color = scheme.primary,
      );
      tp.paint(c, Offset(margin + 24, top));
    });
  }

  void _pushCheck(_Block b) {
    final tp = _buildParagraphTp(b, isHeader: false, offset: 32);
    final top = y;
    push(tp.height, (c) {
      final box = Rect.fromLTWH(margin, top + 2, 15, 15);
      if (b.checked) {
        c.drawRRect(
          RRect.fromRectAndRadius(box, const Radius.circular(4)),
          Paint()..color = scheme.primary,
        );
        final tick = TextPainter(
          text: TextSpan(
            text: '✓',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: scheme.onPrimary,
            ),
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
            ..color = scheme.outline,
        );
      }
      tp.paint(c, Offset(margin + 32, top));
    });
  }

  void _pushCode(_Block b) {
    addGap(paragraphSpacing + 6);
    final maxW = contentW - 32;
    final lines = <TextPainter>[];
    for (final ln in b.codeLines) {
      final tp = TextPainter(
        text: TextSpan(
          text: ln.isEmpty ? ' ' : ln,
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            fontFamily: 'monospace',
            color: scheme.onSurface,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: maxW);
      lines.add(tp);
    }
    final blockH = lines.fold<double>(0, (s, l) => s + l.height) + 20;
    final top = y;
    push(blockH, (c) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(margin, top, contentW, blockH),
          const Radius.circular(12),
        ),
        Paint()..color = scheme.surfaceContainerHighest.withValues(alpha: 0.55),
      );
      var ty = top + 10;
      for (final tp in lines) {
        tp.paint(c, Offset(margin + 16, ty));
        ty += tp.height;
      }
    });
  }

  // ———————————— 截断提示 / 页脚水印 ————————————

  void addTruncated() {
    final tp = TextPainter(
      text: TextSpan(
        text: '…… 内容过长，长图已截断 ……',
        style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final top = y;
    push(tp.height + 12, (c) => tp.paint(c, Offset(margin, top)));
  }

  void addFooter(String suffix) {
    final label =
        suffix.trim().isEmpty ? 'NekoBox' : suffix.trim();
    addGap(8);
    final tp = TextPainter(
      text: TextSpan(
        text: '分享自 $label',
        style: TextStyle(
          fontSize: 13,
          color: scheme.onSurfaceVariant,
          letterSpacing: 0.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final top = y;
    push(tp.height + 4, (c) {
      c.drawLine(
        Offset(margin, top - 4),
        Offset(canW - margin, top - 4),
        Paint()
          ..color = scheme.outlineVariant.withValues(alpha: 0.7)
          ..strokeWidth = 1,
      );
      tp.paint(c, Offset(margin, top));
    });
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
  final String? size;
  final bool code;
  final bool link;

  static const gray =
      _InlineStyle._(false, true, false, false, null, null, null, false, false);
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

/// 仅提取块级属性（行内样式如 bold/color 等不属于块级，不参与行判定）。
Map<String, dynamic> _blockAttrsOf(Map<String, dynamic> attrs) {
  final m = <String, dynamic>{};
  if (attrs['header'] != null) m['header'] = attrs['header'];
  if (attrs['list'] != null) m['list'] = attrs['list'];
  if (attrs['blockquote'] != null) m['blockquote'] = attrs['blockquote'];
  if (attrs['code-block'] != null) m['code-block'] = attrs['code-block'];
  if (attrs['align'] != null) m['align'] = attrs['align'];
  return m;
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

TextStyle? _inlineTextStyle(_Inline inl, ColorScheme scheme) {
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

String _dateLabel(int updatedAt) {
  final d = DateTime.fromMillisecondsSinceEpoch(updatedAt);
  String two(int v) => v.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
}