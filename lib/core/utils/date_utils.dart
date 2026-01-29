class AppDateUtils {
  AppDateUtils._();

  static DateTime now() => DateTime.now();

  static int nowTimestamp() => DateTime.now().millisecondsSinceEpoch;

  static DateTime fromTimestamp(int timestamp) =>
      DateTime.fromMillisecondsSinceEpoch(timestamp);

  static int toTimestamp(DateTime dateTime) => dateTime.millisecondsSinceEpoch;

  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}ө ${duration.inHours % 24}ц';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}ц ${duration.inMinutes % 60}м';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}м ${duration.inSeconds % 60}с';
    } else {
      return '${duration.inSeconds}с';
    }
  }

  static String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years жилийн өмнө';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months сарын өмнө';
    } else if (difference.inDays > 7) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks долоо хоногийн өмнө';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} өдрийн өмнө';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} цагийн өмнө';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} минутын өмнө';
    } else {
      return 'Дөнгөж сая';
    }
  }

  static String formatDate(DateTime dateTime) {
    return '${dateTime.year}-${_padZero(dateTime.month)}-${_padZero(dateTime.day)}';
  }

  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} ${_padZero(dateTime.hour)}:${_padZero(dateTime.minute)}';
  }

  static String _padZero(int value) => value.toString().padLeft(2, '0');

  static DateTime getWeekStart(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    final monday = date.subtract(Duration(days: daysFromMonday));
    return DateTime(monday.year, monday.month, monday.day);
  }

  static DateTime getWeekEnd(DateTime date) {
    final weekStart = getWeekStart(date);
    return weekStart.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
  }

  static Duration timeUntilWeekReset() {
    final now = DateTime.now();
    final nextMonday = getWeekStart(now).add(const Duration(days: 7));
    return nextMonday.difference(now);
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool isToday(DateTime date) => isSameDay(date, DateTime.now());

  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }

  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return to.difference(from).inDays;
  }

  static int calculateHeartsToRegenerate(
    int currentHearts,
    int maxHearts,
    DateTime lastRegenerationAt,
    int regenerationMinutes,
  ) {
    if (currentHearts >= maxHearts) return 0;
    
    final now = DateTime.now();
    final elapsed = now.difference(lastRegenerationAt);
    final heartsToAdd = elapsed.inMinutes ~/ regenerationMinutes;
    
    return (currentHearts + heartsToAdd).clamp(0, maxHearts) - currentHearts;
  }

  static Duration timeUntilNextHeart(
    DateTime lastRegenerationAt,
    int regenerationMinutes,
  ) {
    final now = DateTime.now();
    final nextRegeneration = lastRegenerationAt.add(
      Duration(minutes: regenerationMinutes),
    );
    
    if (nextRegeneration.isBefore(now)) {
      final elapsed = now.difference(lastRegenerationAt).inMinutes;
      final minutesSinceLastRegen = elapsed % regenerationMinutes;
      final minutesUntilNext = regenerationMinutes - minutesSinceLastRegen;
      return Duration(minutes: minutesUntilNext);
    }
    
    return nextRegeneration.difference(now);
  }
}
