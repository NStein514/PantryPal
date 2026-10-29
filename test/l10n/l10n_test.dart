import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:pantrypal/l10n/l10n.dart';
import 'package:pantrypal/models/categories.dart';
import 'package:pantrypal/models/pantry_item.dart';
import 'package:pantrypal/screens/home_screen.dart';
import 'package:pantrypal/state/pantry_store.dart';
import '../helpers.dart';
import '../state/pantry_store_test.dart' show FakeDb, FakeNotifs;

/// Top-level placeholder names in an ICU message (ignores plural branch bodies).
Set<String> _placeholders(String v) => {
      for (final m in RegExp(r'\{([A-Za-z_]\w*)(?=[},])').allMatches(v))
        if (!RegExp(r'(=\d+|zero|one|two|few|many|other)$').hasMatch(v.substring(0, m.start))) m.group(1)!
    };

void main() {
  test('every ARB file has the same messages and placeholders as the English template', () {
    final en = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map<String, dynamic>;
    final keys = en.keys.where((k) => !k.startsWith('@')).toSet();
    final others = Directory('lib/l10n').listSync().whereType<File>().where((f) => f.path.endsWith('.arb'));
    for (final f in others) {
      final arb = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      final k = arb.keys.where((k) => !k.startsWith('@')).toSet();
      expect(k, keys, reason: '${f.path} keys');
      for (final key in keys) {
        expect(_placeholders(arb[key] as String), _placeholders(en[key] as String), reason: '${f.path} $key');
      }
    }
  });

  test('l10nFor picks a supported language and falls back to English', () {
    expect(l10nFor(const Locale('es', 'MX')).navPantry, 'Despensa');
    expect(l10nFor(const Locale('fr')).navPantry, 'Pantry');
    expect(l10nFor(const Locale('en', 'GB')).notifBody(1), contains('1 day'));
    expect(l10nFor(const Locale('es')).notifBody(3), contains('3 días'));
  });

  test('labels for stored keys', () {
    final es = l10nFor(const Locale('es'));
    expect(categoryLabel(es, 'Dairy'), 'Lácteos y huevos');
    expect(categoryLabel(es, 'Something old'), 'Otros');
    expect(statusLabel(es, ExpiryStatus.soon), 'Usar pronto');
  });

  test('date order follows the locale; intl locale keeps the device region', () async {
    await initializeDateFormatting();
    expect(dateFormatIsDayFirst('en_US'), isFalse);
    expect(dateFormatIsDayFirst('en_GB'), isTrue);
    expect(dateFormatIsDayFirst('es'), isTrue);
    expect(dateFormatIsDayFirst('ja'), isFalse);
    expect(intlLocaleFor(const Locale('en', 'GB'), const Locale('en')), 'en_GB');
    expect(intlLocaleFor(const Locale('fr', 'FR'), const Locale('en')), 'en');
  });

  testWidgets('the pantry renders in Spanish', (t) async {
    final store = PantryStore(FakeDb(), FakeNotifs());
    await t.pumpWidget(ChangeNotifierProvider.value(value: store, child: testApp(const HomeScreen(), locale: const Locale('es'))));
    await t.pumpAndSettle();
    expect(find.textContaining('Tu despensa está vacía'), findsOneWidget);
    expect(find.text('Escanear'), findsOneWidget);

    await store.add(PantryItem(name: 'Leche', category: 'Dairy', expiry: DateTime.now().add(const Duration(days: 2))));
    await t.pumpAndSettle();
    expect(find.text('USAR PRONTO'), findsOneWidget);
    expect(find.text('días'), findsOneWidget); // badge caption, plural
    expect(find.textContaining('Lácteos'), findsOneWidget);
  });

  test('supported languages: English first, then by native name', () {
    expect(supportedLanguageCodes, ['en', 'de', 'es', 'fr']);
    expect(supportedLanguageCodes.map(languageNativeName), ['English', 'Deutsch', 'Español', 'Français']);
  });

  test('German and French plurals', () {
    final de = l10nFor(const Locale('de'));
    final fr = l10nFor(const Locale('fr'));
    expect([de.dayCount(1), de.dayCount(3)], ['1 Tag', '3 Tage']);
    expect([fr.widgetDaysLeft(0), fr.widgetDaysLeft(1), fr.widgetDaysLeft(2)], ["aujourd'hui", '1 jour', '2 jours']);
    expect(categoryLabel(fr, 'Dairy'), 'Produits laitiers et œufs');
  });

  testWidgets('the pantry renders in German', (t) async {
    final store = PantryStore(FakeDb(), FakeNotifs());
    await t.pumpWidget(ChangeNotifierProvider.value(value: store, child: testApp(const HomeScreen(), locale: const Locale('de'))));
    await t.pumpAndSettle();
    expect(find.textContaining('Dein Vorrat ist leer'), findsOneWidget);
    expect(find.text('Scannen'), findsOneWidget);
  });

  test('every category has its own label in every language', () {
    for (final code in ['en', 'es', 'de', 'fr']) {
      final l = l10nFor(Locale(code));
      final labels = [for (final c in kCategories) categoryLabel(l, c)];
      expect(labels.toSet().length, kCategories.length, reason: '$code labels must be distinct');
      expect(labels.where((x) => x == l.catOther).length, 1, reason: '$code: only Other falls back to Other');
    }
  });
}
