import 'dart:async';

import 'package:flutter/foundation.dart';

import 'api_service.dart';
import 'app_data.dart';
import 'auth_service.dart';
import 'local_storage_service.dart';

class DataService {
  DataService._internal();

  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;

  final LocalStorageService _localStorage = LocalStorageService();

  Future<AppData> loadAppData({String fallbackUserType = 'owner'}) async {
    final auth = AuthService();
    if (auth.isAuthenticated) {
      return _loadRemoteAppData(fallbackUserType: fallbackUserType);
    }

    final localData = await _localStorage.loadAppData();
    if (localData != null) {
      return localData.copyWith(dataSource: AppDataSource.guestLocal);
    }

    return AppData.initial(
      userType: fallbackUserType,
      dataSource: AppDataSource.guestLocal,
    );
  }

  Future<void> saveVehicleDraft({
    required Map<String, String> carDetails,
    required double estimatedValue,
    required String userType,
    AppOnboardingStatus onboardingStatus = AppOnboardingStatus.vehicleCaptured,
  }) async {
    final auth = AuthService();
    if (auth.isAuthenticated) {
      if (userType == 'owner') {
        await ApiService.syncVehicleData(
          carDetails: carDetails,
          estimatedValue: estimatedValue,
        );
      }
      return;
    }

    final current = await loadAppData(fallbackUserType: userType);
    final mergedFinancials = {
      ...current.financials,
      'estimatedValue': estimatedValue,
    };
    mergedFinancials['equity'] = _calculateEquity(mergedFinancials);

    await _localStorage.saveAppData(
      current.copyWith(
        userType: userType,
        dataSource: AppDataSource.guestLocal,
        onboardingStatus: _maxStatus(
          current.onboardingStatus,
          onboardingStatus,
        ),
        carDetails: {...current.carDetails, ...carDetails},
        financials: mergedFinancials,
      ),
    );
  }

  Future<void> saveProfile({
    required String userType,
    required String name,
    required String phone,
    AppOnboardingStatus onboardingStatus = AppOnboardingStatus.profileCaptured,
  }) async {
    final auth = AuthService();
    if (auth.isAuthenticated) {
      await auth.updateProfile(name, phone);
      return;
    }

    final current = await loadAppData(fallbackUserType: userType);
    await _localStorage.saveAppData(
      current.copyWith(
        userType: userType,
        dataSource: AppDataSource.guestLocal,
        onboardingStatus: _maxStatus(
          current.onboardingStatus,
          onboardingStatus,
        ),
        profileName: name.trim(),
        profilePhone: phone.trim(),
      ),
    );
  }

  Future<void> saveBuyerProfileDraft(Map<String, dynamic> buyerProfile) async {
    final auth = AuthService();
    if (auth.isAuthenticated) {
      await auth.pb.collection('users').update(auth.userId, body: buyerProfile);
      return;
    }

    final current = await loadAppData(fallbackUserType: 'buyer');
    await _localStorage.saveAppData(
      current.copyWith(
        userType: 'buyer',
        dataSource: AppDataSource.guestLocal,
        onboardingStatus: _maxStatus(
          current.onboardingStatus,
          AppOnboardingStatus.loginSkipped,
        ),
        buyerProfile: {...current.buyerProfile, ...buyerProfile},
      ),
    );
  }

  Future<void> markOnboardingSkipped({
    required String userType,
    AppOnboardingStatus status = AppOnboardingStatus.loginSkipped,
  }) async {
    final auth = AuthService();
    if (auth.isAuthenticated) {
      await auth.updateOnboardingStatus('skipped');
      return;
    }

    final current = await loadAppData(fallbackUserType: userType);
    await _localStorage.saveAppData(
      current.copyWith(
        userType: userType,
        dataSource: AppDataSource.guestLocal,
        onboardingStatus: _maxStatus(current.onboardingStatus, status),
      ),
    );
  }

