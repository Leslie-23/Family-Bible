import 'package:shared_preferences/shared_preferences.dart';

import '../models/local_user.dart';

class LocalUserService {
  static const _onboardingCompleteKey = 'onboarding_complete';
  static const _localUserKey = 'local_user';
  static const _tokenKey = 'auth_token';

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
    if (user.token != null) {
      await preferences.setString(_tokenKey, user.token!);
    }
  }

  static Future<String?> readToken() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_tokenKey);
  }

  static Future<void> saveToken(String token) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_tokenKey, token);
  }

  static Future<void> clearToken() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_tokenKey);
  }

  static Future<void> signOut() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_localUserKey);
    await preferences.remove(_tokenKey);
  }
}
