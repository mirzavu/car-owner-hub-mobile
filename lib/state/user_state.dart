import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/app_data.dart';

class UserState {
  final String userType; // 'owner' or 'buyer'
  final String tempPhone;
  final String profileName;
  final String profilePhone;
  final AppOnboardingStatus onboardingStatus;
  final AppDataSource dataSource;

  const UserState({
    required this.userType,
    required this.tempPhone,
    required this.profileName,
    required this.profilePhone,
    required this.onboardingStatus,
    required this.dataSource,
  });

  factory UserState.initial() {
    return const UserState(
      userType: 'owner',
      tempPhone: '',
      profileName: '',
      profilePhone: '',
      onboardingStatus: AppOnboardingStatus.newUser,
      dataSource: AppDataSource.guestLocal,
    );
  }

  UserState copyWith({
    String? userType,
    String? tempPhone,
    String? profileName,
    String? profilePhone,
    AppOnboardingStatus? onboardingStatus,
    AppDataSource? dataSource,
  }) {
    return UserState(
      userType: userType ?? this.userType,
      tempPhone: tempPhone ?? this.tempPhone,
      profileName: profileName ?? this.profileName,
      profilePhone: profilePhone ?? this.profilePhone,
      onboardingStatus: onboardingStatus ?? this.onboardingStatus,
      dataSource: dataSource ?? this.dataSource,
    );
  }

  bool get isGuest => dataSource == AppDataSource.guestLocal;
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

  void setProfile({
    String? name,
    String? phone,
    AppOnboardingStatus? onboardingStatus,
    AppDataSource? dataSource,
  }) {
    state = state.copyWith(
      profileName: name,
      profilePhone: phone,
      onboardingStatus: onboardingStatus,
      dataSource: dataSource,
    );
  }

  void hydrateFromAppData(AppData data) {
    state = state.copyWith(
      userType: data.userType,
      profileName: data.profileName,
      profilePhone: data.profilePhone,
      onboardingStatus: data.onboardingStatus,
      dataSource: data.dataSource,
    );
  }

  void reset({String? userType}) {
    state = UserState.initial().copyWith(userType: userType ?? state.userType);
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserState>(
  (ref) => UserNotifier(),
);
