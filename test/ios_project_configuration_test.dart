import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS Runner bundles GoogleService-Info.plist for Firebase', () {
    final googleServiceInfo = File('ios/Runner/GoogleService-Info.plist');
    final xcodeProject = File('ios/Runner.xcodeproj/project.pbxproj');

    expect(
      googleServiceInfo.existsSync(),
      isTrue,
      reason: 'ios/Runner/GoogleService-Info.plist must exist on disk.',
    );
    expect(
      xcodeProject.existsSync(),
      isTrue,
      reason: 'ios/Runner.xcodeproj/project.pbxproj must exist.',
    );

    final projectContents = xcodeProject.readAsStringSync();

    expect(
      projectContents,
      contains('/* GoogleService-Info.plist */'),
      reason: 'Xcode project must reference GoogleService-Info.plist.',
    );
    expect(
      projectContents,
      contains('/* GoogleService-Info.plist in Resources */'),
      reason: 'GoogleService-Info.plist must be copied into Runner resources.',
    );
  });
}
