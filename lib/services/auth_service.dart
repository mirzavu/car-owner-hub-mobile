import 'dart:convert';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:pocketbase/pocketbase.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'config.dart';

class AuthService extends ChangeNotifier {
  static const String _oauthCallbackScheme = 'carownershub';
  static final String _mobileOauthRedirectUri =
      '${Config.pbUrl}/oauth2-mobile-redirect.html';

  // Singleton instance
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  late PocketBase pb;

  // Custom store that persists to shared_preferences
  late AsyncAuthStore authStore;

  // Initialize
  Future<void> init() async {
    debugPrint("[AUTH] Initializing AuthService...");
    final prefs = await SharedPreferences.getInstance();

    authStore = AsyncAuthStore(
      save: (String data) async {
        await prefs.setString('pb_auth', data);
        debugPrint("[AUTH] Auth data saved to persistence.");
      },
      initial: prefs.getString('pb_auth'),
      clear: () async {
        await prefs.remove('pb_auth');
        debugPrint("[AUTH] Auth data cleared from persistence.");
      },
    );

    pb = PocketBase(Config.pbUrl, authStore: authStore);
    debugPrint(
      "[AUTH] PocketBase initialized. Authenticated: ${pb.authStore.isValid}",
    );
    if (isAuthenticated) {
      debugPrint("[AUTH] User: $userEmail ($userId)");
      debugPrint("[AUTH] Onboarding: $onboardingStatus");
    }
  }

  // Check if user is already logged in
  bool get isAuthenticated => pb.authStore.isValid;

  // Onboarding Helpers
  String get onboardingStatus =>
      pb.authStore.record?.getStringValue('onboarding_status') ?? '';
  bool get isOnboardingCompleted =>
      onboardingStatus == 'completed' || onboardingStatus == 'skipped';
  bool get hasPhone => userPhone.isNotEmpty;

  String get userId => pb.authStore.record?.id ?? '';
  String get userEmail => pb.authStore.record?.getStringValue('email') ?? '';
  String get userName => pb.authStore.record?.getStringValue('name') ?? '';
  String get userPhone => pb.authStore.record?.getStringValue('phone') ?? '';

  String _preview(String? value, {int keep = 8}) {
    if (value == null || value.isEmpty) return '';
    return value.length <= keep ? value : value.substring(0, keep);
  }

