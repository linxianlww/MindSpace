import 'package:go_router/go_router.dart';
import 'package:mindspace/ui/design_system/app_design_system.dart';

/// 设置 hub：常规 / 数据 / 安全 / 关于 分组入口。
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppHeader(title: '设置'),
      content: (context, padding) => ListView(
        padding: padding,
        children: [
          _group(context, '常规', [
            _tile(context, HiuiIcons.skin, '主题设置',
                '浅色 / 深色 / 跟随系统、动态取色', '/settings/theme'),
            _tile(context, HiuiIcons.document, '文本排版', '行距与段距',
                '/settings/text'),
            _tile(context, HiuiIcons.font, '字体管理',
                '导入、删除、预览自定义字体', '/settings/font'),
          ]),
          _group(context, '数据', [
            _tile(context, HiuiIcons.storage, '存储管理', '占用统计、清理缓存、回收站',
                '/settings/storage'),
            _tile(context, HiuiIcons.backup, '备份与恢复', '导出 / 导入 zip 备份',
                '/settings/backup'),
          ]),
          _group(context, '安全', [
            _tile(context, HiuiIcons.lock, '私密空间', 'PIN 码与生物识别解锁设置',
                '/settings/private_space'),
          ]),
          _group(context, '关于', [
            // 需求 7.2 指定入口。
            AppSettingsRow(
              title: '关于与开发者',
              summary: '应用信息、作者与开源项目',
              startAction: HiuiIcon(HiuiIcons.info),
              onClick: () => context.push('/settings/developer'),
            ),
          ]),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// 一组设置行：小节标题 + [MiuixSurface] 分组容器。
  Widget _group(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MiuixSmallTitle(title),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: MiuixSurface(
            cornerRadius: AppTokens.radiusMedium,
            color: MiuixTheme.of(context).colors.surfaceContainer,
            child: Column(mainAxisSize: MainAxisSize.min, children: children),
          ),
        ),
      ],
    );
  }

  Widget _tile(BuildContext context, String icon, String title,
      String summary, String route) {
    return AppSettingsRow(
      title: title,
      summary: summary,
      startAction: HiuiIcon(icon),
      onClick: () => context.push(route),
    );
  }
}
