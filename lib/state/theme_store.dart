import 'package:flutter/material.dart';
import '../data/settings_repo.dart';

/// Light, dark, or follow the device. Persisted; loaded before the first frame.
class ThemeStore extends ChangeNotifier {
  ThemeStore([this._repo]);
  final SettingsRepo? _repo; // null = nothing persisted (tests)
  ThemeMode mode = ThemeMode.system;

  static ThemeMode parse(String? raw) => switch (raw) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  Future<void> load() async {
    mode = parse(await _repo?.loadThemeMode());
    notifyListeners();
  }

  Future<void> setMode(ThemeMode m) async {
    if (m == mode) return;
    mode = m;
    notifyListeners();
    await _repo?.saveThemeMode(m == ThemeMode.system ? null : m.name);
  }
}
