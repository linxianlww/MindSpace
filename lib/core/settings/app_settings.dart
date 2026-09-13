import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../theme/md3e_tokens.dart';

/// 应用设置（主题模式、动态取色、种子色、列表排序）。不可变。
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.useDynamicColor = true,
    this.seedColorValue,
    this.sortField = 'updatedAt',
    this.sortAscending = false,
  });

  final ThemeMode themeMode;
  final bool useDynamicColor;
  final int? seedColorValue;
  final String sortField;
  final bool sortAscending;

  Color get seedColor => seedColorValue != null
      ? Color(seedColorValue!)
      : Md3eTokens.seedPalette['靛蓝']!;

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? useDynamicColor,
    int? Function()? seedColorValue,
    String? sortField,
    bool? sortAscending,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      useDynamicColor: useDynamicColor ?? this.useDynamicColor,
      seedColorValue:
          seedColorValue != null ? seedColorValue() : this.seedColorValue,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }

  /// SharedPreferences 键集中处。
  static const kThemeMode = AppConstants.prefThemeMode;
  static const kDynamic = AppConstants.prefDynamicColor;
  static const kSeed = AppConstants.prefSeedColor;
  static const kSortField = AppConstants.prefSortField;
  static const kSortAsc = AppConstants.prefSortAsc;
}
