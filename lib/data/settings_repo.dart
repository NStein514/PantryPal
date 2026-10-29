import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recipe_preferences.dart';
import '../models/reminder_settings.dart';

class SettingsRepo {
  Future<ReminderSettings> load() async {
    final p = await SharedPreferences.getInstance();
    return ReminderSettings(leadDays: p.getInt('lead_days') ?? 2, hour: p.getInt('reminder_hour') ?? 9);
  }

  Future<RecipePreferences> loadRecipePreferences() async {
    final raw = (await SharedPreferences.getInstance()).getString('recipe_prefs');
    try {
      return raw == null ? const RecipePreferences() : RecipePreferences.fromJson(jsonDecode(raw));
    } catch (_) {
      return const RecipePreferences();
    }
  }

  Future<void> saveRecipePreferences(RecipePreferences p) async =>
      (await SharedPreferences.getInstance()).setString('recipe_prefs', jsonEncode(p.toJson()));

  Future<bool> loadIntroSeen() async => (await SharedPreferences.getInstance()).getBool('intro_seen') ?? false;
  Future<void> saveIntroSeen() async => (await SharedPreferences.getInstance()).setBool('intro_seen', true);

  /// "light" / "dark", or null to follow the device.
  Future<String?> loadThemeMode() async => (await SharedPreferences.getInstance()).getString('theme_mode');

  Future<void> saveThemeMode(String? mode) async {
    final p = await SharedPreferences.getInstance();
    mode == null ? await p.remove('theme_mode') : await p.setString('theme_mode', mode);
  }

  /// In-app language code, or null to follow the device.
  Future<String?> loadLanguage() async => (await SharedPreferences.getInstance()).getString('language');

  Future<void> saveLanguage(String? code) async {
    final p = await SharedPreferences.getInstance();
    code == null ? await p.remove('language') : await p.setString('language', code);
  }

  Future<void> save(ReminderSettings s) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('lead_days', s.leadDays);
    await p.setInt('reminder_hour', s.hour);
  }
}
