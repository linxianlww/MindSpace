import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          _section(context, '外观', [
            _tile(context, Icons.palette_outlined, '主题设置',
                '浅色 / 深色 / 跟随系统、动态取色', '/settings/theme'),
          ]),
          _section(context, '内容与存储', [
            _tile(context, Icons.font_download_outlined, '字体管理',
                '导入、删除、预览自定义字体', '/settings/font'),
            _tile(context, Icons.storage_outlined, '存储管理',
                '占用统计、清理缓存、回收站', '/settings/storage'),
            _tile(context, Icons.backup_outlined, '备份与恢复',
                '导出 / 导入 zip 备份', '/settings/backup'),
          ]),
          _section(context, '关于', [
            // 需求 7.2 指定入口。
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('关于与开发者'),
              subtitle: const Text('应用信息、作者与开源项目'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/developer'),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
          child: Text(title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary)),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title,
      String subtitle, String route) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push(route),
    );
  }
}
