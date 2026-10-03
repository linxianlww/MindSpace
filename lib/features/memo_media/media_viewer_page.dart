import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:mindspace/ui/design_system/app_design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';

import '../../../data/models/memo_type.dart';
import '../desktop_shortcut/add_to_desktop.dart';
import '../home/home_provider.dart';
import 'media_provider.dart';
import 'widgets/media_remark_dialog.dart';

/// 媒体集内置查看器：图片缩放/平移/双击缩放/旋转/裁剪；视频播放/暂停/全屏。
class MediaViewerPage extends ConsumerStatefulWidget {
  const MediaViewerPage(
      {super.key, required this.memoId, this.initialIndex = 0});

  final String memoId;
  final int initialIndex;

  @override
  ConsumerState<MediaViewerPage> createState() => _MediaViewerPageState();
}

class _MediaViewerPageState extends ConsumerState<MediaViewerPage> {
  late final PageController _page =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  /// AppScaffold 子树内的宿主 context（弹层 API 需要脚手架下方的 context）。
  BuildContext? _hostCtx;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(mediaItemsProvider(widget.memoId));
    final memoAsync = ref.watch(memoDetailProvider(widget.memoId));
    return async.when(
      loading: () =>
          const AppScaffold(containerColor: Colors.black, body: SizedBox.shrink()),
      error: (e, _) => AppScaffold(
        containerColor: Colors.black,
        body: Center(
            child: MiuixText('$e', style: const TextStyle(color: Colors.white))),
      ),
      data: (items) {
        if (items.isEmpty) {
          return AppScaffold(containerColor: Colors.black);
        }
        final item = items[_index.clamp(0, items.length - 1)];
        return AppScaffold(
          containerColor: Colors.black,
          // 沉浸式顶栏：AppHeader 不支持自定义配色，直接构造
          // MiuixSmallTopAppBar（黑底白字 + 白色图标）。
          topBar: MiuixSmallTopAppBar(
            title: '${_index + 1}/${items.length}',
            color: Colors.black54,
            titleColor: Colors.white,
            navigationIcon: MiuixIconButton(
              // go_router 返回：查看器仅由编辑页 push 进入，pop 安全
              onPressed: () => context.pop(),
              child: const HiuiIcon(HiuiIcons.arrowBack, color: Colors.white),
            ),
            actions: [
              if (item.kind == MediaKind.image) ...[
                AppTapIcon(
                  icon: const HiuiIcon(HiuiIcons.rotateRight, color: Colors.white),
                  onPressed: () async {
                    await ref
                        .read(mediaControllerProvider)
                        .rotateRight(item);
                    if (mounted) setState(() {});
                  },
                ),
                AppTapIcon(
                  icon: const HiuiIcon(HiuiIcons.crop, color: Colors.white),
                  onPressed: () =>
                      ref.read(mediaControllerProvider).crop(item),
                ),
              ],
              AppTapIcon(
                icon: const HiuiIcon(HiuiIcons.tag, color: Colors.white),
                onPressed: () async {
                  final hostCtx = _hostCtx;
                  if (hostCtx == null || !hostCtx.mounted) return;
                  final r = await MediaRemarkDialog.show(hostCtx,
                      initial: item.remark);
                  if (r != null) {
                    await ref
                        .read(mediaControllerProvider)
                        .setRemark(item, r.isEmpty ? null : r);
                  }
                },
              ),
              AppTapIcon(
                icon: const HiuiIcon(HiuiIcons.export, color: Colors.white),
                tooltip: '添加到桌面',
                onPressed: () {
                  final memo = memoAsync.value;
                  final hostCtx = _hostCtx;
                  if (memo != null && hostCtx != null && hostCtx.mounted) {
                    addMemoToDesktop(hostCtx, ref, memo);
                  }
                },
              ),
            ],
          ),
          // 沉浸式内容：不消化顶栏 padding，图片/视频铺满全屏并延伸到
          // 半透明顶栏之下；备注条自行处理底部安全区。
          content: (context, padding) => Builder(builder: (hostCtx) {
            _hostCtx = hostCtx;
            return Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _page,
                    itemCount: items.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (_, i) {
                      final it = items[i];
                      return it.kind == MediaKind.image
                          ? PhotoView(
                              // 裁剪/旋转会原路径覆盖图片内容（路径不变），
                              // thumbPath 每次重新生成必然变化；用它作 key
                              // 强制重建 PhotoView，配合 MediaController 对
                              // 旧路径的缓存逐出，确保立即显示新图。
                              key: ValueKey('photo-${it.id}-${it.thumbPath}'),
                              imageProvider: FileImage(File(it.path)),
                              minScale: PhotoViewComputedScale.contained,
                              maxScale: PhotoViewComputedScale.covered * 4,
                              backgroundDecoration:
                                  const BoxDecoration(color: Colors.black),
                            )
                          : _VideoPlayer(path: it.path);
                    },
                  ),
                ),
                // 备注标签展示在图片查看页下方。
                if ((item.remark ?? '').isNotEmpty)
                  Container(
                    width: double.infinity,
                    color: Colors.black54,
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 10,
                      bottom: 10 + MediaQuery.paddingOf(context).bottom,
                    ),
                    child: MiuixText(
                      item.remark!,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
              ],
            );
          }),
        );
      },
    );
  }
}

/// 视频播放：video_player + chewie，支持播放/暂停/进度/全屏。
class _VideoPlayer extends StatefulWidget {
  const _VideoPlayer({required this.path});
  final String path;

  @override
  State<_VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<_VideoPlayer> {
  ChewieController? _chewie;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final vp = VideoPlayerController.file(File(widget.path));
    await vp.initialize();
    if (!mounted) {
      await vp.dispose();
      return;
    }
    setState(() {
      _chewie = ChewieController(
        videoPlayerController: vp,
        autoPlay: true,
        looping: false,
        aspectRatio: vp.value.aspectRatio,
        materialProgressColors: ChewieProgressColors(
          playedColor: MiuixTheme.of(context).colors.primary,
        ),
      );
    });
  }

  @override
  void dispose() {
    // ChewieController.dispose() 会连带释放其持有的 VideoPlayerController，
    // 因此不能再对 _vp 调用 dispose()，否则部分平台（尤其 iOS）会 double-free
    // 触发 native crash 或 StateError 断言。
    _chewie?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chewie = _chewie;
    if (chewie == null) {
      return const Center(
          child: MiuixInfiniteProgressIndicator(color: Colors.white));
    }
    return Center(child: Chewie(controller: chewie));
  }
}
