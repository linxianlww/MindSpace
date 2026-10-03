import 'package:file_picker/file_picker.dart';
import 'package:mindspace/ui/design_system/app_design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/file_types.dart';
import '../../../core/di/providers.dart';
import '../desktop_shortcut/add_to_desktop.dart';
import '../../../core/utils/ms_date_utils.dart';
import '../../../core/utils/subtitle_parser.dart';
import '../../../core/utils/uuid_utils.dart';
import '../share/share_service.dart';
import '../home/home_provider.dart';
import 'audio_provider.dart';
import 'widgets/audio_trimmer.dart';
import 'widgets/subtitle_view.dart';
import 'widgets/waveform_view.dart';

/// 音频播放/详情页。
class AudioPlayerPage extends ConsumerWidget {
  const AudioPlayerPage({super.key, required this.memoId});
  final String memoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memoAsync = ref.watch(memoDetailProvider(memoId));
    return AppScaffold(
      topBar: AppHeader(
        title: memoAsync.maybeWhen(
          data: (m) => m?.title ?? '音频铭记',
          orElse: () => '音频铭记',
        ),
        alwaysSmall: true,
        actions: [
          AppTapIcon(
            icon: const HiuiIcon(HiuiIcons.share),
            onPressed: () {
              final m = memoAsync.value;
              final path = m?.metadata['originalPath'] as String?;
              if (path != null) {
                ref.read(shareServiceProvider).shareFile(path);
              }
            },
          ),
          AppTapIcon(
            icon: const HiuiIcon(HiuiIcons.export),
            tooltip: '添加到桌面',
            onPressed: () {
              final m = memoAsync.value;
              if (m != null) {
                addMemoToDesktop(context, ref, m);
              }
            },
          ),
        ],
      ),
      body: memoAsync.when(
        loading: () => const Center(child: AppCircleProgress()),
        error: (e, _) => Center(child: MiuixText('$e')),
        data: (memo) {
          if (memo == null) return const Center(child: MiuixText('铭记不存在'));
          final hasAudio = memo.metadata['originalPath'] != null;
          if (!hasAudio) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const MiuixText('还没有音频'),
                  const SizedBox(height: 16),
                  AppButton(
                    // 录音页已在路由表中注册（/memo/audio/:memoId/record），
                    // pushReplacement 走 go_router 以保持路由栈一致。
                    onPressed: () =>
                        context.pushReplacement('/memo/audio/$memoId/record'),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HiuiIcon(HiuiIcons.mic),
                        SizedBox(width: 8),
                        MiuixText('去录音'),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          return _PlayerBody(memoId: memoId);
        },
      ),
    );
  }
}

/// 播放区主体。
///
/// 只在这里 watch 低频字段（就绪态/错误/字幕/裁剪值）；高频变化的
/// positionMs 由 [_WavePanel] 通过 select 单独消费，避免播放时整页重建。
class _PlayerBody extends ConsumerStatefulWidget {
  const _PlayerBody({required this.memoId});
  final String memoId;

  @override
  ConsumerState<_PlayerBody> createState() => _PlayerBodyState();
}

class _PlayerBodyState extends ConsumerState<_PlayerBody> {
  int _tabIndex = 0;

  /// 上一次选中的页签，用于计算切换动画的滑入方向。
  int _lastTabIndex = 0;
  static const _tabs = ['字幕', '信息'];

