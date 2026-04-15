import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_data.dart';

class LocalStorageService {
  LocalStorageService._internal();

  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;

  static const String _guestAppDataKey = 'guest_app_data_v1';

  Future<AppData?> loadAppData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_guestAppDataKey);
      if (raw == null || raw.trim().isEmpty) {
        return null;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      return AppData.fromJson(decoded);
    } catch (error) {
      debugPrint('[LOCAL] Failed to load guest app data: $error');
      return null;
    }
  }

  Future<void> saveAppData(AppData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_guestAppDataKey, data.toStorageString());
    } catch (error) {
      debugPrint('[LOCAL] Failed to save guest app data: $error');
      rethrow;
    }
  }

  Future<void> clearAppData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_guestAppDataKey);
    } catch (error) {
      debugPrint('[LOCAL] Failed to clear guest app data: $error');
    }
  }
}
