import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';

/// 设置 → 关于与开发者。
///
/// 展示应用信息（版本号来自 package_info_plus）、作者与主页、开源项目清单。
class DeveloperInfoPage extends StatefulWidget {
  const DeveloperInfoPage({super.key});

  @override
  State<DeveloperInfoPage> createState() => _DeveloperInfoPageState();
}

class _DeveloperInfoPageState extends State<DeveloperInfoPage> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _packageInfo = info);
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final info = _packageInfo;

    return Scaffold(
      appBar: AppBar(title: const Text('关于与开发者')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.psychology_alt,
                      size: 64, color: theme.colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(info?.appName ?? 'NekoBox',
                      style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(
                    '版本 ${info?.version ?? '--'} (${info?.buildNumber ?? '--'})',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.person_outline),
                  title: Text('作者'),
                  subtitle: Text(AppConstants.authorName),
                ),
                ListTile(
                  leading: const Icon(Icons.link),
                  title: const Text('个人主页'),
                  subtitle: const Text(AppConstants.authorHomepage),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _openUrl(AppConstants.authorHomepage),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('开源项目', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final p in OpenSourceProjects.all)
            Card(
              child: ListTile(
                title: Text(p.name),
                subtitle: Text(p.description),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => _openUrl(p.url),
              ),
            ),
          const SizedBox(height: 24),
          Center(
            child: Text('感谢所有开源项目的贡献者',
                style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class OpenSourceProject {
  const OpenSourceProject(this.name, this.description, this.url);
  final String name;
  final String description;
  final String url;
}

/// 开源项目清单（许可证以各仓库为准）。
class OpenSourceProjects {
  const OpenSourceProjects._();

  static const all = <OpenSourceProject>[
    // 核心框架
    OpenSourceProject('Flutter', '跨平台 UI 框架',
        'https://github.com/flutter/flutter'),
    OpenSourceProject('Dart', '编程语言', 'https://github.com/dart-lang/sdk'),
    // 状态管理与路由
    OpenSourceProject('flutter_riverpod', '状态管理',
        'https://github.com/rrousselGit/riverpod'),
    OpenSourceProject('go_router', '路由管理',
        'https://github.com/flutter/packages/tree/main/packages/go_router'),
    // 数据与存储
    OpenSourceProject('freezed', '数据模型生成',
        'https://github.com/rrousselGit/freezed'),
    OpenSourceProject('json_serializable', 'JSON 序列化',
        'https://github.com/google/json_serializable.dart'),
    OpenSourceProject('drift', '本地数据库',
        'https://github.com/simolus3/drift'),
    OpenSourceProject('sqflite', 'SQLite 插件',
        'https://github.com/tekartik/sqflite'),
    OpenSourceProject(
        'path_provider',
        '路径获取',
        'https://github.com/flutter/packages/tree/main/packages/path_provider'),
    OpenSourceProject(
        'shared_preferences',
        '轻量设置存储',
        'https://github.com/flutter/packages/tree/main/packages/shared_preferences'),
    OpenSourceProject('uuid', 'UUID 生成',
        'https://github.com/Daegalus/dart-uuid'),
    // UI 与媒体
    OpenSourceProject('flutter_staggered_grid_view', '瀑布流布局',
        'https://github.com/letsar/flutter_staggered_grid_view'),
    OpenSourceProject('flutter_quill', '富文本编辑器',
        'https://github.com/singerdmx/flutter-quill'),
    OpenSourceProject('photo_view', '图片查看器',
        'https://github.com/bluefireteam/photo_view'),
    OpenSourceProject('image', '图片处理',
        'https://github.com/brendan-duncan/image'),
    OpenSourceProject('image_cropper', '图片裁剪',
        'https://github.com/hnvn/flutter_image_cropper'),
    OpenSourceProject(
        'video_player',
        '视频播放',
        'https://github.com/flutter/packages/tree/main/packages/video_player'),
    OpenSourceProject('chewie', '视频播放 UI',
        'https://github.com/fluttercommunity/chewie'),
    // 音频
    OpenSourceProject('record', '录音',
        'https://github.com/llfbandit/record'),
    OpenSourceProject('just_audio', '音频播放',
        'https://github.com/ryanheise/just_audio'),
    OpenSourceProject('audio_waveforms', '音频波形',
        'https://github.com/SimformSolutionsPvtLtd/audio_waveforms'),
    // 文件与文档
    OpenSourceProject('file_picker', '文件选择',
        'https://github.com/miguelpruivo/flutter_file_picker'),
    OpenSourceProject('share_plus', '分享',
        'https://github.com/fluttercommunity/plus_plugins'),
    OpenSourceProject('screenshot', '截图分享',
        'https://github.com/FlutterStudio/screenshot'),
    OpenSourceProject('open_filex', '外部打开文件',
        'https://github.com/crazecoder/open_file'),
    OpenSourceProject('pdfrx', 'PDF 阅读',
        'https://github.com/espresso3389/pdfrx'),
    OpenSourceProject('excel', 'XLSX 解析',
        'https://github.com/justkawal/excel'),
    OpenSourceProject('archive', '压缩归档',
        'https://github.com/brendan-duncan/archive'),
    OpenSourceProject('xml', 'XML 解析',
        'https://github.com/renggli/dart-xml'),
    // 工具与权限
    OpenSourceProject('permission_handler', '权限管理',
        'https://github.com/Baseflow/flutter-permission-handler'),
    OpenSourceProject('logger', '日志', 'https://github.com/Solido/logger'),
    OpenSourceProject(
        'package_info_plus',
        '应用信息',
        'https://github.com/fluttercommunity/plus_plugins'),
    OpenSourceProject(
        'url_launcher',
        '打开链接',
        'https://github.com/flutter/packages/tree/main/packages/url_launcher'),
  ];
}
