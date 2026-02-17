import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'auth_service.dart';

class PushTokenService {
  PushTokenService._internal();

  static final PushTokenService _instance = PushTokenService._internal();
  factory PushTokenService() => _instance;

  bool _initialized = false;
  String _lastSyncedToken = '';
  StreamSubscription<String>? _tokenRefreshSubscription;

  Future<String?> initAndSyncToken() async {
    final auth = AuthService();
    if (!auth.isAuthenticated || auth.userId.isEmpty) return null;

    try {
      if (!_initialized) {
        await _initializeFirebase();
        _initialized = true;
      }

      await _requestPermission();
      final token = await _syncCurrentToken();

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
    if (!auth.isAuthenticated || auth.userId.isEmpty) return;

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
