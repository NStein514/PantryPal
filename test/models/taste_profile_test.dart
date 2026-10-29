import 'package:flutter_test/flutter_test.dart';
import 'package:pantrypal/models/recipe.dart';
import 'package:pantrypal/models/taste_profile.dart';

void main() {
  final now = DateTime(2026, 10, 29, 18);

  test('signals add up, and are capped', () {
    var t = const TasteProfile().cookedIt('frittata', now).savedIt('frittata', now).plannedIt('curry', now);
    expect(t.score('frittata', now), 5);
    expect(t.score('curry', now), 1);
    t = t.swappedAway('curry', now).notForMe('soup', 'Carrot soup', now);
    expect(t.score('curry', now), -0.5);
    expect(t.score('soup', now), -3);
    for (var i = 0; i < 10; i++) {
      t = t.cookedIt('frittata', now);
    }
    expect(t.score('frittata', now), TasteProfile.maxScore);
  });

  test('scores fade with a 30-day half-life, so tastes can change', () {
    final t = const TasteProfile().cookedIt('frittata', now);
    expect(t.score('frittata', now.add(const Duration(days: 30))), closeTo(1.5, 1e-9));
    expect(t.score('frittata', now.add(const Duration(days: 60))), closeTo(0.75, 1e-9));
    // A new signal starts from the faded score, not the old one.
    expect(t.cookedIt('frittata', now.add(const Duration(days: 30))).score('frittata', now.add(const Duration(days: 30))),
        closeTo(4.5, 1e-9));
  });

  test('remembers recent cooking for a fortnight, by calendar day', () {
    final t = const TasteProfile().cookedIt('curry', DateTime(2026, 10, 28, 23, 30));
    expect(t.cookedDaysAgo('curry', DateTime(2026, 10, 29, 0, 10)), 1);
    expect(t.cookedDaysAgo('curry', DateTime(2026, 11, 11)), 14);
    expect(t.cookedDaysAgo('curry', DateTime(2026, 11, 12)), isNull);
    expect(t.cookedDaysAgo('pasta', now), isNull);
  });

  test('"not for me" hides that recipe for 30 days; undo restores it', () {
    var t = const TasteProfile().notForMe('soup', 'Carrot  Soup', now);
    expect(t.isHidden('carrot soup', now), isTrue);
    expect(t.isHidden('carrot soup', now.add(const Duration(days: 31))), isFalse);
    t = t.undoNotForMe('soup', 'Carrot soup', now);
    expect(t.isHidden('carrot soup', now), isFalse);
    expect(t.score('soup', now), 0);
    expect(const TasteProfile().cookedIt(null, now).isEmpty, isTrue); // recipes without a dish id are ignored
  });

  test('JSON round-trip, pruning, and tolerance of junk', () {
    final t = const TasteProfile().cookedIt('frittata', now).notForMe('soup', 'Carrot soup', now);
    final back = TasteProfile.fromJson(t.toJson());
    expect([back.score('frittata', now), back.isHidden('Carrot soup', now), back.cookedDaysAgo('frittata', now)], [3, true, 0]);
    final later = now.add(const Duration(days: 400));
    expect(t.pruned(later).isEmpty, isTrue);
    final junk = TasteProfile.fromJson({'dishes': {'a': 'x', 'b': {'score': 99, 'at': 'not a date'}, 'c': {'score': 99, 'at': now.toIso8601String()}}, 'cooked': 5});
    expect([junk.dishes.keys.toList(), junk.score('c', now)], [['c'], TasteProfile.maxScore]);
    expect(TasteProfile.fromJson('nope').isEmpty, isTrue);
  });

  test('recipes remember their dish through saving and loading', () {
    final r = Recipe.fromJson({'title': 'Spinach frittata', 'dish': 'frittata'})!;
    expect(Recipe.fromJson(r.toJson())!.dish, 'frittata');
    expect(Recipe.fromJson({'title': 'Old save'})!.dish, isNull);
  });
}
