import 'package:shared_preferences/shared_preferences.dart';

import '../models/local_user.dart';

class LocalUserService {
  static const _onboardingCompleteKey = 'onboarding_complete';
  static const _localUserKey = 'local_user';

  static Future<bool> isOnboardingComplete() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_onboardingCompleteKey) ?? false;
  }

  static Future<void> completeOnboarding() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_onboardingCompleteKey, true);
  }

  static Future<LocalUser?> readUser() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(_localUserKey);
    if (value == null) return null;
    return LocalUser.fromJson(value);
  }

  static Future<void> saveUser(LocalUser user) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_localUserKey, user.toJson());
  }

  static Future<void> signOut() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_localUserKey);
  }
}
