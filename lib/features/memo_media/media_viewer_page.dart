import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';

import '../../../data/models/memo_type.dart';
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

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(mediaItemsProvider(widget.memoId));
    return async.when(
      loading: () =>
          const Scaffold(backgroundColor: Colors.black, body: SizedBox.shrink()),
      error: (e, _) => Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text('$e', style: const TextStyle(color: Colors.white))),
      ),
      data: (items) {
        if (items.isEmpty) return const Scaffold(backgroundColor: Colors.black);
        final item = items[_index.clamp(0, items.length - 1)];
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black54,
            foregroundColor: Colors.white,
            title: Text('${_index + 1}/${items.length}',
                style: const TextStyle(color: Colors.white)),
            actions: [
              if (item.kind == MediaKind.image) ...[
                IconButton(
                  icon: const Icon(Icons.rotate_right),
                  onPressed: () async {
                    await ref
                        .read(mediaControllerProvider)
                        .rotateRight(item);
                    if (mounted) setState(() {});
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.crop),
                  onPressed: () =>
                      ref.read(mediaControllerProvider).crop(item),
                ),
              ],
              IconButton(
                icon: const Icon(Icons.label_outline),
                onPressed: () async {
                  final r = await MediaRemarkDialog.show(context,
                      initial: item.remark);
                  if (r != null) {
                    await ref
                        .read(mediaControllerProvider)
                        .setRemark(item, r.isEmpty ? null : r);
                  }
                },
              ),
            ],
          ),
          body: Column(
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
                  child: Text(
                    item.remark!,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
            ],
          ),
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
  VideoPlayerController? _vp;
  ChewieController? _chewie;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final vp = VideoPlayerController.file(File(widget.path));
    _vp = vp;
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
          playedColor: Theme.of(context).colorScheme.primary,
        ),
      );
    });
  }

  @override
  void dispose() {
    _chewie?.dispose();
    _vp?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chewie = _chewie;
    if (chewie == null) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }
    return Center(child: Chewie(controller: chewie));
  }
}
