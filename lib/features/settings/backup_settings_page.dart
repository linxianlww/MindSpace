import 'package:file_picker/file_picker.dart';
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
      final dir = await FilePicker.platform.getDirectoryPath(
        dialogTitle: '选择备份保存位置',
      );
      if (dir == null) return;
      final stamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final out = p.join(dir, 'mindspace_backup_$stamp.zip');
      final size = await _service.exportZip(out);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已导出备份：$out（${size ~/ 1024} KB）')),
        );
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
