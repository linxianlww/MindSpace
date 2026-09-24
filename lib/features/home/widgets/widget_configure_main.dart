// 小组件配置页 Flutter 入口（独立 Flutter 引擎 / isolate）。
//
// 被 Android 原生 *WidgetConfigureActivity 通过自定义 DartEntrypoint 启动。
// 不启动完整 App，只渲染一个轻量配置页：
//   - MemoryListWidgetConfigureActivity → 文件夹选择页
//   - TodoListWidgetConfigureActivity   → 待办铭记选择页
//   - MediaCarouselWidgetConfigureActivity → 媒体集选择页
//
// 选择完成后：
//   1. 通过原生 MethodChannel 写入小组件显示数据至 HomeWidgetPreferences 文件
//   2. 通知原生 Activity 设置 RESULT_OK 并 finish，完成小组件添加
//
// 关键：配置页运行在独立引擎，MethodChannel("neko.box/widget") 必须由配置
// Activity 也注册（见 WidgetChannelRegistrar），否则数据保存会静默失败。

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/di/providers.dart';
import '../../../core/storage/mindspace_storage.dart';
import '../../../data/models/folder.dart';
import '../../../data/models/memo.dart';
import '../../../data/models/memo_type.dart';
import '../../memo_todo/todo_model.dart';
import 'native_home_widget_service.dart';

/// 小组件配置页 Dart 入口函数。
/// 必须是顶层函数且标注 @pragma('vm:entry-point')，确保 AOT 编译时保留。
@pragma('vm:entry-point')
Future<void> configureMain() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await MindspaceStorage.instance.init();
    final prefs = await SharedPreferences.getInstance();
    final configureWidgetId = prefs.getInt('flutter.appWidgetId');

    if (configureWidgetId == null) {
      // 未取到 widget id：展示可取消的错误页，绝不停在空白页——
      // 空白页会让启动器的“添加小组件”流程永久等待 Activity Result。
      runApp(const _ConfigFatalApp(message: '未获取到小组件 ID'));
      return;
    }

    final widgetClassName = prefs.getString('flutter.widgetClassName') ?? '';
    // 消费一次，避免下次配置读到旧值
    await prefs.remove('flutter.appWidgetId');
    await prefs.remove('flutter.widgetClassName');

    Widget page;
    if (widgetClassName.endsWith('MemoryListWidgetConfigureActivity')) {
      page = const MemoryListConfigView();
    } else if (widgetClassName.endsWith('TodoListWidgetConfigureActivity')) {
      page = const TodoListConfigView();
    } else if (widgetClassName.endsWith('MediaCarouselWidgetConfigureActivity')) {
      page = const MediaCarouselConfigView();
    } else {
      runApp(const _ConfigFatalApp(message: '未知的小组件类型'));
      return;
    }

    runApp(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
        ],
        child: WidgetConfigureApp(child: page),
      ),
    );
  } catch (e, st) {
    // 初始化失败（存储/数据库打开失败等）：给出可取消界面，避免启动器卡死。
    runApp(_ConfigFatalApp(message: '初始化失败：$e', stackTrace: st));
  }
}

/// 致命错误兜底页：允许用户取消配置（通知原生 setResult(RESULT_CANCELED)+finish）。
class _ConfigFatalApp extends StatelessWidget {
  const _ConfigFatalApp({required this.message, this.stackTrace});

  final String message;
  final StackTrace? stackTrace;

  Future<void> _cancel() async {
    try {
      await const MethodChannel('neko.box/widget_config').invokeMethod('cancel');
    } catch (_) {
      // 通道不可用时退出引擎页面
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF6750A4),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF6750A4),
        useMaterial3: true,
        brightness: Brightness.dark,

      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('小组件配置')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _cancel,
                child: const Text('取消并返回'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 小组件配置 App 外壳
class WidgetConfigureApp extends StatelessWidget {
  final Widget child;
  const WidgetConfigureApp({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF6750A4),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF6750A4),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: child,
    );
  }
}

// ============================================================
// 铭记列表小组件配置：选择文件夹
// ============================================================

class MemoryListConfigView extends ConsumerStatefulWidget {
  const MemoryListConfigView({super.key});

  @override
  ConsumerState<MemoryListConfigView> createState() => _MemoryListConfigViewState();
}

