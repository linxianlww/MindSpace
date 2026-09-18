import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/storage/mindspace_storage.dart';
import '../../../core/theme/md3e_tokens.dart';
import '../../../core/utils/markdown_delta.dart';
import '../../../core/utils/ms_date_utils.dart';
import '../../../core/utils/totp.dart';
import '../../../data/models/folder.dart';
import '../../../data/models/memo.dart';
import '../../../data/models/memo_type.dart';
import '../../memo_text/widgets/color_picker.dart';
import '../../memo_todo/todo_model.dart';
import '../home_provider.dart';
import '../../share/share_service.dart';
import '../../memo_anniversary/anniversary_provider.dart';
import '../../memo_totp/totp_provider.dart';

/// 长按铭记卡片弹出的操作表。
class MemoActions {
  const MemoActions._();

  static Future<void> show(BuildContext context, WidgetRef ref, Memo memo) {
    return showModalBottomSheet(
      context: context,
      // 弹层高度可能超出屏，强制可滚动（isScrollControlled + SingleChildScrollView）。
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.85,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(memo.title,
                      style: Theme.of(ctx).textTheme.titleMedium),
                ),
                ListTile(
                  leading: const Icon(Icons.drive_file_rename_outline),
                  title: const Text('重命名'),
                  onTap: () {
                    Navigator.pop(ctx);
                    rename(context, ref, memo);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.palette_outlined,
                      color: memo.color != null ? Color(memo.color!) : null),
                  title: Text(memo.color == null ? '设置颜色' : '修改颜色'),
                  onTap: () {
                    Navigator.pop(ctx);
                    setColor(context, ref, memo);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.label_outline,
                      color: memo.remark != null && memo.color != null
                          ? Color(memo.color!)
                          : null),
                  title: Text(memo.remark == null ? '设置备注标签' : '修改备注标签'),
                  onTap: () {
                    Navigator.pop(ctx);
                    editRemarkLabel(context, ref, memo);
                  },
                ),
                if (memo.type == MemoType.anniversary)
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: const Text('编辑'),
                    onTap: () {
                      Navigator.pop(ctx);
                      context.push('/memo/anniversary/${memo.id}/edit');
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.drive_file_move_outline),
                  title: const Text('移动到文件夹'),
                  onTap: () {
                    Navigator.pop(ctx);
                    move(context, ref, memo);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.ios_share),
                  title: const Text('分享'),
                  onTap: () {
                    Navigator.pop(ctx);
                    share(context, ref, memo);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('查看信息'),
                  onTap: () {
                    Navigator.pop(ctx);
                    info(context, memo);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete_outline,
                      color: Theme.of(ctx).colorScheme.error),
                  title: Text('删除（进入回收站）',
                      style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await ref.read(memoRepositoryProvider).softDelete(memo.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('已移入回收站，可在设置中恢复或彻底删除')),
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> rename(
      BuildContext context, WidgetRef ref, Memo memo) async {
    final ctrl = TextEditingController(text: memo.title);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重命名'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: '输入新标题'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('确定')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && result != memo.title) {
      await ref.read(memoRepositoryProvider).rename(memo.id, result);
      // 详情 provider 是普通 FutureProvider 非流式，改名后必须显式失效，
      // 否则详情页/音频页标题仍显示旧名称。
      ref.invalidate(memoDetailProvider(memo.id));
    }
  }

  static Future<void> move(
      BuildContext context, WidgetRef ref, Memo memo) async {
    final folders = await ref.read(folderRepositoryProvider).allFolders();
    if (!context.mounted) return;
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            leading: const Icon(Icons.home_rounded),
            title: const Text('根目录'),
            selected: memo.folderId == null,
            onTap: () async {
              await ref
                  .read(memoRepositoryProvider)
                  .moveToFolder(memo.id, null);
              if (ctx.mounted) Navigator.pop(ctx);
            },
          ),
          for (final Folder f in folders)
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: Text(f.name),
              selected: f.id == memo.folderId,
              onTap: () async {
                await ref
                    .read(memoRepositoryProvider)
                    .moveToFolder(memo.id, f.id);
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
        ],
      ),
    );
  }

  /// 防越权：仅分享应用私有目录内的文件，避免被篡改的 meta 路径外泄任意文件。
  static bool _safeShareable(String? path) =>
      path != null && MindspaceStorage.instance.isWithinSupport(path);

  static Future<void> share(
      BuildContext context, WidgetRef ref, Memo memo) async {
    final share = ref.read(shareServiceProvider);
    switch (memo.type) {
      case MemoType.text:
        final path = memo.metadata['filePath'] as String?;
        if (_safeShareable(path)) {
          try {
            // filePath 现指向 content.delta.json：分享为文件时实时转
            // Markdown（不落盘副本），格式错误则回退为直接分享原始文件。
            final raw =
                await ref.read(fileSystemDatasourceProvider).readString(path!);
            final decoded = jsonDecode(raw);
            if (decoded is List<dynamic>) {
              final md = MarkdownDelta.toMarkdown(decoded);
              final safeName = '${memo.title}.md'
                  .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
              await share.shareBytes(utf8.encode(md), fileName: safeName);
              return;
            }
          } catch (_) {}
          await share.shareFile(path!, text: memo.title);
        } else {
          await share.shareText(memo.title);
        }
      case MemoType.audio:
        final p = memo.metadata['originalPath'] as String? ??
            memo.metadata['trimmedPath'] as String?;
        if (_safeShareable(p)) await share.shareFile(p!);
      case MemoType.totp:
        // 分享即导出 otpauth 配置（含密钥，供迁移到其他验证器），先明确确认。
        final cfg = totpConfigOf(memo);
        if (cfg != null) {
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('导出 TOTP 配置'),
              content: const Text(
                  '将分享包含密钥的 otpauth 链接，可导入 Google Authenticator 等应用。确定继续？'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('取消')),
                FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('导出')),
              ],
            ),
          );
          if (ok == true) {
            await share.shareText(buildOtpauthUri(cfg), subject: memo.title);
          }
        }
      case MemoType.file:
      case MemoType.media:
        final p = memo.metadata['path'] as String?;
        if (_safeShareable(p)) {
          await share.shareFile(p!);
        } else if (memo.type == MemoType.media) {
          // 媒体集：把当前条目交给媒体页打包，这里分享标题兜底。
          final items = await ref.read(memoRepositoryProvider).mediaOf(memo.id);
          if (items.isNotEmpty) {
            await share.shareFiles(items.map((e) => e.path).toList());
          }
        }
      case MemoType.todo:
        // 待办列表：将条目按「☑ / ☐」格式化后分享为纯文本。
        final path = memo.metadata['filePath'] as String?;
        if (_safeShareable(path)) {
          try {
            final raw = await ref
                .read(fileSystemDatasourceProvider)
                .readString(path!);
            final items = TodoItem.listFromJson(raw);
            if (items.isNotEmpty) {
              final sb = StringBuffer('${memo.title}\n');
              for (final it in items) {
                sb.writeln('${it.checked ? '☑' : '☐'} ${it.text}');
              }
              await share.shareText(sb.toString(), subject: memo.title);
              return;
            }
          } catch (_) {}
        }
        await share.shareText(memo.title);
    case MemoType.anniversary:
      final cfg = AnniversaryConfig.fromMemo(memo);
      final calc = computeAnniversary(cfg);
      final status = calc.isToday
          ? '就是今天'
          : (calc.isUpcoming ? '还有 ${calc.count} 天' : '已过 ${calc.absCount} 天');
      await share.shareText('${memo.title}：$status（${calc.targetLabel}）');
    }
  }

  /// 修改铭记颜色：弹出颜色选择盘后写入数据库。
  static Future<void> setColor(BuildContext context, WidgetRef ref, Memo memo) async {
    final result = await ColorPickerSheet.show(context, current: memo.color);
    if (result == null) return; // 取消
    final newColor = result.cleared ? null : result.value;
    await ref.read(memoRepositoryProvider).setAppearance(memo.id, color: newColor);
    ref.invalidate(memoDetailProvider(memo.id));
    ref.invalidate(memoListProvider(memo.folderId));
  }

  /// 设置 / 修改 / 删除备注标签。
  static Future<void> editRemarkLabel(
      BuildContext context, WidgetRef ref, Memo memo) async {
    final ctrl = TextEditingController(text: memo.remark ?? '');
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('备注标签'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 30,
          decoration: const InputDecoration(
            hintText: '输入标签文字（如「重要」「工作」）',
            prefixIcon: Icon(Icons.label_outline),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          if (memo.remark != null && memo.remark!.isNotEmpty)
            TextButton(
              onPressed: () => Navigator.pop(ctx, ''),
              child: const Text('删除', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('保存')),
        ],
      ),
    );
    if (result == null) return;
    await ref
        .read(memoRepositoryProvider)
        .setAppearance(memo.id, remark: result.isEmpty ? null : result);
    ref.invalidate(memoDetailProvider(memo.id));
    ref.invalidate(memoListProvider(memo.folderId));
  }

  static Future<void> info(BuildContext context, Memo memo) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(
            borderRadius: Md3eTokens.dialogBorder),
        title: const Text('铭记信息'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('类型', memo.type.label),
            _row('ID', memo.id),
            _row('创建', MsDateUtils.formatFull(memo.createdAt)),
            _row('更新', MsDateUtils.formatFull(memo.updatedAt)),
            if (memo.remark != null) _row('备注', memo.remark!),
            _row('标签', memo.tags.isEmpty ? '无' : memo.tags.join('、')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('关闭')),
        ],
      ),
    );
  }

  static Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 56,
                child: Text(k,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
            Expanded(child: SelectableText(v)),
          ],
        ),
      );
}
