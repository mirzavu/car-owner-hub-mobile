import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';

class PushTokenService {
  PushTokenService._internal();

  static final PushTokenService _instance = PushTokenService._internal();
  factory PushTokenService() => _instance;
  static const String _pushEnabledPrefKeyBase = 'push_notifications_enabled';
  static const String _guestPendingTokenKey = 'guest_pending_fcm_token';

  bool _initialized = false;
  String _lastSyncedToken = '';
  StreamSubscription<String>? _tokenRefreshSubscription;

  Future<String?> initAndSyncToken({bool force = false}) async {
    if (!force) {
      final shouldSync = await _shouldSyncToken();
      if (!shouldSync) {
        debugPrint(
          '[PUSH] initAndSyncToken skipped (disabled by user preference).',
        );
        return null;
      }
    }

    try {
      if (!_initialized) {
        await _initializeFirebase();
        _initialized = true;
      }

      await _requestPermission();
      final token = await _syncCurrentToken();
      if (token != null && token.isNotEmpty) {
        await _setPushPreference(true);
      }

      _tokenRefreshSubscription ??= FirebaseMessaging.instance.onTokenRefresh
          .listen((token) {
            _syncToken(token);
          });
      return token;
    } catch (error) {
      debugPrint('[PUSH] initAndSyncToken failed: $error');
      return null;
    }
  }

  Future<bool> getPushNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _pushPreferenceKey();
    if (prefs.containsKey(key)) {
      return prefs.getBool(key) ?? true;
    }

    // Backward compatibility for older builds that used a global key.
    if (prefs.containsKey(_pushEnabledPrefKeyBase)) {
      return prefs.getBool(_pushEnabledPrefKeyBase) ?? true;
    }

    final auth = AuthService();
    if (!auth.isAuthenticated) return true;
    final existingToken =
        auth.pb.authStore.record?.getStringValue('fcm_token') ?? '';
    return existingToken.isNotEmpty;
  }

  Future<void> enablePushNotifications() async {
    final token = await initAndSyncToken(force: true);
    if (token == null || token.isEmpty) {
      throw Exception(
        'Unable to enable push notifications. Please allow notification permission and try again.',
      );
    }
    await _setPushPreference(true);
  }

  Future<void> disablePushNotifications() async {
    final auth = AuthService();
    if (auth.isAuthenticated && auth.userId.isNotEmpty) {
      await auth.pb
          .collection('users')
          .update(auth.userId, body: {'fcm_token': ''});
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestPendingTokenKey);

    _lastSyncedToken = '';

    if (_initialized) {
      try {
        await FirebaseMessaging.instance.deleteToken();
      } catch (error) {
        debugPrint('[PUSH] deleteToken failed: $error');
      }
    }

    await _setPushPreference(false);
  }

  Future<bool> _shouldSyncToken() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _pushPreferenceKey();
    if (prefs.containsKey(key)) {
      return prefs.getBool(key) ?? true;
    }
    if (prefs.containsKey(_pushEnabledPrefKeyBase)) {
      return prefs.getBool(_pushEnabledPrefKeyBase) ?? true;
    }
    return true;
  }

  Future<void> _setPushPreference(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _pushPreferenceKey();
    await prefs.setBool(key, enabled);
    // Clean up legacy global key after first successful write.
    await prefs.remove(_pushEnabledPrefKeyBase);
  }

  String _pushPreferenceKey() {
    final userId = AuthService().userId.trim();
    if (userId.isEmpty) return _pushEnabledPrefKeyBase;
    return '${_pushEnabledPrefKeyBase}_$userId';
  }

  Future<void> _initializeFirebase() async {
    if (Firebase.apps.isNotEmpty) return;

    try {
      await Firebase.initializeApp();
    } catch (error) {
      // Firebase config may be missing in local/dev until mobile setup is complete.
      debugPrint('[PUSH] Firebase initialization skipped: $error');
      rethrow;
    }
  }

  Future<void> _requestPermission() async {
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    } catch (error) {
      debugPrint('[PUSH] requestPermission failed: $error');
    }
  }

  Future<String?> _syncCurrentToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return null;
      await _syncToken(token);
      return token;
    } catch (error) {
      debugPrint('[PUSH] getToken failed: $error');
      return null;
    }
  }

  Future<void> _syncToken(String token) async {
    if (token.isEmpty) return;

    final auth = AuthService();
    final prefs = await SharedPreferences.getInstance();
    if (!auth.isAuthenticated || auth.userId.isEmpty) {
      await prefs.setString(_guestPendingTokenKey, token);
      _lastSyncedToken = token;
      return;
    }

    if (_lastSyncedToken == token) return;

    final existingToken =
        auth.pb.authStore.record?.getStringValue('fcm_token') ?? '';
    if (existingToken == token) {
      _lastSyncedToken = token;
      return;
    }

    try {
      await auth.pb
          .collection('users')
          .update(auth.userId, body: {'fcm_token': token});
      await prefs.remove(_guestPendingTokenKey);
      _lastSyncedToken = token;
      debugPrint('[PUSH] FCM token synced for user ${auth.userId}');
    } catch (error) {
      debugPrint('[PUSH] Failed to sync FCM token: $error');
    }
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
  }
}
