import 'dart:convert';

enum AppDataSource {
  guestLocal('guest_local'),
  authenticatedRemote('authenticated_remote');

  const AppDataSource(this.storageValue);
  final String storageValue;

  static AppDataSource fromStorageValue(String? value) {
    return AppDataSource.values.firstWhere(
      (item) => item.storageValue == value,
      orElse: () => AppDataSource.guestLocal,
    );
  }
}

enum AppOnboardingStatus {
  newUser('new'),
  vehicleCaptured('vehicle_captured'),
  loginSkipped('login_skipped'),
  profileCaptured('profile_captured'),
  verificationSkipped('verification_skipped'),
  loanCaptured('loan_captured'),
  completed('completed');

  const AppOnboardingStatus(this.storageValue);
  final String storageValue;

  static AppOnboardingStatus fromStorageValue(String? value) {
    return AppOnboardingStatus.values.firstWhere(
      (item) => item.storageValue == value,
      orElse: () => AppOnboardingStatus.newUser,
    );
  }
}

class AppData {
  const AppData({
    required this.userType,
    required this.dataSource,
    required this.onboardingStatus,
    required this.profileName,
    required this.profilePhone,
    required this.carDetails,
    required this.financials,
    required this.buyerProfile,
    this.scanData,
    this.loanId,
    this.pendingPushToken,
  });

  final String userType;
  final AppDataSource dataSource;
  final AppOnboardingStatus onboardingStatus;
  final String profileName;
  final String profilePhone;
  final Map<String, String> carDetails;
  final Map<String, dynamic> financials;
  final Map<String, dynamic> buyerProfile;
  final Map<String, dynamic>? scanData;
  final String? loanId;
  final String? pendingPushToken;

  factory AppData.initial({
    String userType = 'owner',
    AppDataSource dataSource = AppDataSource.guestLocal,
  }) {
    return AppData(
      userType: userType == 'buyer' ? 'buyer' : 'owner',
      dataSource: dataSource,
      onboardingStatus: AppOnboardingStatus.newUser,
      profileName: '',
      profilePhone: '',
      carDetails: const {
        'year': '',
        'make': '',
        'model': '',
        'trim': '',
        'vin': '',
        'plate': '',
        'mileage': '',
      },
      financials: const {
        'estimatedValue': 0.0,
        'userEstimatedLoan': 0.0,
        'actualRate': 0.0,
        'marketRate': null,
        'monthlyPayment': 0.0,
        'lender': 'Pending...',
        'equity': 0.0,
      },
      buyerProfile: const {},
      scanData: null,
      loanId: null,
      pendingPushToken: null,
    );
  }

  AppData copyWith({
    String? userType,
    AppDataSource? dataSource,
    AppOnboardingStatus? onboardingStatus,
    String? profileName,
    String? profilePhone,
    Map<String, String>? carDetails,
    Map<String, dynamic>? financials,
    Map<String, dynamic>? buyerProfile,
    Map<String, dynamic>? scanData,
    bool keepScanData = true,
    String? loanId,
    bool keepLoanId = true,
    String? pendingPushToken,
    bool keepPendingPushToken = true,
  }) {
    return AppData(
      userType: userType ?? this.userType,
      dataSource: dataSource ?? this.dataSource,
      onboardingStatus: onboardingStatus ?? this.onboardingStatus,
      profileName: profileName ?? this.profileName,
      profilePhone: profilePhone ?? this.profilePhone,
      carDetails: carDetails ?? this.carDetails,
      financials: financials ?? this.financials,
      buyerProfile: buyerProfile ?? this.buyerProfile,
      scanData: keepScanData ? (scanData ?? this.scanData) : scanData,
      loanId: keepLoanId ? (loanId ?? this.loanId) : loanId,
      pendingPushToken: keepPendingPushToken
          ? (pendingPushToken ?? this.pendingPushToken)
          : pendingPushToken,
    );
  }

  bool get hasVehicleData =>
      (carDetails['year'] ?? '').isNotEmpty ||
      (carDetails['make'] ?? '').isNotEmpty ||
      (carDetails['model'] ?? '').isNotEmpty;

  bool get hasLoanData =>
      (loanId ?? '').isNotEmpty ||
      scanData != null && scanData!.isNotEmpty ||
      ((financials['userEstimatedLoan'] ?? 0) as num).toDouble() > 0 ||
      ((financials['actualRate'] ?? 0) as num).toDouble() > 0;

  bool get hasProfileData =>
      profileName.trim().isNotEmpty || profilePhone.trim().isNotEmpty;

  bool get hasBuyerProfile => buyerProfile.isNotEmpty;

  bool get hasAnyData =>
      hasVehicleData || hasLoanData || hasProfileData || hasBuyerProfile;

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': 1,
      'userType': userType,
      'dataSource': dataSource.storageValue,
      'onboardingStatus': onboardingStatus.storageValue,
      'profileName': profileName,
      'profilePhone': profilePhone,
      'carDetails': Map<String, String>.from(carDetails),
      'financials': _cloneDynamicMap(financials),
      'buyerProfile': _cloneDynamicMap(buyerProfile),
      'scanData': scanData == null ? null : _cloneDynamicMap(scanData!),
      'loanId': loanId,
      'pendingPushToken': pendingPushToken,
    };
  }

  String toStorageString() => jsonEncode(toJson());

  factory AppData.fromJson(Map<String, dynamic> json) {
    final rawCarDetails = (json['carDetails'] as Map?) ?? const {};
    final rawFinancials = (json['financials'] as Map?) ?? const {};
    final rawBuyerProfile = (json['buyerProfile'] as Map?) ?? const {};
    final rawScanData = json['scanData'];

    final initial = AppData.initial(
      userType: (json['userType'] ?? '').toString(),
      dataSource: AppDataSource.fromStorageValue(
        (json['dataSource'] ?? '').toString(),
      ),
    );

    return initial.copyWith(
      onboardingStatus: AppOnboardingStatus.fromStorageValue(
        (json['onboardingStatus'] ?? '').toString(),
      ),
      profileName: (json['profileName'] ?? '').toString(),
      profilePhone: (json['profilePhone'] ?? '').toString(),
      carDetails: {
        ...initial.carDetails,
        ...rawCarDetails.map(
          (key, value) => MapEntry(key.toString(), (value ?? '').toString()),
        ),
      },
      financials: {
        ...initial.financials,
        ...Map<String, dynamic>.from(rawFinancials.cast<dynamic, dynamic>()),
      },
      buyerProfile: Map<String, dynamic>.from(
        rawBuyerProfile.cast<dynamic, dynamic>(),
      ),
      scanData: rawScanData is Map
          ? Map<String, dynamic>.from(rawScanData.cast<dynamic, dynamic>())
          : null,
      keepScanData: false,
      loanId: (json['loanId'] ?? '').toString().trim().isEmpty
          ? null
          : (json['loanId'] ?? '').toString(),
      keepLoanId: false,
      pendingPushToken:
          (json['pendingPushToken'] ?? '').toString().trim().isEmpty
          ? null
          : (json['pendingPushToken'] ?? '').toString(),
      keepPendingPushToken: false,
    );
  }

  static Map<String, dynamic> _cloneDynamicMap(Map<String, dynamic> source) {
    return jsonDecode(jsonEncode(source)) as Map<String, dynamic>;
  }
}
