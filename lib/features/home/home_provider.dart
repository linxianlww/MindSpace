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
final folderListProvider =
    StreamProvider.family<List<Folder>, String?>((ref, parentId) {
  return ref.watch(folderRepositoryProvider).watchChildren(parentId);
});

/// 某文件夹下的铭记列表（memoListProvider），排序跟随设置。
final memoListProvider =
    StreamProvider.family<List<Memo>, String?>((ref, folderId) {
  final settings = ref.watch(settingsProvider);
  final keyword = ref.watch(searchKeywordProvider).trim();
  final repo = ref.watch(memoRepositoryProvider);
  if (keyword.isNotEmpty) return repo.watchSearch(keyword);
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
