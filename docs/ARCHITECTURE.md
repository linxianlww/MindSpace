# MindSpace 架构设计文档

> 本地优先 / 隐私优先的 Android 笔记（铭记）应用。Flutter 3.22+、Material 3 Expressive、仅 arm64-v8a。

## 1. 总体分层

采用严格的单向依赖分层，**UI 不直接操作文件系统或数据库**：

```
┌──────────────────────────────────────────────┐
│ features/  页面与 Widget（只监听 Riverpod 状态） │
├──────────────────────────────────────────────┤
│ data/repositories  仓库：编排 DB + 文件系统      │
│ data/datasources  LocalDb / FileSystem 数据源   │
│ data/models       Freezed 领域模型              │
├──────────────────────────────────────────────┤
│ core/database     Drift 表 / DAO / 迁移          │
│ core/storage      私有目录布局 / 导入 / 字体/备份 │
│ core/utils        纯函数工具（识别/解析/转换）     │
│ core/theme router widgets di error 等横切能力    │
└──────────────────────────────────────────────┘
```

依赖方向永远自上而下：`features → repositories → datasources → core`。
`core/di/providers.dart` 是唯一的装配点（Riverpod Provider 图）。

### 1.1 模块划分

| 层 | 目录 | 职责 |
|---|---|---|
| 核心 | `core/constants` | 常量、扩展名→类型识别（纯函数，可单测） |
| 核心 | `core/database` | Drift：7 张表、3 个 DAO、schema 迁移 |
| 核心 | `core/storage` | 私有目录初始化、文件落盘、导入、字体、zip 备份 |
| 核心 | `core/utils` | UUID、MIME、日期、Markdown/Delta、字幕、DOCX/XLSX 解析 |
| 核心 | `core/theme` | MD3E 设计令牌与主题 |
| 核心 | `core/router` | go_router 路由表 + 共享轴转场 |
| 数据 | `data/models` | Freezed 不可变领域模型 + JSON 序列化 |
| 数据 | `data/datasources` | 屏蔽 Drift / dart:io 细节 |
| 数据 | `data/repositories` | 业务用例：CRUD、移动、软删、导入编排、mappers |
| 特性 | `features/home` | 瀑布流、卡片、面包屑、新建 FAB |
| 特性 | `features/folder` | 无限层级文件夹 |
| 特性 | `features/memo_text` | flutter_quill 富文本、工具栏、字体、颜色、分享 |
| 特性 | `features/memo_media` | 图片/视频混合网格、查看器、裁剪、拖拽排序 |
| 特性 | `features/memo_audio` | 录音、播放、波形、裁剪窗口、字幕 |
| 特性 | `features/memo_file` | PDF/DOCX/XLSX 内置阅读，非常规文件外部打开 |
| 特性 | `features/settings` | 主题/字体/存储/备份/关于与开发者 |
| 特性 | `features/share` | 文本/文件/图片分享 |
| 特性 | `features/viewer` | 按类型分发的通用查看器 |

## 2. 数据流（单向）

以“导入一个文件”为例（需求 5.3 的七步流程）：

```
用户选文件
  → ImportRepository.import(path)
      1) FileTypes.classify() 识别 MemoType（纯函数）
      2) UuidUtils.newId() 生成铭记/媒体 UUID
      3) ImportService.placeFile() 复制到私有目录（先 .tmp 再 rename，原子安全写）
      4) 生成缩略图 / 波形 / 尺寸时长等元数据
      5) MemoRepository.save()：mappers 转 Drift Companion → DAO 写库
                              同时写 meta.json（文件系统即真相的冗余快照）
      6) Drift Stream 自动变更
      7) memoListProvider(StreamProvider) 收到新列表 → 瀑布流自动刷新
```

- 列表/详情统一用 `StreamProvider`/`FutureProvider` 监听仓库；写操作走仓库方法。
- 领域模型（Freezed）与 Drift 行对象通过 `data/repositories/mappers.dart` 互转，UI 永远只接触领域模型。

## 3. 存储策略：文件系统即真相

- **数据库只存元数据**，真实字节全部在应用私有目录，不写公共存储、不联网、不多余权限。
- 根目录：`<ApplicationSupportDirectory>/mindspace/`；字体：`<ApplicationSupportDirectory>/font/`。

