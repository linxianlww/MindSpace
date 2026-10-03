import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

/// 应用设置（主题模式、文本排版、列表排序）。不可变。
/// 配色固定为 MIUIX 默认 HyperOS 蓝，无全局主题色设置。
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.lineHeight = 1.7,
    this.paragraphSpacing = 10,
    this.shareImageWatermarkSuffix = AppConstants.defaultShareImageSuffix,
    this.sortField = 'updatedAt',
    this.sortAscending = false,
  });

  final ThemeMode themeMode;

  /// 文本阅读/分享长图的行距（字号倍数）。
  final double lineHeight;

  /// 文本阅读/分享长图的段间距（逻辑像素）。
  final double paragraphSpacing;

  /// 长图末尾水印后缀（「分享自 ___」），用户可在「文本排版」设置中自定义。
  final String shareImageWatermarkSuffix;

  final String sortField;
  final bool sortAscending;

  AppSettings copyWith({
    ThemeMode? themeMode,
    double? lineHeight,
    double? paragraphSpacing,
    String? shareImageWatermarkSuffix,
    String? sortField,
    bool? sortAscending,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
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
  static const kLineHeight = AppConstants.prefLineHeight;
  static const kParagraphSpacing = AppConstants.prefParagraphSpacing;
  static const kShareImageSuffix = AppConstants.prefShareImageSuffix;
  static const kSortField = AppConstants.prefSortField;
  static const kSortAsc = AppConstants.prefSortAsc;
}