  Future<OnboardingSaveResult> saveOnboardingData({
    required String userType,
    required Map<String, String> carDetails,
    required Map<String, dynamic> scanData,
    required double estimatedValue,
    required bool isVerified,
    String? documentId,
  }) async {
    final storedScanData = _sanitizeStoredScanData(scanData);
    final balanceResolution = await _resolveLoanBalance(storedScanData);
    final scanDataForPersistence = {
      ...storedScanData,
      'resolved_loan_balance': balanceResolution.balance,
      'loan_balance_source': balanceResolution.source,
    };
    final auth = AuthService();
    if (auth.isAuthenticated) {
      final newLoanId = await ApiService.syncOnboardingData(
        carDetails: carDetails,
        scanData: scanDataForPersistence,
        estimatedValue: estimatedValue,
        isVerified: isVerified,
        documentId: documentId,
      );
      await auth.updateOnboardingStatus('completed');
      return OnboardingSaveResult(
        resolvedBalance: balanceResolution.balance,
        balanceSource: balanceResolution.source,
        persistedScanData: scanDataForPersistence,
        loanId: newLoanId,
      );
    }

    final current = await loadAppData(fallbackUserType: userType);
    final mergedFinancials = {
      ...current.financials,
      'estimatedValue': estimatedValue,
      'actualRate': _toDouble(scanDataForPersistence['interest_rate']),
      'lender':
          (scanDataForPersistence['lender_name'] ??
                  current.financials['lender'] ??
                  '')
              .toString(),
      'monthlyPayment': _monthlyPaymentFromScan(scanDataForPersistence),
      'userEstimatedLoan': balanceResolution.balance,
      'loanBalanceSource': balanceResolution.source,
    };
    mergedFinancials['equity'] = _calculateEquity(mergedFinancials);

    debugPrint(
      '[DATA] Guest onboarding saved: value=$estimatedValue balance=${balanceResolution.balance} source=${balanceResolution.source}',
    );

    await _localStorage.saveAppData(
      current.copyWith(
        userType: userType,
        dataSource: AppDataSource.guestLocal,
        onboardingStatus: AppOnboardingStatus.completed,
        carDetails: {...current.carDetails, ...carDetails},
        scanData: scanDataForPersistence,
        keepScanData: false,
        financials: mergedFinancials,
        loanId: current.loanId ?? 'guest-loan',
        keepLoanId: false,
      ),
    );

    return OnboardingSaveResult(
      resolvedBalance: balanceResolution.balance,
      balanceSource: balanceResolution.source,
      persistedScanData: scanDataForPersistence,
      loanId: current.loanId ?? 'guest-loan',
    );
  }

  Future<void> updateBalance(double newBalance) async {
    final auth = AuthService();
    if (auth.isAuthenticated) {
      await ApiService.updateLoanBalance(newBalance);
      return;
    }

    final current = await loadAppData();
    if (!current.hasAnyData) return;

    final mergedFinancials = {
      ...current.financials,
      'userEstimatedLoan': newBalance,
    };
    mergedFinancials['equity'] = _calculateEquity(mergedFinancials);

    await _localStorage.saveAppData(
      current.copyWith(financials: mergedFinancials),
    );
  }

  Future<void> migrateLocalToPocketBase({
    String fallbackUserType = 'owner',
  }) async {
    final auth = AuthService();
    if (!auth.isAuthenticated) return;

    final localData = await _localStorage.loadAppData();
    if (localData == null || !localData.hasAnyData) return;

    final remoteData = await _loadRemoteAppData(
      fallbackUserType: fallbackUserType,
    );

    final remoteCompleted =
        auth.isOnboardingCompleted || (remoteData.loanId ?? '').isNotEmpty;

    if (!remoteCompleted) {
      if (localData.hasProfileData) {
        await auth.updateProfile(localData.profileName, localData.profilePhone);
      }

      if (localData.userType == 'buyer' && localData.hasBuyerProfile) {
        await auth.pb
            .collection('users')
            .update(
              auth.userId,
              body: _sanitizeBuyerProfile(localData.buyerProfile),
            );
      }

      if (localData.userType == 'owner' && localData.hasVehicleData) {
        if (localData.scanData != null && localData.scanData!.isNotEmpty) {
          await ApiService.syncOnboardingData(
            carDetails: localData.carDetails,
            scanData: localData.scanData!,
            estimatedValue: _toDouble(localData.financials['estimatedValue']),
            isVerified: true,
          );
          await auth.updateOnboardingStatus('completed');
        } else {
          await ApiService.syncVehicleData(
            carDetails: localData.carDetails,
            estimatedValue: _toDouble(localData.financials['estimatedValue']),
          );
        }
      }
    }

    await auth.verifySession();
    await clearGuestData();
  }

