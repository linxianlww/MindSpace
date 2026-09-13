import 'package:flutter/material.dart';

import '../../../core/theme/md3e_tokens.dart';

/// 新建目标类型。
enum CreateTarget { text, media, audio, file, folder }

/// MD3E 展开式 FAB：点击后以弹性曲线展开五个新建入口。
class CreateFab extends StatefulWidget {
  const CreateFab({super.key, required this.onSelect});

  final void Function(CreateTarget target) onSelect;

  @override
  State<CreateFab> createState() => _CreateFabState();
}

class _CreateFabState extends State<CreateFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: Md3eTokens.medium);
  bool _open = false;

  static const _items = <(CreateTarget, IconData, String, Color)>[
    (CreateTarget.folder, Icons.folder_outlined, '新建文件夹', Color(0xFF8B5E3C)),
    (CreateTarget.text, Icons.notes_rounded, '新建文本', Color(0xFF5B5BD6)),
    (CreateTarget.media, Icons.photo_library_outlined, '新建媒体集', Color(0xFF0F7B6C)),
    (CreateTarget.audio, Icons.mic_none_rounded, '新建音频', Color(0xFFB0005B)),
    (CreateTarget.file, Icons.upload_file_outlined, '导入文件', Color(0xFF3B6B2E)),
  ];

  void _toggle() {
    setState(() => _open = !_open);
    _open ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < _items.length; i++)
          ScaleTransition(
            scale: CurvedAnimation(parent: _ctrl, curve: Md3eTokens.emphasized),
            child: SizeTransition(
              sizeFactor: CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
              child: _miniItem(context, _items[i]),
            ),
          ),
        FloatingActionButton.extended(
          onPressed: _toggle,
          icon: AnimatedRotation(
            turns: _open ? 0.125 : 0,
            duration: Md3eTokens.medium,
            curve: Md3eTokens.emphasized,
            child: Icon(_open ? Icons.close : Icons.add),
          ),
          label: Text(_open ? '收起' : '新建'),
        ),
      ],
    );
  }

  Widget _miniItem(
      BuildContext context, (CreateTarget, IconData, String, Color) item) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: scheme.surfaceContainerHigh,
            elevation: 2,
            borderRadius: BorderRadius.circular(Md3eTokens.radiusChip),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Text(item.$3,
                  style: Theme.of(context).textTheme.labelLarge),
            ),
          ),
          const SizedBox(width: 10),
          FloatingActionButton.small(
            heroTag: 'create_${item.$1.name}',
            backgroundColor: item.$4,
            foregroundColor: Colors.white,
            onPressed: () {
              _toggle();
              widget.onSelect(item.$1);
            },
            child: Icon(item.$2),
          ),
        ],
      ),
    );
  }
}
