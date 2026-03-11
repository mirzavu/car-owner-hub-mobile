import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserState {
  final String userType; // 'owner' or 'buyer'
  final String tempPhone;

  const UserState({
    required this.userType,
    required this.tempPhone,
  });

  factory UserState.initial() {
    return const UserState(userType: 'owner', tempPhone: '');
  }

  UserState copyWith({
    String? userType,
    String? tempPhone,
  }) {
    return UserState(
      userType: userType ?? this.userType,
      tempPhone: tempPhone ?? this.tempPhone,
    );
  }
}

class UserNotifier extends StateNotifier<UserState> {
  UserNotifier() : super(UserState.initial());

  static const String _userTypeStorageKey = 'selected_user_type';

  Future<String?> restoreUserType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedType = prefs.getString(_userTypeStorageKey);
      if (storedType == 'owner' || storedType == 'buyer') {
        state = state.copyWith(userType: storedType);
        return storedType;
      }
    } catch (e) {
      // Best effort restore only.
    }
    return null;
  }

  Future<void> persistUserType(String type) async {
    if (type != 'owner' && type != 'buyer') return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userTypeStorageKey, type);
    } catch (e) {
      // Best effort persist only.
    }
  }

  void setUserType(String type) {
    if (type != 'owner' && type != 'buyer') return;
    state = state.copyWith(userType: type);
    persistUserType(type);
  }

  void setTempPhone(String value) {
    state = state.copyWith(tempPhone: value);
  }

  void clearTempPhone() {
    state = state.copyWith(tempPhone: '');
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserState>(
  (ref) => UserNotifier(),
);
