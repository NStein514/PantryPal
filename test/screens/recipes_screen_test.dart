import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pantrypal/data/settings_repo.dart';
import 'package:pantrypal/models/pantry_item.dart';
import 'package:pantrypal/models/recipe_preferences.dart';
import 'package:pantrypal/models/unit.dart';
import 'package:pantrypal/screens/recipes_screen.dart';
import 'package:pantrypal/state/pantry_store.dart';
import 'package:pantrypal/state/saved_recipes.dart';
import 'package:pantrypal/state/shopping_store.dart';
import 'package:pantrypal/state/taste_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers.dart';
import '../state/pantry_store_test.dart' show FakeDb, FakeNotifs;
import '../state/shopping_store_test.dart' show FakeShoppingDb;

DateTime _inDays(int d) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day + d);
}

/// Recipes come from the on-device engine: instant, offline, deterministic.
Future<({PantryStore store, ShoppingStore shop, TasteStore taste})> _pump(WidgetTester t, {bool withItems = true}) async {
  await t.binding.setSurfaceSize(const Size(800, 2400));
  addTearDown(() => t.binding.setSurfaceSize(null));
  final store = PantryStore(FakeDb(), FakeNotifs());
  if (withItems) {
    await store.add(PantryItem(name: 'Spinach', quantity: 200, unit: Unit.g, expiry: _inDays(1), category: 'Produce')); // id 1
    await store.add(PantryItem(name: 'Eggs', quantity: 6, expiry: _inDays(12), category: 'Dairy')); // id 2
    await store.add(PantryItem(name: 'Feta', quantity: 150, unit: Unit.g, expiry: _inDays(4), category: 'Dairy')); // id 3
    await store.add(PantryItem(name: 'Spaghetti', quantity: 500, unit: Unit.g, category: 'Grains')); // id 4
    await store.add(PantryItem(name: 'Bananas', quantity: 3, expiry: _inDays(1), category: 'Produce')); // id 5
  }
  final shop = ShoppingStore(FakeShoppingDb());
  final taste = TasteStore();
  await t.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: store),
      ChangeNotifierProvider.value(value: shop),
      ChangeNotifierProvider(create: (_) => SavedRecipes()),
      ChangeNotifierProvider.value(value: taste),
    ],
    child: testApp(const RecipesScreen()),
  ));
  await t.pumpAndSettle();
  return (store: store, shop: shop, taste: taste);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('ideas appear at once from the pantry, no network needed', (t) async {
    await _pump(t);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('Spinach'), findsWidgets); // the item expiring tomorrow leads
    expect(find.text('More ideas'), findsOneWidget);
  });

  testWidgets('an empty pantry explains what to do', (t) async {
    await _pump(t, withItems: false);
    expect(find.textContaining('Add some items'), findsOneWidget);
  });

  testWidgets('more ideas add new dishes, then say when there are no more', (t) async {
    await _pump(t);
    final before = find.byType(Card).evaluate().length + find.textContaining('min').evaluate().length;
    for (var i = 0; i < 10 && find.text('More ideas').evaluate().isNotEmpty; i++) {
      await t.ensureVisible(find.text('More ideas'));
      await t.tap(find.text('More ideas'));
      await t.pumpAndSettle();
    }
    expect(find.textContaining('min').evaluate().length, greaterThan(before ~/ 2));
    expect(find.textContaining("That's every idea"), findsOneWidget);
  });

  testWidgets('build around an item: ideas use it', (t) async {
    await _pump(t);
    await t.tap(find.widgetWithText(FilterChip, 'Bananas'));
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(TextButton, 'New ideas'));
    await t.pumpAndSettle();
    expect(find.textContaining('Banana'), findsWidgets);
  });

  testWidgets('preferences apply immediately and are kept', (t) async {
    await _pump(t);
    await t.tap(find.byTooltip('Recipe preferences'));
    await t.pumpAndSettle();
    await t.tap(find.text('Vegan'));
    await t.tap(find.text('Apply'));
    await t.pumpAndSettle();
    expect(find.textContaining('frittata'), findsNothing); // eggs and feta are out
    expect((await SettingsRepo().loadRecipePreferences()).diets, {Diet.vegan});
  });

  testWidgets('saving a recipe puts it under Saved', (t) async {
    await _pump(t);
    await t.tap(find.byTooltip('Save recipe').first);
    await t.pumpAndSettle();
    await t.tap(find.text('Saved (1)'));
    await t.pumpAndSettle();
    expect(find.byTooltip('Remove from saved'), findsOneWidget);
  });

  testWidgets('detail: in pantry, on your list, basics; cooking updates the pantry', (t) async {
    final r = await _pump(t);
    await r.shop.addAll(['Onion']);
    await t.tap(find.textContaining('frittata').first);
    await t.pumpAndSettle();
    expect(find.text('Spinach · 200 g'), findsOneWidget); // matched to the pantry item
    expect(find.text('Kitchen basics'), findsWidgets); // oil, salt, pepper: never "to buy"

    await t.tap(find.text('I cooked this'));
    await t.pumpAndSettle();
    await t.tap(find.text('Update pantry'));
    await t.pumpAndSettle();
    expect(r.store.items.firstWhere((i) => i.name == 'Eggs').quantity, lessThan(6));
    expect(find.textContaining('Updated'), findsOneWidget);
  });

  testWidgets('"not for me" removes the idea and teaches the engine; Undo puts it back', (t) async {
    final r = await _pump(t);
    final cards = find.byTooltip('Not for me');
    final before = cards.evaluate().length;
    expect(before, greaterThan(0));
    await t.tap(cards.first);
    await t.pumpAndSettle();
    expect(find.byTooltip('Not for me').evaluate().length, before - 1);
    expect(find.text('Got it — fewer ideas like this.'), findsOneWidget);
    expect(r.taste.profile.hidden, hasLength(1));

    await t.tap(find.text('Undo'));
    await t.pumpAndSettle();
    expect(find.byTooltip('Not for me').evaluate().length, before);
    expect(r.taste.profile.hidden, isEmpty);
  });

  testWidgets('cooking and saving teach the engine', (t) async {
    final r = await _pump(t);
    await t.tap(find.byTooltip('Save recipe').first);
    await t.pumpAndSettle();
    expect(r.taste.profile.dishes.values.single.score, 2);

    await t.tap(find.textContaining('frittata').first);
    await t.pumpAndSettle();
    await t.tap(find.text('I cooked this'));
    await t.pumpAndSettle();
    await t.tap(find.text('Update pantry'));
    await t.pumpAndSettle();
    expect(r.taste.profile.cooked.keys, contains('frittata'));
  });
}
