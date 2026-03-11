import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/push_token_service.dart';
import 'financials_state.dart';
import 'user_state.dart';
import 'vehicle_state.dart';

class AppFlowState {
  final String step;
  final String activeTab;
  final int? shopInitialStepDelta;
  final String? overlayScreen;
  final bool loading;
  final String loadingText;

  const AppFlowState({
    required this.step,
    required this.activeTab,
    required this.shopInitialStepDelta,
    required this.overlayScreen,
    required this.loading,
    required this.loadingText,
  });

  factory AppFlowState.initial() {
    return const AppFlowState(
      step: 'loading',
      activeTab: 'home',
      shopInitialStepDelta: null,
      overlayScreen: null,
      loading: false,
      loadingText: '',
    );
  }

  AppFlowState copyWith({
    String? step,
    String? activeTab,
    int? shopInitialStepDelta,
    String? overlayScreen,
    bool? loading,
    String? loadingText,
    bool keepOverlay = true,
    bool keepShopDelta = true,
  }) {
    return AppFlowState(
      step: step ?? this.step,
      activeTab: activeTab ?? this.activeTab,
      shopInitialStepDelta:
          keepShopDelta ? (shopInitialStepDelta ?? this.shopInitialStepDelta) : shopInitialStepDelta,
      overlayScreen: keepOverlay ? (overlayScreen ?? this.overlayScreen) : overlayScreen,
      loading: loading ?? this.loading,
      loadingText: loadingText ?? this.loadingText,
    );
  }
}

class AppFlowNotifier extends StateNotifier<AppFlowState> {
  AppFlowNotifier(this.ref) : super(AppFlowState.initial()) {
    _initApp();
  }

  final Ref ref;