  Future<void> clearGuestData() async {
    await _localStorage.clearAppData();
  }

  Future<void> updateGuestIdentity({
    required String userType,
    AppOnboardingStatus? onboardingStatus,
  }) async {
    final auth = AuthService();
    if (auth.isAuthenticated) return;

    final current = await loadAppData(fallbackUserType: userType);
    await _localStorage.saveAppData(
      current.copyWith(
        userType: userType,
        dataSource: AppDataSource.guestLocal,
        onboardingStatus: onboardingStatus ?? current.onboardingStatus,
      ),
    );
  }

  Future<AppData> _loadRemoteAppData({required String fallbackUserType}) async {
    final auth = AuthService();
    final vehicle = await ApiService.getUserVehicle();
    final snapshot = await ApiService.getCurrentLoanSnapshot();
    final buyerProfile = _loadBuyerProfileFromRecord(auth);

    final userType = _deriveRemoteUserType(
      vehicle: vehicle,
      snapshot: snapshot,
      buyerProfile: buyerProfile,
      fallbackUserType: fallbackUserType,
    );
    final financials = {
      ...AppData.initial().financials,
      if (vehicle != null)
        'estimatedValue': _toDouble(vehicle['current_market_value']),
      if (snapshot != null) ...{
        'estimatedValue': snapshot.estimatedValue,
        'userEstimatedLoan': snapshot.currentBalance,
        'actualRate': snapshot.interestRate,
        'monthlyPayment': snapshot.monthlyPayment,
      },
    };
    financials['equity'] = _calculateEquity(financials);

    return AppData(
      userType: userType,
      dataSource: AppDataSource.authenticatedRemote,
      onboardingStatus: _deriveRemoteOnboardingStatus(
        auth: auth,
        vehicle: vehicle,
        snapshot: snapshot,
      ),
      profileName: auth.displayName,
      profilePhone: auth.userPhone,
      carDetails: {
        ...AppData.initial().carDetails,
        if (vehicle != null) ...{
          'year': (vehicle['year'] ?? '').toString(),
          'make': (vehicle['make'] ?? '').toString(),
          'model': (vehicle['model'] ?? '').toString(),
          'trim': (vehicle['trim'] ?? '').toString(),
          'vin': (vehicle['vin'] ?? '').toString(),
          'mileage': (vehicle['mileage'] ?? '').toString(),
        },
      },
      financials: financials,
      buyerProfile: buyerProfile,
      scanData: null,
      loanId: snapshot?.loanId,
      pendingPushToken: null,
    );
  }

  Map<String, dynamic> _loadBuyerProfileFromRecord(AuthService auth) {
    final record = auth.pb.authStore.record;
    if (record == null) return const {};

    return {
      'income_range': record.getStringValue('income_range'),
      'employment_status': record.getStringValue('employment_status'),
      'credit_score_range': record.getStringValue('credit_score_range'),
      'monthly_budget': record.get('monthly_budget'),
      'dob': record.getStringValue('dob'),
      'address': record.getStringValue('address'),
      'employer_name': record.getStringValue('employer_name'),
      'job_title': record.getStringValue('job_title'),
      'employment_duration': record.getStringValue('employment_duration'),
      'housing_cost': record.get('housing_cost'),
      'downpayment': record.get('downpayment'),
      'has_cosigner': record.getBoolValue('has_cosigner'),
      'buyer_notes': record.getStringValue('buyer_notes'),
    }..removeWhere((_, value) {
      if (value == null) return true;
      if (value is String) return value.trim().isEmpty;
      return false;
    });
  }

  Map<String, dynamic> _sanitizeBuyerProfile(Map<String, dynamic> profile) {
    return Map<String, dynamic>.from(profile)
      ..removeWhere((_, value) => value == null);
  }

  AppOnboardingStatus _deriveRemoteOnboardingStatus({
    required AuthService auth,
    required Map<String, dynamic>? vehicle,
    required LoanSnapshot? snapshot,
  }) {
    if (snapshot != null || auth.onboardingStatus == 'completed') {
      return AppOnboardingStatus.completed;
    }
    if (auth.onboardingStatus == 'skipped') {
      return vehicle != null
          ? AppOnboardingStatus.verificationSkipped
          : AppOnboardingStatus.loginSkipped;
    }
    if (vehicle != null) {
      return AppOnboardingStatus.vehicleCaptured;
    }
    if (auth.hasPhone) {
      return AppOnboardingStatus.profileCaptured;
    }
    return AppOnboardingStatus.newUser;
  }

