import 'package:logger/logger.dart';

/// 统一日志实例。关键操作（导入、移动、删除、备份等）都通过它记录。
final AppLogger appLogger = AppLogger._();

class AppLogger {
  AppLogger._()
      : _logger = Logger(
          printer: PrettyPrinter(
            methodCount: 0,
            errorMethodCount: 8,
            lineLength: 80,
            colors: true,
            printEmojis: true,
            dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
          ),
          level: Level.debug,
        );

  final Logger _logger;

  void d(Object? message) => _logger.d(message);
  void i(Object? message) => _logger.i(message);
  void w(Object? message, [Object? error, StackTrace? stack]) =>
      _logger.w(message, error: error, stackTrace: stack);
  void e(Object? message, [Object? error, StackTrace? stack]) =>
      _logger.e(message, error: error, stackTrace: stack);
}
