import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

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

  Future<void> _export() async {
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
        // Android/iOS：走系统 SAF “创建文档”对话框（ACTION_CREATE_DOCUMENT），
        // 插件通过 ContentResolver 写入。旧版 Android（≤9）直写 /storage/
        // emulated/0 必须持有 WRITE_EXTERNAL_STORAGE 运行时权限，容易
        // “导出失败：Permission denied”；SAF 方案全版本可用且无需任何权限。
        final saved = await FilePicker.platform.saveFile(
          dialogTitle: '保存备份',
          fileName: 'mindspace_backup_$stamp.zip',
          bytes: bytes,
          type: FileType.custom,
          allowedExtensions: ['zip'],
        );
        if (saved == null) return; // 用户取消
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已导出备份（${size ~/ 1024} KB）')),
          );
        }
      } else {
        // 桌面端：先选目录再直写文件。
        final dir = await FilePicker.platform.getDirectoryPath(
          dialogTitle: '选择备份保存位置',
        );
        if (dir == null) return;
        final out = p.join(dir, 'mindspace_backup_$stamp.zip');
        await File(out).writeAsBytes(bytes, flush: true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已导出备份：$out（${size ~/ 1024} KB）')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('导出失败：$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    setState(() => _busy = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
      final path = result?.files.single.path;
      if (path == null) return;
      await _service.importZip(path);
      if (mounted) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('恢复完成'),
            content: const Text('数据已恢复，重启应用后完全生效。'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('知道了')),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('恢复失败：$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('备份与恢复')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.file_upload_outlined),
                  title: const Text('导出备份'),
                  subtitle: const Text('将全部铭记、文件夹与字体打包为 zip'),
                  onTap: _export,
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.file_download_outlined),
                  title: const Text('恢复备份'),
                  subtitle: const Text('从 zip 恢复（会覆盖同名数据）'),
                  onTap: _import,
                ),
              ),
              const SizedBox(height: 12),
              Text('备份仅保存在你选择的位置，不会上传到网络。',
                  style: Theme.of(context).textTheme.bodySmall),
              Text('当前时间：${MsDateUtils.formatFull(DateTime.now().millisecondsSinceEpoch)}',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          if (_busy) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