  @override
  Widget build(BuildContext context) {
    final memoId = widget.memoId;
    final memo = ref.watch(memoDetailProvider(memoId)).value!;
    final subs = ref.watch(audioPlayerProvider(memoId).select((v) => v.subs));
    final activeIndex =
        ref.watch(audioPlayerProvider(memoId).select((v) => v.activeSubIndex));
    final ready = ref.watch(audioPlayerProvider(memoId).select((v) => v.ready));
    final error = ref.watch(audioPlayerProvider(memoId).select((v) => v.error));
    final notifier = ref.read(audioPlayerProvider(memoId).notifier);

    return Column(
      children: [
        // 面板区可收缩：横屏/小屏高度不足时内部滚动，防止 RenderFlex 溢出。
        Flexible(
          flex: 0,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Column(
                children: [
                  MiuixText(memo.title,
                      style: MiuixTheme.of(context).textStyles.title3),
                  const SizedBox(height: 16),
                  _StatusBanner(
                      error: error, ready: ready, onRetry: notifier.retry),
                  const SizedBox(height: 16),
                  // 独立消费者：positionMs 每 200ms 变化，仅波形/时间重建。
                  _WavePanel(memoId: memoId),
                  const SizedBox(height: 8),
                  _ControlsPanel(memoId: memoId),
                  _TrimButtons(
                    memoId: memoId,
                    fullDurationMs: ref.watch(audioPlayerProvider(memoId)
                        .select((v) => v.fullDurationMs)),
                    durationMs: ref.watch(audioPlayerProvider(memoId)
                        .select((v) => v.durationMs)),
                    trimStartMs: ref.watch(audioPlayerProvider(memoId)
                        .select((v) => v.trimStartMs)),
                    trimEndMs: ref.watch(
                        audioPlayerProvider(memoId).select((v) => v.trimEndMs)),
                    onApply: notifier.setTrimWindow,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // 与页面既有 20 水平边距取齐，不再占满全宽。
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AppTabStrip(
            tabs: _tabs,
            selectedIndex: _tabIndex,
            onTabSelected: (i) => setState(() {
              if (i == _tabIndex) return;
              _lastTabIndex = _tabIndex;
              _tabIndex = i;
            }),
          ),
        ),
        // 页签内容左右滑动切换：新页从旧页方向滑入，旧页向反向滑出
        // （播放状态在 provider 层，不受影响）。
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: AppTokens.curveStandard,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              final dir = (_tabIndex - _lastTabIndex).sign;
              final isNew = child.key == ValueKey(_tabIndex);
              final begin =
                  isNew ? Offset(dir * 0.06, 0) : Offset(-dir * 0.06, 0);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(begin: begin, end: Offset.zero)
                      .animate(animation),
                  child: child,
                ),
              );
            },
            child: KeyedSubtree(
              key: ValueKey(_tabIndex),
              child: _tabIndex == 0
                  ? SubtitleView(
                      subs: subs,
                      activeIndex: activeIndex,
                      onTap: notifier.jumpToSubtitle,
                    )
                  : _InfoTab(
                      memoId: memoId,
                      durationMs: ready
                          ? ref.watch(audioPlayerProvider(memoId)
                              .select((v) => v.durationMs))
                          : null,
                      trimStartMs: ref.watch(audioPlayerProvider(memoId)
                          .select((v) => v.trimStartMs)),
                      trimEndMs: ref.watch(audioPlayerProvider(memoId)
                          .select((v) => v.trimEndMs)),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 加载中 / 初始化失败状态（低频）。
class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.error,
    required this.ready,
    required this.onRetry,
  });
  final String? error;
  final bool ready;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = MiuixTheme.of(context).colors;
    if (error != null) {
      return MiuixSurface(
        cornerRadius: AppTokens.radiusMedium,
        color: scheme.errorContainer.withValues(alpha: 0.6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              HiuiIcon(HiuiIcons.error, color: scheme.onErrorContainer),
              const SizedBox(width: 12),
              Expanded(
                child: MiuixText(error!,
                    style: MiuixTheme.of(context)
                        .textStyles
                        .body1
                        .copyWith(color: scheme.onErrorContainer)),
              ),
              AppButton(
                variant: AppButtonStyle.text,
                onPressed: onRetry,
                child: const MiuixText('重试'),
              ),
            ],
          ),
        ),
      );
    }
    if (!ready) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: AppCircleProgress(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          MiuixText('正在加载音频…', style: MiuixTheme.of(context).textStyles.body1),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}

/// 波形 + 时间标签：只消费高频的 positionMs/durationMs/wave/trimStartMs。
class _WavePanel extends ConsumerWidget {
  const _WavePanel({required this.memoId});
  final String memoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pos =
        ref.watch(audioPlayerProvider(memoId).select((v) => v.positionMs));
    final dur =
        ref.watch(audioPlayerProvider(memoId).select((v) => v.durationMs));
    final wave = ref.watch(audioPlayerProvider(memoId).select((v) => v.wave));
    final trimStart =
        ref.watch(audioPlayerProvider(memoId).select((v) => v.trimStartMs));
    final notifier = ref.read(audioPlayerProvider(memoId).notifier);

    return Column(
      children: [
        PlaybackWaveform(
          wave: wave,
          positionMs: pos,
          // 波形进度条按裁剪后有效时长绘制。
          durationMs: dur,
          // seek 回调统一绝对时间轴坐标（未裁剪时 trimStart 为 0）。
          onSeek: (ms) => notifier.seekTo(ms + (trimStart ?? 0)),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            MiuixText(MsDateUtils.formatDuration(pos)),
            MiuixText(MsDateUtils.formatDuration(dur)),
          ],
        ),
      ],
    );
  }
}

