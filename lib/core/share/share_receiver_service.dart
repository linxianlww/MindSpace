import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../di/providers.dart';
import '../storage/mindspace_storage.dart';
import '../utils/app_logger.dart';
import '../utils/totp.dart';
import '../../data/models/memo.dart';
import '../../data/models/memo_type.dart';
import '../../data/repositories/import_repository.dart';
import '../../data/repositories/memo_repository.dart';
import '../../features/memo_totp/totp_provider.dart';

/// 分享/TOTP/文本选择事件——来自 Android native 的入站数据。
class ShareEvent {
  ShareEvent({required this.action, required this.data});

  /// process_text | send_text | send_file | send_multiple | view_totp
  final String action;
  final Map<String, dynamic> data;

  factory ShareEvent.fromMap(Map<dynamic, dynamic> map) {
    return ShareEvent(
      action: map['action'] as String? ?? 'unknown',
      data: Map<String, dynamic>.from(map),
    );
  }

  String get mimeType => (data['mime'] as String?) ?? '';
  String get uri => (data['uri'] as String?) ?? '';
  String get text => (data['text'] as String?) ?? '';
  String get title => (data['title'] as String?) ?? '';
  String get displayName => (data['displayName'] as String?) ?? '';
  String get subject => (data['subject'] as String?) ?? '';

