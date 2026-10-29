import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pantrypal/models/meal_plan.dart';
import 'package:pantrypal/models/pantry_item.dart';
import 'package:pantrypal/models/recipe.dart';
import 'package:pantrypal/models/unit.dart';
import 'package:pantrypal/screens/recipes_screen.dart';
import 'package:pantrypal/screens/shopping_screen.dart';
import 'package:pantrypal/state/meal_plan_store.dart';
import 'package:pantrypal/state/pantry_store.dart';
import 'package:pantrypal/state/saved_recipes.dart';
import 'package:pantrypal/state/shopping_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers.dart';
import '../state/pantry_store_test.dart' show FakeDb, FakeNotifs;
import '../state/shopping_store_test.dart' show FakeShoppingDb;

final today = DateTime(2026, 10, 28, 18);
Recipe _r(String title, {int milkMl = 0}) => Recipe.fromJson({
      'title': title, 'minutes': 20,
      'ingredients': [if (milkMl > 0) {'name': 'Milk', 'amount': milkMl, 'unit': 'ml', 'pantry_id': 1}, {'name': 'Basil'}],
      'steps': ['Cook'],
    })!;

Future<({PantryStore pantry, ShoppingStore shop, MealPlanStore plan})> _pump(WidgetTester t,
    {MealPlan initial = const MealPlan(), List<PantryItem> extra = const []}) async {
  await t.binding.setSurfaceSize(const Size(800, 2400));
  addTearDown(() => t.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({'meal_plan': jsonEncode(initial.toJson())});
  final pantry = PantryStore(FakeDb(), FakeNotifs());
  await pantry.add(PantryItem(name: 'Milk', quantity: 1, unit: Unit.l)); // id 1
  for (final i in extra) {
    await pantry.add(i);
  }
  final shop = ShoppingStore(FakeShoppingDb());
  final plan = MealPlanStore(clock: () => today);
  await plan.load();
  await t.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: pantry),
      ChangeNotifierProvider.value(value: shop),
      ChangeNotifierProvider.value(value: plan),
      ChangeNotifierProvider(create: (_) => SavedRecipes()),
    ],
    child: testApp(const RecipesScreen()),
  ));
  await t.pumpAndSettle();
  await t.tap(find.text('Plan'));
  await t.pumpAndSettle();
  return (pantry: pantry, shop: shop, plan: plan);
}