class _MemoryListConfigViewState extends ConsumerState<MemoryListConfigView> {
  late Future<List<Folder>> _foldersFuture;

  @override
  void initState() {
    super.initState();
    _foldersFuture = ref.read(folderRepositoryProvider).allFolders();
  }

  void _retry() {
    setState(() {
      _foldersFuture = ref.read(folderRepositoryProvider).allFolders();
    });
  }

  Future<void> _onFolderSelected(Folder folder) async {
    final memoRepo = ref.read(memoRepositoryProvider);
    // 根目录用 null 表示（Folder 占位 id 为空字符串）。
    final folderId = folder.id.isEmpty ? null : folder.id;
    final memos = (await memoRepo.watchByFolder(folderId).first).take(30).toList();

    final items = memos
        .map((m) => {
              'id': m.id,
              'type': m.type.wire,
              'title': m.title,
              'subtitle': _subtitleOf(m),
              'color': m.color ?? 0,
            })
        .toList();

    final bridge = NativeHomeWidgetService.instance;
    await bridge.saveWidgetData('folderId', folder.id);
    await bridge.saveWidgetData('folderName', folder.name);
    // 通道只接受字符串，列表必须 JSON 编码（原生侧按 JSON 解析）。
    await bridge.saveWidgetData('memosJson', jsonEncode(items));
    await bridge.updateWidget(className: 'MemoryListWidgetProvider');
    await _notifyConfigComplete();
  }

  String _subtitleOf(Memo m) {
    switch (m.type) {
      case MemoType.text:
        return (m.remark?.isNotEmpty ?? false) ? m.remark! : '文本铭记';
      case MemoType.todo:
        return '待办';
      case MemoType.media:
        return '媒体集';
      case MemoType.audio:
        return '音频';
      case MemoType.file:
        return '文件';
      case MemoType.totp:
        return 'TOTP';
      case MemoType.anniversary:
        return '纪念日';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('选择文件夹')),
      body: FutureBuilder<List<Folder>>(
        future: _foldersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ConfigErrorView(
              message: '文件夹加载失败：${snapshot.error}',
              onRetry: _retry,
            );
          }
          final folders = snapshot.data ?? [];
          return ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: const Text('根目录'),
                onTap: () => _onFolderSelected(
                  const Folder(
                    id: '',
                    name: '根目录',
                    createdAt: 0,
                    updatedAt: 0,
                    sortOrder: 0,
                  ),
                ),
              ),
              ...folders.map((f) => ListTile(
                    leading: const Icon(Icons.folder_outlined),
                    title: Text(f.name),
                    onTap: () => _onFolderSelected(f),
                  )),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================
// 待办列表小组件配置：选择待办铭记
// ============================================================

class TodoListConfigView extends ConsumerStatefulWidget {
  const TodoListConfigView({super.key});

  @override
  ConsumerState<TodoListConfigView> createState() => _TodoListConfigViewState();
}

class _TodoListConfigViewState extends ConsumerState<TodoListConfigView> {
  late Future<List<Memo>> _todosFuture;

  @override
  void initState() {
    super.initState();
    _todosFuture = ref.read(memoRepositoryProvider).activeByType(MemoType.todo);
  }

  void _retry() {
    setState(() {
      _todosFuture = ref.read(memoRepositoryProvider).activeByType(MemoType.todo);
    });
  }

