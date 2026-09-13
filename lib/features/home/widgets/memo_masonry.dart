import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../../core/theme/md3e_tokens.dart';
import '../../../data/models/memo.dart';
import 'memo_card.dart';

/// 自适应多列瀑布流：手机双列，宽屏三/四列；卡片高度自适应。
class MemoMasonry extends StatelessWidget {
  const MemoMasonry({
    super.key,
    required this.memos,
    required this.onOpen,
    required this.onLongPress,
  });

  final List<Memo> memos;
  final void Function(Memo memo) onOpen;
  final void Function(Memo memo) onLongPress;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = Md3eTokens.masonryColumns(width);
    return MasonryGridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
      crossAxisCount: columns,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      itemCount: memos.length,
      itemBuilder: (context, i) {
        final memo = memos[i];
        return MemoCard(
          memo: memo,
          onTap: () => onOpen(memo),
          onLongPress: () => onLongPress(memo),
        );
      },
    );
  }
}
