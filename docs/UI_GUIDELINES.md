# MindSpace UI 指南（MIUIX 优先）

> 本文档是界面层的唯一规范。重构于 2026-09，基于 `flutter_miuix 1.2.0`
> （github.com/ChuxinNeko/flutter_miuix，标准 HyperOS 风格，不使用 OS4 玻璃组件）。

## 1. 架构总览

```
MiuixThemeController（唯一配色来源：动态取色/品牌橙 seed/深浅色）
  └── MaterialApp.router（Material 兼容桥，仅服务第三方包内部渲染）
        └── GoRouter（push 式导航，无底部 tab）
              └── AppScaffold（每页根部，= MiuixScaffold + 弹层/snackbar 宿主）
                    └── 页面内容（Miuix* 组件 + 少量 App* 组件）
```

- **主题单一事实来源**：`lib/app.dart` 的 `MiuixThemeController`。`core/theme/app_theme.dart`
  只生成最小 Material `ThemeData` 供第三方包（flutter_quill、chewie、pdfrx）内部使用，
  业务代码不得依赖 Material 主题。
- **状态栏样式**由 app.dart 根据主题 `SystemChrome.setSystemUIOverlayStyle` 设置。

## 2. 页面骨架

页面只 import barrel：`package:mindspace/ui/design_system/app_design_system.dart`。

```dart
// 静态内容：body 自动以 contentPadding 包裹
AppScaffold(topBar: AppHeader(title: '标题'), body: ...);

// 滚动内容：content builder 自行消化 padding（推荐）
AppScaffold(
  topBar: AppHeader(title: '标题'),
  content: (context, padding) => ListView(padding: padding, children: [...]),
);
```

要点：
- `contentPadding` = 顶栏高度 + 底栏高度 + 系统安全区。**MiuixScaffold 是满屏布局**，
  顶栏悬浮于内容之上，滚动视图必须自行消化 padding。
- MiuixScaffold **不做键盘避让**：含输入框/底部工具栏的页面在 content 外层加
  `Padding(padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom))`。
- FAB 用 `AppScaffold(floatingActionButton: ...)` 传入，位置 `fabPosition`。

### 折叠大标题（首页模式）

```dart
final _collapse = miuixScrollBehavior();

AppScaffold(
  topBar: MiuixTopAppBar(
    title: 'MindSpace',
    scrollBehavior: _collapse,
    blurred: true, // 毛玻璃
    actions: [...],
  ),
  content: (context, padding) => MiuixScrollBehaviorListener(
    behavior: _collapse,
    child: CustomScrollView(slivers: [
      SliverPadding(padding: EdgeInsets.only(top: padding.top), sliver: ...),
      // ...
    ]),
  ),
);
```

`MiuixScrollBehaviorListener` 只响应 depth==0 的纵向滚动，内嵌横向列表不会误触折叠。

## 3. 组件选择对照表

| 场景 | 用什么 | 不要用 |
|---|---|---|
| 页面脚手架 | `AppScaffold` | Flutter Scaffold / AppView（已删） |
| 顶栏 | `AppHeader`（小标题）/ `MiuixTopAppBar`（折叠大标题） | Material AppBar |
| 列表行 | `MiuixBasicComponent`（通用）/ `MiuixArrowPreference`（跳转行）/ `AppListRow`（带约定封装） | ListTile |
| 开关行 | `MiuixSwitchPreference` | SwitchListTile |
| 单选行 | `MiuixRadioButtonPreference` | RadioListTile |
| 复选框 | `MiuixCheckbox` / `MiuixCheckboxPreference` | Material Checkbox |
| 滑条 | `MiuixSlider` / `MiuixRangeSlider`（`(double,double)` 记录回调） | Material Slider/RangeSlider |
| 输入框 | `AppInput`（errorText/helperText 封装）/ `MiuixTextField` / 搜索 `MiuixSearchBar`+`MiuixInputField` | Material TextField |
| 卡片/分组容器 | `MiuixCard`（可按压，sink 反馈）/ `MiuixSurface`（静态容器） | Material Card |
| 按钮 | `MiuixButton`（主色）/ `MiuixTextButton`（文字）/ `AppButton`（需要 outlined 变体时）/ `MiuixFloatingActionButton`（FAB） | Material 系列按钮 |
| 对话框 | `AppDialog.show/close`（MiuixOverlayDialog 宿主） | showDialog |
| 底部抽屉 | `AppSheet.show/close`（MiuixOverlayBottomSheet 宿主） | showModalBottomSheet |
| **锚定菜单** | `MiuixOverlayIconDropdownMenu`（child=触发图标/文字，条目 `MiuixDropdownItem(text/icon/summary/selected/enabled/onClick)`，选中自动收起） | 顶栏溢出菜单、倍速等小选择器**不要**用底部抽屉 |
| 轻提示 | `AppSnackbar.show`（MiuixSnackbarHost 宿主） | ScaffoldMessenger/SnackBar |
| 分段/页签 | `MiuixTabRow` / `AppTabStrip` | SegmentedButton、TabBar |
| 面包屑 | `MiuixBreadcrumbBar` + `MiuixBreadcrumbItem(path:, text:)` | 自绘面包屑 |
| 下拉刷新 | `AppRefresh`（MiuixPullToRefresh 封装） | RefreshIndicator |
| 进度 | `AppCircleProgress`（不确定态）/ `MiuixLinearProgressIndicator(progress:)` / `MiuixCircularProgressIndicator(progress:)` | Material 进度条 |
| 日期选择 | `MiuixDatePicker`（放 AppSheet 内） | showDatePicker |
| 分隔线 | `MiuixHorizontalDivider` / `AppSeparator` | Material Divider |
| 状态视图 | `EmptyState` / `LoadingState` / `ErrorState`（barrel） | 自绘 |
| 日期/数字 | `MiuixDatePicker` / `MiuixNumberPicker` | — |

