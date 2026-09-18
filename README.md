# NekoBox · MindSpace

<div align="center">
  <img src="icon.png" width="120" height="120" alt="NekoBox Logo">
  <br><br>
  <p><b>本地优先 · 隐私优先</b> 的笔记本</p>
  <p>文本 / 媒体集 / 音频 / 文件 · 四类铭记</p>
</div>

---

## 简介

NekoBox（项目名 MindSpace）是一款**完全离线**、**隐私至上**的 Android 笔记本应用。所有数据存储在你的设备本地，绝不上传、绝不分发。通过 Flutter 3.22+ 构建，采用 Material 3 Expressive 设计风格，仅支持 arm64-v8a 架构。

### 核心理念

- **本地优先**：所有数据 100% 存储在应用私有目录，不读公共存储、不申请多余权限
- **隐私唯一**：无任何联网权限，零追踪、零服务器、零云端
- **文件即真相**：数据库只存元数据，真实文件落盘私有目录，可备份、可恢复、可人工排查

---

## 功能特性

### 四类铭记

| 类型 | 说明 |
|---|---|
| 📝 **文本** | 富文本编辑器（flutter_quill），支持自定义字体、颜色、Markdown/Delta 导出 |
| 🖼️ **媒体集** | 图片/视频混合网格、图片查看器（photo_view）、裁剪、拖拽排序、缩略图缓存 |
| 🎙️ **音频** | 录音（audio_waveforms）、播放（just_audio）、波形显示、裁剪窗口（无重编码） |
| 📄 **文件** | PDF 内置阅读（pdfrx）、DOCX 自研解析、XLSX 表格浏览，非常规文件外部打开 |

### TOTP 验证码

支持扫码导入 `otpauth://` 协议的 TOTP 验证码（兼容 Google Authenticator / 1Password），本地生成 6 位动态密码。

### 文件夹管理

无限层级文件夹嵌套、拖拽移动、软删除 + 回收站恢复。

### 主题与个性化

- Android 12+ 动态取色（Material You / 壁纸色）
- 双种子 MD3E 配色体系
- 自定义种子色取色器（HEX 输入）
- 自定义字体导入

### 备份与恢复

一键打包所有铭记与字体为 zip，恢复到任意设备。

### 分享

文本、文件、图片一键分享，分享时临时缓存到系统目录。

---

## 技术栈

| 类别 | 技术 |
|---|---|
| 框架 | Flutter 3.22+ / Dart 3.13+ |
| UI | Material 3 Expressive（MD3E）、Riverpod 状态管理、go_router 路由 |
| 数据库 | Drift（内置 SQLite），多文件 DAO 架构 |
| 富文本 | flutter_quill |
| 音频 | just_audio + audio_waveforms |
| 视频 | video_player + chewie |
| 文档解析 | pdfrx（PDF）/ Excel（XLSX）/ 自研 DOCX（XML + archive） |
| TOTP | crypto（HMAC-SHA1 RFC6238）+ mobile_scanner |
| 依赖注入 | Riverpod + providers.dart 单一装配点 |
| 代码生成 | freezed 4 / json_serializable 6.14 / drift_dev 2.35 / build_runner 2.16 |

### 架构分层

```
features/      页面与 Widget（只监听 Riverpod 状态）
───────────────────────────────────────────────────────
data/          仓库编排（DB + 文件系统）+ 数据源 + 领域模型
───────────────────────────────────────────────────────
core/          Drift · 存储 · 主题 · 路由 · 工具 · 错误处理 · UI 组件
```

依赖方向永远自上而下：`features → repositories → datasources → core`。

> 详见 [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)

---

## 构建要求

- Flutter SDK ≥ 3.22.0
- Dart SDK ≥ 3.4.0
- Android SDK（compileSdk 34+）
- 仅构建 arm64-v8a APK（已锁定 abiFilters）

## 快速开始

```bash
# 克隆项目
git clone https://github.com/linxianlww/mindspace.git
cd mindspace

# 安装依赖
flutter pub get

# 代码生成（必须执行）
dart run build_runner build --delete-conflicting-outputs

# 运行调试版
flutter run --debug

# 构建发布版 APK（仅 arm64）
flutter build apk --release --target-platform android-arm64
```

### 离线构建

项目包含本地化修补版原生库（`third_party/pdfium_dart` 内置 arm64 .so、`pdfrx_engine` 兼容性补丁），无需 GitHub 下载构建依赖，国内网络即可构建。

---

## 项目结构

```
MindSpace/
├── lib/                          # Dart 源码
│   ├── main.dart                 # 应用入口
│   ├── app.dart                  # NekoBoxApp 根组件
│   ├── core/                     # 核心层（横切能力）
│   │   ├── constants/            # 常量 & 文件类型识别
│   │   ├── database/             # Drift 表 / DAO / 迁移
│   │   ├── di/                   # Riverpod Provider 装配
│   │   ├── error/                # 统一异常体系
│   │   ├── router/               # go_router 路由表
│   │   ├── settings/             # 应用设置
│   │   ├── storage/              # 私有目录 / 导入 / 字体 / 备份
│   │   ├── theme/                # MD3E 主题 & 令牌
│   │   ├── utils/                # 纯函数工具
│   │   └── widgets/              # 通用组件
│   ├── data/                     # 数据层
│   │   ├── datasources/          # 本地数据源封装
│   │   ├── models/               # Freezed 领域模型
│   │   └── repositories/         # 业务用例编排
│   └── features/                 # 特性（页面 & Widget）
│       ├── home/                 # 主页 / 瀑布流 / FAB
│       ├── folder/               # 文件夹管理
│       ├── memo_text/            # 文本铭记
│       ├── memo_media/           # 媒体集
│       ├── memo_audio/           # 音频铭记
│       ├── memo_file/            # 文件铭记
│       ├── memo_totp/            # TOTP 验证码
│       ├── memo_todo/            # 待办
│       ├── memo_anniversary/     # 纪念日
│       ├── settings/             &nbsp;设置（主题/字体/存储/备份/关于）
│       ├── share/                # 分享
│       └── viewer/               # 通用查看器
├── third_party/                  # 修补版第三方库
│   ├── pdfium_dart/              # 离线构建挂钩
│   └── pdfrx_engine/             # Dart 3.13 兼容补丁
├── android/                      # Android 配置
├── assets/                       # 应用资源
├── docs/
│   └── ARCHITECTURE.md           # 架构设计文档
├── pubspec.yaml                  # 依赖配置
└── README.md                     # 本文件
```

---

## 隐私与安全

- **零网络声明**：`AndroidManifest.xml` 无任何联网权限，分享时才把文件临时复制到缓存暴露给系统分享面板
- **软删除 + 回收站**：删除只写标记，恢复或彻底删除由用户决定
- **安全写入**：所有文件操作先写 `.tmp` 再 `rename`，失败不覆盖原文件
- **UUID 命名**：文件夹/铭记/媒体一律 v4 UUID，杜绝路径冲突

---

## 许可证

本项目采用 [GNU AGPL-3.0](LICENSE) 许可证。

```
MindSpace
Copyright (C) 2026  linxianlww

本程序是自由软件：您可以在自由软件基金会发布的 GNU Affero 通用公共许可证（第 3 版或任意后续版本）的条款下重新分发和/修改它。
本程序分发意在有用但不提供任何担保；也没有对适销性或特定用途适用性的默示担保。详见 GNU Affero 通用公共许可证。
```

---

<div align="center">
  <p>🐱 Made with love by linxianlww</p>
</div>
