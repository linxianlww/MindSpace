import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../data/models/folder.dart';

/// 单个文件夹实体。
final folderEntityProvider =
    FutureProvider.family<Folder?, String>((ref, folderId) {
  return ref.watch(folderRepositoryProvider).findById(folderId);
});

/// 文件夹内的子文件夹与铭记直接复用 home_provider 的 family：
/// - folderListProvider(folderId)
/// - memoListProvider(folderId)