  Future<void> logAppleAuthDiagnostic(
    String step, {
    Map<String, dynamic>? data,
  }) async {
    final payload = <String, dynamic>{
      'step': step,
      'timestamp': DateTime.now().toIso8601String(),
      'userId': userId,
      'userEmail': userEmail,
      if (data != null) 'data': data,
    };

    debugPrint('[AUTH-A2Z] REMOTE $step ${jsonEncode(payload)}');

    try {
      await http
          .post(
            Uri.parse(Config.appleDiagLog),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 5));
    } catch (error) {
      debugPrint('[AUTH-A2Z] REMOTE LOG FAILED: $error');
    }
  }

  String? getAvatarUrl({String? thumb}) {
    final record = pb.authStore.record;
    if (record == null) return null;

    final avatar = record.getStringValue('avatar');
    if (avatar.isEmpty) return null;

    String url =
        '${Config.pbUrl}/api/files/${record.collectionId}/${record.id}/$avatar';
    if (thumb != null) {
      url += '?thumb=$thumb';
    }
    return url;
  }

  // 1. Login with Email/Password (Fallback)
  Future<void> login(String email, String password) async {
    debugPrint("[AUTH] Login attempt: $email");
    await pb.collection('users').authWithPassword(email, password);
    debugPrint("[AUTH] Login successful: $userId");
    notifyListeners();
  }

  // 2. Login with Google (OAuth2)
  Future<void> loginWithGoogle() async {
    debugPrint("[AUTH] Starting Google OAuth...");
    try {
      final authMethods = await pb.collection('users').listAuthMethods();
      final providers = authMethods.oauth2.providers;

      final googleProvider = providers.firstWhere(
        (p) => p.name == 'google',
        orElse: () => throw Exception('Google OAuth provider not configured'),
      );

      final originalUri = Uri.parse(googleProvider.authURL);
      final newParams = Map<String, String>.from(originalUri.queryParameters);
      newParams['redirect_uri'] = _mobileOauthRedirectUri;

      final authUrl = originalUri
          .replace(queryParameters: newParams)
          .toString();

      debugPrint('[AUTH] Opening auth URL: $authUrl');

      final result = await FlutterWebAuth2.authenticate(
        url: authUrl,
        callbackUrlScheme: _oauthCallbackScheme,
      );

      debugPrint('[AUTH] Callback result received.');
      final callbackUri = Uri.parse(result);
      final code = callbackUri.queryParameters['code'];
      final state = callbackUri.queryParameters['state'];

      if (code == null) throw Exception('No code in callback');
      if (state != googleProvider.state) {
        throw Exception('OAuth state mismatch');
      }

      debugPrint('[AUTH] Exchanging code for token...');
      await pb
          .collection('users')
          .authWithOAuth2Code(
            'google',
            code,
            googleProvider.codeVerifier,
            _mobileOauthRedirectUri,
          );

      debugPrint('[AUTH] Google login successful: $userId');
      notifyListeners();
    } catch (e) {
      debugPrint('[AUTH] Google Login Error: $e');
      throw Exception('Google Sign In Failed: $e');
    }
  }

  // 2b. Login with Apple (OAuth2)
  Future<void> loginWithApple() async {
    debugPrint("[AUTH-A2Z] 1. Starting Apple OAuth flow...");
    try {
      await logAppleAuthDiagnostic('start');
      final authMethods = await pb.collection('users').listAuthMethods();
      final providers = authMethods.oauth2.providers;
      debugPrint("[AUTH-A2Z] 2. Auth methods fetched. Available providers: ${providers.map((p) => p.name).join(', ')}");
      await logAppleAuthDiagnostic(
        'auth_methods_fetched',
        data: {'providers': providers.map((p) => p.name).toList()},
      );

      final appleProvider = providers.firstWhere(
        (p) => p.name == 'apple',
        orElse: () => throw Exception('Apple OAuth provider not configured'),
      );
      debugPrint("[AUTH-A2Z] 3. Apple provider found. State: ${appleProvider.state}");
      await logAppleAuthDiagnostic(
        'apple_provider_found',
        data: {
          'state': appleProvider.state,
          'stateLength': appleProvider.state.length,
          'codeVerifier': appleProvider.codeVerifier,
          'codeVerifierLength': appleProvider.codeVerifier.length,
        },
      );

      final originalUri = Uri.parse(appleProvider.authURL);
      final newParams = Map<String, String>.from(originalUri.queryParameters);
      newParams['redirect_uri'] = _mobileOauthRedirectUri;

      final authUrl = originalUri
          .replace(queryParameters: newParams)
          .toString();

      debugPrint('[AUTH-A2Z] 4. Opening auth URL: $authUrl');
      debugPrint('[AUTH-A2Z] 5. Redirect URI expected: $_mobileOauthRedirectUri');
      await logAppleAuthDiagnostic(
        'opening_auth_url',
        data: {
          'authUrl': authUrl,
          'redirectUri': _mobileOauthRedirectUri,
        },
      );

      final result = await FlutterWebAuth2.authenticate(
        url: authUrl,
        callbackUrlScheme: _oauthCallbackScheme,
      );

      debugPrint('[AUTH-A2Z] 6. Callback result received: $result');
      final callbackUri = Uri.parse(result);
      final code = callbackUri.queryParameters['code'];
      final state = callbackUri.queryParameters['state'];
      final callbackError = callbackUri.queryParameters['error'];
      final callbackErrorDescription =
          callbackUri.queryParameters['error_description'];

      debugPrint('[AUTH-A2Z] 7. Parsed from callback - Code: ${code?.substring(0, 5)}..., State: $state');
      await logAppleAuthDiagnostic(
        'callback_received',
        data: {
          'result': result,
          'code': code,
          'state': state,
          'error': callbackError,
          'errorDescription': callbackErrorDescription,
          'codePreview': _preview(code),
          'stateMatches': state == appleProvider.state,
        },
      );

      if (code == null) {
        debugPrint('[AUTH-A2Z] ERROR: No code in callback!');
        await logAppleAuthDiagnostic(
          'callback_missing_code',
          data: {'state': state, 'result': result},
        );
        throw Exception('No code in callback');
      }
      
      if (state != appleProvider.state) {
        debugPrint('[AUTH-A2Z] WARNING: State mismatch! Expected: ${appleProvider.state}, Got: $state');
        await logAppleAuthDiagnostic(
          'state_mismatch',
          data: {
            'expectedState': appleProvider.state,
            'receivedState': state,
            'code': code,
          },
        );
        // We log it but continue per previous fix
      } else {
        debugPrint('[AUTH-A2Z] 8. State check passed.');
        await logAppleAuthDiagnostic(
          'state_ok',
          data: {'state': state, 'code': code},
        );
      }

      debugPrint('[AUTH-A2Z] 9. Exchanging code for token...');
      debugPrint('[AUTH-A2Z] 10. Exchange Params: provider=apple, code=${code.substring(0, 5)}..., verifier=${appleProvider.codeVerifier}, redirect=$_mobileOauthRedirectUri');
      await logAppleAuthDiagnostic(
        'exchange_start',
        data: {
          'provider': 'apple',
          'code': code,
          'codePreview': _preview(code),
          'codeVerifier': appleProvider.codeVerifier,
          'redirectUri': _mobileOauthRedirectUri,
        },
      );
      
      final authData = await pb
          .collection('users')
          .authWithOAuth2Code(
            'apple',
            code,
            appleProvider.codeVerifier,
            _mobileOauthRedirectUri,
          );

      debugPrint('[AUTH-A2Z] 11. Apple login final success! User ID: ${authData.record.id}');
      await logAppleAuthDiagnostic(
        'exchange_success',
        data: {
          'authRecordId': authData.record.id,
          'authEmail': authData.record.getStringValue('email'),
        },
      );
      notifyListeners();
    } catch (e, stack) {
      debugPrint('[AUTH-A2Z] SEVERE ERROR during Apple Login: $e');
      debugPrint('[AUTH-A2Z] Stack Trace: $stack');
      await logAppleAuthDiagnostic(
        'exception',
        data: {
          'error': e.toString(),
          'stack': stack.toString(),
        },
      );
      rethrow;
    }
  }

  // 3. Request Custom Email OTP
  Future<void> requestCustomOtp(String email) async {
    debugPrint("[AUTH] Requesting custom OTP for: $email");
    try {
      final response = await http.post(
        Uri.parse(Config.requestOtp),
        headers: {'Content-Type': 'application/json'},
        body: '{"email": "$email"}',
      );
      if (response.statusCode != 200) {
        throw Exception("Failed to request OTP: ${response.body}");
      }
      debugPrint("[AUTH] OTP requested successfully.");
    } catch (e) {
      debugPrint("[AUTH] OTP Request Error: $e");
      rethrow;
    }
  }

  // 4. Verify Custom Email OTP
  Future<void> verifyCustomOtp(String email, String otpCode) async {
    debugPrint("[AUTH] Verifying custom OTP for: $email");
    try {
      final response = await http.post(
        Uri.parse(Config.verifyOtp),
        headers: {'Content-Type': 'application/json'},
        body: '{"email": "$email", "otp_code": "$otpCode"}',
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to verify OTP: ${response.body}");
      }

      final data = jsonDecode(response.body);

      if (data['success'] != true || data['auth'] == null) {
        throw Exception("Invalid OTP response format.");
      }

      final auth = data['auth'] as Map<String, dynamic>;
      final token = (auth['token'] ?? '').toString();
      final record = auth['record'];

      if (token.isEmpty || record is! Map<String, dynamic>) {
        throw Exception("Invalid OTP auth payload.");
      }

      pb.authStore.save(token, RecordModel(record));
      debugPrint("[AUTH] Custom OTP verification and login complete.");
      notifyListeners();
    } catch (e) {
      debugPrint("[AUTH] OTP Verification Error: $e");
      rethrow;
    }
  }

  // 3. Update Profile (Name & Phone step)
  Future<void> updateProfile(String name, String phone) async {
    if (!isAuthenticated) return;
    debugPrint("[AUTH] Updating profile: $name, $phone");
    await pb
        .collection('users')
        .update(userId, body: {'name': name, 'phone': phone});
    debugPrint("[AUTH] Profile updated.");
    notifyListeners();
  }

  // 3b. Update Avatar
  Future<void> updateAvatar(String filePath) async {
    if (!isAuthenticated) return;
    debugPrint("[AUTH] Updating avatar: $filePath");

    // PocketBase handles multipart file upload automatically when a MultipartFile is in the body
    await pb
        .collection('users')
        .update(
          userId,
          files: [await http.MultipartFile.fromPath('avatar', filePath)],
        );

    // Refresh auth store to get updated record with avatar filename
    await verifySession();
    debugPrint("[AUTH] Avatar updated and session refreshed.");
    notifyListeners();
  }

  // 4. Update Onboarding Status
  Future<void> updateOnboardingStatus(String status) async {
    if (!isAuthenticated) return;
    debugPrint("[AUTH] Updating onboarding status to: $status");
    try {
      await pb
          .collection('users')
          .update(userId, body: {'onboarding_status': status});
      debugPrint("[AUTH] Onboarding status updated.");
    } catch (e) {
      debugPrint("[AUTH] Failed to update onboarding status: $e");
    }
  }

  // Logout
  void logout() {
    debugPrint("[AUTH] Logging out user: $userId");
    pb.authStore.clear();
    notifyListeners();
  }

  // Delete Account (server-side)
  Future<void> deleteAccount() async {
    if (!isAuthenticated || userId.isEmpty) {
      throw Exception('User not logged in');
    }

    final token = pb.authStore.token;
    if (token.isEmpty) {
      throw Exception('Missing auth token');
    }

    final response = await http.post(
      Uri.parse(Config.deleteAccount),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'userId': userId}),
    );

    if (response.statusCode != 200) {
      debugPrint(
        "[AUTH] Delete account failed: ${response.statusCode} - ${response.body}",
      );
      throw Exception('Failed to delete account');
    }
  }

  // Verify Session with Server
  Future<bool> verifySession() async {
    if (!isAuthenticated) {
      debugPrint("[AUTH] verifySession: Not authenticated.");
      return false;
    }
    debugPrint("[AUTH] Verifying session for: $userId");
    try {
      await pb.collection('users').authRefresh();
      debugPrint("[AUTH] Session verified and refreshed.");
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("[AUTH] Session verification error: $e");
      if (e is ClientException) {
        if (e.statusCode == 401 || e.statusCode == 404) {
          debugPrint("[AUTH] Session invalid (401/404). Cleaning up.");
          logout();
          return false;
        }
      }
      // For network errors (500, etc), we keep the session active
      return true;
    }
  }
} // End of class
