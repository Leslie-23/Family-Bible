import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

class SettingsService {
  static const _settingsKey = 'app_settings';

  static Future<AppSettings> read() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(_settingsKey);

    if (value == null) return AppSettings.defaults;

    return AppSettings.fromJson(value);
  }

  static Future<void> save(AppSettings settings) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_settingsKey, settings.toJson());
  }
}
