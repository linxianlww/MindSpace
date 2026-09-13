import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/storage/mindspace_storage.dart';
import '../../core/utils/file_utils.dart';
import '../home/home_provider.dart';

/// 存储管理：占用统计、清理缩略图缓存、回收站管理。
class StorageSettingsPage extends ConsumerStatefulWidget {
  const StorageSettingsPage({super.key});

  @override
  ConsumerState<StorageSettingsPage> createState() =>
      _StorageSettingsPageState();
}

class _StorageSettingsPageState extends ConsumerState<StorageSettingsPage> {
  int _dataSize = 0;
  int _cacheSize = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    final s = MindspaceStorage.instance;
    setState(() {
      _dataSize = FileUtils.dirSize(s.baseDir.path);
      _cacheSize = FileUtils.dirSize(s.cacheThumbDir.path);
    });
  }

  Future<void> _clearCache() async {
    final dir = MindspaceStorage.instance.cacheThumbDir;
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
      dir.createSync(recursive: true);
    }
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final trash = ref.watch(trashListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('存储管理')),
      body: ListView(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.folder_outlined),
                  title: const Text('铭记数据占用'),
                  trailing: Text(FileUtils.humanSize(_dataSize)),
                ),
                ListTile(
                  leading: const Icon(Icons.burst_mode_outlined),
                  title: const Text('缩略图缓存'),
                  trailing: Text(FileUtils.humanSize(_cacheSize)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: OutlinedButton.icon(
                    onPressed: _clearCache,
                    icon: const Icon(Icons.cleaning_services_outlined),
                    label: const Text('清理缓存'),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                    child: Text('回收站',
                        style: Theme.of(context).textTheme.titleMedium)),
                TextButton(
                  onPressed: () async {
                    await ref.read(memoRepositoryProvider).emptyMemoTrash();
                    await ref.read(folderRepositoryProvider).emptyFolderTrash();
                    _refresh();
                  },
                  child: const Text('清空回收站'),
                ),
              ],
            ),
          ),
          trash.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('$e'),
            ),
            data: (list) {
              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('回收站为空')),
                );
              }
              return Column(
                children: [
                  for (final m in list)
                    ListTile(
                      title: Text(m.title),
                      subtitle: Text('删除于 ${DateTime.fromMillisecondsSinceEpoch(m.deletedAt ?? m.updatedAt)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: '恢复',
                            icon: const Icon(Icons.restore_from_trash_outlined),
                            onPressed: () async {
                              await ref
                                  .read(memoRepositoryProvider)
                                  .restore(m.id);
                              _refresh();
                            },
                          ),
                          IconButton(
                            tooltip: '彻底删除',
                            icon: const Icon(Icons.delete_forever_outlined),
                            onPressed: () async {
                              await ref
                                  .read(memoRepositoryProvider)
                                  .hardDelete(m.id);
                              _refresh();
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
