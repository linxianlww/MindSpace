/// 全局常量：目录名、数据库名、SharedPreferences 键、分页等。
///
/// 设计原则：所有用户数据只落在应用私有目录，
/// 即 `<ApplicationSupportDirectory>/mindspace` 与 `/font`，绝不写入公共存储。
class AppConstants {
  const AppConstants._();

  /// 铭记与文件夹根目录名。
  static const String mindspaceDirName = 'mindspace';

  /// 字体目录名。
  static const String fontDirName = 'font';

  /// 根级铭记所在目录（未归入任何文件夹的铭记）。
  static const String rootDirName = 'root';

  /// 文件夹目录名。
  static const String foldersDirName = 'folders';

  /// 每个铭记目录内的固定文件名。
  static const String metaFileName = 'meta.json';
  static const String assetsDirName = 'assets';
  static const String audioDirName = 'audio';
  static const String filesDirName = 'files';

  /// 文本铭记的三种落盘格式。
  static const String markdownFileName = 'content.md';
  static const String rtfFileName = 'content.rtf';
  static const String plainTextFileName = 'content.txt';

  /// Drift 数据库文件名。
  static const String databaseName = 'mindspace.sqlite';

  // —— SharedPreferences 键 ——
  static const String prefThemeMode = 'pref.theme_mode'; // light/dark/system
  static const String prefDynamicColor = 'pref.dynamic_color'; // bool
  static const String prefSeedColor = 'pref.seed_color'; // int
  static const String prefSortField = 'pref.sort_field'; // createdAt/updatedAt/title
  static const String prefSortAsc = 'pref.sort_asc'; // bool
  static const String prefLineHeight = 'pref.line_height'; // double：文本阅读行距
  static const String prefParagraphSpacing =
      'pref.paragraph_spacing'; // double：段落间距（px）
  static const String prefShareImageSuffix =
      'pref.share_image_suffix'; // String?：长图末尾「分享自」后缀

  /// 默认长图水印后缀（分享自 ___）。
  static const String defaultShareImageSuffix = 'NekoBox';

  /// 瀑布流单页加载条数（分页）。
  static const int pageSize = 30;

  /// 应用作者与主页（关于与开发者页使用）。
  static const String authorName = '咏叹调 Aria';
  static const String authorHomepage = 'https://linxianlww.github.io/';

  /// 仅支持的 ABI。
  static const List<String> supportedAbis = ['arm64-v8a'];
}
