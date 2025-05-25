import 'package:shared_preferences/shared_preferences.dart';
import 'game_result_model.dart';

const String todayBestKey = 'today_best_result';

String _todayKey() {
  final now = DateTime.now();
  return '$todayBestKey-${now.year}-${now.month}-${now.day}';
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