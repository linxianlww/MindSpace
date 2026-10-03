import 'package:mindspace/ui/design_system/app_design_system.dart';

/// 备注标签编辑弹框，返回新备注；清空返回空串。
class RemarkEditor {
  const RemarkEditor._();

  /// [context] 必须位于 [AppScaffold] 子树内（页面级调用请传脚手架下方
  /// 的 context，否则找不到弹层宿主）。
  static Future<String?> show(BuildContext context, {String? initial}) {
    final ctrl = TextEditingController(text: initial);
    return AppDialog.show<String>(
      context: context,
      title: '备注标签',
      content: AppInput(
        controller: ctrl,
        autofocus: true,
        hintText: '例如：重要 / 灵感 / 待办',
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
