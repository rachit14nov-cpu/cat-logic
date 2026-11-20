/// Daily puzzles are indexed from this calendar date, in the device's local date.
final DateTime dailyEpoch = DateTime(2026, 1, 1);

int dailyIndex(DateTime date, int length, {DateTime? epoch}) {
  if (length <= 0) {
    throw ArgumentError.value(length, 'length', 'must be positive');
  }
  final start = epoch ?? dailyEpoch;
  final day = DateTime(date.year, date.month, date.day);
  final origin = DateTime(start.year, start.month, start.day);
  var delta = day.difference(origin).inDays % length;
  if (delta < 0) delta += length;
  return delta;
}

String isoDate(DateTime date) {
  final local = DateTime(date.year, date.month, date.day);
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

/// Streak bookkeeping. Hint use is deliberately not an input: a hint cannot
/// break, pause, or reset a streak.
class DailyStreak {
  const DailyStreak({required this.count, required this.lastCompleted});

  final int count;
  final String? lastCompleted;

  DailyStreak recordCompletion(DateTime now) {
    final today = isoDate(now);
    if (lastCompleted == today) {
      return this;
    }
    final yesterday = isoDate(now.subtract(const Duration(days: 1)));
    final next = lastCompleted == yesterday ? count + 1 : 1;
    return DailyStreak(count: next, lastCompleted: today);
  }

  int visibleOn(DateTime now) {
    final today = isoDate(now);
    final yesterday = isoDate(now.subtract(const Duration(days: 1)));
    if (lastCompleted == today || lastCompleted == yesterday) return count;
    return 0;
  }
}
