import 'package:flutter/widgets.dart';
import '../data/settings_repo.dart';
import '../l10n/l10n.dart';

/// The app's language: an explicit choice from Settings, or null to follow the device.
class LocaleStore extends ChangeNotifier {
  LocaleStore([this._repo]);
  final SettingsRepo? _repo; // null = nothing persisted (tests)
  String? _code;

  /// Chosen language code, or null for "system default".
  String? get languageCode => _code;

  /// Passed to MaterialApp.locale; null lets Flutter resolve from the device.
  Locale? get locale => _code == null ? null : Locale(_code!);

  Future<void> load() async {
    final saved = await _repo?.loadLanguage();
    _code = supportedLanguageCodes.contains(saved) ? saved : null; // ignore removed languages
    appLocaleOverride = locale;
    notifyListeners();
  }

  Future<void> setLanguage(String? code) async {
    if (code != null && !supportedLanguageCodes.contains(code)) return;
    if (code == _code) return;
    _code = code;
    appLocaleOverride = locale;
    await _repo?.saveLanguage(code);
    notifyListeners();
  }
}
