import 'dart:io';
import 'package:flutter/foundation.dart';

class Config {
  // 1. Determine the Base URL based on the platform
  static String get baseUrl {
    if (kReleaseMode) {
      // Production URL (Phase 3)
      return 'https://your-production-url.com';
    }

    // Development URLs
    if (Platform.isAndroid) {
      // Android Emulator uses 10.0.2.2 to access host localhost
      // BUT if 10.0.2.2 fails, we force LAN IP which works for both Emulator & Real Device
      return 'http://192.168.29.174:3000';
    } else if (Platform.isIOS) {
      // iOS Simulator uses localhost
      return 'http://127.0.0.1:3000';
    } else {
      // Real Device (assuming default, can be overridden)
      // Check if we can detect loopback vs real IP, but for now
      // strict 10.0.2.2 for android emulator is key.
      // For real device testing, users typically need to put their LAN IP.
      // We will default to a common LAN IP placeholder or localhost if not on mobile OS.
      if (!Platform.isAndroid && !Platform.isIOS) {
        return 'http://localhost:3000'; // Desktop/Web dev
      }
      // Detected LAN IP from hostname -I
      return 'http://192.168.29.174:3000';
    }
  }

  // PocketBase URL (Usually on port 8090)
  static String get pbUrl {
    if (kReleaseMode) return 'https://your-pb-url.com';
    if (Platform.isAndroid) return 'http://10.0.2.2:8090';
    if (Platform.isIOS) return 'http://127.0.0.1:8090';
    if (!Platform.isAndroid && !Platform.isIOS) {
      return 'http://127.0.0.1:8090';
    }
    return 'http://192.168.29.174:8090';
  }

  // API Endpoints
  static String get scanDoc => '$baseUrl/api/scan-document';
  static String get dashboard => '$baseUrl/api/dashboard';
  static String get inventory => '$baseUrl/api/inventory';
  static String get submitLead => '$baseUrl/api/submit-lead';
  static String get estimateValue => '$baseUrl/api/estimate-value';
}
