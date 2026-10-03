import 'package:flutter/widgets.dart';
import 'package:flutter_miuix/miuix.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// hiui 图标目录（小米 hiui icon-resources SVG，assets/icons/）。
///
/// 命名为 kebab→camel 的语义名；值为资源路径，配合 [HiuiIcon] 使用。
/// hiui 缺失的富文本/编辑类图标为按 hiui 描边风格手绘的同风格 SVG。
class HiuiIcons {
  const HiuiIcons._();

  static const String add = 'assets/icons/add.svg';
  static const String ai = 'assets/icons/ai.svg';
  static const String alignCenter = 'assets/icons/align_center.svg';
  static const String alignLeft = 'assets/icons/align_left.svg';
  static const String alignRight = 'assets/icons/align_right.svg';
  static const String arrowBack = 'assets/icons/arrow_back.svg';
  static const String audio = 'assets/icons/audio.svg';
  static const String backup = 'assets/icons/backup.svg';
  static const String bold = 'assets/icons/bold.svg';
  static const String building = 'assets/icons/building.svg';
  static const String calendar = 'assets/icons/calendar.svg';
  static const String camera = 'assets/icons/camera.svg';
  static const String check = 'assets/icons/check.svg';
  static const String checkCircle = 'assets/icons/check_circle.svg';
  static const String checkSquare = 'assets/icons/check_square.svg';
  static const String chevronLeft = 'assets/icons/chevron_left.svg';
  static const String chevronRight = 'assets/icons/chevron_right.svg';
  static const String clear = 'assets/icons/clear.svg';
  static const String close = 'assets/icons/close.svg';
  static const String code = 'assets/icons/code.svg';
  static const String copy = 'assets/icons/copy.svg';
  static const String crop = 'assets/icons/crop.svg';
  static const String cut = 'assets/icons/cut.svg';
  static const String document = 'assets/icons/document.svg';
  static const String download = 'assets/icons/download.svg';
  static const String drag = 'assets/icons/drag.svg';
  static const String edit = 'assets/icons/edit.svg';
  static const String error = 'assets/icons/error.svg';
  static const String export = 'assets/icons/export.svg';
  static const String eye = 'assets/icons/eye.svg';
  static const String eyeOff = 'assets/icons/eye_off.svg';
  static const String file = 'assets/icons/file.svg';
  static const String fileText = 'assets/icons/file_text.svg';
  static const String fingerprint = 'assets/icons/fingerprint.svg';
  static const String font = 'assets/icons/font.svg';
  static const String folder = 'assets/icons/folder.svg';
  static const String folderAdd = 'assets/icons/folder_add.svg';
  static const String folderMove = 'assets/icons/folder_move.svg';
  static const String folderOpen = 'assets/icons/folder_open.svg';
  static const String heading = 'assets/icons/heading.svg';
  static const String home = 'assets/icons/home.svg';
  static const String image = 'assets/icons/image.svg';
  static const String inbox = 'assets/icons/inbox.svg';
  static const String info = 'assets/icons/info.svg';
  static const String italic = 'assets/icons/italic.svg';
  static const String key = 'assets/icons/key.svg';
  static const String lineSpacing = 'assets/icons/line_spacing.svg';
  static const String link = 'assets/icons/link.svg';
  static const String listBulleted = 'assets/icons/list_bulleted.svg';
  static const String listNumbered = 'assets/icons/list_numbered.svg';
  static const String lock = 'assets/icons/lock.svg';
  static const String mic = 'assets/icons/mic.svg';
  static const String minusSquare = 'assets/icons/minus_square.svg';
  static const String more = 'assets/icons/more.svg';
  static const String mosaic = 'assets/icons/mosaic.svg';
  static const String noPhoto = 'assets/icons/no_photo.svg';
  static const String openInNew = 'assets/icons/open_in_new.svg';
  static const String paste = 'assets/icons/paste.svg';
  static const String pause = 'assets/icons/pause.svg';
  static const String pin = 'assets/icons/pin.svg';
  static const String play = 'assets/icons/play.svg';
  static const String qrCode = 'assets/icons/qr_code.svg';
  static const String quote = 'assets/icons/quote.svg';
  static const String record = 'assets/icons/record.svg';
  static const String repeat = 'assets/icons/repeat.svg';
  static const String reset = 'assets/icons/reset.svg';
  static const String rotateRight = 'assets/icons/rotate_right.svg';
  static const String screenshot = 'assets/icons/screenshot.svg';
  static const String search = 'assets/icons/search.svg';
  static const String settings = 'assets/icons/settings.svg';
  static const String share = 'assets/icons/share.svg';
  static const String skin = 'assets/icons/skin.svg';
  static const String sort = 'assets/icons/sort.svg';
  static const String spaceBar = 'assets/icons/space_bar.svg';
  static const String stop = 'assets/icons/stop.svg';
  static const String storage = 'assets/icons/storage.svg';
  static const String strikethrough = 'assets/icons/strikethrough.svg';
  static const String subtitles = 'assets/icons/subtitles.svg';
  static const String tag = 'assets/icons/tag.svg';
  static const String textFields = 'assets/icons/text_fields.svg';
  static const String time = 'assets/icons/time.svg';
  static const String trash = 'assets/icons/trash.svg';
  static const String tune = 'assets/icons/tune.svg';
  static const String underline = 'assets/icons/underline.svg';
  static const String undo = 'assets/icons/undo.svg';
  static const String unlock = 'assets/icons/unlock.svg';
  static const String upload = 'assets/icons/upload.svg';
  static const String user = 'assets/icons/user.svg';
  static const String video = 'assets/icons/video.svg';
  static const String waveform = 'assets/icons/waveform.svg';
}

/// hiui SVG 图标组件 —— 对齐 [Icon] 的用法（icon/size/color）。
///
/// 颜色经 `BlendMode.srcIn` 染色；未显式给色时依次回退
/// IconTheme → MiuixTheme 的 onSurface。
class HiuiIcon extends StatelessWidget {
  const HiuiIcon(
    this.icon, {
    super.key,
    this.size = 24.0,
    this.color,
  });

  /// hiui 图标资源路径（[HiuiIcons] 常量）。
  final String icon;

  final double? size;

  /// 染色色；null 时取 IconTheme / 主题前景色。
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color resolved = color ??
        IconTheme.of(context).color ??
        MiuixTheme.of(context).colors.onSurface;
    return SvgPicture.asset(
      icon,
      width: size,
      height: size,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(resolved, BlendMode.srcIn),
    );
  }
}
