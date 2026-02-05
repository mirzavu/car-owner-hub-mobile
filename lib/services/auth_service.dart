import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:pocketbase/pocketbase.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

class AuthService {
  // Singleton instance
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  late PocketBase pb;

  // Custom store that persists to shared_preferences
  late AsyncAuthStore authStore;

  // Initialize
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    authStore = AsyncAuthStore(
      save: (String data) async => prefs.setString('pb_auth', data),
      initial: prefs.getString('pb_auth'),
      clear: () async => prefs.remove('pb_auth'),
    );

    pb = PocketBase(Config.pbUrl, authStore: authStore);

    debugPrint("AuthService Initialized");
    debugPrint("Is Authenticated: $isAuthenticated");
    if (isAuthenticated) {
      debugPrint("User ID: $userId");
      debugPrint("Onboarding Status: $onboardingStatus");
      debugPrint("User Phone: $userPhone");
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
  String get userPhone => pb.authStore.record?.getStringValue('phone') ?? '';

  // 1. Login with Email/Password (Fallback)
  Future<void> login(String email, String password) async {
    await pb.collection('users').authWithPassword(email, password);
  }

  // 2. Login with Google (Manual OAuth2 Code Exchange - Android 15+ Compatible)
  // Uses flutter_web_auth_2 with Chrome Auth Tab + custom web redirect page
  Future<void> loginWithGoogle() async {
    try {
      // Step 1: Get available OAuth2 providers from PocketBase
      final authMethods = await pb.collection('users').listAuthMethods();
      final providers = authMethods.oauth2.providers;

      // Find Google provider
      final googleProvider = providers.firstWhere(
        (p) => p.name == 'google',
        orElse: () => throw Exception('Google OAuth provider not configured'),
      );

      // Step 2: Build the authorization URL with our HTTPS redirect page
      // This page will then redirect to the app via deep link
      const callbackScheme = 'carownerhub';
      const webRedirectUri =
          'https://pb.carowner.demotesting.co.uk/oauth2-mobile-redirect.html';

      // The authURL from PocketBase includes the base params.
      // We must REPLACE the default redirect_uri with our custom one.
      final originalUri = Uri.parse(googleProvider.authURL);
      final newParams = Map<String, String>.from(originalUri.queryParameters);
      newParams['redirect_uri'] = webRedirectUri;

      final authUrl = originalUri
          .replace(queryParameters: newParams)
          .toString();

      debugPrint('[OAuth] Opening auth URL: $authUrl');
      debugPrint('[OAuth] Code verifier: ${googleProvider.codeVerifier}');
      debugPrint('[OAuth] State: ${googleProvider.state}');

      // Step 3: Open Chrome Auth Tab and wait for deep link callback
      // The web redirect page will redirect to carownerhub://oauth2callback?code=xxx&state=yyy
      final result = await FlutterWebAuth2.authenticate(
        url: authUrl,
        callbackUrlScheme: callbackScheme,
      );

      debugPrint('[OAuth] Callback result: $result');

      // Step 4: Parse the callback URL to extract code and state
      final callbackUri = Uri.parse(result);
      final code = callbackUri.queryParameters['code'];
      final state = callbackUri.queryParameters['state'];

      if (code == null) {
        throw Exception('Authorization code not found in callback');
      }

      // Verify state matches
      if (state != googleProvider.state) {
        debugPrint(
          '[OAuth] State mismatch - expected: ${googleProvider.state}, got: $state',
        );
        throw Exception('OAuth state mismatch - possible CSRF attack');
      }

      debugPrint('[OAuth] Code received, exchanging for token...');

      // Step 5: Exchange the authorization code for tokens via PocketBase
      // IMPORTANT: Use the same redirect URI that was used in the authorization request
      await pb
          .collection('users')
          .authWithOAuth2Code(
            'google',
            code,
            googleProvider.codeVerifier,
            webRedirectUri,
          );

      debugPrint('[OAuth] Authentication successful!');
      debugPrint('[OAuth] User ID: ${pb.authStore.record?.id}');
      debugPrint(
        '[OAuth] Email: ${pb.authStore.record?.getStringValue('email')}',
      );
    } catch (e) {
      debugPrint('[OAuth] Error: $e');
      throw Exception('Google Sign In Failed: $e');
    }
  }

  // 3. Update Profile (Phone Number step)
  Future<void> updatePhone(String phone) async {
    if (!isAuthenticated) return;
    await pb.collection('users').update(userId, body: {'phone': phone});
  }

  // 4. Update Onboarding Status
  Future<void> updateOnboardingStatus(String status) async {
    if (!isAuthenticated) {
      debugPrint("Cannot update onboarding status: Not authenticated");
      return;
    }

    try {
      debugPrint("Updating onboarding status to: $status for user: $userId");
      final record = await pb
          .collection('users')
          .update(userId, body: {'onboarding_status': status});

      debugPrint("Update Response Data: ${record.data}");

      // Refresh auth store to get updated record
      debugPrint("Refreshing auth store...");
      await pb.collection('users').authRefresh();

      debugPrint("AuthStore Record Data: ${pb.authStore.record?.data}");
      debugPrint("New Onboarding Status via getter: $onboardingStatus");
    } catch (e) {
      debugPrint("Error updating onboarding status: $e");
    }
  }

  // Logout
  void logout() {
    pb.authStore.clear();
  }
}
