import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/memo.dart';
import '../../data/models/memo_type.dart';

/// 按铭记类型跳转到对应的查看/编辑路由。
void openMemo(BuildContext context, Memo memo) {
  final id = memo.id;
  switch (memo.type) {
    case MemoType.text:
      context.push('/memo/text/$id');
    case MemoType.media:
      // 媒体集先进入缩略图网格页，点开单张再进入全屏查看。
      context.push('/memo/media/$id/edit');
    case MemoType.audio:
      context.push('/memo/audio/$id');
    case MemoType.file:
      context.push('/memo/file/$id');
  }
}

/// 新建后直接进入对应编辑页。
void openNewMemo(BuildContext context, MemoType type, String id) {
  switch (type) {
    case MemoType.text:
      context.push('/memo/text/$id/edit');
    case MemoType.media:
      context.push('/memo/media/$id/edit');
    case MemoType.audio:
      context.push('/memo/audio/$id/record');
    case MemoType.file:
      context.push('/memo/file/$id');
  }
}
