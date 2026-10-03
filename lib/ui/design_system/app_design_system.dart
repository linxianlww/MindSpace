/// MindSpace MIUIX 统一设计系统。
///
/// 页面层只允许 import 本文件。所有用户可见 UI 均通过 MIUIX 组件
/// （`Miuix*`）或本层少量 `App*` 组件完成。
///
/// ## 规则
/// - 本 barrel **不导出** `flutter/material.dart` 的组件库表面；
///   Material 色板与 ThemeMode 常量以 `show Colors, ThemeMode` 白名单导出（图标为 hiui SVG）。
/// - 不得在页面中使用 Material 组件（Scaffold/AppBar/TextField/Switch 等）。
/// - 优先直接使用 MIUIX 原生组件；`App*` 只保留有真实封装价值的组件：
///   - [AppScaffold]：页面脚手架（MiuixScaffold + 弹层/snackbar 宿主）
///   - [AppHeader]：小标题顶栏
///   - [AppDialog]/[AppSheet]/[AppSnackbar]：命令式弹层 API
///   - [AppButton]：filled/outlined/text 三态按钮（MIUIX 无 outlined 变体）
///   - [AppListRow]：带箭头/颜色语义约定的列表行（MiuixBasicComponent 封装）
///   - [AppInput]：带错误/提示文字的输入框（MiuixTextField 封装）
///   - [AppTapIcon]/[AppCircleProgress]/[AppSeparator]/[AppTabStrip]/
///     [AppRefresh]/[AppChip]/[AppAvatar]/[AppSelectableText] 等轻量约定
///   - [EmptyState]/[LoadingState]/[ErrorState]：页面状态视图
library;

// Flutter 基础 widgets（Icon/IconData/EdgeInsets 等均在 widgets 层）
export 'package:flutter/widgets.dart';

// Material 白名单：仅色板与 ThemeMode 常量（图标已全面切换 hiui SVG）
export 'package:flutter/material.dart' show Colors, ThemeMode;

// MIUIX 全套组件 + 主题系统
export 'package:flutter_miuix/miuix.dart';

// 设计令牌
export 'tokens.dart';

// hiui 图标体系
export 'hiui_icons.dart';

// 统一 App* 组件
export 'app_scaffold.dart';
export 'app_button.dart';
export 'app_dialog.dart';
export 'app_sheet.dart';
export 'app_snackbar.dart';
export 'app_text_field.dart';
export 'app_icon_button.dart';
export 'app_list_tile.dart';
export 'app_divider.dart';
export 'app_progress.dart';
export 'app_tab_bar.dart';
export 'app_refresh.dart';
export 'app_chip.dart';
export 'app_avatar.dart';
export 'app_selectable_text.dart';
export 'app_animated_switcher.dart';
export 'app_data_table.dart';
export 'app_reorderable_drag.dart';
export 'app_state_views.dart';
export 'app_settings_row.dart';