/// 播放控制按钮：只消费低频 playing/looping/speed。
class _ControlsPanel extends ConsumerWidget {
  const _ControlsPanel({required this.memoId});
  final String memoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playing =
        ref.watch(audioPlayerProvider(memoId).select((v) => v.playing));
    final looping =
        ref.watch(audioPlayerProvider(memoId).select((v) => v.looping));
    final speed = ref.watch(audioPlayerProvider(memoId).select((v) => v.speed));
    final notifier = ref.read(audioPlayerProvider(memoId).notifier);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppTapIcon(
          size: 30,
          icon: const HiuiIcon(HiuiIcons.repeat, size: 30),
          color: looping ? MiuixTheme.of(context).colors.primary : null,
          onPressed: notifier.toggleLoop,
        ),
        const SizedBox(width: 8),
        MiuixFloatingActionButton(
          onPressed: notifier.toggle,
          child: HiuiIcon(playing ? HiuiIcons.pause : HiuiIcons.play,
              color: MiuixTheme.of(context).colors.onPrimary),
        ),
        const SizedBox(width: 8),
        _SpeedMenu(speed: speed, onSelected: notifier.setSpeed),
      ],
    );
  }
}

class _SpeedMenu extends StatelessWidget {
  const _SpeedMenu({required this.speed, required this.onSelected});
  final double speed;
  final ValueChanged<double> onSelected;