  Future<void> _initApp() async {
    final auth = AuthService();

    debugPrint('--- APP INITIALIZATION ---');

    await Future.delayed(const Duration(milliseconds: 500));

    debugPrint('Is Authenticated: ${auth.isAuthenticated}');
    if (!auth.isAuthenticated) {
      debugPrint('Routing to: splash');
      state = state.copyWith(step: 'splash');
      return;
    }

    final bool isSessionValid = await auth.verifySession();
    if (!isSessionValid) {
      debugPrint('Session invalid or user deleted. Routing to: splash');
      state = state.copyWith(step: 'splash');
      return;
    }

    final storedType = await ref.read(userProvider.notifier).restoreUserType();
    if (storedType == 'buyer') {
      state = state.copyWith(activeTab: 'home');
    }

    final fcmToken = await PushTokenService().initAndSyncToken();
    if (fcmToken != null && fcmToken.isNotEmpty) {
      debugPrint('[PUSH] FCM Token: $fcmToken');

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          debugPrint(
            'Message also contained a notification: ${message.notification}',
          );
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('A new onMessageOpenedApp event was published!');
      });
    }

    debugPrint('Onboarding Status: ${auth.onboardingStatus}');
    debugPrint('Onboarding Completed: ${auth.isOnboardingCompleted}');
    debugPrint('Has Phone: ${auth.hasPhone} (${auth.userPhone})');

    LoanSnapshot? snapshot = await ApiService.getCurrentLoanSnapshot();
    Map<String, dynamic>? userVehicle = await ApiService.getUserVehicle();

    if (userVehicle != null) {
      ref.read(vehicleProvider.notifier).updateCarDetails({
        'year': userVehicle['year'],
        'make': userVehicle['make'],
        'model': userVehicle['model'],
        'trim': userVehicle['trim'],
        'vin': userVehicle['vin'],
        'mileage': userVehicle['mileage'],
      });
      
      final estimatedValue = userVehicle['current_market_value'] as double;
      if (estimatedValue > 0) {
        ref.read(financialsProvider.notifier).update({
          'estimatedValue': estimatedValue,
        });
      }
    }

    if (auth.isOnboardingCompleted || snapshot != null) {
      debugPrint(
        "[INIT] Routing to: main-app. ${snapshot != null ? 'Loan found.' : 'Onboarding marked completed.'}",
      );

      if (snapshot != null) {
        ref.read(financialsProvider.notifier).applySnapshot(snapshot);
      }

      state = state.copyWith(step: 'main-app');

      if (snapshot != null) {
        await runTimeTravel(snapshot: snapshot);
      }
    } else if (!auth.hasPhone) {
      debugPrint('Routing to: auth-phone');
      state = state.copyWith(step: 'auth-phone');
    } else {
      final userType = ref.read(userProvider).userType;
      if (userType == 'buyer') {
        debugPrint('Routing to: main-app (buyer)');
        state = state.copyWith(step: 'main-app');
      } else {
        debugPrint('Routing to: scan-intro');
        state = state.copyWith(step: 'scan-intro');
      }
    }

    debugPrint('--------------------------');
  }

  void setStep(String newStep, [Map<String, dynamic>? data]) {
    if (state.step == newStep && data == null) return;
    
    debugPrint('[STEP] Transition: ${state.step} -> $newStep');
    if (data != null) {
      debugPrint('[STEP] Incoming Data: $data');
    }

    if (data != null) {
      ref.read(vehicleProvider.notifier).setLastScanData(data);
      ref.read(financialsProvider.notifier).updateFromScanData(data);
    }

    if (AuthService().isAuthenticated) {
      final carDetails = ref.read(vehicleProvider).carDetails;
      if (carDetails['year'] != null && carDetails['year']!.isNotEmpty) {
        _syncDraftVehicle();
      }
    }

    state = state.copyWith(step: newStep);

    if (newStep == 'main-app') {
      ref.read(userProvider.notifier).clearTempPhone();
      ref.read(vehicleProvider.notifier).clearLastScanData();
    }
  }

  Future<void> loginWithGoogle() async {
    debugPrint('[AUTH] loginWithGoogle flow started');
    setStep('loading');

    try {
      await AuthService().loginWithGoogle();
      debugPrint('[AUTH] Google login backend successful');

      final fcmToken = await PushTokenService().initAndSyncToken();
      if (fcmToken != null && fcmToken.isNotEmpty) {
        debugPrint('[PUSH] FCM Token synced: $fcmToken');
      }

      // Check if phone is already present
      if (AuthService().userPhone.isNotEmpty) {
        debugPrint('[AUTH] User has phone, routing to scan-intro');
        setStep('scan-intro');
      } else {
        debugPrint('[AUTH] User missing phone, routing to auth-phone');
        setStep('auth-phone');
      }
    } catch (e, stackTrace) {
      debugPrint('[AUTH] Google Login Error: $e');
      debugPrint('[AUTH] Stack Trace: $stackTrace');
      // Revert to login screen on error so user can try again
      setStep('auth-login');
      rethrow; // Re-throw so UI can show a snackbar if needed
    }
  }

  void setActiveTab(String tab, {int? stepDelta}) {
    state = state.copyWith(
      activeTab: tab,
      shopInitialStepDelta: stepDelta,
      keepShopDelta: stepDelta == null,
    );
  }

  void setOverlay(String? overlay) {
    state = state.copyWith(overlayScreen: overlay, keepOverlay: false);
  }

  Future<void> _syncDraftVehicle() async {
    if (!AuthService().isAuthenticated) return;
    final carDetails = ref.read(vehicleProvider).carDetails;
    if (carDetails['year'] == null || carDetails['year']!.isEmpty) return;

    try {
      debugPrint('[SYNC] Triggering background draft sync...');
      final financials = ref.read(financialsProvider).data;
      await ApiService.syncVehicleData(
        carDetails: carDetails,
        estimatedValue: (financials['estimatedValue'] as num).toDouble(),
      );
      debugPrint('[SYNC] Draft vehicle synced successfully.');
    } catch (e) {
      debugPrint('[SYNC] Draft sync failed: $e');
    }
  }

  Future<void> runTimeTravel({LoanSnapshot? snapshot}) async {
    debugPrint('[TIME-TRAVEL] Function called.');

    if (snapshot == null) {
      debugPrint('[TIME-TRAVEL] No snapshot provided. Fetching from DB...');
      snapshot = await ApiService.getCurrentLoanSnapshot();
    }

    double originalBalance;
    double interestRate;
    int termMonths;
    String? startDate;
    double monthlyPayment;

    final lastScanData = ref.read(vehicleProvider).lastScanData;

    if (snapshot != null) {
      debugPrint('[TIME-TRAVEL] Using database snapshot data.');
      ref.read(financialsProvider.notifier).setLoanId(snapshot.loanId);
      originalBalance = snapshot.originalBalance;
      interestRate = snapshot.interestRate;
      termMonths = snapshot.termMonths;
      startDate = snapshot.startDate;
      monthlyPayment = snapshot.monthlyPayment;
    } else if (lastScanData != null) {
      debugPrint('[TIME-TRAVEL] Using lastScanData from memory (fresh scan).');
      originalBalance =
          (lastScanData['original_amount_financed'] ??
                  lastScanData['current_balance'] ??
                  0)
              .toDouble();
      interestRate = (lastScanData['interest_rate'] ?? 0).toDouble();
      termMonths = (lastScanData['term_months'] ?? 0).toInt();
      startDate = lastScanData['contract_date']?.toString();
      monthlyPayment =
          (lastScanData['monthly_payment'] ??
                  (lastScanData['bi_weekly_payment'] ?? 0) * 2.16)
              .toDouble();
    } else {
      debugPrint(
        '[TIME-TRAVEL] No data source available (restart or no scan). Skipping.',
      );
      return;
    }

    debugPrint(
      '[TIME-TRAVEL] Input: Balance=$originalBalance, Rate=$interestRate, Term=$termMonths, Start=$startDate, Payment=$monthlyPayment',
    );

    if (originalBalance == 0 ||
        interestRate == 0 ||
        termMonths == 0 ||
        startDate == null ||
        startDate.isEmpty) {
      debugPrint('[TIME-TRAVEL] Missing required parameters. Aborting.');
      return;
    }

    try {
      final result = await ApiService.calculateLoanEquity(
        originalBalance: originalBalance,
        interestRate: interestRate,
        termMonths: termMonths,
        startDate: startDate,
        monthlyPayment: monthlyPayment,
      );

      debugPrint('[TIME-TRAVEL] Result received: $result');

      if (result['calculated_balance'] != null) {
        final newBalance = result['calculated_balance'].toDouble();
        debugPrint('[TIME-TRAVEL] Calculated balance from API: $newBalance');
        ref.read(financialsProvider.notifier).update({
          'userEstimatedLoan': newBalance,
        });

        if (newBalance == 0) {
          ref.read(financialsProvider.notifier).update({
            'monthlyPayment': 0.0,
          });
          debugPrint(
            '[TIME-TRAVEL] Balance is 0. Setting monthly payment to 0.',
          );
        }

        ref.read(financialsProvider.notifier).calculateEquity();
        debugPrint(
          '[TIME-TRAVEL] Equity recalculated. Proceeding to DB update...',
        );
        ApiService.updateLoanBalance(newBalance);
      } else {
        debugPrint(
          '[TIME-TRAVEL] API returned null calculated_balance. No update performed.',
        );
      }
    } catch (e) {
      debugPrint('[TIME-TRAVEL] Error during calculation: $e');
    }
  }
}

final appFlowProvider = StateNotifierProvider<AppFlowNotifier, AppFlowState>(
  (ref) => AppFlowNotifier(ref),
);
