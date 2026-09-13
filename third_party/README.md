# third_party 本地补丁说明（MindSpace）

本目录存放两个被 **vendoring（本地化）** 并打了补丁的第三方包，根 `pubspec.yaml`
通过 `dependency_overrides` 以 `path` 方式引用它们。**交付/迁移工程时必须连同本目录
一起打包**，否则无法离线复现构建。

## 1. pdfrx_engine（来自 pdfrx 2.4.5 依赖的 pdfrx_engine 0.4.4）

- **为什么本地化**：
  - 版本约束：`excel 4.0.6` 死锁 `archive ^3.6.1`，而较新的 `pdfrx`（2.4.6+）会经
    `pdfrx_engine 0.4.5+` 传导到 `image ^4.8 / archive ^4`，与 excel 冲突。因此 pdfrx
    固定在 **2.4.5**、engine 固定在 **0.4.4**（该版本不依赖 archive/image）。
  - 编译兼容：0.4.4 的 `lib/src/native/pdf_file_cache.dart` 在 Dart 3.13 空安全下，
    在 `await` 之后的嵌套异步闭包里访问可空参数 `cache` 会编译失败（提升失效）。
- **补丁内容**：把读取闭包改为在开头取 `final c = cache!;`，闭包内统一使用 `c`。
- pubspec 删除了 `resolution: workspace`，使其可作为 path 依赖被主工程覆盖。

## 2. pdfium_dart（0.2.5，pdfrx 的 PDFium FFI 绑定）

- **为什么本地化**：其原生构建钩子 `hook/build.dart` 会在构建时从
  `github.com/bblanchon/pdfium-binaries/releases` 下载 PDFium 预编译库；国内直连
  github 经常超时，导致构建不可复现。
- **补丁内容（离线优先）**：
  - 预先通过可信镜像下载 `pdfium-android-arm64.tgz`（release `chromium/7811`），
    解出 arm64 的 `lib/libpdfium.so`，放到：
    `prebuilt/android-arm64/libpdfium.so`（约 6.1 MiB）。
  - 重写 `hook/build.dart`：优先把 `prebuilt/<platform>-<arch>/` 下的本地库复制到
    输出目录；仅当本地库缺失时才回退到原联网下载逻辑。
  - pubspec 删除 `resolution: workspace` 以及仅用于重新生成 FFI 绑定的
    dev_dependencies（ffigen/lints/test，绑定产物已在 lib/ 中）。

## 复现方式

```bash
flutter pub get
flutter build apk --release --target-platform android-arm64
```

无需联网下载任何原生库；产物 `build/app/outputs/flutter-apk/app-release.apk` 内
`lib/` 只含 `arm64-v8a`（由根 `android/build.gradle.kts` 的 `finalizeDsl` 强制，
详见该文件注释）。
