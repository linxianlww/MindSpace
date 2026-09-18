import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../../core/theme/md3e_tokens.dart';
import '../../../data/models/folder.dart';
import '../../../data/models/memo.dart';
import 'folder_card.dart';
import 'memo_card.dart';

/// 自适应多列瀑布流：文件夹卡片在前，铭记卡片在后，共享同一网格。
/// 手机双列，宽屏三/四列；卡片高度自适应。
/// 文件夹优先排列（视觉上坐落于铭记之上）。
class MemoMasonry extends StatelessWidget {
  const MemoMasonry({
    super.key,
    required this.folders,
    required this.memos,
    required this.onOpenMemo,
    required this.onOpenFolder,
    required this.onLongPressMemo,
    required this.onLongPressFolder,
  });

  final List<Folder> folders;
  final List<Memo> memos;
  final void Function(Memo memo) onOpenMemo;
  final void Function(Folder folder) onOpenFolder;
  final void Function(Memo memo) onLongPressMemo;
  final void Function(Folder folder) onLongPressFolder;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = Md3eTokens.masonryColumns(width);
    final total = folders.length + memos.length;

    return MasonryGridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
      crossAxisCount: columns,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      itemCount: total,
      itemBuilder: (context, i) {
        // 文件夹条目排在最前，铭记紧跟其后。
        if (i < folders.length) {
          final f = folders[i];
          return FolderCard(
            folder: f,
            onTap: () => onOpenFolder(f),
            onLongPress: () => onLongPressFolder(f),
          );
        }
        final memo = memos[i - folders.length];
        return MemoCard(
          memo: memo,
          onTap: () => onOpenMemo(memo),
          onLongPress: () => onLongPressMemo(memo),
        );
      },
    );
  }
}
