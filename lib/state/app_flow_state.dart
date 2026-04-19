import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/app_data.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../services/push_token_service.dart';
import 'financials_state.dart';
import 'user_state.dart';
import 'vehicle_state.dart';

class AppFlowState {
  final String step;
  final String activeTab;
  final int? shopInitialStepDelta;
  final String? overlayScreen;
  final String? detailsBackTarget;
  final bool loading;
  final String loadingText;
  final String scannerMode; // 'onboarding' or 'garage'
  final String? pendingDocType;

  const AppFlowState({
    required this.step,
    required this.activeTab,
    required this.shopInitialStepDelta,
    required this.overlayScreen,
    required this.detailsBackTarget,
    required this.loading,
    required this.loadingText,
    this.scannerMode = 'onboarding',
    this.pendingDocType,
  });

  factory AppFlowState.initial() {
    return const AppFlowState(
      step: 'loading',
      activeTab: 'home',
      shopInitialStepDelta: null,
      overlayScreen: null,
      detailsBackTarget: null,
      loading: false,
      loadingText: '',
      scannerMode: 'onboarding',
      pendingDocType: null,
    );
  }

  AppFlowState copyWith({
    String? step,
    String? activeTab,
    int? shopInitialStepDelta,
    String? overlayScreen,
    String? detailsBackTarget,
    bool? loading,
    String? loadingText,
    String? scannerMode,
    String? pendingDocType,
    bool keepOverlay = true,
    bool keepShopDelta = true,
    bool keepDetailsBackTarget = true,
  }) {
    return AppFlowState(
      step: step ?? this.step,
      activeTab: activeTab ?? this.activeTab,
      shopInitialStepDelta: keepShopDelta
          ? (shopInitialStepDelta ?? this.shopInitialStepDelta)
          : shopInitialStepDelta,
      overlayScreen: keepOverlay
          ? (overlayScreen ?? this.overlayScreen)
          : overlayScreen,
      detailsBackTarget: keepDetailsBackTarget
          ? (detailsBackTarget ?? this.detailsBackTarget)
          : detailsBackTarget,
      loading: loading ?? this.loading,
      loadingText: loadingText ?? this.loadingText,
      scannerMode: scannerMode ?? this.scannerMode,
      pendingDocType: pendingDocType ?? this.pendingDocType,
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
    final userNotifier = ref.read(userProvider.notifier);

    debugPrint('--- APP INITIALIZATION ---');

    await Future.delayed(const Duration(milliseconds: 500));

    if (auth.isAuthenticated) {
      final bool isSessionValid = await auth.verifySession();
      if (!isSessionValid) {
        debugPrint('Session invalid. Falling back to guest/local state.');
      }
    }

    final storedType = await userNotifier.restoreUserType();
    final appData = await DataService().loadAppData(
      fallbackUserType: storedType ?? ref.read(userProvider).userType,
    );
    _hydrateProviders(appData);

    if (auth.isAuthenticated) {
      final fcmToken = await PushTokenService().initAndSyncToken(requestPermission: false);
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
    }

    final nextStep = _resolveStep(
      appData,
      isAuthenticated: auth.isAuthenticated,
      hasPhone: auth.hasPhone || appData.profilePhone.trim().isNotEmpty,
    );

    debugPrint('Routing to: $nextStep');
    state = state.copyWith(
      step: nextStep,
      activeTab: appData.userType == 'buyer' ? 'home' : state.activeTab,
    );

    debugPrint('--------------------------');
  }

  void setStep(String newStep, [Map<String, dynamic>? data, String? scannerMode, String? pendingDocType]) {
    if (state.step == newStep && data == null && scannerMode == null && pendingDocType == null) return;

    debugPrint('[STEP] Transition: ${state.step} -> $newStep');
    if (data != null) {
      debugPrint('[STEP] Incoming Data: ${_sanitizeLogData(data)}');
    }

    if (data != null) {
      ref.read(vehicleProvider.notifier).setLastScanData(data);
      ref.read(financialsProvider.notifier).updateFromScanData(data);
    }

    final detailsBackTarget = newStep == 'details'
        ? (state.step == 'main-app' ? 'main-app' : 'user-type')
        : null;

    final user = ref.read(userProvider);
    if (newStep == 'teaser' && state.step == 'details' && user.userType == 'buyer') {
      debugPrint('[STEP] Promoting user from Buyer to Owner after vehicle captured');
      ref.read(userProvider.notifier).setUserType('owner');
      ref.read(userProvider.notifier).setProfile(
            onboardingStatus: AppOnboardingStatus.vehicleCaptured,
            dataSource: user.dataSource,
          );

      if (!AuthService().isAuthenticated) {
        unawaited(DataService().updateGuestIdentity(
          userType: 'owner',
          onboardingStatus: AppOnboardingStatus.vehicleCaptured,
        ));
      }
    }

    state = state.copyWith(
      step: newStep,
      detailsBackTarget: detailsBackTarget,
      keepDetailsBackTarget: newStep == 'details' || newStep == 'teaser',
      scannerMode: scannerMode ?? (newStep == 'scanner' ? state.scannerMode : 'onboarding'),
      pendingDocType: pendingDocType ?? state.pendingDocType,
    );

    final carDetails = ref.read(vehicleProvider).carDetails;
    if ((carDetails['year'] ?? '').isNotEmpty ||
        (carDetails['make'] ?? '').isNotEmpty ||
        (carDetails['model'] ?? '').isNotEmpty) {
      unawaited(_persistVehicleDraft());
    }

    if (newStep == 'main-app') {
      final user = ref.read(userProvider);
      if (data != null && data['loanId'] != null) {
        debugPrint('[STEP] Valid loanId received in payload: ${data['loanId']}');
        ref.read(financialsProvider.notifier).setLoanId(data['loanId'] as String);
        if (user.isGuest) {
          ref.read(userProvider.notifier).setProfile(
                onboardingStatus: AppOnboardingStatus.completed,
                dataSource: AppDataSource.guestLocal,
              );
        }
      } else if (user.isGuest && _hasLoanCompletionPayload(data)) {
        debugPrint(
          '[STEP] Guest loan completion detected. Promoting in-memory state to main dashboard.',
        );
        ref.read(financialsProvider.notifier).setLoanId('guest-loan');
        ref
            .read(userProvider.notifier)
            .setProfile(
              onboardingStatus: AppOnboardingStatus.completed,
              dataSource: AppDataSource.guestLocal,
            );
      }
      ref.read(userProvider.notifier).clearTempPhone();
      ref.read(vehicleProvider.notifier).clearLastScanData();
    }
  }

  Future<void> handleGarageScanComplete(String filePath) async {
    final docType = state.pendingDocType;
    final loanId = ref.read(financialsProvider).loanId;

    if (docType == null) {
      debugPrint("[GARAGE] No pending doc type for scan complete");
      setStep('main-app');
      return;
    }

    state = state.copyWith(loading: true, loadingText: "Uploading document...");

    try {
      await ApiService.uploadGarageDocument(filePath, docType, loanId: loanId);
      debugPrint("[GARAGE] Scan upload success: $docType");
      state = state.copyWith(loading: false, pendingDocType: null);
      setStep('main-app');
    } catch (e) {
      debugPrint("[GARAGE] Scan upload failed: $e");
      state = state.copyWith(loading: false);
      // Maybe stay on main-app but show error snackbar
      setStep('main-app');
    }
  }

  Future<void> loginWithGoogle() async {
    debugPrint('[AUTH] loginWithGoogle flow started');
    setStep('loading');

    try {
      await AuthService().loginWithGoogle();
      debugPrint('[AUTH] Google login backend successful');
      await handleSuccessfulAuthentication();
    } catch (e, stackTrace) {
      debugPrint('[AUTH] Google Login Error: $e');
      debugPrint('[AUTH] Stack Trace: $stackTrace');
      // Revert to login screen on error so user can try again
      setStep('auth-login');
      rethrow; // Re-throw so UI can show a snackbar if needed
    }
  }

  Future<void> loginWithApple() async {
    debugPrint('[AUTH] loginWithApple flow started');
    setStep('loading');

    try {
      await AuthService().loginWithApple();
      debugPrint('[AUTH] Apple login backend successful');
      await handleSuccessfulAuthentication();
    } catch (e, stackTrace) {
      debugPrint('[AUTH] Apple Login Error: $e');
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

  void handleBackFromRoot() {
    debugPrint('[BACK] Root back handling for step: ${state.step}');
    navigateBack();
  }

  bool canNavigateBack([String? step]) => backTargetFor(step) != null;

  String? backTargetFor([String? step]) {
    final currentStep = step ?? state.step;
    final user = ref.read(userProvider);
    final hasPhone = AuthService().hasPhone || user.profilePhone.isNotEmpty;

    switch (currentStep) {
      case 'user-type':
        return 'splash';
      case 'details':
        return state.detailsBackTarget ?? 'user-type';
      case 'teaser':
        return 'details';
      case 'auth-login':
        return _resolveAuthLoginBackTarget(user);
      case 'auth-email':
        return 'auth-login';
      case 'auth-otp':
        return 'auth-email';
      case 'auth-phone':
        return _authPhoneBackTarget(user);
      case 'scan-intro':
        return _scanIntroBackTarget(user, hasPhone: hasPhone);
      case 'scanner':
      case 'verify':
        return 'scan-intro';
      case 'loading':
      case 'splash':
      case 'main-app':
      default:
        return null;
    }
  }

  void navigateBack([String? step]) {
    final target = backTargetFor(step);
    if (target == null) return;
    setStep(target);
  }

  Future<void> _persistVehicleDraft() async {
    final carDetails = ref.read(vehicleProvider).carDetails;
    if (carDetails['year'] == null || carDetails['year']!.isEmpty) return;

    try {
      debugPrint('[SYNC] Persisting vehicle draft...');
      final financials = ref.read(financialsProvider).data;
      await DataService().saveVehicleDraft(
        carDetails: carDetails,
        estimatedValue: (financials['estimatedValue'] as num).toDouble(),
        userType: ref.read(userProvider).userType,
      );
      debugPrint('[SYNC] Draft vehicle persisted successfully.');
    } catch (e) {
      debugPrint('[SYNC] Draft vehicle persistence failed: $e');
    }
  }

  Future<void> handleSuccessfulAuthentication() async {
    final storedType = ref.read(userProvider).userType;
    await DataService().migrateLocalToPocketBase(fallbackUserType: storedType);

    final appData = await DataService().loadAppData(
      fallbackUserType: storedType,
    );
    _hydrateProviders(appData);

    final fcmToken = await PushTokenService().initAndSyncToken(requestPermission: false);
    if (fcmToken != null && fcmToken.isNotEmpty) {
      debugPrint('[PUSH] FCM Token synced: $fcmToken');
    }

    final nextStep = _resolveStep(
      appData,
      isAuthenticated: true,
      hasPhone: AuthService().hasPhone || appData.profilePhone.isNotEmpty,
    );
    state = state.copyWith(
      activeTab: appData.userType == 'buyer' ? 'home' : state.activeTab,
    );
    setStep(nextStep);
  }

  Future<void> skipLoginForNow() async {
    final user = ref.read(userProvider);
    await DataService().markOnboardingSkipped(userType: user.userType);
    ref
        .read(userProvider.notifier)
        .setProfile(
          onboardingStatus: AppOnboardingStatus.loginSkipped,
          dataSource: AppDataSource.guestLocal,
        );
    setStep(user.userType == 'buyer' ? 'main-app' : 'scan-intro');
  }

  Future<void> skipRegistrationForNow() async {
    final user = ref.read(userProvider);
    await DataService().markOnboardingSkipped(
      userType: user.userType,
      status: user.userType == 'buyer'
          ? AppOnboardingStatus.loginSkipped
          : AppOnboardingStatus.profileCaptured,
    );
    ref
        .read(userProvider.notifier)
        .setProfile(
          onboardingStatus: user.userType == 'buyer'
              ? AppOnboardingStatus.loginSkipped
              : AppOnboardingStatus.profileCaptured,
          dataSource: user.dataSource,
        );
    setStep(user.userType == 'buyer' ? 'main-app' : 'scan-intro');
  }

  Future<void> skipLoanVerification() async {
    final user = ref.read(userProvider);
    final currentStatus = user.onboardingStatus;

    // Only set skipped if it is not already higher (loanCaptured or completed)
    final bool shouldUpdateStatus = !(currentStatus == AppOnboardingStatus.completed ||
        currentStatus == AppOnboardingStatus.loanCaptured ||
        currentStatus == AppOnboardingStatus.verificationSkipped);

    if (shouldUpdateStatus) {
      final nextStatus = user.userType == 'owner'
          ? AppOnboardingStatus.verificationSkipped
          : AppOnboardingStatus.loginSkipped;
      await DataService().markOnboardingSkipped(
        userType: user.userType,
        status: nextStatus,
      );
      ref.read(userProvider.notifier).setProfile(onboardingStatus: nextStatus, dataSource: user.dataSource);
    }

    setStep('main-app');
  }

  Future<void> logoutToSplash() async {
    if (AuthService().isAuthenticated) {
      AuthService().logout();
    }
    await DataService().clearGuestData();
    _resetProviders();
    state = AppFlowState.initial().copyWith(step: 'splash');
  }

  String authLoginBackTarget() {
    return _resolveAuthLoginBackTarget(ref.read(userProvider));
  }

  Future<void> startOwnerVehicleFlow() async {
    state = state.copyWith(activeTab: 'home');
    setStep('details');
  }

  void _hydrateProviders(AppData appData) {
    ref.read(userProvider.notifier).hydrateFromAppData(appData);
    ref
        .read(vehicleProvider.notifier)
        .hydrate(
          carDetails: appData.carDetails,
          lastScanData: appData.scanData,
        );
    ref
        .read(financialsProvider.notifier)
        .hydrate(data: appData.financials, loanId: appData.loanId);
  }

  void _resetProviders() {
    final selectedType = ref.read(userProvider).userType;
    ref.read(userProvider.notifier).reset(userType: selectedType);
    ref.read(vehicleProvider.notifier).reset();
    ref.read(financialsProvider.notifier).reset();
  }

  String _resolveStep(
    AppData appData, {
    required bool isAuthenticated,
    required bool hasPhone,
  }) {
    if (isAuthenticated) {
      if (appData.userType == 'buyer') {
        return 'main-app';
      }
      if ((appData.loanId ?? '').isNotEmpty ||
          appData.onboardingStatus == AppOnboardingStatus.completed ||
          AuthService().isOnboardingCompleted) {
        return 'main-app';
      }
      if (!hasPhone) {
        return 'auth-phone';
      }
      return 'scan-intro';
    }

    if (!appData.hasAnyData ||
        appData.onboardingStatus == AppOnboardingStatus.newUser) {
      return 'splash';
    }

    if (appData.userType == 'buyer') {
      return 'main-app';
    }

    switch (appData.onboardingStatus) {
      case AppOnboardingStatus.vehicleCaptured:
        return 'teaser';
      case AppOnboardingStatus.loginSkipped:
      case AppOnboardingStatus.profileCaptured:
        return 'scan-intro';
      case AppOnboardingStatus.verificationSkipped:
        return 'main-app';
      case AppOnboardingStatus.loanCaptured:
      case AppOnboardingStatus.completed:
        return 'main-app';
      case AppOnboardingStatus.newUser:
        return 'splash';
    }
  }

  String _resolveAuthLoginBackTarget(UserState user) {
    if (AuthService().isAuthenticated) {
      return 'main-app';
    }

    if (!user.isGuest || user.onboardingStatus == AppOnboardingStatus.newUser) {
      return user.userType == 'buyer' ? 'user-type' : 'teaser';
    }

    if (user.userType == 'buyer') {
      return 'main-app';
    }

    switch (user.onboardingStatus) {
      case AppOnboardingStatus.vehicleCaptured:
        return 'teaser';
      case AppOnboardingStatus.loginSkipped:
      case AppOnboardingStatus.profileCaptured:
        return 'scan-intro';
      case AppOnboardingStatus.verificationSkipped:
        return 'main-app';
      case AppOnboardingStatus.loanCaptured:
      case AppOnboardingStatus.completed:
        return 'main-app';
      case AppOnboardingStatus.newUser:
        return 'teaser';
    }
  }

  String? _authPhoneBackTarget(UserState user) {
    if (AuthService().isAuthenticated) {
      return null;
    }
    return 'auth-login';
  }

  String _scanIntroBackTarget(UserState user, {required bool hasPhone}) {
    if (user.isGuest && user.userType == 'owner') {
      switch (user.onboardingStatus) {
        case AppOnboardingStatus.profileCaptured:
          return 'auth-phone';
        case AppOnboardingStatus.verificationSkipped:
          return 'main-app';
        case AppOnboardingStatus.loginSkipped:
        case AppOnboardingStatus.vehicleCaptured:
        case AppOnboardingStatus.newUser:
          return 'teaser';
        case AppOnboardingStatus.loanCaptured:
        case AppOnboardingStatus.completed:
          return 'main-app';
      }
    }

    if (hasPhone) {
      return 'main-app';
    }
    return 'auth-phone';
  }

  bool _hasLoanCompletionPayload(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return false;
    return data.containsKey('interest_rate') &&
        (data.containsKey('original_amount_financed') ||
            data.containsKey('current_balance') ||
            data.containsKey('monthly_payment') ||
            data.containsKey('bi_weekly_payment'));
  }

  Map<String, dynamic> _sanitizeLogData(Map<String, dynamic> data) {
    final sanitized = Map<String, dynamic>.from(data);
    if (sanitized.containsKey('raw_ocr')) {
      sanitized['raw_ocr'] = '[TRUNCATED]';
    }
    return sanitized;
  }
}

final appFlowProvider = StateNotifierProvider<AppFlowNotifier, AppFlowState>(
  (ref) => AppFlowNotifier(ref),
);
