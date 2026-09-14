import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/storage/mindspace_storage.dart';
import '../../../core/theme/md3e_tokens.dart';
import '../../../core/utils/ms_date_utils.dart';
import '../../../data/models/folder.dart';
import '../../../data/models/memo.dart';
import '../../../data/models/memo_type.dart';
import '../home_provider.dart';
import '../../share/share_service.dart';

/// 长按铭记卡片弹出的操作表。
class MemoActions {
  const MemoActions._();

  static Future<void> show(BuildContext context, WidgetRef ref, Memo memo) {
    return showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
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
                    const SnackBar(content: Text('已移入回收站，可在设置中恢复或彻底删除')),
                  );
                }
              },
            ),
            const SizedBox(height: 8),
          ],
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
          await share.shareFile(path!, text: memo.title);
        } else {
          await share.shareText(memo.title);
        }
      case MemoType.audio:
        final p = memo.metadata['originalPath'] as String? ??
            memo.metadata['trimmedPath'] as String?;
        if (_safeShareable(p)) await share.shareFile(p!);
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
    }
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
            _row('类型', memo.type.wire),
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
