import 'dart:io';

import 'package:mindspace/ui/design_system/app_design_system.dart';

import '../../../../core/utils/file_utils.dart';

/// 非常规文件的详细信息卡：名称、大小、类型、路径、修改时间。
class FileInfoCard extends StatelessWidget {
  const FileInfoCard({
    super.key,
    required this.name,
    required this.path,
    required this.sizeBytes,
    required this.ext,
  });

  final String name;
  final String path;
  final int sizeBytes;
  final String ext;

  @override
  Widget build(BuildContext context) {
    final scheme = MiuixTheme.of(context).colors;
    final textStyles = MiuixTheme.of(context).textStyles;
    final modified =
        File(path).existsSync() ? File(path).statSync().modified : null;
    return MiuixSurface(
      cornerRadius: AppTokens.radiusMedium,
      color: scheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppAvatar(
                  radius: 28,
                  backgroundColor: scheme.secondaryContainer,
                  child: HiuiIcon(HiuiIcons.document,
                      color: scheme.onSecondaryContainer),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MiuixText(name,
                          style: textStyles.title4,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      MiuixText(
                        '.${ext.isEmpty ? '未知' : ext}  ·  ${FileUtils.humanSize(sizeBytes)}',
                        style: textStyles.footnote1,
                        color: scheme.onSurfaceVariantSummary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // 隐私考虑：不展示应用内部完整路径，仅显示文件名/大小/修改时间。
            if (modified != null) ...[
              const AppSeparator(),
              MiuixText(
                '修改于 $modified',
                style: textStyles.footnote1,
                color: scheme.onSurfaceVariantSummary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
