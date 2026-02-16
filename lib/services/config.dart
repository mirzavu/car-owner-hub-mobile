import 'dart:io';
import 'package:flutter/foundation.dart';

class Config {
  // 1. Determine the Base URL based on the platform
  static String get baseUrl {
    // Check if provided via build-args (e.g. flutter build --define=BACKEND_URL=...)
    const String fromEnv = String.fromEnvironment('BACKEND_URL');
    if (fromEnv.isNotEmpty) return fromEnv;

    if (kReleaseMode) {
      // Production URL placeholder (Should be set via --define in CI/CD)
      return 'https://api.carownershub.com';
    }

    // Development URLs
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3007'; // Standard Android Emulator loopback
    } else if (Platform.isIOS) {
      return 'http://127.0.0.1:3007';
    } else {
      return 'http://localhost:3007';
    }
  }

  // PocketBase URL
  static String get pbUrl {
    const String fromEnv = String.fromEnvironment('POCKETBASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;

    if (kReleaseMode) {
      return 'https://pb.carownershub.com';
    }

    return 'http://127.0.0.1:8097';
  }

  // API Endpoints
  static String get scanDoc => '$baseUrl/api/scan-document';
  static String get dashboard => '$baseUrl/api/dashboard';
  static String get inventory => '$baseUrl/api/inventory';
  static String get submitLead => '$baseUrl/api/submit-lead';
  static String get estimateValue => '$baseUrl/api/estimate-value';
  static String get calculateEquity => '$baseUrl/api/calculate-equity';
}
