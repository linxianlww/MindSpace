import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/di/providers.dart';
import '../../../core/storage/mindspace_storage.dart';
import '../../../core/utils/ms_date_utils.dart';
import '../../../data/models/memo.dart';
import '../../../data/models/memo_type.dart';
import '../../memo_todo/todo_model.dart';
import 'native_home_widget_service.dart';

/// 小组件名称常量（AndroidManifest 中注册的 Provider 类名，不含包前缀）
class WidgetNames {
  static const quickActions = 'QuickActionsWidgetProvider';
  static const memoryList = 'MemoryListWidgetProvider';
  static const todoList = 'TodoListWidgetProvider';
  static const mediaCarousel = 'MediaCarouselWidgetProvider';
}

/// 小组件同步服务：将 Flutter 数据同步到 Android 小组件。
///
/// 底层通信：MethodChannel("neko.box/widget") → MainActivity（Kotlin）
/// 数据存储：SharedPreferences("HomeWidgetPreferences")
class HomeWidgetService {
  HomeWidgetService(this._ref);

  final Ref _ref;

  /// 同步铭记列表小组件数据
  Future<void> syncMemoryList(String? folderId) async {
    try {
      final memoRepo = _ref.read(memoRepositoryProvider);
      final folderRepo = _ref.read(folderRepositoryProvider);

      String folderName = '根目录';
      if (folderId != null) {
        final folder = await folderRepo.findById(folderId);
        if (folder != null) folderName = folder.name;
      }

      final memos = await memoRepo
          .watchByFolder(folderId, sortField: 'updatedAt', ascending: false)
          .first;

      final memoItems = memos
          .where((m) => !m.isDeleted)
          .map((m) => _MemoWidgetItem.fromMemo(m))
          .toList();

      final bridge = NativeHomeWidgetService.instance;
      await bridge.saveWidgetData('folderId', folderId ?? '');
      await bridge.saveWidgetData('folderName', folderName);
      await bridge.saveWidgetData(
        'memosJson',
        jsonEncode(memoItems.map((e) => e.toJson()).toList()),
      );
      await bridge.updateWidget(className: WidgetNames.memoryList);
    } catch (e) {
      debugPrint('syncMemoryList error: $e');
    }
  }

  /// 同步待办列表小组件数据
  Future<void> syncTodoList(String memoId) async {
    try {
      final memoRepo = _ref.read(memoRepositoryProvider);
      final memo = await memoRepo.findById(memoId);
      if (memo == null || memo.type != MemoType.todo) return;

      final items = await _loadTodoItems(memoId);

      // 计算 todo JSON 文件在磁盘上的绝对路径
      final todoFilePath = p.join(
        MindspaceStorage.instance.memoDir(
          memoId: memo.id,
          folderId: memo.folderId,
        ),
        'content.todo.json',
      );

      final bridge = NativeHomeWidgetService.instance;
      await bridge.saveWidgetData('todoMemoId', memoId);
      await bridge.saveWidgetData('todoTitle', memo.title);
      await bridge.saveWidgetData('todoFilePath', todoFilePath);
      await bridge.saveWidgetData(
        'todoJson',
        jsonEncode(items.map((e) => {
          'id': e.id,
          'text': e.text,
          'checked': e.checked,
          'sortOrder': e.sortOrder,
        }).toList()),
      );
      await bridge.updateWidget(className: WidgetNames.todoList);
    } catch (e) {
      debugPrint('syncTodoList error: $e');
    }
  }

  Future<List<TodoItem>> _loadTodoItems(String memoId) async {
    try {
      final memoRepo = _ref.read(memoRepositoryProvider);
      final memo = await memoRepo.findById(memoId);
      if (memo == null || memo.type != MemoType.todo) return [];
      final todoJson = memo.metadata['todoItems'];
      if (todoJson is String && todoJson.isNotEmpty) {
        return TodoItem.listFromJson(todoJson);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> toggleTodoItem(String memoId, String itemId) async {
    try {
      final memoRepo = _ref.read(memoRepositoryProvider);
      final memo = await memoRepo.findById(memoId);
      if (memo == null) return;

      final items = await _loadTodoItems(memoId);
      final index = items.indexWhere((e) => e.id == itemId);
      if (index < 0) return;

      items[index] = items[index].copyWith(checked: !items[index].checked);

      await memoRepo.save(memo.copyWith(metadata: {
        ...memo.metadata,
        'todoItems': jsonEncode(items.map((e) => e.toJson()).toList()),
      }));

      await syncTodoList(memoId);
    } catch (e) {
      debugPrint('toggleTodoItem error: $e');
    }
  }

  /// 同步媒体集轮播小组件数据
  Future<void> syncMediaCarousel(String memoId) async {
    try {
      final memoRepo = _ref.read(memoRepositoryProvider);
      final memo = await memoRepo.findById(memoId);
      if (memo == null) return;

      final mediaItems = await memoRepo.mediaOf(memoId);
      final imagePaths = mediaItems
          .where((e) => e.kind == MediaKind.image && e.path.isNotEmpty)
          .map((e) => e.path)
          .join(',');

      final bridge = NativeHomeWidgetService.instance;
      await bridge.saveWidgetData('mediaMemoId', memoId);
      await bridge.saveWidgetData('mediaMemoTitle', memo.title);
      await bridge.saveWidgetData('imagePaths', imagePaths);
      await bridge.saveWidgetData('currentImageIndex', '0');
      await bridge.updateWidget(className: WidgetNames.mediaCarousel);
    } catch (e) {
      debugPrint('syncMediaCarousel error: $e');
    }
  }

  /// 更新快捷操作小组件（仅触发刷新）
  Future<void> updateQuickActions() async {
    await NativeHomeWidgetService.instance.updateWidget(
      className: WidgetNames.quickActions,
    );
  }
}

/// 铭记小组件条目数据
class _MemoWidgetItem {
  final String id;
  final String type;
  final String title;
  final String subtitle;
  final int color;
  final String? thumbPath;

  _MemoWidgetItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    this.color = 0,
    this.thumbPath,
  });

  factory _MemoWidgetItem.fromMemo(Memo memo) {
    return _MemoWidgetItem(
      id: memo.id,
      type: memo.type.wire,
      title: memo.title,
      subtitle: _subtitleFor(memo),
      color: memo.color ?? 0,
      thumbPath: memo.thumbnailPath,
    );
  }

  static String _subtitleFor(Memo memo) {
    switch (memo.type) {
      case MemoType.text:
        return memo.metadata['excerpt']?.toString() ?? '文本铭记';
      case MemoType.media:
        final count = memo.metadata['count'];
        return count == null ? '媒体集' : '$count 个媒体';
      case MemoType.audio:
        final dur = memo.metadata['durationMs'] as int?;
        return dur == null ? '音频铭记' : '时长 ${MsDateUtils.formatDuration(dur)}';
      default:
        return MsDateUtils.format(memo.updatedAt);
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'subtitle': subtitle,
        'color': color,
        'thumbPath': thumbPath ?? '',
      };
}
