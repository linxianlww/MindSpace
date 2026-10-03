import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mindspace/ui/design_system/app_design_system.dart';

import '../../../core/di/providers.dart';
import '../../../core/settings/private_space_service.dart';
import '../../../core/storage/mindspace_storage.dart';
import '../../../core/utils/markdown_delta.dart';
import '../../../core/utils/ms_date_utils.dart';
import '../../../core/utils/totp.dart';
import '../../../core/widgets/pin_input_dialog.dart';
import '../../../data/models/folder.dart';
import '../../../data/models/memo.dart';
import '../../../data/models/memo_type.dart';
import '../../memo_text/widgets/color_picker.dart';
import '../../memo_todo/todo_model.dart';
import '../../desktop_shortcut/add_to_desktop.dart';
import '../home_provider.dart';
import '../../share/share_service.dart';
import '../../memo_anniversary/anniversary_provider.dart';
import '../../memo_totp/totp_provider.dart';

/// 长按铭记卡片弹出的操作表（Miuix 底部抽屉 + MiuixBasicComponent 行）。
class MemoActions {
  const MemoActions._();

  static Future<void> show(BuildContext context, WidgetRef ref, Memo memo) {
    final colors = MiuixTheme.of(context).colors;
    return AppSheet.show(
      context: context,
      title: '铭记操作',
      builder: (ctx) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _actionRow(
              ctx,
              icon: HiuiIcons.edit,
              title: '重命名',
              onClick: () {
                AppSheet.close(ctx);
                rename(context, ref, memo);
              },
            ),
            _actionRow(
              ctx,
              icon: HiuiIcons.skin,
              iconColor: memo.color != null ? Color(memo.color!) : null,
              title: memo.color == null ? '设置颜色' : '修改颜色',
              onClick: () {
                AppSheet.close(ctx);
                setColor(context, ref, memo);
              },
            ),
            _actionRow(
              ctx,
              icon: HiuiIcons.tag,
              // 备注标签图标随铭记卡片色（仅依卡片色，不要求已设置备注）
              iconColor: memo.color != null ? Color(memo.color!) : null,
              title: memo.remark == null ? '设置备注标签' : '修改备注标签',
              onClick: () {
                AppSheet.close(ctx);
                editRemarkLabel(context, ref, memo);
              },
            ),
            if (memo.type == MemoType.anniversary)
              _actionRow(
                ctx,
                icon: HiuiIcons.edit,
                title: '编辑',
                onClick: () {
                  AppSheet.close(ctx);
                  context.push('/memo/anniversary/${memo.id}/edit');
                },
              ),
            _actionRow(
              ctx,
              icon: HiuiIcons.folderMove,
              title: '移动到文件夹',
              onClick: () {
                AppSheet.close(ctx);
                move(context, ref, memo);
              },
            ),
            _actionRow(
              ctx,
              icon: HiuiIcons.lock,
              title: '移动到私密空间',
              onClick: () {
                AppSheet.close(ctx);
                moveToPrivateSpace(context, ref, memo);
              },
            ),
            _actionRow(
              ctx,
              icon: HiuiIcons.share,
              title: '分享',
              onClick: () {
                AppSheet.close(ctx);
                share(context, ref, memo);
              },
            ),
            _actionRow(
              ctx,
              icon: HiuiIcons.export,
              title: '添加到桌面',
              onClick: () {
                AppSheet.close(ctx);
                addMemoToDesktop(context, ref, memo);
              },
            ),
            _actionRow(
              ctx,
              icon: HiuiIcons.info,
              title: '查看信息',
              onClick: () {
                AppSheet.close(ctx);
                info(context, memo);
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
                await ref.read(memoRepositoryProvider).softDelete(memo.id);
                if (context.mounted) {
                  AppSnackbar.show(context, message: '已移入回收站，可在设置中恢复或彻底删除');
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// 操作表单行 —— MiuixBasicComponent（startAction 图标 + 标题 + sink 反馈）。
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

  static Future<void> rename(
      BuildContext context, WidgetRef ref, Memo memo) async {
    final ctrl = TextEditingController(text: memo.title);
    try {
      final result = await AppDialog.show<String>(
        context: context,
        title: '重命名',
        content: AppInput(
          controller: ctrl,
          onChanged: (_) {},
          hintText: '输入新标题',
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
      if (result != null && result.isNotEmpty && result != memo.title) {
        await ref.read(memoRepositoryProvider).rename(memo.id, result);
        ref.invalidate(memoDetailProvider(memo.id));
      }
    } finally {
      ctrl.dispose();
    }
  }

  static Future<void> move(
      BuildContext context, WidgetRef ref, Memo memo) async {
    final folders = await ref.read(folderRepositoryProvider).allFolders();
    if (!context.mounted) return;
    await AppSheet.show(
      context: context,
      title: '移动到文件夹',
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: [
          MiuixBasicComponent(
            title: '根目录',
            startAction: HiuiIcon(HiuiIcons.home),
            onClick: () async {
              await ref
                  .read(memoRepositoryProvider)
                  .moveToFolder(memo.id, null);
              if (ctx.mounted) AppSheet.close(ctx);
            },
          ),
          for (final Folder f in folders)
            MiuixBasicComponent(
              title: f.name,
              startAction: HiuiIcon(HiuiIcons.folder),
              onClick: () async {
                await ref
                    .read(memoRepositoryProvider)
                    .moveToFolder(memo.id, f.id);
                if (ctx.mounted) AppSheet.close(ctx);
              },
            ),
        ],
      ),
    );
  }

  static Future<void> moveToPrivateSpace(
      BuildContext context, WidgetRef ref, Memo memo) async {
    final PrivateSpaceService service = ref.read(privateSpaceServiceProvider);

    if (memo.folderId == kPrivateSpaceFolderId) {
      if (context.mounted) {
        AppSnackbar.show(context, message: '该铭记已在私密空间中');
      }
      return;
    }

    await ref.read(folderRepositoryProvider).ensurePrivateSpaceFolder();

    if (!service.hasPin) {
      if (!context.mounted) return;

      final confirmed = await AppDialog.show<bool>(
        context: context,
        title: '创建 PIN 码',
        content: const MiuixText('私密空间需要 PIN 码保护。是否现在创建？\n\n创建后该铭记将被移动到私密空间。'),
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
              .read(memoRepositoryProvider)
              .moveToFolder(memo.id, kPrivateSpaceFolderId);
          if (context.mounted) {
            AppSnackbar.show(context, message: '已移动到私密空间并解锁');
            ref.invalidate(memoListProvider(memo.folderId));
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
              .read(memoRepositoryProvider)
              .moveToFolder(memo.id, kPrivateSpaceFolderId);
          if (!context.mounted) return;
          AppSnackbar.show(context, message: '已移动到私密空间');
          ref.invalidate(memoListProvider(memo.folderId));
        }
      },
      onVerify: (pin) async {
        final ok = await service.unlock(pin);
        if (ok && context.mounted) {
          await ref
              .read(memoRepositoryProvider)
              .moveToFolder(memo.id, kPrivateSpaceFolderId);
          if (!context.mounted) return ok;
          AppSnackbar.show(context, message: '已移动到私密空间');
          ref.invalidate(memoListProvider(memo.folderId));
        }
        return ok;
      },
    );
  }

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
            final raw =
                await ref.read(fileSystemDatasourceProvider).readString(path!);
            final decoded = jsonDecode(raw);
            if (decoded is List<dynamic>) {
              final md = MarkdownDelta.toMarkdown(decoded);
              final safeName =
                  '${memo.title}.md'.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
              await share.shareBytes(utf8.encode(md), fileName: safeName);
              return;
            }
          } catch (_) {}
          await share.shareFile(path!, text: memo.title);
        } else {
          await share.shareText(memo.title);
        }
        return;
      case MemoType.audio:
        final p = memo.metadata['originalPath'] as String? ??
            memo.metadata['trimmedPath'] as String?;
        if (_safeShareable(p)) await share.shareFile(p!);
        return;
      case MemoType.totp:
        final cfg = totpConfigOf(memo);
        if (cfg != null) {
          final ok = await AppDialog.show<bool>(
            context: context,
            title: '导出 TOTP 配置',
            content: const MiuixText(
                '将分享包含密钥的 otpauth 链接，可导入 Google Authenticator 等应用。确定继续？'),
            actions: [
              AppButton(
                  variant: AppButtonStyle.text,
                  onPressed: () => AppDialog.close<bool>(context, false),
                  child: const MiuixText('取消')),
              AppButton(
                  onPressed: () => AppDialog.close<bool>(context, true),
                  child: const MiuixText('导出')),
            ],
          );
          if (ok == true) {
            await share.shareText(buildOtpauthUri(cfg), subject: memo.title);
          }
        }
        return;
      case MemoType.file:
      case MemoType.media:
        final p = memo.metadata['path'] as String?;
        if (_safeShareable(p)) {
          await share.shareFile(p!);
        } else if (memo.type == MemoType.media) {
          final items = await ref.read(memoRepositoryProvider).mediaOf(memo.id);
          if (items.isNotEmpty) {
            await share.shareFiles(items.map((e) => e.path).toList());
          }
        }
      case MemoType.todo:
        final path = memo.metadata['filePath'] as String?;
        if (_safeShareable(path)) {
          try {
            final raw =
                await ref.read(fileSystemDatasourceProvider).readString(path!);
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
        return;
      case MemoType.anniversary:
        final cfg = AnniversaryConfig.fromMemo(memo);
        final calc = computeAnniversary(cfg);
        final status = calc.isToday
            ? '就是今天'
            : (calc.isUpcoming
                ? '还有 ${calc.count} 天'
                : '已过 ${calc.absCount} 天');
        await share.shareText('${memo.title}：$status（${calc.targetLabel}）');
    }
  }

  static Future<void> setColor(
      BuildContext context, WidgetRef ref, Memo memo) async {
    final result = await ColorPickerSheet.show(context, current: memo.color);
    if (result == null) return;
    final newColor = result.cleared ? null : result.value;
    await ref
        .read(memoRepositoryProvider)
        .setAppearance(memo.id, color: newColor);
    ref.invalidate(memoDetailProvider(memo.id));
    ref.invalidate(memoListProvider(memo.folderId));
  }

  static Future<void> editRemarkLabel(
      BuildContext context, WidgetRef ref, Memo memo) async {
    final ctrl = TextEditingController(text: memo.remark ?? '');
    try {
      final result = await AppDialog.show<String?>(
        context: context,
        title: '备注标签',
        content: AppInput(
          controller: ctrl,
          onChanged: (_) {},
          hintText: '输入标签文字（如「重要」「工作」）',
          // 与 TOTP 编辑页一致：补齐图标与边框/文字的间距，避免贴边。
          leadingIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: HiuiIcon(HiuiIcons.tag),
          ),
        ),
        actions: [
          if (memo.remark != null && memo.remark!.isNotEmpty)
            // 删除操作用主题错误色（error），禁止硬编码 Colors.red
            AppButton(
              variant: AppButtonStyle.text,
              onPressed: () => AppDialog.close<String?>(context, ''),
              child: MiuixText('删除',
                  style: TextStyle(color: MiuixTheme.of(context).colors.error)),
            ),
          AppButton(
              variant: AppButtonStyle.text,
              onPressed: () => AppDialog.close<String?>(context),
              child: const MiuixText('取消')),
          AppButton(
              onPressed: () =>
                  AppDialog.close<String?>(context, ctrl.text.trim()),
              child: const MiuixText('保存')),
        ],
      );
      if (result == null) return;
      await ref
          .read(memoRepositoryProvider)
          .setAppearance(memo.id, remark: result.isEmpty ? null : result);
      ref.invalidate(memoDetailProvider(memo.id));
      ref.invalidate(memoListProvider(memo.folderId));
    } finally {
      ctrl.dispose();
    }
  }

  static Future<void> info(BuildContext context, Memo memo) async {
    return AppDialog.show(
      context: context,
      title: '铭记信息',
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
        AppButton(
            variant: AppButtonStyle.text,
            onPressed: () => AppDialog.close(context),
            child: const MiuixText('关闭')),
      ],
    );
  }

  static Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 56, child: MiuixText(k, fontWeight: FontWeight.w600)),
            Expanded(child: AppSelectableText(v)),
          ],
        ),
      );
}
