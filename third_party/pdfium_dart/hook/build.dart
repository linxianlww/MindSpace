import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:http/http.dart' as http;

const _pdfiumRelease = 'chromium%2F7811';
const _assetName = 'libpdfium';

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;
    if (input.config.code.targetOS == OS.iOS) return;

    final target = _PdfiumTarget.fromCodeConfig(input.config.code);
    final outputSubdir = _pdfiumRelease.replaceAll('%2F', '_');
    final outputFile = input.outputDirectoryShared.resolve(
      '$outputSubdir/${target.archivePlatform}-${target.archiveArch}/${target.libraryFileName}',
    );

    await _providePdfium(
      packageRoot: input.packageRoot,
      outputFile: outputFile,
      target: target,
      pdfiumRelease: _pdfiumRelease,
    );

    output.assets.code.add(
      CodeAsset(
        package: input.packageName,
        name: _assetName,
        linkMode: DynamicLoadingBundled(),
        file: outputFile,
      ),
    );
  });
}

Future<void> _providePdfium({
  required Uri packageRoot,
  required Uri outputFile,
  required _PdfiumTarget target,
  required String pdfiumRelease,
}) async {
  final output = File.fromUri(outputFile);
  if (await output.exists()) return;

  // 【MindSpace 本地补丁 · 离线优先】优先使用随包内置在
  // prebuilt/<platform>-<arch>/ 下的 PDFium 预编译库（已通过可信镜像下载并随
  // 仓库一起提供），避免构建时访问国内不稳定的 github.com releases。
  final prebuilt = File.fromUri(
    packageRoot.resolve(
      'prebuilt/${target.archivePlatform}-${target.archiveArch}/${target.libraryFileName}',
    ),
  );
  if (await prebuilt.exists()) {
    await output.parent.create(recursive: true);
    await prebuilt.copy(output.path);
    return;
  }

  // 回退路径：内置库缺失时才联网下载（保持上游原逻辑）。
  final archiveUri = Uri.parse(
    'https://github.com/bblanchon/pdfium-binaries/releases/download/'
    '$pdfiumRelease/pdfium-${target.archivePlatform}-${target.archiveArch}.tgz',
  );

  final response = await http.Client().get(archiveUri);
  if (response.statusCode != 200) {
    throw Exception('Failed to download PDFium: $archiveUri');
  }

  final archive = TarDecoder().decodeBytes(
    GZipDecoder().decodeBytes(response.bodyBytes),
  );
  final member = archive.findFile(target.archiveLibraryPath);
  if (member == null) {
    throw Exception(
      'PDFium archive $archiveUri does not contain ${target.archiveLibraryPath}.',
    );
  }

  await output.parent.create(recursive: true);
  await output.writeAsBytes(member.content as List<int>);
}

final class _PdfiumTarget {
  const _PdfiumTarget({
    required this.archivePlatform,
    required this.archiveArch,
    required this.archiveLibraryPath,
    required this.libraryFileName,
  });

  final String archivePlatform;
  final String archiveArch;
  final String archiveLibraryPath;
  final String libraryFileName;

  static _PdfiumTarget fromCodeConfig(CodeConfig config) {
    final arch = switch (config.targetArchitecture) {
      Architecture.ia32 => 'x86',
      Architecture.x64 => 'x64',
      Architecture.arm => 'arm',
      Architecture.arm64 => 'arm64',
      _ => throw UnsupportedError(
        'Unsupported PDFium architecture: ${config.targetArchitecture}',
      ),
    };

    return switch (config.targetOS) {
      OS.android => _PdfiumTarget(
        archivePlatform: 'android',
        archiveArch: arch,
        archiveLibraryPath: 'lib/libpdfium.so',
        libraryFileName: 'libpdfium.so',
      ),
      OS.windows => _PdfiumTarget(
        archivePlatform: 'win',
        archiveArch: arch,
        archiveLibraryPath: 'bin/pdfium.dll',
        libraryFileName: 'pdfium.dll',
      ),
      OS.linux => _PdfiumTarget(
        archivePlatform: 'linux',
        archiveArch: arch,
        archiveLibraryPath: 'lib/libpdfium.so',
        libraryFileName: 'libpdfium.so',
      ),
      OS.macOS => _PdfiumTarget(
        archivePlatform: 'mac',
        archiveArch: arch,
        archiveLibraryPath: 'lib/libpdfium.dylib',
        libraryFileName: 'libpdfium.dylib',
      ),
      _ => throw UnsupportedError(
        'Unsupported PDFium platform: ${config.targetOS}',
      ),
    };
  }
}
