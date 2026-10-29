import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantrypal/data/settings_repo.dart';
import 'package:pantrypal/l10n/l10n.dart';
import 'package:pantrypal/state/locale_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => appLocaleOverride = null);

  test('defaults to the device language', () async {
    final s = LocaleStore(SettingsRepo());
    await s.load();
    expect([s.languageCode, s.locale, appLocaleOverride], [null, null, null]);
  });

  test('persists a choice, drives the global override, and can go back to system', () async {
    final s = LocaleStore(SettingsRepo());
    await s.load();
    var notified = 0;
    s.addListener(() => notified++);
    await s.setLanguage('de');
    expect(appLocaleOverride, const Locale('de'));
    expect(currentAppLocale(), const Locale('de'));
    expect(l10nFor(currentAppLocale()).navPantry, 'Vorrat');

    final reloaded = LocaleStore(SettingsRepo());
    await reloaded.load();
    expect(reloaded.languageCode, 'de');

    await s.setLanguage(null);
    expect([s.languageCode, appLocaleOverride], [null, null]);
    expect(await SettingsRepo().loadLanguage(), isNull);
    expect(notified, 2);
  });

  test('ignores unsupported codes, saved or requested', () async {
    SharedPreferences.setMockInitialValues({'language': 'xx'});
    final s = LocaleStore(SettingsRepo());
    await s.load();
    expect(s.languageCode, isNull);
    await s.setLanguage('klingon');
    expect(s.languageCode, isNull);
  });
}
