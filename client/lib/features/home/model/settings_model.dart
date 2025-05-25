import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsModel {
  final int currentLevel;

  SettingsModel({this.currentLevel = 1});

  SettingsModel copyWith({int? currentLevel}) {
    return SettingsModel(
      currentLevel: currentLevel ?? this.currentLevel,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'currentLevel': currentLevel,
    };
  }

  factory SettingsModel.fromMap(Map<String, dynamic> map) {
    return SettingsModel(
      currentLevel: map['currentLevel'] ?? 1,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory SettingsModel.fromJson(String source) =>
      SettingsModel.fromMap(jsonDecode(source));

  static const _prefsKey = 'settings';

  static Future<void> save(SettingsModel settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, settings.toJson());
  }

  static Future<SettingsModel> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefsKey);
    if (jsonStr == null) return SettingsModel();
    return SettingsModel.fromJson(jsonStr);
  }
}

void main() async {
  // Load the current settings
  final settings = await SettingsModel.load();

  // Update the settings as needed
  final updatedSettings = settings.copyWith(currentLevel: 2);

  // Save the updated settings
  await SettingsModel.save(updatedSettings);
}