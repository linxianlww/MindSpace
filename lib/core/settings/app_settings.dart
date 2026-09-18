import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../theme/md3e_tokens.dart';

/// 应用设置（主题模式、动态取色、种子色、列表排序）。不可变。
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.useDynamicColor = true,
    this.seedColorValue,
    this.lineHeight = 1.7,
    this.paragraphSpacing = 10,
    this.shareImageWatermarkSuffix = AppConstants.defaultShareImageSuffix,
    this.sortField = 'updatedAt',
    this.sortAscending = false,
  });

  final ThemeMode themeMode;
  final bool useDynamicColor;
  final int? seedColorValue;

  /// 文本阅读/分享长图的行距（字号倍数）。
  final double lineHeight;

  /// 文本阅读/分享长图的段间距（逻辑像素）。
  final double paragraphSpacing;

  /// 长图末尾水印后缀（「分享自 ___」），用户可在「文本排版」设置中自定义。
  final String shareImageWatermarkSuffix;

  final String sortField;
  final bool sortAscending;

  /// 当前生效的种子色：用户通过取色器/预设自定义则用其 HEX，否则用品牌亮橙。
  Color get seedColor => seedColorValue != null
      ? Color(seedColorValue!)
      : Md3eTokens.brandSeed;

  /// MD3E 双种子取色的次种子色：仅在品牌默认配色（未自定义）时启用红色，
  /// 用户自定义单一种子时不启用。
  Color? get secondarySeedColor =>
      seedColorValue == null ? Md3eTokens.brandSecondarySeed : null;

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? useDynamicColor,
    int? Function()? seedColorValue,
    double? lineHeight,
    double? paragraphSpacing,
    String? shareImageWatermarkSuffix,
    String? sortField,
    bool? sortAscending,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      useDynamicColor: useDynamicColor ?? this.useDynamicColor,
      seedColorValue:
          seedColorValue != null ? seedColorValue() : this.seedColorValue,
      lineHeight: lineHeight ?? this.lineHeight,
      paragraphSpacing: paragraphSpacing ?? this.paragraphSpacing,
      shareImageWatermarkSuffix:
          shareImageWatermarkSuffix ?? this.shareImageWatermarkSuffix,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }

  /// SharedPreferences 键集中处。
  static const kThemeMode = AppConstants.prefThemeMode;
  static const kDynamic = AppConstants.prefDynamicColor;
  static const kSeed = AppConstants.prefSeedColor;
  static const kLineHeight = AppConstants.prefLineHeight;
  static const kParagraphSpacing = AppConstants.prefParagraphSpacing;
  static const kShareImageSuffix = AppConstants.prefShareImageSuffix;
  static const kSortField = AppConstants.prefSortField;
  static const kSortAsc = AppConstants.prefSortAsc;
}
