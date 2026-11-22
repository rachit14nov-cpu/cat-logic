abstract class CloudSaveService {
  Future<Map<String, Object?>?> pull();

  Future<void> push(Map<String, Object?> data);
}

class NoopCloudSaveService implements CloudSaveService {
  @override
  Future<Map<String, Object?>?> pull() async => null;

  @override
  Future<void> push(Map<String, Object?> data) async {}
}
