abstract class AnalyticsService {
  Future<void> logEvent(String name, [Map<String, Object>? params]);
}

class NoopAnalyticsService implements AnalyticsService {
  @override
  Future<void> logEvent(String name, [Map<String, Object>? params]) async {}
}
