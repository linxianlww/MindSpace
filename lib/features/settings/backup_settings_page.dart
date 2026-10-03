import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:mindspace/ui/design_system/app_design_system.dart';

import '../../core/storage/backup_service.dart';
import '../../core/utils/ms_date_utils.dart';

/// 备份与恢复：导出整个私有数据目录为 zip，或从 zip 恢复。
class BackupSettingsPage extends StatefulWidget {
  const BackupSettingsPage({super.key});

  @override
  State<BackupSettingsPage> createState() => _BackupSettingsPageState();
}

class _BackupSettingsPageState extends State<BackupSettingsPage> {
  static const _service = BackupService();
  bool _busy = false;

  Future<void> _export(BuildContext context) async {
    setState(() => _busy = true);
    try {
      final stamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      // 先在内存中打包，再决定保存方式。
      final bytes = await _service.exportZipBytes();
      final size = bytes.length;

      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        // Android/iOS：走系统 SAF "创建文档"对话框（ACTION_CREATE_DOCUMENT），
        // 插件通过 ContentResolver 写入。旧版 Android（≤9）直写 /storage/
        // emulated/0 必须持有 WRITE_EXTERNAL_STORAGE 运行时权限，容易
        // "导出失败：Permission denied"；SAF 方案全版本可用且无需任何权限。
        final saved = await FilePicker.platform.saveFile(
          dialogTitle: '保存备份',
          fileName: 'mindspace_backup_$stamp.zip',
          bytes: bytes,
          type: FileType.custom,
          allowedExtensions: ['zip'],
        );
        if (saved == null) return; // 用户取消
        if (context.mounted) {
          AppSnackbar.show(context, message: '已导出备份（${size ~/ 1024} KB）');
        }
      } else {
        // 桌面端：先选目录再直写文件。
        final dir = await FilePicker.platform.getDirectoryPath(
          dialogTitle: '选择备份保存位置',
        );
        if (dir == null) return;
        final out = p.join(dir, 'mindspace_backup_$stamp.zip');
        await File(out).writeAsBytes(bytes, flush: true);
        if (context.mounted) {
          AppSnackbar.show(context, message: '已导出备份：$out（${size ~/ 1024} KB）');
        }
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.show(context, message: '导出失败：$e');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import(BuildContext context) async {
    setState(() => _busy = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
      final path = result?.files.single.path;
      if (path == null) return;
      await _service.importZip(path);
      if (context.mounted) {
        await AppDialog.show<void>(
          context: context,
          title: '恢复完成',
          message: '数据已恢复，重启应用后完全生效。',
          actions: [
            MiuixTextButton(
              '知道了',
              onPressed: () => AppDialog.close<void>(context),
            ),
          ],
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.show(context, message: '恢复失败：$e');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = MiuixTheme.of(context).colors;

    return AppScaffold(
      topBar: AppHeader(title: '备份与恢复'),
      content: (context, padding) => Stack(
        children: [
          ListView(
            padding: padding.add(
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            children: [
              SizedBox(
                width: double.infinity,
                child: MiuixButton(
                  onPressed: _busy ? null : () => _export(context),
                  colors: MiuixButtonDefaults.buttonColorsPrimary(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      HiuiIcon(HiuiIcons.upload,
                          color: _busy
                              ? colors.disabledOnPrimaryButton
                              : colors.onPrimary),
                      const SizedBox(width: 8),
                      MiuixText('导出备份'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: MiuixButton(
                  onPressed: _busy ? null : () => _import(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      HiuiIcon(HiuiIcons.download,
                          color: _busy
                              ? colors.disabledOnSecondaryVariant
                              : colors.onSecondaryVariant),
                      const SizedBox(width: 8),
                      MiuixText('恢复备份'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              MiuixSurface(
                cornerRadius: AppTokens.radiusMedium,
                color: colors.surfaceContainer,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MiuixBasicComponent(
                      startAction: HiuiIcon(HiuiIcons.info),
                      title: '备份说明',
                      summary: '备份仅保存在你选择的位置，不会上传到网络。',
                    ),
                    MiuixBasicComponent(
                      startAction: HiuiIcon(HiuiIcons.time),
                      title: '当前时间',
                      summary: MsDateUtils.formatFull(
                          DateTime.now().millisecondsSinceEpoch),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
          if (_busy) const Center(child: AppCircleProgress()),
        ],
      ),
    );
  }
}
