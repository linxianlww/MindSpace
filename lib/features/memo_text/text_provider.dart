import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../core/di/providers.dart';
import '../../core/storage/mindspace_storage.dart';
import '../../core/utils/font_loader.dart';
import '../../core/utils/markdown_delta.dart';
import '../../data/models/font_asset.dart';
import '../../data/models/memo.dart';

/// 文本编辑器运行时数据。
class TextEditorData {
  const TextEditorData({
    required this.memo,
    required this.controller,
    this.fontFamily,
    this.saving = false,
  });

  final Memo memo;
  final QuillController controller;
  final String? fontFamily;
  final bool saving;

  TextEditorData copyWith({
    Memo? memo,
    String? Function()? fontFamily,
    bool? saving,
  }) {
    return TextEditorData(
      memo: memo ?? this.memo,
      controller: controller,
      fontFamily: fontFamily != null ? fontFamily() : this.fontFamily,
      saving: saving ?? this.saving,
    );
  }
}

class TextEditorNotifier
    extends FamilyAsyncNotifier<TextEditorData, String> {
  /// 结构校验的文档构建：delta 可能来自被篡改/损坏的文件，逐项检查
  /// 操作是否为 {insert/retain/delete} 对象，非法时回退为空文档，
  /// 避免构建期抛未捕获异常导致整个编辑器进入错误态。
  static Document _safeDocument(List<dynamic> ops) {
    try {
      final valid = ops.every((op) =>
          op is Map<String, dynamic> &&
          (op.containsKey('insert') ||
              op.containsKey('retain') ||
              op.containsKey('delete')));
      if (!valid) return _emptyDocument();
      return Document.fromJson(ops);
    } catch (_) {
      return _emptyDocument();
    }
  }

  static Document _emptyDocument() => Document()..insert(0, '\n');

  @override
  Future<TextEditorData> build(String memoId) async {
    final memoRepo = ref.read(memoRepositoryProvider);
    final memo = await memoRepo.findById(memoId);
    if (memo == null) throw StateError('铭记不存在: $memoId');

    final storage = MindspaceStorage.instance;
    final dir = storage.memoDir(memoId: memoId, folderId: memo.folderId);
    final fs = ref.read(fileSystemDatasourceProvider);
    final deltaPath = p.join(dir, 'content.delta.json');

    List<dynamic> ops = [
      {'insert': '\n'}
    ];
    if (fs.exists(deltaPath)) {
      try {
        final raw = await fs.readString(deltaPath);
        final decoded = jsonDecode(raw);
        if (decoded is List<dynamic>) {
          ops = decoded;
        }
      } catch (_) {/* 损坏则退回空文档 */}
    } else {
      final imported = memo.metadata['filePath'] as String?;
      if (imported != null &&
          storage.isWithinSupport(imported) &&
          fs.exists(imported)) {
        final text = await fs.readString(imported);
        ops = [
          {'insert': '$text\n'}
        ];
      }
    }

    final controller = QuillController(
      document: _safeDocument(ops),
      selection: const TextSelection.collapsed(offset: 0),
    );
    ref.onDispose(controller.dispose);

    String? family;
    if (memo.fontId != null) {
      final fonts = await ref.read(fontRepositoryProvider).allFonts();
      FontAsset? match;
      for (final f in fonts) {
        if (f.id == memo.fontId) {
          match = f;
          break;
        }
      }
      if (match != null) family = await FontLoaderCache.ensure(match);
    }

    // 记录加载时的内容签名，用于 pop 时判断是否需要保存。
    _initialSignature = jsonEncode(ops);
    _initialTitle = memo.title;

    return TextEditorData(memo: memo, controller: controller, fontFamily: family);
  }

  /// 加载时的内容签名（delta JSON）。
  String? _initialSignature;
  /// 加载时的标题。
  String? _initialTitle;

  /// 当前内容是否相对加载时发生了变化（内容或标题有实质修改）。
  bool hasUnsavedChanges() {
    final cur = state.value;
    if (cur == null) return false;
    if (cur.memo.title != (_initialTitle ?? cur.memo.title)) return true;
    final curSig = jsonEncode(cur.controller.document.toDelta().toJson());
    return curSig != (_initialSignature ?? curSig);
  }

  /// 保存：仅写一份 content.delta.json（富文本唯一正本），不再同时落
  /// markdown / 纯文本副本，避免同一份内容在磁盘上重复占空间。
  /// 需要 Markdown / 纯文本时由 delta 实时转换（分享、导出、搜索）。
  Future<void> save({String? title}) async {
    // 内容未实质变更则跳过保存，避免仅查看后返回也刷新 updatedAt。
    if (!hasUnsavedChanges() && title == null) return;
    final cur = state.value;
    if (cur == null) return;
    state = AsyncData(cur.copyWith(saving: true));
    final controller = cur.controller;
    final ops = controller.document.toDelta().toJson();
    final plain = MarkdownDelta.toPlainText(ops);
    final memo = cur.memo;
    final storage = MindspaceStorage.instance;
    final dir = storage.memoDir(memoId: memo.id, folderId: memo.folderId);
    final fs = ref.read(fileSystemDatasourceProvider);
    fs.ensureDir(dir);
    final deltaPath = p.join(dir, 'content.delta.json');
    await fs.writeString(deltaPath, jsonEncode(ops));
    // 清理历史三文件存储遗留（首次保存老数据后即瘦身），
    // 同一目录下可能残留 content.md / content.txt / content.rtf。
    for (final legacy in const [
      'content.md',
      'content.txt',
      'content.rtf',
      'content.markdown'
    ]) {
      final lp = p.join(dir, legacy);
      if (lp != deltaPath && fs.exists(lp)) {
        try {
          await fs.delete(lp);
        } catch (_) {/* 清理失败不影响保存 */}
      }
    }

    final next = memo.copyWith(
      title: (title == null || title.isEmpty) ? memo.title : title,
      metadata: {
        ...memo.metadata,
        'filePath': deltaPath,
        'excerpt': plain.isEmpty ? '空文本' : plain,
      },
    );
    final saved = await ref.read(memoRepositoryProvider).save(next);
    state = AsyncData(cur.copyWith(memo: saved, saving: false));
  }

  Future<void> setColor(int? color) async {
    final cur = state.value;
    if (cur == null) return;
    await ref.read(memoRepositoryProvider).setAppearance(cur.memo.id,
        color: color, remark: cur.memo.remark);
    final refreshed = await ref.read(memoRepositoryProvider).findById(cur.memo.id);
    if (refreshed != null) {
      state = AsyncData(cur.copyWith(memo: refreshed));
    }
  }

  Future<void> setRemark(String? remark) async {
    final cur = state.value;
    if (cur == null) return;
    await ref
        .read(memoRepositoryProvider)
        .setAppearance(cur.memo.id, color: cur.memo.color, remark: remark);
    final refreshed = await ref.read(memoRepositoryProvider).findById(cur.memo.id);
    if (refreshed != null) {
      state = AsyncData(cur.copyWith(memo: refreshed));
    }
  }

  /// 选择自定义字体：落库 + 动态加载 + 应用到编辑器。
  Future<void> applyFont(FontAsset? font) async {
    final cur = state.value;
    if (cur == null) return;
    String? family;
    var memo = cur.memo;
    if (font != null) {
      family = await FontLoaderCache.ensure(font);
      memo = memo.copyWith(fontId: font.id);
      await ref.read(memoRepositoryProvider).save(memo);
    } else {
      memo = memo.copyWith(fontId: null);
      await ref.read(memoRepositoryProvider).save(memo);
    }
    state = AsyncData(cur.copyWith(
      memo: memo,
      fontFamily: () => family,
    ));
  }
}

final textEditorProvider = AsyncNotifierProvider.family<TextEditorNotifier,
    TextEditorData, String>(TextEditorNotifier.new);