### 已删除（勿再引用）
`AppView`、`AppPanel`、`AppToggle(Row)`、`AppCheck(Row)`、`AppChoice(Row)`、`AppSlide`、
`AppRangeSlider`、`AppFloatButton`、`AppTooltip`、`AppNavBar`、`AppLineProgress`、
`AppRingProgress`、`AppTabContent`、`AppAvatarBordered`、`Md3eTokens`、`UiStyle`、
core/widgets 下 `md3e_card` / `md3e_switch` / `state_views`（state_views 已迁至设计系统）。

## 4. Material 白名单规则

barrel 从 material 只导出 `Icons`、`Colors`、`ThemeMode` 三个符号。
页面确需其他 material 符号时用 show 导入并注释原因：

```dart
import 'package:flutter/material.dart' show ReorderableListView; // 拖拽排序框架
```

**禁止**在页面中使用 Material 组件（Scaffold/AppBar/TextField/Dialog/SnackBar 等）。
允许出现 Material 的白名单文件：`lib/app.dart`（桥）、`lib/core/theme/app_theme.dart`（桥）、
`lib/ui/design_system/app_scaffold.dart`（透明 Material 环境补齐）、
`lib/core/widgets/pin_input_dialog.dart`（安全组件，待迁移）、
第三方包（flutter_quill / chewie / pdfrx / ReorderableListView 框架件）。

## 5. 弹层宿主机制（重要）

`AppDialog` / `AppSheet` / `AppSnackbar` 通过 `AppScaffold.maybeOf(context)`
（`findAncestorStateOfType`）找到页面脚手架，把弹层交给 MiuixScaffold 的
popup / snackbar 层渲染。因此：

1. **context 规则**：`AppScaffold` 会把 MiuixScaffold 子树内的 context 传给
   `content: (context, padding)` 闭包——页面处理器应使用这个 context（或把它
   赋给 State 字段），**不要**用页面 State 自身的 `context`（位于脚手架之上，
   查不到宿主，release 下静默无效）。顶栏（topBar）里构造的闭包同理：用局部
   `Builder` 捕获，或改用自注册的锚定菜单组件。
2. **关闭弹层一律用 `AppDialog.close(ctx, result)` / `AppSheet.close(ctx, result)`，
   绝不能用 `Navigator.pop`** —— 弹层不是路由，Navigator.pop 会误退页面。
3. 弹层经 `renderInRoot` 自注册到根 MiuixScaffold 的弹层注册表；
   `MiuixOverlayIconDropdownMenu` 等锚定菜单同理，只要在页面树内即可用。

### 菜单 vs 抽屉 vs 对话框（易混组件选择）

- **锚定菜单**（`MiuixOverlayIconDropdownMenu`）：顶栏溢出动作、小按钮触发的
  互斥短选项（倍速、标题层级）——轻量、不离开锚点、带 `selected` 勾选态。
- **底部抽屉**（`AppSheet`）：长按条目操作单、多字段/长列表选择器（日期、
  色板、字体、移动到文件夹）。
- **居中对话框**（`AppDialog`）：确认提示、单行文本输入。
- 按钮语义：破坏性确认 = `AppButton(variant: text)` + `colors.error`；
  取消 = text 或 outlined；主操作 = filled `MiuixButton`。
  行语义：跳转子页 = `MiuixArrowPreference`；即时动作 = `MiuixBasicComponent`；
  破坏性行的图标/标题用 `colors.error`。

## 6. 视觉约定

- 主题色一律 `MiuixTheme.of(context).colors.*`；不硬编码颜色（媒体查看器黑底沉浸式的
  白色前景除外）。
- 文字用 `MiuixText` / `MiuixTheme.of(context).textStyles.*`（title1/2/3/4、headline、
  body1/2、footnote1/2、main、button、subtitle）。
- 圆角/间距用 `AppTokens`（radiusCard=26、radiusDialog=28、radiusFab=20、
  radiusChip=16、radiusBar=22；spacingXS/S/M/L/XL）。
- 主题色：全局固定 MIUIX 默认 HyperOS 蓝（浅 primary `0xFF3482FF`/深
  `0xFF277AF7`），无动态取色、无主题色设置；个别多色场景（如 FAB 类型色）
  用固定色值常量，不依赖品牌种子。
- 图标：一律 `HiuiIcon(HiuiIcons.xxx)`（hiui SVG，`assets/icons/`）；
  **禁止使用 Material 的 `Icons`**（barrel 白名单已不含 Icons）。
- 设置偏好行：跳转/选择行用 `AppSettingsRow`（带 HyperOS 圆底箭头，无分割线）；
  纯动作行用 `MiuixBasicComponent`。偏好行之间不加分割线。
- 分组容器：`MiuixSurface(cornerRadius: AppTokens.radiusMedium)` 包多行 +
  `MiuixSmallTitle('分组名')` 小节标题。
