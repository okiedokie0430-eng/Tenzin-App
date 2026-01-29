import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

class AppLogger {
  AppLogger._();

  static bool _enabled = kDebugMode;
  static LogLevel _minLevel = LogLevel.debug;

  static void configure({bool? enabled, LogLevel? minLevel}) {
    if (enabled != null) _enabled = enabled;
    if (minLevel != null) _minLevel = minLevel;
  }

  static void debug(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.debug, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void info(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.info, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void warning(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.warning, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_enabled) return;
    if (level.index < _minLevel.index) return;

    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.name.toUpperCase().padRight(7);
    final tagStr = tag != null ? '[$tag] ' : '';
    
    final buffer = StringBuffer();
    buffer.writeln('$timestamp $levelStr $tagStr$message');
    
    if (error != null) {
      buffer.writeln('Error: $error');
    }
    
    if (stackTrace != null) {
      buffer.writeln('StackTrace: $stackTrace');
    }

    // In debug mode, use debugPrint for better formatting
    if (kDebugMode) {
      debugPrint(buffer.toString());
    }
  }

  static void logDatabase(String operation, String table, {Map<String, dynamic>? data}) {
    debug('DB: $operation on $table', tag: 'DATABASE');
    if (data != null && kDebugMode) {
      debug('Data: $data', tag: 'DATABASE');
    }
  }

  static void logSync(String message, {String? status}) {
    info('SYNC: $message ${status != null ? "[$status]" : ""}', tag: 'SYNC');
  }

  static void logAuth(String message) {
    info('AUTH: $message', tag: 'AUTH');
  }

  static void logNetwork(String method, String endpoint, {int? statusCode}) {
    debug('$method $endpoint ${statusCode != null ? "-> $statusCode" : ""}', tag: 'NETWORK');
  }

  static void logPerformance(String operation, Duration duration) {
    final ms = duration.inMilliseconds;
    final level = ms > 100 ? LogLevel.warning : LogLevel.debug;
    _log(level, 'PERF: $operation took ${ms}ms', tag: 'PERFORMANCE');
  }

  /// Log error with class and method context - for backward compatibility
  static void logError(String className, String methodName, Object e, {StackTrace? stackTrace}) {
    error('$className.$methodName: $e', tag: className, error: e, stackTrace: stackTrace);
  }

  /// Log warning with class and message context
  static void logWarning(String className, String message) {
    warning('$className: $message', tag: className);
  }

  /// Log info with class and message context
  static void logInfo(String className, String message) {
    info('$className: $message', tag: className);
  }
}