  String _deriveRemoteUserType({
    required Map<String, dynamic>? vehicle,
    required LoanSnapshot? snapshot,
    required Map<String, dynamic> buyerProfile,
    required String fallbackUserType,
  }) {
    if (vehicle != null || snapshot != null) {
      return 'owner';
    }
    if (buyerProfile.isNotEmpty) {
      return 'buyer';
    }
    return fallbackUserType == 'buyer' ? 'buyer' : 'owner';
  }

  AppOnboardingStatus _maxStatus(AppOnboardingStatus a, AppOnboardingStatus b) {
    return a.index >= b.index ? a : b;
  }

  double _monthlyPaymentFromScan(Map<String, dynamic> scanData) {
    final monthly = scanData['monthly_payment'];
    if (monthly != null) {
      return _toDouble(monthly);
    }
    return _toDouble(scanData['bi_weekly_payment']) * 2.16;
  }

  double _calculateEquity(Map<String, dynamic> financials) {
    return _toDouble(financials['estimatedValue']) -
        _toDouble(financials['userEstimatedLoan']);
  }

  double _toDouble(dynamic value, [double fallback = 0.0]) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  Map<String, dynamic> _sanitizeStoredScanData(Map<String, dynamic> scanData) {
    final stored = Map<String, dynamic>.from(scanData);
    stored.remove('raw_ocr');
    return stored;
  }

  Future<_LoanBalanceResolution> _resolveLoanBalance(
    Map<String, dynamic> scanData,
  ) async {
    final scannedCurrent = _toDouble(scanData['current_balance'], -1);
    final originalBalance = _toDouble(
      scanData['original_amount_financed'] ?? scanData['current_balance'],
      0,
    );
    final interestRate = _toDouble(scanData['interest_rate'], 0);
    final termMonths = _toInt(scanData['term_months'], 0);
    final startDate = (scanData['contract_date'] ?? '').toString().trim();
    final monthlyPayment = _monthlyPaymentFromScan(scanData);

    debugPrint(
      '[DATA] Resolving guest loan balance: original=$originalBalance scannedCurrent=${scannedCurrent >= 0 ? scannedCurrent : 'missing'} rate=$interestRate term=$termMonths start=$startDate payment=$monthlyPayment',
    );

    if (originalBalance > 0 &&
        interestRate > 0 &&
        termMonths > 0 &&
        startDate.isNotEmpty &&
        monthlyPayment > 0) {
      try {
        final calculation = await ApiService.calculateLoanEquity(
          originalBalance: originalBalance,
          interestRate: interestRate,
          termMonths: termMonths,
          startDate: startDate,
          monthlyPayment: monthlyPayment,
        );
        final calculatedBalance = _toDouble(
          calculation['calculated_balance'],
          -1,
        );
        if (calculatedBalance >= 0) {
          debugPrint(
            '[DATA] Guest loan balance resolved from calculation: $calculatedBalance',
          );
          return _LoanBalanceResolution(
            balance: calculatedBalance,
            source: 'calculated',
          );
        }
      } catch (error) {
        debugPrint('[DATA] Guest loan balance calculation failed: $error');
      }
    }

    if (scannedCurrent >= 0) {
      debugPrint(
        '[DATA] Guest loan balance falling back to scanned current balance: $scannedCurrent',
      );
      return _LoanBalanceResolution(
        balance: scannedCurrent,
        source: 'scanned_current_balance',
      );
    }

    debugPrint(
      '[DATA] Guest loan balance falling back to original financed amount: $originalBalance',
    );
    return _LoanBalanceResolution(
      balance: originalBalance,
      source: 'original_amount_financed',
    );
  }

  int _toInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }
}

class _LoanBalanceResolution {
  const _LoanBalanceResolution({required this.balance, required this.source});

  final double balance;
  final String source;
}

class OnboardingSaveResult {
  const OnboardingSaveResult({
    required this.resolvedBalance,
    required this.balanceSource,
    required this.persistedScanData,
    this.loanId,
  });

  final double resolvedBalance;
  final String balanceSource;
  final Map<String, dynamic> persistedScanData;
  final String? loanId;
}
