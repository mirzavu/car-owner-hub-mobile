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

  test('iOS AppDelegate registers for APNs and forwards device token', () {
    final appDelegate = File('ios/Runner/AppDelegate.swift');

    expect(
      appDelegate.existsSync(),
      isTrue,
      reason: 'ios/Runner/AppDelegate.swift must exist.',
    );

    final appDelegateContents = appDelegate.readAsStringSync();

    expect(
      appDelegateContents,
      contains('application.registerForRemoteNotifications()'),
      reason: 'AppDelegate must explicitly register for remote notifications.',
    );
    expect(
      appDelegateContents,
      contains('didRegisterForRemoteNotificationsWithDeviceToken'),
      reason: 'AppDelegate must receive the APNs device token.',
    );
    expect(
      appDelegateContents,
      contains('Messaging.messaging().apnsToken = deviceToken'),
      reason: 'AppDelegate must forward the APNs token to Firebase Messaging.',
    );
  });
}
