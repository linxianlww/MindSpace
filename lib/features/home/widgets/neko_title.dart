import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home_provider.dart';

/// 主页标题：NekoBox + 一言副标题。
/// 副标题在联网时从 hitokoto.cn 拉取，失败（离线/超时）时不显示。
class NekoBoxTitle extends ConsumerWidget {
  const NekoBoxTitle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hitoAsync = ref.watch(hitokotoProvider);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('NekoBox'),
        if (hitoAsync.valueOrNull case final hito?)
          Text(
            hito,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
          ),
      ],
    );
  }
}
