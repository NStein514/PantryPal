import 'package:flutter_test/flutter_test.dart';
import 'package:pantrypal/models/meal_plan.dart';
import 'package:pantrypal/models/recipe.dart';

void main() {
  final today = DateTime(2026, 10, 28, 19, 30);
  const soup = Recipe(title: 'Soup'), stew = Recipe(title: 'Stew'), pasta = Recipe(title: 'Pasta');

  test('days are local calendar days and roll over months', () {
    expect(MealPlan.dayKey(today), '2026-10-28');
    expect(MealPlan.nextDays(today, 5).map(MealPlan.dayKey), ['2026-10-28', '2026-10-29', '2026-10-30', '2026-10-31', '2026-11-01']);
  });

  test('add keeps day order, ignores the same recipe twice on one day, and finds empty days', () {
    var p = const MealPlan().add(DateTime(2026, 10, 30), stew).add(today, soup).add(today, soup).add(today, pasta);
    expect(p.meals.map((m) => '${m.day} ${m.recipe.title}'), ['2026-10-28 Soup', '2026-10-28 Pasta', '2026-10-30 Stew']);
    expect(p.on(today).length, 2);
    expect(p.emptyDays(today, 4).map(MealPlan.dayKey), ['2026-10-29', '2026-10-31']);
    p = p.remove(p.on(today).first);
    expect(p.on(today).single.recipe.title, 'Pasta');
  });

  test('cooked meals drop out of the shopping view; replace swaps the recipe and resets cooked', () {
    var p = const MealPlan().add(today, soup).add(DateTime(2026, 10, 29), stew);
    p = p.setCooked(p.meals.first, true);
    expect(p.upcoming(today).map((m) => m.recipe.title), ['Stew']);
    p = p.replace(p.meals.first, pasta);
    expect([p.meals.first.recipe.title, p.meals.first.cooked], ['Pasta', false]);
  });

  test('pruning drops past days; JSON round-trips and skips junk', () {
    final p = const MealPlan().add(DateTime(2026, 10, 27), soup).add(today, stew);
    expect(p.pruned(today).meals.map((m) => m.recipe.title), ['Stew']);
    final back = MealPlan.fromJson([
      ...p.setCooked(p.meals.last, true).toJson(),
      {'day': 'tomorrow', 'recipe': {'title': 'X'}},
      {'day': '2026-10-29', 'recipe': {'no': 'title'}},
      'junk',
    ]);
    expect(back.meals.map((m) => '${m.day} ${m.recipe.title} ${m.cooked}'), ['2026-10-27 Soup false', '2026-10-28 Stew true']);
  });
}
