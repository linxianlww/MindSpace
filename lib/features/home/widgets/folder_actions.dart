import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/settings/private_space_service.dart';
import '../../../core/widgets/pin_input_dialog.dart';
import '../../../data/models/folder.dart';
import '../home_provider.dart';

/// 长按文件夹弹出的操作表（与 MemoActions 对应）。
class FolderActions {
  const FolderActions._();

  static Future<void> show(BuildContext context, WidgetRef ref, Folder f) {
    return showModalBottomSheet(
      context: context,
      // 横屏等场景下内容可能超出默认高度。
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(f.name,
                    style: Theme.of(ctx).textTheme.titleMedium),
              ),
              ListTile(
                leading: const Icon(Icons.drive_file_rename_outline),
                title: const Text('重命名'),
                onTap: () {
                  Navigator.pop(ctx);
                  _rename(context, ref, f);
                },
              ),
              ListTile(
                leading: const Icon(Icons.drive_file_move_outline),
                title: const Text('移动到其他文件夹'),
                onTap: () {
                  Navigator.pop(ctx);
                  _move(context, ref, f);
                },
              ),
              if (f.id != kPrivateSpaceFolderId)
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('移动到私密空间'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _moveToPrivateSpace(context, ref, f);
                  },
                ),
              ListTile(
                leading: Icon(Icons.delete_outline,
                    color: Theme.of(ctx).colorScheme.error),
                title: Text('删除（进入回收站）',
                    style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ref.read(folderRepositoryProvider).softDelete(f.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('文件夹已移入回收站')),
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _rename(
      BuildContext context, WidgetRef ref, Folder f) async {
    final ctrl = TextEditingController(text: f.name);
    try {
      final result = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('重命名文件夹'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: const InputDecoration(hintText: '输入新名称'),
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
      if (result != null && result.isNotEmpty && result != f.name) {
        await ref.read(folderRepositoryProvider).rename(f.id, result);
      }
    } finally {
      ctrl.dispose();
    }
  }

  static Future<void> _move(
      BuildContext context, WidgetRef ref, Folder f) async {
    final folders = await ref.read(folderRepositoryProvider).allFolders();
    if (!context.mounted) return;
    final candidates = folders.where((e) => e.id != f.id).toList();
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: const Icon(Icons.home_rounded),
              title: const Text('根目录'),
              selected: f.parentId == null,
              onTap: () async {
                await ref.read(folderRepositoryProvider).move(f.id, null);
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
            for (final Folder c in candidates)
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: Text(c.name),
                selected: c.id == f.parentId,
                onTap: () async {
                  await ref.read(folderRepositoryProvider).move(f.id, c.id);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  /// 移动文件夹到私密空间：需要 PIN 验证。
  static Future<void> _moveToPrivateSpace(
      BuildContext context, WidgetRef ref, Folder f) async {
    final PrivateSpaceService service =
        ref.read(privateSpaceServiceProvider);

    // 确保私密空间文件夹存在
    await ref.read(folderRepositoryProvider).ensurePrivateSpaceFolder();

    // 未设置 PIN：引导创建
    if (!service.hasPin) {
      if (!context.mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('创建 PIN 码'),
          content: const Text(
              '私密空间需要 PIN 码保护。是否现在创建？\n\n创建后该文件夹将被移动到私密空间。'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('创建')),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;

      await showPinInputDialog(
        context: context,
        mode: PinDialogMode.create,
        onCreated: (pin) async {
          await service.setPin(pin);
          await ref
              .read(folderRepositoryProvider)
              .move(f.id, kPrivateSpaceFolderId);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('已移动到私密空间并解锁')),
            );
            ref.invalidate(folderListProvider(f.parentId));
          }
        },
      );
      return;
    }

    // 已设置 PIN：验证
    if (!context.mounted) return;

    await showPinInputDialog(
      context: context,
      mode: PinDialogMode.verify,
      biometricEnabled: service.canCheckBiometrics && service.biometricEnabled,
      onBiometricTap: () async {
        final ok = await service.unlockWithBiometric();
        if (ok && context.mounted) {
          Navigator.of(context).pop();
          await ref
              .read(folderRepositoryProvider)
              .move(f.id, kPrivateSpaceFolderId);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已移动到私密空间')),
          );
          ref.invalidate(folderListProvider(f.parentId));
        }
      },
      onVerify: (pin) async {
        final ok = await service.unlock(pin);
        if (ok && context.mounted) {
          await ref
              .read(folderRepositoryProvider)
              .move(f.id, kPrivateSpaceFolderId);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已移动到私密空间')),
          );
          ref.invalidate(folderListProvider(f.parentId));
        }
        return ok;
      },
    );
  }
}
