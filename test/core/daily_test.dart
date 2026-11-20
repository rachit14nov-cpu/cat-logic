import 'package:cat_logic/core/daily.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the same calendar date always picks the same puzzle', () {
    final first = DateTime(2026, 11, 20, 8, 30);
    final later = DateTime(2026, 11, 20, 23, 5);
    expect(dailyIndex(first, 420), dailyIndex(later, 420));
    expect(dailyIndex(DateTime(2026, 11, 21), 420), isNot(dailyIndex(first, 420)));
    expect(dailyIndex(DateTime(2026, 1, 1), 420), 0);
  });

  test('a streak grows across consecutive days and a hint is not an input', () {
    var streak = const DailyStreak(count: 0, lastCompleted: null);
    streak = streak.recordCompletion(DateTime(2026, 11, 18));
    expect(streak.count, 1);
    final usedHint = true;
    streak = streak.recordCompletion(DateTime(2026, 11, 19));
    expect(usedHint, isTrue);
    expect(streak.count, 2);
    final again = streak.recordCompletion(DateTime(2026, 11, 19, 21));
    expect(again.count, 2);
    final afterGap = streak.recordCompletion(DateTime(2026, 11, 21));
    expect(afterGap.count, 1);
    expect(streak.visibleOn(DateTime(2026, 11, 19)), 2);
    expect(streak.visibleOn(DateTime(2026, 11, 25)), 0);
  });
}