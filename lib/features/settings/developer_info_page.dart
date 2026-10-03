import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mindspace/ui/design_system/app_design_system.dart';

import '../../core/constants/app_constants.dart';

/// 设置 → 关于与开发者。
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
    final info = _packageInfo;
    final miuixTheme = MiuixTheme.of(context);
    final groupColor = miuixTheme.colors.surfaceContainer;

    return AppScaffold(
      topBar: AppHeader(title: '关于与开发者'),
      content: (context, padding) => ListView(
        padding: padding.add(
          const EdgeInsets.fromLTRB(12, 8, 12, 24),
        ),
        children: [
          // 应用信息卡
          MiuixCard(
            cornerRadius: AppTokens.radiusCard,
            insideMargin: const EdgeInsets.all(20),
            child: Column(
              children: [
                HiuiIcon(HiuiIcons.ai,
                    size: 64, color: miuixTheme.colors.primary),
                const SizedBox(height: 12),
                MiuixText(info?.appName ?? 'NekoBox',
                    style: miuixTheme.textStyles.title3),
                const SizedBox(height: 4),
                MiuixText(
                  '版本 ${info?.version ?? '--'} (${info?.buildNumber ?? '--'})',
                  style: miuixTheme.textStyles.body1,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          MiuixSurface(
            cornerRadius: AppTokens.radiusMedium,
            color: groupColor,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MiuixBasicComponent(
                  startAction: HiuiIcon(HiuiIcons.user),
                  title: '作者',
                  summary: AppConstants.authorName,
                ),
                MiuixBasicComponent(
                  startAction: HiuiIcon(HiuiIcons.link),
                  title: '个人主页',
                  summary: AppConstants.authorHomepage,
                  endActions: [
                    HiuiIcon(HiuiIcons.openInNew,
                        size: 18,
                        color: miuixTheme.colors.onSurfaceVariantActions),
                  ],
                  onClick: () => _openUrl(AppConstants.authorHomepage),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          MiuixSmallTitle('开源项目'),
          MiuixSurface(
            cornerRadius: AppTokens.radiusMedium,
            color: groupColor,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final p in OpenSourceProjects.all)
                  MiuixBasicComponent(
                    title: p.name,
                    summary: p.description,
                    endActions: [
                      HiuiIcon(HiuiIcons.openInNew,
                          size: 18,
                          color: miuixTheme.colors.onSurfaceVariantActions),
                    ],
                    onClick: () => _openUrl(p.url),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: MiuixText('感谢所有开源项目的贡献者',
                style: miuixTheme.textStyles.footnote1),
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
    OpenSourceProject(
        'Flutter', '跨平台 UI 框架', 'https://github.com/flutter/flutter'),
    OpenSourceProject('Dart', '编程语言', 'https://github.com/dart-lang/sdk'),
    // 状态管理与路由
    OpenSourceProject(
        'flutter_riverpod', '状态管理', 'https://github.com/rrousselGit/riverpod'),
    OpenSourceProject('go_router', '路由管理',
        'https://github.com/flutter/packages/tree/main/packages/go_router'),
    // 数据与存储
    OpenSourceProject(
        'freezed', '数据模型生成', 'https://github.com/rrousselGit/freezed'),
    OpenSourceProject('json_serializable', 'JSON 序列化',
        'https://github.com/google/json_serializable.dart'),
    OpenSourceProject('drift', '本地数据库', 'https://github.com/simolus3/drift'),
    OpenSourceProject(
        'sqflite', 'SQLite 插件', 'https://github.com/tekartik/sqflite'),
    OpenSourceProject('path_provider', '路径获取',
        'https://github.com/flutter/packages/tree/main/packages/path_provider'),
    OpenSourceProject('shared_preferences', '轻量设置存储',
        'https://github.com/flutter/packages/tree/main/packages/shared_preferences'),
    OpenSourceProject(
        'uuid', 'UUID 生成', 'https://github.com/Daegalus/dart-uuid'),
    // UI 与媒体
    OpenSourceProject('flutter_staggered_grid_view', '瀑布流布局',
        'https://github.com/letsar/flutter_staggered_grid_view'),
    OpenSourceProject('flutter_quill', '富文本编辑器',
        'https://github.com/singerdmx/flutter-quill'),
    OpenSourceProject(
        'photo_view', '图片查看器', 'https://github.com/bluefireteam/photo_view'),
    OpenSourceProject(
        'image', '图片处理', 'https://github.com/brendan-duncan/image'),
    OpenSourceProject('image_cropper', '图片裁剪',
        'https://github.com/hnvn/flutter_image_cropper'),
    OpenSourceProject('video_player', '视频播放',
        'https://github.com/flutter/packages/tree/main/packages/video_player'),
    OpenSourceProject(
        'chewie', '视频播放 UI', 'https://github.com/fluttercommunity/chewie'),
    // 音频
    OpenSourceProject('record', '录音', 'https://github.com/llfbandit/record'),
    OpenSourceProject(
        'just_audio', '音频播放', 'https://github.com/ryanheise/just_audio'),
    OpenSourceProject('audio_waveforms', '音频波形',
        'https://github.com/SimformSolutionsPvtLtd/audio_waveforms'),
    // 文件与文档
    OpenSourceProject('file_picker', '文件选择',
        'https://github.com/miguelpruivo/flutter_file_picker'),
    OpenSourceProject(
        'share_plus', '分享', 'https://github.com/fluttercommunity/plus_plugins'),
    OpenSourceProject(
        'screenshot', '截图分享', 'https://github.com/FlutterStudio/screenshot'),
    OpenSourceProject(
        'open_filex', '外部打开文件', 'https://github.com/crazecoder/open_file'),
    OpenSourceProject(
        'pdfrx', 'PDF 阅读', 'https://github.com/espresso3389/pdfrx'),
    OpenSourceProject('excel', 'XLSX 解析', 'https://github.com/justkawal/excel'),
    OpenSourceProject(
        'archive', '压缩归档', 'https://github.com/brendan-duncan/archive'),
    OpenSourceProject('xml', 'XML 解析', 'https://github.com/renggli/dart-xml'),
    // 工具与权限
    OpenSourceProject('permission_handler', '权限管理',
        'https://github.com/Baseflow/flutter-permission_handler'),
    OpenSourceProject('logger', '日志', 'https://github.com/Solido/logger'),
    OpenSourceProject('package_info_plus', '应用信息',
        'https://github.com/fluttercommunity/plus_plugins'),
    OpenSourceProject('url_launcher', '打开链接',
        'https://github.com/flutter/packages/tree/main/packages/url_launcher'),
    // UI 组件
    OpenSourceProject('flutter_miuix', 'MIUIX 风格组件库',
        'https://github.com/ChuxinNeko/flutter_miuix'),
  ];
}
