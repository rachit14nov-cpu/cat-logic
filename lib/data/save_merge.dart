import 'progress.dart';

/// Keeps every finished puzzle and the larger hint wallet. Device preferences stay local.
ProgressData mergeProgress(ProgressData local, ProgressData? cloud) {
  if (cloud == null) return local;
  final completed = {...local.completed, ...cloud.completed};
  final best = Map<String, int>.from(local.bestMs);
  cloud.bestMs.forEach((id, time) {
    final current = best[id];
    if (current == null || time < current) best[id] = time;
  });
  final dailyBest = Map<String, int>.from(local.dailyBestMs);
  cloud.dailyBestMs.forEach((day, time) {
    final current = dailyBest[day];
    if (current == null || time < current) dailyBest[day] = time;
  });
  final localDay = local.lastDailyDate;
  final cloudDay = cloud.lastDailyDate;
  final useCloudStreak = cloudDay != null && (localDay == null || cloudDay.compareTo(localDay) > 0);
  return local.copyWith(
    completed: completed,
    bestMs: best,
    dailyBestMs: dailyBest,
    hintBalance: local.hintBalance > cloud.hintBalance ? local.hintBalance : cloud.hintBalance,
    removeAds: local.removeAds || cloud.removeAds,
    starterBundleClaimed: local.starterBundleClaimed || cloud.starterBundleClaimed,
    dailyStreak: useCloudStreak ? cloud.dailyStreak : local.dailyStreak,
    lastDailyDate: useCloudStreak ? cloudDay : localDay,
  );
}
