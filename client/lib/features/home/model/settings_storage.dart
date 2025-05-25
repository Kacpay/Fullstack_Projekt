import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'settings_model.dart';

const String settingsKey = 'settings';

Future<void> saveSettings(SettingsModel settings) async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setString(settingsKey, jsonEncode(settings.toMap()));
}

Future<SettingsModel> loadSettings() async {
  final prefs = await SharedPreferences.getInstance();
  final jsonStr = prefs.getString(settingsKey);
  if (jsonStr == null) {
    return SettingsModel(); // domyślne ustawienia
  }
  return SettingsModel.fromMap(jsonDecode(jsonStr));
}