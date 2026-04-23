import 'package:car_owners_hub/services/app_data.dart';
import 'package:car_owners_hub/state/app_flow_state.dart';
import 'package:car_owners_hub/state/user_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('scanIntroBackTargetFor', () {
    UserState ownerGuest(AppOnboardingStatus status) {
      return UserState.initial().copyWith(
        userType: 'owner',
        onboardingStatus: status,
        dataSource: AppDataSource.guestLocal,
      );
    }

    test('returns main-app for guest owner with loginSkipped', () {
      final target = scanIntroBackTargetFor(
        ownerGuest(AppOnboardingStatus.loginSkipped),
        hasPhone: false,
      );

      expect(target, 'main-app');
    });

    test('returns teaser for guest owner with vehicleCaptured', () {
      final target = scanIntroBackTargetFor(
        ownerGuest(AppOnboardingStatus.vehicleCaptured),
        hasPhone: false,
      );

      expect(target, 'teaser');
    });

    test('returns main-app when hasPhone is true for non-guest path', () {
      final target = scanIntroBackTargetFor(
        UserState.initial().copyWith(
          userType: 'owner',
          onboardingStatus: AppOnboardingStatus.profileCaptured,
          dataSource: AppDataSource.authenticatedRemote,
        ),
        hasPhone: true,
      );

      expect(target, 'main-app');
    });

    test('returns auth-phone when hasPhone is false for non-guest path', () {
      final target = scanIntroBackTargetFor(
        UserState.initial().copyWith(
          userType: 'owner',
          onboardingStatus: AppOnboardingStatus.profileCaptured,
          dataSource: AppDataSource.authenticatedRemote,
        ),
        hasPhone: false,
      );

      expect(target, 'auth-phone');
    });
  });
}
