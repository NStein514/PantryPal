import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pantrypal/models/pantry_item.dart';
import 'package:pantrypal/models/reminder_settings.dart';
import 'package:pantrypal/models/shopping_item.dart';
import 'package:pantrypal/models/unit.dart';
import 'package:pantrypal/screens/settings_screen.dart';
import 'package:pantrypal/services/backup_files.dart';
import 'package:pantrypal/services/backup_service.dart';
import 'package:pantrypal/data/product_memory_db.dart';
import 'package:pantrypal/data/settings_repo.dart';
import 'package:pantrypal/l10n/l10n.dart';
import 'package:pantrypal/models/known_product.dart';
import 'package:pantrypal/state/locale_store.dart';
import 'package:pantrypal/state/pantry_store.dart';
import 'package:pantrypal/models/recipe.dart';
import 'package:pantrypal/state/taste_store.dart';
import 'package:pantrypal/state/theme_store.dart';
import 'package:pantrypal/state/shopping_store.dart';
import '../helpers.dart';
import '../state/pantry_store_test.dart' show FakeDb, FakeNotifs;
import '../state/shopping_store_test.dart' show FakeShoppingDb;
import 'scan_screen_test.dart' show FakeMemory;

class FakeFiles implements BackupFiles {
  FakeFiles([this.toPick]);
  final String? toPick;
  String? shared;
  String? sharedName;
  @override
  Future<void> share(String json, String fileName, {Rect? origin}) async {
    shared = json;
    sharedName = fileName;
  }

  @override
  Future<String?> pick() async => toPick;
}

Future<(PantryStore, ShoppingStore)> _pump(WidgetTester t, FakeFiles files,
    {LocaleStore? language, FakeMemory? memory, ThemeStore? appearance, TasteStore? taste}) async {
  // Tall surface so every Settings tile is on screen without scrolling.
  await t.binding.setSurfaceSize(const Size(800, 1400));
  addTearDown(() => t.binding.setSurfaceSize(null));
  final pantry = PantryStore(FakeDb(), FakeNotifs());
  final shop = ShoppingStore(FakeShoppingDb());
  await pantry.add(PantryItem(name: 'Old'));
  await t.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: pantry),
      ChangeNotifierProvider.value(value: shop),
      Provider<BackupFiles>.value(value: files),
      ChangeNotifierProvider.value(value: language ?? LocaleStore()),
      ChangeNotifierProvider.value(value: appearance ?? ThemeStore()),
      ChangeNotifierProvider.value(value: taste ?? TasteStore()),
      if (memory != null) Provider<ProductMemoryDb>.value(value: memory),
    ],
    child: testApp(const SettingsScreen()),
  ));
  return (pantry, shop);
}

