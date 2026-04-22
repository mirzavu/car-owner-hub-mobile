import 'package:flutter/foundation.dart';

class Config {
  static const String androidLanHost = String.fromEnvironment(
    'ANDROID_DEV_HOST',
    defaultValue: '192.168.29.174',
  );

  // 1. Determine the Base URL based on the platform
  static String get baseUrl {
    // Check if provided via build-args
    const String fromEnv = String.fromEnvironment('BACKEND_URL');
    if (fromEnv.isNotEmpty) return fromEnv;

    // Easy toggle for production
    const String appEnv = String.fromEnvironment('APP_ENV');
    if (appEnv == 'prod') return 'https://api.carownershub.app';

    if (kReleaseMode) {
      // Production URL fallback
      return 'https://api.carownershub.app';
    }

    // Web and desktop dev builds should talk to localhost by default.
    if (kIsWeb) return 'http://localhost:3077';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://$androidLanHost:3077';
      case TargetPlatform.iOS:
        return 'http://127.0.0.1:3077';
      default:
        return 'http://localhost:3077';
    }
  }

  // PocketBase URL
  static String get pbUrl {
    const String fromEnv = String.fromEnvironment('POCKETBASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;

    // Easy toggle for production
    const String appEnv = String.fromEnvironment('APP_ENV');
    if (appEnv == 'prod') return 'https://pb.carownershub.app';

    if (kReleaseMode) {
      return 'https://pb.carownershub.app';
    }

    if (kIsWeb) return 'http://localhost:8077';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://$androidLanHost:8077';
      case TargetPlatform.iOS:
        return 'http://127.0.0.1:8077';
      default:
        return 'http://localhost:8077';
    }
  }

  // API Endpoints
  static String get scanDoc => '$baseUrl/api/scan-document';
  static String get parseLoanDetails => '$baseUrl/api/parse-loan-details';
  static String get dashboard => '$baseUrl/api/dashboard';
  static String get inventory => '$baseUrl/api/inventory';
  static String get tradeUpPreview => '$baseUrl/api/trade-up-preview';
  static String get submitLead => '$baseUrl/api/submit-lead';
  static String get estimateValue => '$baseUrl/api/estimate-value';
  static String get calculateEquity => '$baseUrl/api/calculate-equity';
  static String get notifications => '$baseUrl/api/notifications';
  static String get notificationsMarkRead =>
      '$baseUrl/api/notifications/mark-read';
  static String get activity => '$baseUrl/api/activity';
  static String get uploadGarageDoc => '$baseUrl/api/upload-garage-doc';
  static String get deleteAccount => '$baseUrl/api/account/delete';

  // OTP Endpoints
  static String get requestOtp => '$baseUrl/api/auth/request-otp';
  static String get verifyOtp => '$baseUrl/api/auth/verify-otp';
}
