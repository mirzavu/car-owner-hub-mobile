import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../services/app_data.dart';
import '../services/data_service.dart';
import '../screens/auth_email_screen.dart';
import '../screens/auth_otp_screen.dart';
import '../screens/login_screen.dart';
import '../screens/registration_screen.dart';
import '../screens/scan_prompt_screen.dart';
import '../screens/scanner_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/teaser_equity_screen.dart' as teaser;
import '../screens/user_type_screen.dart';
import '../screens/vehicle_info_screen.dart';
import '../screens/verify_scan_screen.dart';
import '../screens/main_app_screen.dart';
import '../state/app_flow_state.dart';
import '../state/financials_state.dart';
import '../state/user_state.dart';
import '../state/vehicle_state.dart';
import '../widgets/fintech_shell.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final appFlowNotifier = ref.read(appFlowProvider.notifier);

  return GoRouter(
    initialLocation: '/loading',
    refreshListenable: GoRouterRefreshStream(appFlowNotifier.stream),
    redirect: (context, state) {
      final step = ref.read(appFlowProvider).step;
      final target = '/$step';
      if (state.matchedLocation != target) {
        return target;
      }
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => FintechShell(child: child),
        routes: [
          GoRoute(
            path: '/loading',
            builder: (context, state) => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          ),
          GoRoute(
            path: '/splash',
            builder: (context, state) => Consumer(
              builder: (context, ref, _) => SplashScreen(
                onNext: () =>
                    ref.read(appFlowProvider.notifier).setStep('user-type'),
              ),
            ),
          ),
          GoRoute(
            path: '/user-type',
            builder: (context, state) => Consumer(
              builder: (context, ref, _) => UserTypeScreen(
                onSelect: (type) {
                  ref.read(userProvider.notifier).setUserType(type);
                  if (type == 'buyer') {
                    ref.read(appFlowProvider.notifier).setActiveTab('home');
                  }
                  if (type == 'owner') {
                    ref.read(appFlowProvider.notifier).setStep('details');
                  } else {
                    ref.read(appFlowProvider.notifier).setStep('auth-login');
                  }
                },
                onBack: () =>
                    ref.read(appFlowProvider.notifier).setStep('splash'),
              ),
            ),
          ),
          GoRoute(
            path: '/details',
            builder: (context, state) => Consumer(
              builder: (context, ref, _) => VehicleInfoScreen(
                onBack:
                    ref
                        .read(appFlowProvider.notifier)
                        .canNavigateBack('details')
                    ? () => ref
                          .read(appFlowProvider.notifier)
                          .navigateBack('details')
                    : null,
                onNext: (nextStep) =>
                    ref.read(appFlowProvider.notifier).setStep(nextStep),
                onEstimateComplete: (value, details) {
                  debugPrint(
                    '[ONBOARDING] Estimate received: \$$value, Details: $details',
                  );
                  ref.read(financialsProvider.notifier).update({
                    'estimatedValue': value,
                  });
                  ref.read(vehicleProvider.notifier).updateCarDetails({
                    'year': details['year'] ?? '',
                    'make': details['make'] ?? '',
                    'model': details['model'] ?? '',
                    'trim': details['trim'] ?? '',
                    'mileage': details['mileage'] ?? '',
                    'vin': '',
                    'plate': '',
                  });
                  ref.read(financialsProvider.notifier).calculateEquity();
                },
              ),
            ),
          ),
          GoRoute(
            path: '/teaser',
            builder: (context, state) => Consumer(
              builder: (context, ref, _) {
                final carDetails = ref.read(vehicleProvider).carDetails;
                final financials = ref.read(financialsProvider).data;
                return teaser.TeaserEquityScreen(
                  carDetails: teaser.CarDetails(
                    year: carDetails['year'] ?? '',
                    make: carDetails['make'] ?? '',
                    model: carDetails['model'] ?? '',
                  ),
                  financials: teaser.Financials(
                    estimatedValue: financials['estimatedValue'],
                    userEstimatedLoan: financials['userEstimatedLoan'],
                  ),
                  onNext: () =>
                      ref.read(appFlowProvider.notifier).setStep('auth-login'),
                  onBack: () =>
                      ref.read(appFlowProvider.notifier).navigateBack('teaser'),
                );
              },
            ),
          ),
          GoRoute(
            path: '/auth-login',
            builder: (context, state) => Consumer(
              builder: (context, ref, _) => LoginScreen(
                onLoginGoogle: () =>
                    ref.read(appFlowProvider.notifier).loginWithGoogle(),
                onSkip: () =>
                    ref.read(appFlowProvider.notifier).skipLoginForNow(),
                setStep: (nextStep, [data, mode, doc]) =>
                    ref.read(appFlowProvider.notifier).setStep(nextStep, data, mode, doc),
                onBack: () => ref
                    .read(appFlowProvider.notifier)
                    .navigateBack('auth-login'),
              ),
            ),
          ),
          GoRoute(
            path: '/auth-email',
            builder: (context, state) => Consumer(
              builder: (context, ref, _) => AuthEmailScreen(
                setStep: (nextStep, [data, mode, doc]) =>
                    ref.read(appFlowProvider.notifier).setStep(nextStep, data, mode, doc),
                onBack: () => ref
                    .read(appFlowProvider.notifier)
                    .navigateBack('auth-email'),
              ),
            ),
          ),
          GoRoute(
            path: '/auth-otp',
            builder: (context, state) => Consumer(
              builder: (context, ref, _) {
                final lastScanData = ref.read(vehicleProvider).lastScanData;
                return AuthOtpScreen(
                  email: lastScanData?['email'] ?? '',
                  onAuthSuccess: () => ref
                      .read(appFlowProvider.notifier)
                      .handleSuccessfulAuthentication(),
                  setStep: (nextStep, [data, mode, doc]) =>
                      ref.read(appFlowProvider.notifier).setStep(nextStep, data, mode, doc),
                  onBack: () => ref
                      .read(appFlowProvider.notifier)
                      .navigateBack('auth-otp'),
                );
              },
            ),
          ),
          GoRoute(
            path: '/auth-phone',
            builder: (context, state) => Consumer(
              builder: (context, ref, _) {
                final user = ref.read(userProvider);
                return RegistrationScreen(
                  initialName: user.profileName,
                  onBack:
                      ref
                          .read(appFlowProvider.notifier)
                          .canNavigateBack('auth-phone')
                      ? () => ref
                            .read(appFlowProvider.notifier)
                            .navigateBack('auth-phone')
                      : null,
                  setStep: (nextStep, [data, mode, doc]) {
                    if (nextStep == 'scan-intro' && user.userType == 'buyer') {
                      ref.read(appFlowProvider.notifier).setStep('main-app');
                    } else {
                      ref.read(appFlowProvider.notifier).setStep(nextStep, data, mode, doc);
                    }
                  },
                  initialValue: user.tempPhone,
                  onChanged: (val) =>
                      ref.read(userProvider.notifier).setTempPhone(val),
                  onSubmitProfile: (name, phone) async {
                    await DataService().saveProfile(
                      userType: user.userType,
                      name: name,
                      phone: phone,
                    );
                    ref
                        .read(userProvider.notifier)
                        .setProfile(
                          name: name,
                          phone: phone,
                          onboardingStatus: AppOnboardingStatus.profileCaptured,
                        );
                  },
                  onSkip: user.isGuest
                      ? () => ref
                            .read(appFlowProvider.notifier)
                            .skipRegistrationForNow()
                      : null,
                  onLogout: () =>
                      ref.read(appFlowProvider.notifier).logoutToSplash(),
                );
              },
            ),
          ),
          GoRoute(
            path: '/scan-intro',
            builder: (context, state) => Consumer(
              builder: (context, ref, _) => ScanPromptScreen(
                onSkip: () =>
                    ref.read(appFlowProvider.notifier).skipLoanVerification(),
                setStep: (nextStep, [data, mode, doc]) =>
                    ref.read(appFlowProvider.notifier).setStep(nextStep, data, mode, doc),
                onBack: () => ref
                    .read(appFlowProvider.notifier)
                    .navigateBack('scan-intro'),
              ),
            ),
          ),
          GoRoute(
            path: '/scanner',
            builder: (context, state) => Consumer(
              builder: (context, ref, _) => ScannerScreen(
                mode: ref.watch(appFlowProvider).scannerMode,
                onPhotoCaptured: (path) => ref.read(appFlowProvider.notifier).handleGarageScanComplete(path),
                onSkip: () =>
                    ref.read(appFlowProvider.notifier).skipLoanVerification(),
                setStep: (nextStep, [data, scanMode, pendingDoc]) =>
                    ref.read(appFlowProvider.notifier).setStep(nextStep, data, scanMode, pendingDoc),
              ),
            ),
          ),
          GoRoute(
            path: '/verify',
            builder: (context, state) => Consumer(
              builder: (context, ref, _) {
                final vehicle = ref.read(vehicleProvider);
                final financials = ref.read(financialsProvider).data;
                return VerifyScanScreen(
                  setStep: (nextStep, [data, mode, doc]) {
                    ref.read(appFlowProvider.notifier).setStep(nextStep, data, mode, doc);
                  },
                  scanData: vehicle.lastScanData ?? {},
                  carDetails: vehicle.carDetails,
                  estimatedValue: (financials['estimatedValue'] as num)
                      .toDouble(),
                  onUpdateCarDetails: (updates) {
                    ref
                        .read(vehicleProvider.notifier)
                        .updateCarDetails(updates);
                  },
                  onBack: () {
                    ref.read(appFlowProvider.notifier).navigateBack('verify');
                  },
                );
              },
            ),
          ),
          GoRoute(
            path: '/main-app',
            builder: (context, state) => const MainAppScreen(),
          ),
        ],
      ),
    ],
  );
});
