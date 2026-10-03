import 'package:mindspace/ui/design_system/app_design_system.dart';

/// 为单个媒体添加/修改备注标签。
class MediaRemarkDialog {
  const MediaRemarkDialog._();

  /// [context] 必须位于 [AppScaffold] 子树内（页面级调用请传脚手架下方
  /// 的 context，否则找不到弹层宿主）。
  static Future<String?> show(BuildContext context, {String? initial}) {
    final ctrl = TextEditingController(text: initial);
    return AppDialog.show<String>(
      context: context,
      title: '媒体备注',
      content: AppInput(
        controller: ctrl,
        autofocus: true,
        hintText: '给这张图片/视频加个备注',
      ),
      actions: [
        MiuixTextButton('取消', onPressed: () => AppDialog.close(context)),
        MiuixButton(
          onPressed: () => AppDialog.close<String>(context, ctrl.text.trim()),
          child: const MiuixText('保存'),
        ),
      ],
    ).whenComplete(() => ctrl.dispose());
  }
}
