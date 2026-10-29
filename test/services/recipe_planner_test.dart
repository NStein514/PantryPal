import 'package:flutter_test/flutter_test.dart';
import 'package:pantrypal/models/pantry_item.dart';
import 'package:pantrypal/models/recipe.dart';
import 'package:pantrypal/models/unit.dart';
import 'package:pantrypal/services/recipe_planner.dart';

void main() {
  final now = DateTime.now();
  DateTime inDays(int d) => DateTime(now.year, now.month, now.day + d);
  final pantry = [
    PantryItem(id: 1, name: 'Whole milk', quantity: 1, unit: Unit.l, expiry: inDays(2)),
    PantryItem(id: 2, name: 'Eggs', quantity: 6, expiry: inDays(10)),
    PantryItem(id: 3, name: 'Flour', quantity: 1, unit: Unit.kg),
    PantryItem(id: 4, name: 'Tomatoes', quantity: 4, expiry: inDays(1)),
    PantryItem(id: 5, name: 'Ice cream', quantity: 1),
    PantryItem(id: 6, name: 'Tomatoes', quantity: 2, expiry: inDays(0)),
  ];

  group('name matching', () {
    test('plurals, extra words, and no partial overlaps', () {
      expect(nameMatchScore('tomato', 'Tomatoes'), 3);
      expect(nameMatchScore('Milk', 'Whole milk'), 2);
      expect(nameMatchScore('berries', 'Berry'), 3);
      expect(nameMatchScore('cream cheese', 'Ice cream'), 0);
      expect(nameMatchScore('', 'Milk'), 0);
    });

    test('a plausible pantry_id wins; an implausible one is ignored', () {
      expect(matchIngredient(const RecipeIngredient(name: 'chopped tomatoes', pantryId: 4), pantry)?.id, 4);
      expect(matchIngredient(const RecipeIngredient(name: 'Milk', pantryId: 2), pantry)?.id, 1); // id 2 is eggs
      expect(matchIngredient(const RecipeIngredient(name: 'Milk', pantryId: 99), pantry)?.id, 1);
    });

    test('ties go to the item that expires soonest', () {
      expect(matchIngredient(const RecipeIngredient(name: 'tomato'), pantry)?.id, 6);
    });
  });

  test('checkPantry splits have / to buy and counts expiring items used', () {
    const r = Recipe(title: 'Shakshuka', ingredients: [
      RecipeIngredient(name: 'Tomatoes', pantryId: 4),
      RecipeIngredient(name: 'Eggs', amount: 4),
      RecipeIngredient(name: 'Feta'),
      RecipeIngredient(name: 'Milk'),
    ]);
    final c = checkPantry(r, pantry);
    expect(c.have.values.map((p) => p.id), [4, 2, 1]);
    expect(c.missing.map((i) => i.name), ['Feta']);
    expect(c.expiringUsed, 2); // tomatoes (1 day) and milk (2 days)
  });

  group('cooking deductions', () {
    List<String> plan(List<RecipeIngredient> ings) => [
          for (final d in planDeductions(Recipe(title: 't', ingredients: ings), pantry))
            '${d.item.id}:${formatQuantity(d.amount, d.item.unit)}:${d.known ? 'known' : 'ask'}${d.usesAll ? ':all' : ''}'
        ];

    test('converts units into the pantry item unit', () {
      expect(plan(const [RecipeIngredient(name: 'Milk', amount: 250, unit: Unit.ml)]), ['1:0.25 L:known']);
      expect(plan(const [RecipeIngredient(name: 'Flour', amount: 1.5, unit: Unit.kg)]), ['3:1 kg:known:all']); // capped
    });

    test('counted items round up to whole pieces', () {
      expect(plan(const [RecipeIngredient(name: 'Eggs', amount: 2.5)]), ['2:×3:known']);
      expect(plan(const [RecipeIngredient(name: 'Eggs', amount: 0.5)]), ['2:×1:known']);
    });

    test('unknown or unconvertible amounts are proposed but marked to ask', () {
      expect(plan(const [RecipeIngredient(name: 'Flour', amount: 2, unitText: 'cups')]), ['3:1 kg:ask:all']);
      expect(plan(const [RecipeIngredient(name: 'Milk')]), ['1:1 L:ask:all']);
      expect(plan(const [RecipeIngredient(name: 'Eggs', amount: 200, unit: Unit.g)]), ['2:×6:ask:all']); // grams of a counted item
    });

    test('ingredients using the same item add up; missing ones are skipped', () {
      expect(plan(const [
        RecipeIngredient(name: 'Milk', amount: 200, unit: Unit.ml),
        RecipeIngredient(name: 'Feta', amount: 100, unit: Unit.g),
        RecipeIngredient(name: 'whole milk', amount: 0.3, unit: Unit.l),
      ]), ['1:0.5 L:known']);
    });
  });
}