  List<Map<String, dynamic>> get items =>
      (data['items'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
      [];
}

/// 处理 Android 平台发来的分享事件（冷启动 MethodChannel + 运行时 EventChannel 双通道）。
///
/// 收到一个 ShareEvent 后：
///   - process_text / send_text   → 创建文本铭记，直接写 content.delta.json
///   - send_file                  → 持久化 URI 后按 mime 调用 ImportRepository -> 媒体集/音频/文件铭记
///   - send_multiple              → 持久化多个 URIs 后 -> 媒体集
///   - view_totp                  → 解析 otpauth URI -> 创建 TOTP 铭记
///
/// 所有铭记保存到根目录（folderId = null）。
class ShareReceiverService {
  ShareReceiverService(this._importRepo, this._memoRepo);

  final ImportRepository _importRepo;
  final MemoRepository _memoRepo;

  StreamController<ShareEvent>? _controller;
  StreamSubscription? _eventSub;

  /// 启动监听。
  void start() {
    if (_controller != null) return;

    _controller = StreamController<ShareEvent>.broadcast();

    // 1. 冷启动：检查是否有上一进程留下的 pending share
    _checkInitialShare();

    // 2. 运行时：监听 EventChannel
    const eventChannel = EventChannel('neko.box/share/events');
    _eventSub = eventChannel.receiveBroadcastStream().listen((dynamic raw) {
      if (raw is Map) {
        _handleShareEvent(ShareEvent.fromMap(raw));
      }
    }, onError: (e) {
      appLogger.w('ShareReceiver EventChannel error', e);
    });

    // 业务层订阅：收到事件 -> 保存铭记
    _controller!.stream.listen(_handleShareEvent);
  }

  Future<void> _checkInitialShare() async {
    try {
      const methodChannel = MethodChannel('neko.box/share');
      final result = await methodChannel.invokeMethod<dynamic>('getInitialShare');
      if (result is Map) {
        final event = ShareEvent.fromMap(result);
        _controller?.add(event);
      }
    } on PlatformException catch (e) {
      appLogger.w('getInitialShare 失败', e);
    } catch (e) {
      appLogger.w('getInitialShare 未知错误', e);
    }
  }

  Future<void> _handleShareEvent(ShareEvent event) async {
    try {
      appLogger.i('ShareReceiver 收到: ${event.action}');
      switch (event.action) {
        case 'process_text':
        case 'send_text':
          await _saveTextMemo(event);
          break;
        case 'send_file':
          await _saveFileMemo(event);
          break;
        case 'send_multiple':
          await _saveMultipleMediaSet(event);
          break;
        case 'view_totp':
          await _saveTotpMemo(event);
          break;
        default:
          appLogger.w('未知 action: ${event.action}');
      }
    } catch (e, st) {
      appLogger.e('ShareReceiver 处理失败', e, st);
    }
  }

  // —— 文本铭记 ——
  Future<Memo?> _saveTextMemo(ShareEvent event) async {
    final content = event.text;
    if (content.isEmpty) {
      appLogger.w('ShareReceiver: 空文本忽略');
      return null;
    }
    final title = event.title.isNotEmpty ? event.title : _fallbackTitle(content);

    final memo = await _memoRepo.createBlank(
      MemoType.text,
      folderId: null,
      title: title,
    );
    final dir = MindspaceStorage.instance.memoDir(memoId: memo.id, folderId: null);
    MindspaceStorage.instance.ensureDir(dir);

    final deltaPath = p.join(dir, 'content.delta.json');
    await File(deltaPath).writeAsString(jsonEncode([{'insert': '$content\n'}]));

    final saved = await _memoRepo.save(memo.copyWith(
      metadata: {'filePath': deltaPath, 'sourceFormat': 'txt'},
    ));
    appLogger.i('文本铭记已保存: ${saved.title}');
    _savedMemoId = saved.id;
    return saved;
  }

  String _fallbackTitle(String content) {
    final firstLine = content.split('\n').firstWhere(
          (l) => l.trim().isNotEmpty,
          orElse: () => content,
        );
    final trimmed = firstLine.trim();
    return trimmed.length > 40 ? '${trimmed.substring(0, 40)}...' : trimmed;
  }

  // —— 单文件铭记 ——
  Future<Memo?> _saveFileMemo(ShareEvent event) async {
    final uri = event.uri;
    if (uri.isEmpty) return null;

    final String? localPath = await _persistUri(uri, event.displayName);
    if (localPath == null) {
      appLogger.w('ShareReceiver: 持久化 URI 失败 $uri');
      return null;
    }
    final memos = await _importRepo.importFiles([localPath], folderId: null);
    if (memos.isNotEmpty) {
      _savedMemoId = memos.last.id;
      appLogger.i('文件铭记已保存: ${memos.last.id}');
      return memos.last;
    }
    return null;
  }

  // —— 媒体集（多文件）——
  Future<Memo?> _saveMultipleMediaSet(ShareEvent event) async {
    final paths = <String>[];
    for (final item in event.items) {
      final uri = item['uri'] as String?;
      final displayName = item['displayName'] as String?;
      if (uri == null) continue;
      final path = await _persistUri(uri, displayName);
      if (path == null) continue;
      paths.add(path);
    }
    if (paths.isEmpty) {
      appLogger.w('ShareReceiver: 无有效媒体文件');
      return null;
    }
    final imported = await _importRepo.importFiles(paths, folderId: null);
    if (imported.isNotEmpty) {
      _savedMemoId = imported.last.id;
      appLogger.i('媒体集已保存: ${paths.length} items');
      return imported.last;
    }
    return null;
  }

  // —— TOTP 铭记 ——
  Future<Memo?> _saveTotpMemo(ShareEvent event) async {
    final uri = event.uri;
    if (uri.isEmpty) return null;

    final config = parseOtpauthUri(uri);
    if (config == null) {
      appLogger.w('ShareReceiver: 无效的 otpauth URI: $uri');
      return null;
    }

    final title = config.issuer.isNotEmpty && config.account.isNotEmpty
        ? '${config.issuer} · ${config.account}'
        : config.issuer.isNotEmpty
            ? config.issuer
            : config.account.isNotEmpty
                ? config.account
                : 'TOTP';

    final memo = await _memoRepo.createBlank(
      MemoType.totp,
      folderId: null,
      title: title,
    );
    final saved = await _memoRepo.save(memo.copyWith(
      metadata: {
        TotpKeys.secret: normalizeSecret(config.secret),
        TotpKeys.issuer: config.issuer.trim(),
        TotpKeys.account: config.account.trim(),
        TotpKeys.period: config.period,
        TotpKeys.digits: config.digits,
        TotpKeys.algorithm: config.algorithm,
      },
    ));
    _savedMemoId = saved.id;
    appLogger.i('TOTP 铭记已保存: ${saved.title}');
    return saved;
  }

  // —— Bottom：把 content:// URI 持久化到本地 ——
  Future<String?> _persistUri(String uri, String? suggestedName) async {
    try {
      const methodChannel = MethodChannel('neko.box/share');
      final result = await methodChannel.invokeMethod<String>(
        'persistUri',
        {'uri': uri, 'suggestedName': suggestedName},
      );
      return result;
    } on PlatformException catch (e) {
      appLogger.w('persistUri 失败', e);
      return null;
    }
  }

  String? _savedMemoId;
  String? consumeSavedMemoId() {
    final id = _savedMemoId;
    _savedMemoId = null;
    return id;
  }

  void dispose() {
    _eventSub?.cancel();
    _controller?.close();
    _controller = null;
  }
}

// —————————————— Providers ——————————————

final shareReceiverServiceProvider = Provider<ShareReceiverService>((ref) {
  final service = ShareReceiverService(
    ref.watch(importRepositoryProvider),
    ref.watch(memoRepositoryProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});
