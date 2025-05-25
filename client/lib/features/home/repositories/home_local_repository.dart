import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../model/settings_model.dart';
import '../model/game_result_model.dart';

class HomeLocalRepository {
  static const String _settingsKey = 'settings';
  static const String _todayBestKey = 'today_best_result';

  // SETTINGS
  Future<void> saveSettings(SettingsModel settings) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_settingsKey, jsonEncode(settings.toMap()));
  }

  Future<SettingsModel> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_settingsKey);
    if (jsonStr == null) {
      return SettingsModel();
    }
    return SettingsModel.fromMap(jsonDecode(jsonStr));
  }

  // TODAY BEST RESULT
  String _todayKey() {
    final now = DateTime.now();
    return '$_todayBestKey-${now.year}-${now.month}-${now.day}';
  }

  Future<bool> saveTodayBestResult(GameResultModel result) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _todayKey();
    final existingJson = prefs.getString(key);

    if (existingJson != null) {
      final existing = GameResultModel.fromJson(existingJson);
      // Najpierw level, potem score
      if (result.level < existing.level) return false;
      if (result.level == existing.level && result.score <= existing.score) return false;
    }
    await prefs.setString(key, result.toJson());
    return true;
  }

  Future<GameResultModel?> getTodayBestResult() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _todayKey();
    final jsonStr = prefs.getString(key);
    if (jsonStr == null) return null;
    return GameResultModel.fromJson(jsonStr);
  }
}