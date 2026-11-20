abstract class AnalyticsService {
  Future<void> logEvent(String name, [Map<String, Object>? params]);
}

class NoopAnalyticsService implements AnalyticsService {
  final List<String> events = [];

  @override
  Future<void> logEvent(String name, [Map<String, Object>? params]) async {
    events.add(name);
  }
}
