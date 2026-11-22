import 'dart:io';

/// Rewrites the iOS mirror of `config/application_id.txt`.
///
/// Android reads that file directly. Run this after changing the id so the
/// iOS build setting stays in step.
void main() {
  final id = File('config/application_id.txt').readAsStringSync().trim();
  if (!RegExp(r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$').hasMatch(id)) {
    stderr.writeln('application id looks wrong: $id');
    exitCode = 1;
    return;
  }
  File('ios/Flutter/AppId.xcconfig').writeAsStringSync(
    '// Generated from config/application_id.txt. Edit that file, then run\n'
    '// `dart run tool/apply_application_id.dart`.\n'
    'CATLOGIC_APPLICATION_ID=$id\n',
  );
  stdout.writeln('iOS application id set to $id');
}
