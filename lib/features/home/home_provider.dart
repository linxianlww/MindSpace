import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../core/di/providers.dart';
import '../../data/models/folder.dart';
import '../../data/models/memo.dart';

/// 主页 / 文件夹浏览共享状态。

/// 当前所在文件夹 id（null = 根目录）。
final currentFolderIdProvider = StateProvider<String?>((ref) => null);

/// 搜索关键字（空串表示不搜索）。
final searchKeywordProvider = StateProvider<String>((ref) => '');

/// 某父文件夹下的子文件夹列表（folderListProvider）。
///
/// 顶层列表（parentId == null）已自动排除私密空间入口文件夹，
/// UI 通过 [privateSpaceEntryProvider] 单独获取。
final folderListProvider =
    StreamProvider.family<List<Folder>, String?>((ref, parentId) {
  final repo = ref.watch(folderRepositoryProvider);
  if (parentId == null) {
    return repo.watchTopLevel();
  }
  return repo.watchChildren(parentId);
});

/// 某文件夹下的铭记列表（memoListProvider），排序跟随设置。
///
/// 私密空间根目录（folderId == kPrivateSpaceFolderId）调用 watchPrivateFolder
///（仅允许已解锁会话访问）；其他文件夹调用 watchByFolder（自动排除私密空间内容）。
final memoListProvider =
    StreamProvider.family<List<Memo>, String?>((ref, folderId) {
  final settings = ref.watch(settingsProvider);
  final keyword = ref.watch(searchKeywordProvider).trim();
  final repo = ref.watch(memoRepositoryProvider);
  if (keyword.isNotEmpty) return repo.watchSearch(keyword);
  if (folderId == kPrivateSpaceFolderId) {
    // 私密空间：仅当已解锁时才能查看（调用方在进入私密空间前已做 PIN 验证）
    return repo.watchPrivateFolder(
      folderId,
      sortField: settings.sortField,
      ascending: settings.sortAscending,
    );
  }
  return repo.watchByFolder(
    folderId,
    sortField: settings.sortField,
    ascending: settings.sortAscending,
  );
});

/// 单个铭记详情（memoDetailProvider）。
final memoDetailProvider =
    FutureProvider.family<Memo?, String>((ref, memoId) {
  return ref.watch(memoRepositoryProvider).findById(memoId);
});

/// 面包屑祖先链。
final breadcrumbProvider =
    FutureProvider.family<List<Folder>, String?>((ref, folderId) {
  return ref.watch(folderRepositoryProvider).ancestorChain(folderId);
});

/// 回收站。
final trashListProvider = StreamProvider<List<Memo>>(
    (ref) => ref.watch(memoRepositoryProvider).watchTrash());

/// 一言（hitokoto.cn）副标题：仅返回句子正文，失败时返回 null。
final hitokotoProvider = FutureProvider<String?>((ref) async {
  try {
    final resp = await http
        .get(Uri.parse('https://v1.hitokoto.cn/?c=a&encode=json'))
        .timeout(const Duration(seconds: 5));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final text = data['hitokoto'] as String?;
      if (text == null || text.isEmpty) return null;
      return text;
    }
  } catch (_) {
    // 网络不可达时静默失败，不显示副标题。
  }
  return null;
});

/// 前一次 currentFolderId（用于检测离开私密文件夹 → 触发锁定）。
final previousFolderIdProvider = StateProvider<String?>((ref) => null);