void main() {
  testWidgets('Plan my week fills only empty days with dinners, without repeating planned titles', (t) async {
    final r = await _pump(t, initial: const MealPlan().add(DateTime(2026, 10, 29), _r('Already planned')), extra: [
      PantryItem(name: 'Spinach', quantity: 300, unit: Unit.g, expiry: DateTime(2026, 10, 29)),
      PantryItem(name: 'Chicken thighs', quantity: 600, unit: Unit.g, expiry: DateTime(2026, 10, 30), category: 'Meat'),
      PantryItem(name: 'Rice', quantity: 1, unit: Unit.kg),
      PantryItem(name: 'Spaghetti', quantity: 500, unit: Unit.g),
      PantryItem(name: 'Red peppers', quantity: 3),
    ]);
    expect(find.text('Today'), findsOneWidget);
    await t.tap(find.text('Plan my week'));
    await t.pumpAndSettle();
    await t.tap(find.text('3 days'));
    await t.pumpAndSettle();
    final days = r.plan.plan.meals.map((m) => m.day).toList();
    expect(days, ['2026-10-28', '2026-10-29', '2026-10-30']); // the 29th kept its meal
    expect(r.plan.plan.meals[1].recipe.title, 'Already planned');
    final titles = r.plan.plan.meals.map((m) => m.recipe.title.toLowerCase()).join(' ');
    expect(titles, isNot(anyOf(contains('smoothie'), contains('porridge'), contains('pancake'))));
  });

  testWidgets('swap replaces one meal with a different idea', (t) async {
    final r = await _pump(t, initial: const MealPlan().add(today, _r('Old')), extra: [
      PantryItem(name: 'Spinach', quantity: 300, unit: Unit.g, expiry: DateTime(2026, 10, 29)),
      PantryItem(name: 'Spaghetti', quantity: 500, unit: Unit.g),
    ]);
    await t.tap(find.byType(PopupMenuButton<String>));
    await t.pumpAndSettle();
    await t.tap(find.text('Swap for another idea'));
    await t.pumpAndSettle();
    expect(r.plan.plan.meals.single.recipe.title, isNot('Old'));
  });

  testWidgets("the week's shopping reserves pantry stock and goes onto the list", (t) async {
    final r = await _pump(t,
        initial: const MealPlan().add(today, _r('A', milkMl: 600)).add(DateTime(2026, 10, 29), _r('B', milkMl: 600)));
    await t.tap(find.text('Shopping for the week'));
    await t.pumpAndSettle();
    expect(find.text('Milk 0.2 L'), findsOneWidget); // 1 L covers A and 400 ml of B
    expect(find.text('Basil'), findsOneWidget);
    await t.tap(find.text('Add 2 to shopping list'));
    await t.pumpAndSettle();
    expect(r.shop.items.map((i) => i.name), ['Milk 0.2 L', 'Basil']);
  });

  testWidgets('ticking a meal cooked takes it off the week\'s shopping', (t) async {
    final r = await _pump(t, initial: const MealPlan().add(today, _r('A', milkMl: 1500)));
    await t.tap(find.byType(Checkbox));
    await t.pumpAndSettle();
    expect(r.plan.plan.meals.single.cooked, isTrue);
    expect(t.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Shopping for the week')).onPressed, isNull);
  });

  testWidgets('a recipe can be added to a day from its detail screen; cooking it from the plan ticks it off', (t) async {
    final r = await _pump(t, extra: [
      PantryItem(name: 'Spinach', quantity: 300, unit: Unit.g, expiry: DateTime(2026, 10, 29)),
      PantryItem(name: 'Eggs', quantity: 6),
    ]);
    await t.tap(find.text('Ideas'));
    await t.pumpAndSettle();
    await t.tap(find.textContaining('frittata').first);
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('Add to plan'));
    await t.pumpAndSettle();
    await t.tap(find.text('Tomorrow'));
    await t.pumpAndSettle();
    expect(find.text('Added to Tomorrow'), findsOneWidget);
    expect(r.plan.plan.meals.single.day, '2026-10-29');

    await t.pageBack();
    await t.pumpAndSettle();
    await t.tap(find.text('Plan'));
    await t.pumpAndSettle();
    await t.tap(find.textContaining('frittata').first);
    await t.pumpAndSettle();
    await t.tap(find.text('I cooked this'));
    await t.pumpAndSettle();
    await t.tap(find.text('Update pantry'));
    await t.pumpAndSettle();
    expect(r.plan.plan.meals.single.cooked, isTrue);
    expect(r.pantry.items.firstWhere((i) => i.name == 'Eggs').quantity, lessThan(6));
  });

  testWidgets('bought items keep their amount and category in the pantry', (t) async {
    final shop = ShoppingStore(FakeShoppingDb());
    final pantry = PantryStore(FakeDb(), FakeNotifs());
    await shop.addAll(['Milk 500 ml', 'salt, pepper']);
    await t.pumpWidget(MultiProvider(
      providers: [ChangeNotifierProvider.value(value: shop), ChangeNotifierProvider.value(value: pantry)],
      child: testApp(const ShoppingScreen()),
    ));
    for (final cb in find.byType(CheckboxListTile).evaluate().toList()) {
      await t.tap(find.byWidget(cb.widget));
      await t.pumpAndSettle();
    }
    await t.tap(find.text('To pantry'));
    await t.pumpAndSettle();
    expect(pantry.items.map((i) => '${i.name} ${i.quantityLabel} ${i.category}'),
        ['Milk 500 ml Dairy', 'Salt ×1 Spices', 'Pepper ×1 Spices']);
  });
}
