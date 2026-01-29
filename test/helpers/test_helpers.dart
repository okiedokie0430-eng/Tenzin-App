import 'package:flutter_test/flutter_test.dart';

/// Тест туслах функцууд / Test helper functions

/// Mock класс бүртгэлийн туслагч
void registerFallbackValues() {
  // Энд fallback values бүртгэнэ
  // Register fallback values here
}

/// Тест хугацааг симуляц хийх
class FakeClock {
  DateTime _now;

  FakeClock([DateTime? initialTime]) : _now = initialTime ?? DateTime.now();

  DateTime get now => _now;

  void advance(Duration duration) {
    _now = _now.add(duration);
  }

  void set(DateTime time) {
    _now = time;
  }
}

/// Тест өгөгдөл үүсгэгч / Test data generators
class TestData {
  static int _idCounter = 0;

  static String generateId([String prefix = 'test']) {
    _idCounter++;
    return '${prefix}_$_idCounter';
  }

  static void resetCounter() {
    _idCounter = 0;
  }

  static DateTime get now => DateTime.now();

  static DateTime daysAgo(int days) => now.subtract(Duration(days: days));

  static DateTime minutesAgo(int minutes) =>
      now.subtract(Duration(minutes: minutes));
}

/// Хүлээх туслагч / Wait helper
Future<void> waitFor(
  Future<bool> Function() condition, {
  Duration timeout = const Duration(seconds: 5),
  Duration interval = const Duration(milliseconds: 100),
}) async {
  final deadline = DateTime.now().add(timeout);

  while (DateTime.now().isBefore(deadline)) {
    if (await condition()) return;
    await Future.delayed(interval);
  }

  throw TimeoutException('Condition not met within $timeout');
}

class TimeoutException implements Exception {
  final String message;

  TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}

/// Matcher туслагч / Matcher helpers
Matcher isWithinSeconds(DateTime expected, int seconds) {
  return predicate<DateTime>((actual) {
    final diff = actual.difference(expected).abs();
    return diff.inSeconds <= seconds;
  }, 'is within $seconds seconds of $expected');
}

Matcher isWithinMinutes(DateTime expected, int minutes) {
  return predicate<DateTime>((actual) {
    final diff = actual.difference(expected).abs();
    return diff.inMinutes <= minutes;
  }, 'is within $minutes minutes of $expected');
}