void main() {
  final backup = BackupService.encode(
    items: [PantryItem(name: 'Flour', quantity: 2, unit: Unit.kg)],
    shopping: const [ShoppingItem(name: 'Basil')],
    reminders: const ReminderSettings(leadDays: 5, hour: 7),
  );

  testWidgets('export shares a decodable backup of the current data', (t) async {
    final files = FakeFiles();
    await _pump(t, files);
    await t.tap(find.text('Export backup'));
    await t.pumpAndSettle();
    expect(files.sharedName, startsWith('pantrypal-backup-'));
    expect(BackupService.decode(files.shared!).items.single.name, 'Old');
  });

  testWidgets('import → Replace swaps the data and restores reminder settings', (t) async {
    final (pantry, shop) = await _pump(t, FakeFiles(backup));
    await t.tap(find.text('Import backup'));
    await t.pumpAndSettle();
    expect(find.textContaining('1 pantry item and 1 shopping item'), findsOneWidget);
    await t.tap(find.text('Replace'));
    await t.pumpAndSettle();
    expect(pantry.items.map((i) => '${i.name} ${i.quantityLabel}'), ['Flour 2 kg']);
    expect(shop.items.single.name, 'Basil');
    expect([pantry.reminders.leadDays, pantry.reminders.hour], [5, 7]);
    expect(find.text('Restored 1 pantry and 1 shopping items'), findsOneWidget);
  });

  testWidgets('import → Merge keeps existing items and settings', (t) async {
    final (pantry, _) = await _pump(t, FakeFiles(backup));
    await t.tap(find.text('Import backup'));
    await t.pumpAndSettle();
    await t.tap(find.text('Merge'));
    await t.pumpAndSettle();
    expect(pantry.items.map((i) => i.name), ['Old', 'Flour']);
    expect(pantry.reminders.leadDays, 2);
  });

  testWidgets('a file that is not a backup shows a message and changes nothing', (t) async {
    final (pantry, _) = await _pump(t, FakeFiles('{"hello":1}'));
    await t.tap(find.text('Import backup'));
    await t.pumpAndSettle();
    expect(find.text("That file isn't a PantryPal backup."), findsOneWidget);
    expect(pantry.items.single.name, 'Old');
  });

  testWidgets('language picker lists every translation and stores the choice', (t) async {
    addTearDown(() => appLocaleOverride = null);
    final language = LocaleStore();
    await _pump(t, FakeFiles(), language: language);
    await t.tap(find.byKey(const Key('language-picker')));
    await t.pumpAndSettle();
    for (final name in ['System default', 'English', 'Deutsch', 'Español', 'Français']) {
      expect(find.text(name), findsWidgets, reason: name);
    }
    await t.tap(find.text('Français').last);
    await t.pumpAndSettle();
    expect(language.languageCode, 'fr');
    expect(appLocaleOverride, const Locale('fr'));
  });

  testWidgets('backups carry the remembered products both ways', (t) async {
    final source = FakeMemory()..products.add(const KnownProduct(name: 'Oat milk', category: 'Dairy', barcode: '123'));
    final files = FakeFiles();
    await _pump(t, files, memory: source);
    await t.tap(find.text('Export backup'));
    await t.pumpAndSettle();
    expect(BackupService.decode(files.shared!).products.single.barcode, '123');

    final target = FakeMemory()..products.add(const KnownProduct(name: 'Old'));
    await _pump(t, FakeFiles(files.shared), memory: target);
    await t.tap(find.text('Import backup'));
    await t.pumpAndSettle();
    expect(find.textContaining('1 remembered product'), findsOneWidget);
    await t.tap(find.text('Replace'));
    await t.pumpAndSettle();
    expect(target.products.map((p) => p.name), ['Oat milk']);
  });

  testWidgets('Remembered products is reachable from Settings', (t) async {
    await _pump(t, FakeFiles(), memory: FakeMemory());
    await t.tap(find.text('Remembered products'));
    await t.pumpAndSettle();
    expect(find.textContaining('Nothing remembered yet'), findsOneWidget);
  });

  testWidgets('Appearance switches between system, light and dark', (t) async {
    final appearance = ThemeStore();
    await _pump(t, FakeFiles(), appearance: appearance);
    expect(find.text('Appearance'), findsOneWidget);
    expect(appearance.mode, ThemeMode.system);
    await t.tap(find.text('Dark'));
    await t.pumpAndSettle();
    expect(appearance.mode, ThemeMode.dark);
    await t.tap(find.text('Light'));
    await t.pumpAndSettle();
    expect(appearance.mode, ThemeMode.light);
  });

  testWidgets('the chosen theme is remembered', (t) async {
    final first = ThemeStore(SettingsRepo());
    await first.load();
    await first.setMode(ThemeMode.dark);
    final again = ThemeStore(SettingsRepo());
    await again.load();
    expect(again.mode, ThemeMode.dark);
    await again.setMode(ThemeMode.system);
    expect(await SettingsRepo().loadThemeMode(), isNull);
    expect(ThemeStore.parse('nonsense'), ThemeMode.system);
  });

  testWidgets('reset what was learned, after confirming', (t) async {
    final taste = TasteStore();
    await _pump(t, FakeFiles(), taste: taste);
    await t.pumpAndSettle();
    final reset = find.text('Reset what PantryPal has learned');
    expect(t.widget<ListTile>(find.ancestor(of: reset, matching: find.byType(ListTile))).enabled, isFalse); // nothing yet

    await taste.notForMe(Recipe.fromJson({'title': 'Carrot soup', 'dish': 'soup'})!);
    await t.pumpAndSettle();
    await t.ensureVisible(reset);
    await t.tap(reset);
    await t.pumpAndSettle();
    await t.tap(find.text('Cancel'));
    await t.pumpAndSettle();
    expect(taste.profile.isEmpty, isFalse);

    await t.tap(reset);
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(FilledButton, 'Reset'));
    await t.pumpAndSettle();
    expect(taste.profile.isEmpty, isTrue);
    expect(find.text('Suggestions start fresh.'), findsOneWidget);
  });
}