  Future<void> _onTodoSelected(Memo memo) async {
    // 待办条目以 content.todo.json 文件为准（与 TodoEditorNotifier 同一套读写）。
    final storage = MindspaceStorage.instance;
    final fs = ref.read(fileSystemDatasourceProvider);
    final dir = storage.memoDir(memoId: memo.id, folderId: memo.folderId);
    final todoPath = p.join(dir, 'content.todo.json');
    List<TodoItem> todoItems = const [];
    try {
      if (fs.exists(todoPath)) {
        final raw = await fs.readString(todoPath);
        todoItems = TodoItem.listFromJson(raw);
      }
    } catch (_) {
      // 文件缺失/损坏：按空待办处理
    }

    final items = todoItems
        .map((t) => {
              'id': t.id,
              'text': t.text,
              'checked': t.checked,
            })
        .toList();

    final bridge = NativeHomeWidgetService.instance;
    await bridge.saveWidgetData('todoMemoId', memo.id);
    await bridge.saveWidgetData('todoTitle', memo.title);
    await bridge.saveWidgetData('todoFilePath', todoPath);
    await bridge.saveWidgetData('todoJson', jsonEncode(items));
    await bridge.updateWidget(className: 'TodoListWidgetProvider');
    await _notifyConfigComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('选择待办铭记')),
      body: FutureBuilder<List<Memo>>(
        future: _todosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ConfigErrorView(
              message: '待办加载失败：${snapshot.error}',
              onRetry: _retry,
            );
          }
          final todos = snapshot.data ?? [];
          if (todos.isEmpty) {
            return const Center(child: Text('暂无待办铭记'));
          }
          return ListView(
            children: todos
                .map((m) => ListTile(
                      leading: const Icon(Icons.check_box_outlined),
                      title: Text(m.title.isEmpty ? '无标题' : m.title),
                      subtitle: const Text('待办'),
                      onTap: () => _onTodoSelected(m),
                    ))
                .toList(),
          );
        },
      ),
    );
  }
}

// ============================================================
// 媒体轮播小组件配置：选择媒体集
// ============================================================

class MediaCarouselConfigView extends ConsumerStatefulWidget {
  const MediaCarouselConfigView({super.key});

  @override
  ConsumerState<MediaCarouselConfigView> createState() =>
      _MediaCarouselConfigViewState();
}

class _MediaCarouselConfigViewState
    extends ConsumerState<MediaCarouselConfigView> {
  late Future<List<Memo>> _mediaFuture;

  @override
  void initState() {
    super.initState();
    _mediaFuture = ref.read(memoRepositoryProvider).activeByType(MemoType.media);
  }

  void _retry() {
    setState(() {
      _mediaFuture = ref.read(memoRepositoryProvider).activeByType(MemoType.media);
    });
  }

  Future<void> _onMediaSelected(Memo memo) async {
    // 媒体条目存于数据库（assets DAO），图片文件路径为 MediaItem.path。
    final mediaItems = await ref.read(memoRepositoryProvider).mediaOf(memo.id);
    final imageItems =
        mediaItems.where((m) => m.kind == MediaKind.image).toList();

    final items = imageItems
        .map((m) => {
              'path': m.path,
              'fileName': p.basename(m.path),
              'kind': m.kind.wire,
            })
        .toList();

    final bridge = NativeHomeWidgetService.instance;
    await bridge.saveWidgetData('mediaMemoId', memo.id);
    await bridge.saveWidgetData('mediaMemoTitle', memo.title);
    await bridge.saveWidgetData('imagePaths', jsonEncode(items));
    await bridge.updateWidget(className: 'MediaCarouselWidgetProvider');
    await _notifyConfigComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('选择媒体集')),
      body: FutureBuilder<List<Memo>>(
        future: _mediaFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ConfigErrorView(
              message: '媒体集加载失败：${snapshot.error}',
              onRetry: _retry,
            );
          }
          final media = snapshot.data ?? [];
          if (media.isEmpty) {
            return const Center(child: Text('暂无媒体集'));
          }
          return ListView(
            children: media
                .map((m) => ListTile(
                      leading: const Icon(Icons.perm_media_outlined),
                      title: Text(m.title.isEmpty ? '无标题' : m.title),
                      subtitle: const Text('媒体集'),
                      onTap: () => _onMediaSelected(m),
                    ))
                .toList(),
          );
        },
      ),
    );
  }
}

/// 配置页通用错误视图：提供“重试”和“取消”，避免永久停在 loading。
class _ConfigErrorView extends StatelessWidget {
  const _ConfigErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  Future<void> _cancel() async {
    try {
      await const MethodChannel('neko.box/widget_config').invokeMethod('cancel');
    } catch (_) {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 40, color: Colors.grey),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(onPressed: _cancel, child: const Text('取消')),
                const SizedBox(width: 12),
                FilledButton(onPressed: onRetry, child: const Text('重试')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 通知原生配置完成：setResult(RESULT_OK) + finish
Future<void> _notifyConfigComplete() async {
  try {
    await const MethodChannel('neko.box/widget_config')
        .invokeMethod('finishWithSuccess');
  } catch (e) {
    // 兜底：通道异常时直接关闭配置引擎页面
    SystemNavigator.pop();
  }
}
