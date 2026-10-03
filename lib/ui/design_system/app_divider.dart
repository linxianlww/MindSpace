import 'package:flutter/widgets.dart';
import 'package:flutter_miuix/miuix.dart';

/// 统一水平分隔线。
class AppSeparator extends StatelessWidget {
  const AppSeparator({super.key, this.height = 1, this.thickness, this.color});

  final double height;
  final double? thickness;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return MiuixHorizontalDivider(
      thickness: thickness ?? 0.75,
      color: color,
    );
  }
}
