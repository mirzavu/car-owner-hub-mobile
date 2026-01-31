import 'package:pocketbase/pocketbase.dart';
import 'package:url_launcher/url_launcher.dart';
import 'config.dart';

class AuthService {
  // Singleton instance
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  late PocketBase pb;

  // Initialize
  void init() {
    pb = PocketBase(Config.pbUrl);
  }

  // Check if user is already logged in
  bool get isAuthenticated => pb.authStore.isValid;
  String get userId => pb.authStore.record?.id ?? '';
  String get userEmail => pb.authStore.record?.getStringValue('email') ?? '';

  // 1. Login with Email/Password (Fallback)
  Future<void> login(String email, String password) async {
    await pb.collection('users').authWithPassword(email, password);
  }

  // 2. Login with Google (The Main Method)
  Future<void> loginWithGoogle() async {
    await pb.collection('users').authWithOAuth2('google', (url) async {
      // This callback opens the browser for the user to sign in
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    });
  }

  // 3. Update Profile (Phone Number step)
  Future<void> updatePhone(String phone) async {
    if (!isAuthenticated) return;
    await pb.collection('users').update(userId, body: {'phone': phone});
  }

  // Logout
  void logout() {
    pb.authStore.clear();
  }
}
