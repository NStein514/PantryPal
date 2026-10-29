import 'package:flutter_test/flutter_test.dart';
import 'package:pantrypal/models/recipe.dart';
import 'package:pantrypal/models/recipe_preferences.dart';
import 'package:pantrypal/models/unit.dart';

void main() {
  test('parses AI output: amounts, modelled and unmodelled units, pantry ids', () {
    final r = Recipe.fromJson({
      'title': ' Tomato Pasta ',
      'summary': 'Quick',
      'minutes': 19.6,
      'servings': 2,
      'ingredients': [
        {'name': 'Milk', 'amount': 250, 'unit': 'ml', 'pantry_id': 12},
        {'name': 'Flour', 'amount': 2, 'unit': 'cups'},
        {'name': 'Eggs', 'amount': 3, 'unit': null},
        {'name': 'Salt'},
        'Basil',
        {'name': '', 'amount': 1},
      ],
      'steps': ['Boil', ' ', 'Serve'],
    })!;
    expect([r.title, r.minutes, r.servings, r.steps], ['Tomato Pasta', 20, 2, ['Boil', 'Serve']]);
    expect(r.ingredients.map((i) => '${i.name}|${i.amountLabel}|${i.unit?.name}|${i.pantryId}'),
        ['Milk|250 ml|ml|12', 'Flour|2 cups|null|null', 'Eggs|×3|null|null', 'Salt||null|null', 'Basil||null|null']);
  });

  test('reads recipes cached by older versions of the app', () {
    final r = Recipe.fromJson({
      'title': 'Milk Soup', 'uses_expiring': ['Milk'], 'missing': ['Basil'], 'minutes': 20, 'steps': ['Heat milk'],
    })!;
    expect(r.ingredients.map((i) => i.name), ['Milk', 'Basil']);
  });

  test('round-trips through JSON, unit text included', () {
    final r = Recipe.fromJson({
      'title': 'Pancakes', 'servings': 4, 'minutes': 25,
      'ingredients': [{'name': 'Flour', 'amount': 2, 'unit': 'cup'}, {'name': 'Milk', 'amount': 0.5, 'unit': 'l', 'pantry_id': 3}],
      'steps': ['Mix'],
    })!;
    final back = Recipe.fromJson(r.toJson())!;
    expect(back.ingredients.map((i) => i.amountLabel), ['2 cup', '0.5 L']);
    expect([back.servings, back.minutes, back.ingredients.last.pantryId], [4, 25, 3]);
  });

  test('parseList drops junk and repeated titles; id ignores case and spacing', () {
    final list = Recipe.parseList([{'title': 'Soup'}, {'title': 'soup '}, {'no': 'title'}, 'x', {'title': 'Stew'}]);
    expect(list.map((r) => r.title), ['Soup', 'Stew']);
    expect(Recipe.parseList('nope'), isEmpty);
    expect(const Recipe(title: 'Tomato  Pasta').id, 'tomato pasta');
  });

  test('preferences: prompt rules and JSON round-trip with clamping', () {
    const p = RecipePreferences(diets: {Diet.vegan, Diet.glutenFree}, servings: 4, maxMinutes: 30, avoid: ' mushrooms ');
    final rules = p.promptRules().join(' ');
    expect(rules, contains('serves 4'));
    expect(rules, contains('vegan'));
    expect(rules, contains('gluten-free'));
    expect(rules, contains('at most 30 minutes'));
    expect(rules, contains('Never use these: mushrooms'));
    final back = RecipePreferences.fromJson(p.toJson());
    expect([back.diets, back.servings, back.maxMinutes, back.avoid], [{Diet.vegan, Diet.glutenFree}, 4, 30, 'mushrooms']);
    expect(const RecipePreferences().promptRules(), ['Each recipe serves 2; scale ingredient amounts for that.']);
    final odd = RecipePreferences.fromJson({'servings': 99, 'diets': ['vegan', 'keto'], 'max_minutes': -5});
    expect([odd.servings, odd.diets, odd.maxMinutes], [12, {Diet.vegan}, null]);
    expect(Unit.tryParse('cups'), isNull);
  });
}