  static const _speeds = [0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  Widget build(BuildContext context) {
    // 锚定下拉菜单替代底部抽屉：触发器保持原有速度文字外观
    // （MiuixIconButton 默认透明背景，无背景圆角）。
    return MiuixOverlayIconDropdownMenu(
      entry: MiuixDropdownEntry(items: [
        for (final s in _speeds)
          MiuixDropdownItem(
            text: '${s}x',
            selected: s == speed,
            onClick: () => onSelected(s),
          ),
      ]),
      child: MiuixText('${speed}x',
          style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

/// 裁剪 / 导入字幕按钮（低频）。
class _TrimButtons extends ConsumerWidget {
  const _TrimButtons({
    required this.memoId,
    required this.fullDurationMs,
    required this.durationMs,
    required this.trimStartMs,
    required this.trimEndMs,
    required this.onApply,
  });

  final String memoId;
  final int fullDurationMs;
  final int durationMs;
  final int? trimStartMs;
  final int? trimEndMs;
  final Future<void> Function(int? startMs, int? endMs) onApply;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = MiuixTheme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppButton(
          variant: AppButtonStyle.text,
          onPressed: () => AppSheet.show<void>(
            context: context,
            builder: (_) => SingleChildScrollView(
              child: AudioTrimmer(
                memoId: memoId,
                // 滑块坐标始终基于文件原始全长。
                durationMs: fullDurationMs > 0 ? fullDurationMs : durationMs,
                initialStart: trimStartMs,
                initialEnd: trimEndMs,
                onApply: onApply,
              ),
            ),
          ),
          // 操作行统一规格：primary 色 18 图标 + body2/onSurface 文字。
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HiuiIcon(HiuiIcons.cut, size: 18, color: theme.colors.primary),
              const SizedBox(width: 6),
              MiuixText('裁剪',
                  style: theme.textStyles.body2, color: theme.colors.onSurface),
            ],
          ),
        ),
        AppButton(
          variant: AppButtonStyle.text,
          onPressed: () => _importSubtitle(context, ref),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HiuiIcon(HiuiIcons.subtitles,
                  size: 18, color: theme.colors.primary),
              const SizedBox(width: 6),
              MiuixText('导入字幕',
                  style: theme.textStyles.body2, color: theme.colors.onSurface),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _importSubtitle(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['lrc', 'srt', 'txt'],
    );
    final path = result?.files.single.path;
    if (path == null) return;
    final raw = await ref.read(fileSystemDatasourceProvider).readString(path);
    final ext = FileTypes.extensionOf(path);
    final parsed = SubtitleParser.parse(memoId, raw, ext);
    // 为缺少 id 的条目兜底（解析器已生成，这里确保非空）。
    final items = parsed
        .map((s) => s.id.isEmpty ? s.copyWith(id: UuidUtils.newId()) : s)
        .toList();
    await ref.read(memoRepositoryProvider).replaceSubtitles(items);
    ref.invalidate(memoDetailProvider(memoId));
    // 播放器以 memoId 为 key 且不随 memo 变化重建，必须显式刷新字幕列表，
    // 否则"提示成功但字幕区仍空白"。
    await ref.read(audioPlayerProvider(memoId).notifier).reloadSubtitles();
    if (context.mounted) {
      AppSnackbar.show(context, message: '已导入 ${items.length} 条字幕');
    }
  }
}

class _InfoTab extends ConsumerWidget {
  const _InfoTab({
    required this.memoId,
    this.durationMs,
    this.trimStartMs,
    this.trimEndMs,
  });
  final String memoId;
  final int? durationMs;
  final int? trimStartMs;
  final int? trimEndMs;

  static String _fileNameOf(String? path) {
    if (path == null || path.isEmpty) return '-';
    final idx = path.lastIndexOf('/');
    return idx >= 0 && idx < path.length - 1 ? path.substring(idx + 1) : path;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memo = ref.watch(memoDetailProvider(memoId)).value;
    if (memo == null) return const SizedBox.shrink();
    final meta = memo.metadata;
    final dur = durationMs ?? (meta['durationMs'] as int?) ?? 0;
    final tStart = trimStartMs ?? meta['trimStartMs'] as int?;
    final tEnd = trimEndMs ?? meta['trimEndMs'] as int?;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        AppListRow(
          leading: const HiuiIcon(HiuiIcons.heading),
          title: const MiuixText('标题'),
          subtitle: MiuixText(memo.title),
        ),
        AppListRow(
          leading: const HiuiIcon(HiuiIcons.time),
          title: const MiuixText('时长'),
          subtitle: MiuixText(MsDateUtils.formatDuration(dur)),
        ),
        AppListRow(
          leading: const HiuiIcon(HiuiIcons.audio),
          title: const MiuixText('原始文件'),
          // 隐私考虑：只展示文件名，不展示应用内部完整路径。
          subtitle: MiuixText(meta['originalName'] as String? ??
              _fileNameOf(meta['originalPath'] as String?)),
        ),
        if (tStart != null || tEnd != null)
          AppListRow(
            leading: const HiuiIcon(HiuiIcons.cut),
            title: const MiuixText('裁剪区间'),
            subtitle: MiuixText(
                '${MsDateUtils.formatDuration(tStart ?? 0)} ~ ${MsDateUtils.formatDuration(tEnd ?? dur)}'),
          ),
        AppListRow(
          leading: const HiuiIcon(HiuiIcons.time),
          title: const MiuixText('创建时间'),
          subtitle: MiuixText(MsDateUtils.formatFull(memo.createdAt)),
        ),
      ],
    );
  }
}
