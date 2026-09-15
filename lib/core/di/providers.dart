import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import '../settings/app_settings.dart';
import '../storage/font_storage.dart';
import '../storage/import_service.dart';
import '../../data/datasources/file_system_datasource.dart';
import '../../data/datasources/local_database_datasource.dart';
import '../../data/repositories/folder_repository.dart';
import '../../data/repositories/font_repository.dart';
import '../../data/repositories/import_repository.dart';
import '../../data/repositories/memo_repository.dart';

/// 全局依赖注入（基础设施 + 仓库 + 设置）。
/// UI 只监听这里暴露的状态，不直接 new 数据库或操作文件系统。

// 在 main() 中 override 为已加载实例。
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('需在 main 中 override sharedPrefsProvider'),
);

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final fileSystemDatasourceProvider =
    Provider<FileSystemDatasource>((ref) => const FileSystemDatasource());

final localDbDatasourceProvider = Provider<LocalDatabaseDatasource>(
    (ref) => LocalDatabaseDatasource(ref.watch(appDatabaseProvider)));

final folderRepositoryProvider = Provider<FolderRepository>(
    (ref) => FolderRepository(ref.watch(localDbDatasourceProvider)));

final memoRepositoryProvider = Provider<MemoRepository>((ref) =>
    MemoRepository(ref.watch(localDbDatasourceProvider),
        ref.watch(fileSystemDatasourceProvider)));

final fontStorageProvider = Provider<FontStorage>(
    (ref) => FontStorage(ref.watch(fileSystemDatasourceProvider)));

final fontRepositoryProvider = Provider<FontRepository>((ref) =>
    FontRepository(ref.watch(localDbDatasourceProvider),
        ref.watch(fontStorageProvider)));

final importServiceProvider =
    Provider<ImportService>((ref) => const ImportService());

final importRepositoryProvider = Provider<ImportRepository>((ref) =>
    ImportRepository(
      ref.watch(memoRepositoryProvider),
      ref.watch(importServiceProvider),
      ref.watch(fileSystemDatasourceProvider),
    ));

/// 已导入字体列表（编辑器字体选择与字体管理页共用）。
final fontListProvider = StreamProvider(
    (ref) => ref.watch(fontRepositoryProvider).watchFonts());

// —————————————— 设置 ——————————————
class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(this._prefs) : super(const AppSettings()) {
    _load();
  }

  final SharedPreferences _prefs;

  void _load() {
    final modeName = _prefs.getString(AppSettings.kThemeMode);
    final mode = ThemeMode.values.firstWhere(
      (m) => m.name == modeName,
      orElse: () => ThemeMode.system,
    );
    state = AppSettings(
      themeMode: mode,
      useDynamicColor: _prefs.getBool(AppSettings.kDynamic) ?? true,
      seedColorValue: _prefs.getInt(AppSettings.kSeed),
      lineHeight: (_prefs.getDouble(AppSettings.kLineHeight) ?? 1.7)
          .clamp(1.2, 2.2),
      paragraphSpacing:
          (_prefs.getDouble(AppSettings.kParagraphSpacing) ?? 10.0)
              .clamp(0.0, 32.0),
      sortField: _prefs.getString(AppSettings.kSortField) ?? 'updatedAt',
      sortAscending: _prefs.getBool(AppSettings.kSortAsc) ?? false,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setString(AppSettings.kThemeMode, mode.name);
  }

  Future<void> setDynamicColor(bool value) async {
    state = state.copyWith(useDynamicColor: value);
    await _prefs.setBool(AppSettings.kDynamic, value);
  }

  Future<void> setSeedColor(int? value) async {
    state = state.copyWith(seedColorValue: () => value);
    if (value == null) {
      await _prefs.remove(AppSettings.kSeed);
    } else {
      await _prefs.setInt(AppSettings.kSeed, value);
    }
  }

  Future<void> setLineHeight(double value) async {
    final v = value.clamp(1.2, 2.2);
    state = state.copyWith(lineHeight: v);
    await _prefs.setDouble(AppSettings.kLineHeight, v);
  }

  Future<void> setParagraphSpacing(double value) async {
    final v = value.clamp(0.0, 32.0);
    state = state.copyWith(paragraphSpacing: v);
    await _prefs.setDouble(AppSettings.kParagraphSpacing, v);
  }

  Future<void> setSort(String field, bool ascending) async {
    state = state.copyWith(sortField: field, sortAscending: ascending);
    await _prefs.setString(AppSettings.kSortField, field);
    await _prefs.setBool(AppSettings.kSortAsc, ascending);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>(
        (ref) => SettingsNotifier(ref.watch(sharedPrefsProvider)));

/// 便捷：只监听主题模式。
final themeModeProvider = Provider<ThemeMode>(
    (ref) => ref.watch(settingsProvider.select((s) => s.themeMode)));
