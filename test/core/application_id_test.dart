import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the application id is com.tinybitlabs.catlogic and Android reads that file', () {
    final id = File('config/application_id.txt').readAsStringSync().trim();
    expect(id, 'com.tinybitlabs.catlogic');
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(gradle.contains("applicationIdFile"), isTrue);
    expect(gradle.contains('com.tinybitlabs.catlogic'), isFalse);
    expect(gradle.contains('com.catlogic.puzzle'), isFalse);
    final xcconfig = File('ios/Flutter/AppId.xcconfig').readAsStringSync();
    expect(xcconfig.contains('CATLOGIC_APPLICATION_ID=$id'), isTrue);
    final project = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    expect(project.contains(r'$(CATLOGIC_APPLICATION_ID)'), isTrue);
    expect(project.contains('com.tinybitlabs.catLogic'), isFalse);
    expect(project.contains('com.tinybitlabs.cat_logic'), isFalse);
  });
}
