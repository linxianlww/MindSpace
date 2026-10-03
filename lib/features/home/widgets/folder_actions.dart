import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindspace/ui/design_system/app_design_system.dart';

import '../../../core/di/providers.dart';
import '../../../core/settings/private_space_service.dart';
import '../../../core/widgets/pin_input_dialog.dart';
import '../../../data/models/folder.dart';
import '../home_provider.dart';

/// 长按文件夹弹出的操作表（与 MemoActions 对应；Miuix 底部抽屉）。
class FolderActions {
  const FolderActions._();

  static Future<void> show(BuildContext context, WidgetRef ref, Folder f) {
    final colors = MiuixTheme.of(context).colors;
    return AppSheet.show(
      context: context,
      title: '文件夹操作',
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _actionRow(
            ctx,
            icon: HiuiIcons.edit,
            title: '重命名',
            onClick: () {
              AppSheet.close(ctx);
              _rename(context, ref, f);
            },
          ),
          _actionRow(
            ctx,
            icon: HiuiIcons.folderMove,
            title: '移动到其他文件夹',
            onClick: () {
              AppSheet.close(ctx);
              _move(context, ref, f);
            },
          ),
          if (f.id != kPrivateSpaceFolderId)
            _actionRow(
              ctx,
              icon: HiuiIcons.lock,
              title: '移动到私密空间',
              onClick: () {
                AppSheet.close(ctx);
                _moveToPrivateSpace(context, ref, f);
              },
            ),
          _actionRow(
            ctx,
            icon: HiuiIcons.trash,
            iconColor: colors.error,
            title: '删除（进入回收站）',
            titleColor: colors.error,
            onClick: () async {
              AppSheet.close(ctx);
              await ref.read(folderRepositoryProvider).softDelete(f.id);
              if (context.mounted) {
                AppSnackbar.show(context, message: '文件夹已移入回收站');
              }
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// 操作表单行 —— MiuixBasicComponent（与 MemoActions._actionRow 一致）。
  static Widget _actionRow(
    BuildContext sheetCtx, {
    required String icon,
    required String title,
    Color? iconColor,
    Color? titleColor,
    required VoidCallback onClick,
  }) {
    return MiuixBasicComponent(
      title: title,
      startAction: HiuiIcon(icon, color: iconColor),
      titleColor: titleColor != null
          ? MiuixBasicComponentColors(
              color: titleColor,
              disabledColor: titleColor.withValues(alpha: 0.38),
            )
          : null,
      onClick: onClick,
    );
  }

  static Future<void> _rename(
      BuildContext context, WidgetRef ref, Folder f) async {
    final ctrl = TextEditingController(text: f.name);
    try {
      final result = await AppDialog.show<String>(
        context: context,
        title: '重命名文件夹',
        content: AppInput(
          controller: ctrl,
          onChanged: (_) {},
          hintText: '输入新名称',
        ),
        actions: [
          AppButton(
              variant: AppButtonStyle.text,
              onPressed: () => AppDialog.close(context),
              child: const MiuixText('取消')),
          AppButton(
              onPressed: () =>
                  AppDialog.close<String>(context, ctrl.text.trim()),
              child: const MiuixText('确定')),
        ],
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
    await AppSheet.show(
      context: context,
      title: '移动到其他文件夹',
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: [
          MiuixBasicComponent(
            title: '根目录',
            startAction: HiuiIcon(HiuiIcons.home),
            onClick: () async {
              await ref.read(folderRepositoryProvider).move(f.id, null);
              if (ctx.mounted) AppSheet.close(ctx);
            },
          ),
          for (final Folder c in candidates)
            MiuixBasicComponent(
              title: c.name,
              startAction: HiuiIcon(HiuiIcons.folder),
              onClick: () async {
                await ref.read(folderRepositoryProvider).move(f.id, c.id);
                if (ctx.mounted) AppSheet.close(ctx);
              },
            ),
        ],
      ),
    );
  }

  static Future<void> _moveToPrivateSpace(
      BuildContext context, WidgetRef ref, Folder f) async {
    final PrivateSpaceService service = ref.read(privateSpaceServiceProvider);

    await ref.read(folderRepositoryProvider).ensurePrivateSpaceFolder();

    if (!service.hasPin) {
      if (!context.mounted) return;

      final confirmed = await AppDialog.show<bool>(
        context: context,
        title: '创建 PIN 码',
        content: const MiuixText('私密空间需要 PIN 码保护。是否现在创建？\n\n创建后该文件夹将被移动到私密空间。'),
        actions: [
          AppButton(
              variant: AppButtonStyle.text,
              onPressed: () => AppDialog.close<bool>(context, false),
              child: const MiuixText('取消')),
          AppButton(
              onPressed: () => AppDialog.close<bool>(context, true),
              child: const MiuixText('创建')),
        ],
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
            AppSnackbar.show(context, message: '已移动到私密空间并解锁');
            ref.invalidate(folderListProvider(f.parentId));
          }
        },
      );
      return;
    }

    if (!context.mounted) return;

    await showPinInputDialog(
      context: context,
      mode: PinDialogMode.verify,
      biometricEnabled: service.canCheckBiometrics && service.biometricEnabled,
      onBiometricTap: () async {
        final ok = await service.unlockWithBiometric();
        if (ok && context.mounted) {
          // 关闭白名单 PIN 对话框（原生 showDialog 路由承载）
          PinInputDialog.close(context);
          await ref
              .read(folderRepositoryProvider)
              .move(f.id, kPrivateSpaceFolderId);
          if (!context.mounted) return;
          AppSnackbar.show(context, message: '已移动到私密空间');
          ref.invalidate(folderListProvider(f.parentId));
        }
      },
      onVerify: (pin) async {
        final ok = await service.unlock(pin);
        if (ok && context.mounted) {
          await ref
              .read(folderRepositoryProvider)
              .move(f.id, kPrivateSpaceFolderId);
          if (!context.mounted) return ok;
          AppSnackbar.show(context, message: '已移动到私密空间');
          ref.invalidate(folderListProvider(f.parentId));
        }
        return ok;
      },
    );
  }
}
