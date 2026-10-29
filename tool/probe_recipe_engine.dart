// ignore_for_file: avoid_print — a command-line probe: printing is its output.
// Prints what the recipe engine suggests for a few realistic pantries.
// Run: dart run tool/probe_recipe_engine.dart
import 'package:pantrypal/models/pantry_item.dart';
import 'package:pantrypal/models/recipe.dart';
import 'package:pantrypal/models/recipe_preferences.dart';
import 'package:pantrypal/models/taste_profile.dart';
import 'package:pantrypal/models/unit.dart';
import 'package:pantrypal/services/recipe_engine.dart';
import 'package:pantrypal/services/recipe_planner.dart';

DateTime inDays(int d) { final n = DateTime.now(); return DateTime(n.year, n.month, n.day + d); }
var _id = 0;
PantryItem p(String name, {double q = 1, Unit u = Unit.count, int? days, String cat = 'Other'}) =>
    PantryItem(id: ++_id, name: name, quantity: q, unit: u, expiry: days == null ? null : inDays(days), category: cat);

void show(String label, List<Recipe> rs, List<PantryItem> pantry) {
  print('\n=== $label');
  for (final r in rs) {
    final c = checkPantry(r, pantry);
    print('• ${r.title}  (${r.minutes} min, ${r.servings} servings) — have ${c.have.length}, buy ${c.missing.length}');
    print('    ${r.summary}');
    print('    ${r.ingredients.map((i) => '${i.name}${i.amountLabel.isEmpty ? '' : ' ${i.amountLabel}'}${i.staple ? '*' : ''}${i.pantryId != null ? '' : (i.staple ? '' : ' [buy]')}').join(', ')}');
    print('    ${r.steps.length} steps: ${r.steps.first}');
  }
}

void main() {
  const e = RecipeEngine();
  final fridge = [
    p('Spinach', q: 200, u: Unit.g, days: 1, cat: 'Produce'), p('Feta', q: 150, u: Unit.g, days: 4, cat: 'Dairy'),
    p('Eggs', q: 6, days: 12, cat: 'Dairy'), p('Red peppers', q: 2, days: 2, cat: 'Produce'),
    p('Chicken thighs', q: 500, u: Unit.g, days: 2, cat: 'Meat'), p('Basmati rice', q: 1, u: Unit.kg, cat: 'Grains'),
    p('Spaghetti', q: 500, u: Unit.g, cat: 'Grains'), p('Onion', q: 3, days: 20, cat: 'Produce'),
    p('Chopped tomatoes', q: 400, u: Unit.g, cat: 'Canned'), p('Whole milk', q: 1, u: Unit.l, days: -2, cat: 'Dairy'),
    p('Bananas', q: 3, days: 1, cat: 'Produce'), p('Greek yogurt', q: 500, u: Unit.g, days: 6, cat: 'Dairy'),
  ];
  show('typical fridge, 3 ideas', e.suggest(fridge), fridge);
  show('more ideas (avoid the first 3)', e.suggest(fridge, avoidTitles: [for (final r in e.suggest(fridge)) r.title]), fridge);
  show('build around: bananas', e.suggest(fridge, focusIds: {fridge[10].id!}), fridge);
  show('vegan, 30 min max, 4 servings', e.suggest(fridge, prefs: const RecipePreferences(diets: {Diet.vegan}, maxMinutes: 30, servings: 4)), fridge);
  final student = [p('Pasta', q: 500, u: Unit.g, cat: 'Grains'), p('Cheddar', q: 200, u: Unit.g, days: 10, cat: 'Dairy'),
    p('Tortillas', q: 6, days: 3, cat: 'Bakery')];
  show('sparse student pantry + shopping list', e.suggest(student, shoppingList: ['Broccoli', 'Eggs']), student);
  show('Spanish', e.suggest(fridge, language: 'es'), fridge);
  show('week plan, 5 dinners', e.suggest(fridge, count: 5, mainsOnly: true, forPlan: true), fridge);
  var taste = const TasteProfile();
  for (var i = 0; i < 3; i++) {
    taste = taste.cookedIt('frittata', DateTime.now().subtract(Duration(days: 10 + 5 * i)));
  }
  show('after cooking frittatas three times', e.suggest(fridge, taste: taste), fridge);
}
