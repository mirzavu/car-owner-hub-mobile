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
  static const String _softPromptShownKey = 'notification_soft_prompt_shown';

  bool _initialized = false;
  String _lastSyncedToken = '';
  StreamSubscription<String>? _tokenRefreshSubscription;

  Future<String?> initAndSyncToken({
    bool force = false,
    bool requestPermission = true,
  }) async {
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
      await _ensureFirebaseInitialized();

      if (requestPermission) {
        final status = await _requestPermission();
        if (status == AuthorizationStatus.denied) {
          debugPrint('[PUSH] Permission denied during initAndSyncToken');
          return null;
        }
      }
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
    await _ensureFirebaseInitialized();

    // 1. Check current status
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      throw Exception(
        'Notification permission is denied. Please enable it in your device settings to receive push notifications.',
      );
    }

    // 2. Request/Refresh token
    final token = await initAndSyncToken(force: true);

    if (token == null || token.isEmpty) {
      // iOS specific check: APNS token might be missing due to config/entitlements
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken == null) {
          throw Exception(
            'Unable to fetch APNS token. If this is a real device, please check your internet connection and ensure the app has push capabilities configured.',
          );
        }
      }

      throw Exception(
        'Unable to enable push notifications. Please ensure you have allowed notification permissions and try again.',
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

  Future<AuthorizationStatus> getAuthorizationStatus() async {
    try {
      await _ensureFirebaseInitialized();
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      return settings.authorizationStatus;
    } catch (error) {
      debugPrint('[PUSH] getAuthorizationStatus failed: $error');
      return AuthorizationStatus.denied;
    }
  }

  Future<bool> hasShownSoftPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_softPromptShownKey) ?? false;
  }

  Future<void> markSoftPromptShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_softPromptShownKey, true);
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
    if (Firebase.apps.isNotEmpty) {
      _initialized = true;
      return;
    }

    try {
      await Firebase.initializeApp();
      _initialized = true;
    } catch (error) {
      // Firebase config may be missing in local/dev until mobile setup is complete.
      debugPrint('[PUSH] Firebase initialization skipped: $error');
      rethrow;
    }
  }

  Future<void> _ensureFirebaseInitialized() async {
    if (_initialized && Firebase.apps.isNotEmpty) return;
    await _initializeFirebase();
    if (Firebase.apps.isEmpty) {
      throw Exception(
        'Firebase is not configured for this build. Initialize Firebase before using push notifications.',
      );
    }
  }

  Future<AuthorizationStatus> _requestPermission() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      debugPrint(
        '[PUSH] Permission requested. Status: ${settings.authorizationStatus}',
      );
      return settings.authorizationStatus;
    } catch (error) {
      debugPrint('[PUSH] requestPermission failed: $error');
      return AuthorizationStatus.notDetermined;
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
