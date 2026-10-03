import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindspace/ui/design_system/app_design_system.dart';

import '../../core/di/providers.dart';
import '../../core/storage/mindspace_storage.dart';
import '../../core/utils/file_utils.dart';
import '../home/home_provider.dart';
import '../memo_media/media_provider.dart';

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

  /// 缩略图缓存占总占用的比例（0..1），作为用量进度条的取值。
  double get _cacheShare {
    final total = _dataSize + _cacheSize;
    if (total <= 0) return 0.0;
    return _cacheSize / total;
  }

  Future<void> _clearCache() async {
    final dir = MindspaceStorage.instance.cacheThumbDir;
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
      dir.createSync(recursive: true);
    }
    // 清理 Flutter 图片内存缓存
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    // 自愈：重新生成缺失的缩略图
    await ref.read(mediaControllerProvider).repairThumbnails();
    _refresh();
  }

  Future<void> _confirmClearCache(BuildContext context) async {
    final ok = await AppDialog.show<bool>(
      context: context,
      title: '清理缓存？',
      message: '将删除全部缩略图缓存，浏览铭记时会自动重建。',
      actions: [
        MiuixTextButton(
          '取消',
          onPressed: () => AppDialog.close<bool>(context, false),
        ),
        MiuixButton(
          onPressed: () => AppDialog.close<bool>(context, true),
          child: const MiuixText('清理'),
        ),
      ],
    );
    if (ok == true) await _clearCache();
  }

  Future<void> _confirmEmptyTrash(BuildContext context) async {
    final ok = await AppDialog.show<bool>(
      context: context,
      title: '清空回收站？',
      message: '回收站中的全部铭记与文件夹将被彻底删除，无法恢复。',
      actions: [
        MiuixTextButton(
          '取消',
          onPressed: () => AppDialog.close<bool>(context, false),
        ),
        // 破坏性操作：主题错误色文字按钮（禁止硬编码 Colors.red）
        AppButton(
          variant: AppButtonStyle.text,
          onPressed: () => AppDialog.close<bool>(context, true),
          child: MiuixText('清空',
              style: TextStyle(color: MiuixTheme.of(context).colors.error)),
        ),
      ],
    );
    if (ok == true) {
      await ref.read(memoRepositoryProvider).emptyMemoTrash();
      await ref.read(folderRepositoryProvider).emptyFolderTrash();
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final trash = ref.watch(trashListProvider);
    final miuixTheme = MiuixTheme.of(context);

    Widget sizeLabel(String text) => MiuixText(
          text,
          style: miuixTheme.textStyles.body2,
          color: miuixTheme.colors.onSurfaceVariantActions,
        );

    return AppScaffold(
      topBar: AppHeader(title: '存储管理'),
      content: (context, padding) => ListView(
        padding: padding,
        children: [
          MiuixSmallTitle('存储占用'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: MiuixSurface(
              cornerRadius: AppTokens.radiusMedium,
              color: miuixTheme.colors.surfaceContainer,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MiuixBasicComponent(
                    startAction: HiuiIcon(HiuiIcons.folder),
                    title: '铭记数据占用',
                    endActions: [sizeLabel(FileUtils.humanSize(_dataSize))],
                  ),
                  MiuixBasicComponent(
                    startAction: HiuiIcon(HiuiIcons.image),
                    title: '缩略图缓存',
                    endActions: [sizeLabel(FileUtils.humanSize(_cacheSize))],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MiuixText(
                          '缩略图缓存占比 ${(_cacheShare * 100).toStringAsFixed(1)}%',
                          style: miuixTheme.textStyles.footnote1,
                          color: miuixTheme.colors.onSurfaceVariantSummary,
                        ),
                        const SizedBox(height: 8),
                        MiuixLinearProgressIndicator(
                          progress: _cacheShare,
                        ),
                      ],
                    ),
                  ),
                  MiuixBasicComponent(
                    title: '清理缓存',
                    summary: '删除缩略图缓存，浏览时自动重建',
                    startAction: HiuiIcon(HiuiIcons.clear),
                    onClick: () => _confirmClearCache(context),
                  ),
                ],
              ),
            ),
          ),
          MiuixSmallTitle('回收站'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: MiuixSurface(
              cornerRadius: AppTokens.radiusMedium,
              color: miuixTheme.colors.surfaceContainer,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 不可逆破坏性操作：图标与标题用主题错误色，不用箭头（非跳转）
                  MiuixBasicComponent(
                    title: '清空回收站',
                    titleColor: MiuixBasicComponentColors(
                      color: miuixTheme.colors.error,
                      disabledColor: miuixTheme.colors.disabledPrimary,
                    ),
                    summary: '彻底删除回收站中的全部铭记与文件夹',
                    startAction: HiuiIcon(HiuiIcons.trash,
                        color: miuixTheme.colors.error),
                    onClick: () => _confirmEmptyTrash(context),
                  ),
                  trash.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: AppCircleProgress()),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: MiuixText('$e'),
                    ),
                    data: (list) {
                      if (list.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: MiuixText('回收站为空')),
                        );
                      }
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final item in list)
                            AppListRow(
                              title: MiuixText(item.title),
                              subtitle: MiuixText(
                                  '删除于 ${DateTime.fromMillisecondsSinceEpoch(item.deletedAt ?? item.updatedAt)}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AppTapIcon(
                                    tooltip: '恢复',
                                    icon: HiuiIcon(HiuiIcons.reset),
                                    onPressed: () async {
                                      await ref
                                          .read(memoRepositoryProvider)
                                          .restore(item.id);
                                      _refresh();
                                    },
                                  ),
                                  AppTapIcon(
                                    tooltip: '彻底删除',
                                    icon: HiuiIcon(HiuiIcons.trash),
                                    onPressed: () async {
                                      await ref
                                          .read(memoRepositoryProvider)
                                          .hardDelete(item.id);
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
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