```
mindspace/
  root/<memoId>/                 # 根级铭记
  folders/<folderId>/memos/<memoId>/
      meta.json                 # 与 DB 一致的快照，便于备份/恢复/人工排查
      content.md|rtf|txt         # 文本铭记正文
      assets/<uuid>.jpg|mp4      # 媒体集
      audio/original.m4a         # 录音/导入音频（trimmed 为裁剪结果）
      files/<originalName>       # 文件铭记
```

- **UUID 命名**：文件夹/铭记/媒体/字体一律 v4 UUID，杜绝重名与路径冲突。
- **安全写**：所有写入先写 `*.tmp` 再 `rename`，失败不覆盖原文件（用户数据操作失败不丢原文件）。
- **软删除 + 回收站**：删除只写 `deletedAt`；存储设置里可恢复或彻底删除（此时才删目录）。
- **备份**：`BackupService` 用 archive 把 mindspace 与 font 目录打成 zip；恢复即解压覆盖回私有目录。

## 4. 状态管理（Riverpod）

- 基础设施与仓库在 `core/di/providers.dart` 以 Provider 单例装配；`SharedPreferences` 在 `main()` 预加载后 override 注入。
- 关键 provider：`folderListProvider(parentId)`、`memoListProvider(folderId)`、
  `memoDetailProvider(id)`、`fontListProvider`、`settingsProvider`、`themeModeProvider`，
  以及各特性内的 `textEditorProvider` / `mediaEditorProvider` / `audioPlayerProvider` /
  `recorderProvider`。
- 异步统一用 `StreamProvider/FutureProvider/StateNotifier`，UI 侧用 `.when(data/loading/error)`
  渲染加载态、空态、可重试错误态。

## 5. 导航

go_router 集中声明（`core/router/app_router.dart`），页面转场为共享轴（Fade+微位移）。
四类铭记各有查看/编辑路由；新建后直接进入对应编辑器；`/settings/developer` 为关于与开发者页。

## 6. 关键技术决策（不确定处的合理取舍）

1. **不引入 ffmpeg_kit**：该包已从 pub.dev 退役且体积巨大。音频“裁剪”采用**裁剪窗口**方案——
   `just_audio.setClip` 精确试听，起止时间存入 metadata（`trimStartMs/trimEndMs`），
   播放与导出都按窗口进行，不做有损重编码；需要真正重编码时可在 `AudioTrimmer` 处接原生编码器。
2. **DOCX 自研解析**：不依赖已不稳定的 docx_to_text，用 `archive` 解 zip + `xml` 解析
   `word/document.xml`（w:p 段落、w:t 文本）；XLSX 用 `excel` 包解析为工作表。
3. **Drift 多文件 DAO**：表集中在 `mindspace_tables.dart`，表类用 `*Rows` 命名并显式
   `@DataClassName(*Row)` 避免名单数化撞名；每个 DAO 独立 `part 'xxx_dao.g.dart'`。
4. **代码生成版本与 Dart 3.13 对齐**：freezed 4（模型类需 `abstract class`）、drift/drift_dev 2.35、
   build_runner 2.16、analyzer 14，避免旧 analyzer 在新 SDK 上栈溢出。
5. **动态取色**：Android 12+ 用 dynamic_color 取壁纸色，否则回落到种子色 ColorScheme。
6. **媒体权限最小化**：选图/选文件走系统 Photo Picker / SAF（file_picker），仅录音时动态申请麦克风。

## 7. 错误处理与隐私

- `core/error/app_exception.dart` 统一异常体系（文件不存在/权限/格式/解析/导入/数据库/未知），
  `normalizeAppError` 归一化；`main()` 内注册 `FlutterError.onError` 与
  `PlatformDispatcher.onError`，关键路径用 logger 记录。
- 无任何网络权限；分享时才把文件临时复制到缓存暴露给系统分享面板。

## 8. 性能

- 列表用缩略图（最大宽 480、JPEG80）缓存于私有 cache 目录；视频懒加载。
- 大图解码走 Future（可平滑升级为 Isolate）；波形预计算后以 int 采样存入 metadata。
- 播放器/录音器/控制器在 Provider dispose 时统一释放。

## 9. 构建约束

- `android/app/build.gradle.kts` 中 `ndk.abiFilters += "arm64-v8a"`，splits 仅打 arm64；
  release：`flutter build apk --release --target-platform android-arm64`。
- 所有原生插件均选用提供 arm64-v8a 产物的库，不引入仅 x86 的依赖。
