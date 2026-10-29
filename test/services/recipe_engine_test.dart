import 'package:flutter_test/flutter_test.dart';
import 'package:pantrypal/models/pantry_item.dart';
import 'package:pantrypal/models/recipe.dart';
import 'package:pantrypal/models/recipe_preferences.dart';
import 'package:pantrypal/models/taste_profile.dart';
import 'package:pantrypal/models/unit.dart';
import 'package:pantrypal/services/meal_shopping.dart';
import 'package:pantrypal/services/recipe_engine.dart';
import 'package:pantrypal/services/recipe_planner.dart';

DateTime inDays(int d) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day + d);
}

void main() {
  const engine = RecipeEngine();
  var nextId = 0;
  PantryItem p(String name, {double q = 1, Unit u = Unit.count, int? days, String cat = 'Other'}) =>
      PantryItem(id: ++nextId, name: name, quantity: q, unit: u, expiry: days == null ? null : inDays(days), category: cat);

  late List<PantryItem> fridge;
  late PantryItem spinach, chicken, eggs, feta, milk, bananas, yogurt;
  setUp(() {
    fridge = [
      spinach = p('Spinach', q: 200, u: Unit.g, days: 1, cat: 'Produce'),
      feta = p('Feta', q: 150, u: Unit.g, days: 4, cat: 'Dairy'),
      eggs = p('Eggs', q: 6, days: 12, cat: 'Dairy'),
      p('Red peppers', q: 2, days: 2, cat: 'Produce'),
      chicken = p('Chicken thighs', q: 500, u: Unit.g, days: 2, cat: 'Meat'),
      p('Basmati rice', q: 1, u: Unit.kg, cat: 'Grains'),
      p('Spaghetti', q: 500, u: Unit.g, cat: 'Grains'),
      p('Onion', q: 3, days: 20, cat: 'Produce'),
      p('Chopped tomatoes', q: 400, u: Unit.g, cat: 'Canned'),
      milk = p('Whole milk', q: 1, u: Unit.l, days: -2, cat: 'Dairy'), // expired
      bananas = p('Bananas', q: 3, days: 1, cat: 'Produce'),
      yogurt = p('Greek yogurt', q: 500, u: Unit.g, days: 6, cat: 'Dairy'),
    ];
  });
  /// Every dish the engine can make, one at a time, each from the full pantry.
  List<Recipe> everyDish(List<PantryItem> pantry, {String lang = 'en'}) {
    final rs = <Recipe>[];
    for (var i = 0; i < 40; i++) {
      final next = engine.suggest(pantry, count: 1, language: lang, avoidTitles: [for (final r in rs) r.title]);
      if (next.isEmpty) break;
      rs.add(next.single);
    }
    return rs;
  }

  Set<int> pantryIds(Recipe r) => {for (final i in r.ingredients) if (i.pantryId != null) i.pantryId!};
  Iterable<String> allText(List<Recipe> rs) => [for (final r in rs) ...[r.title, r.summary, ...r.steps, ...r.ingredients.map((i) => i.name)]];

  test('leads with what expires soonest, and never uses expired dairy or meat', () {
    final ideas = engine.suggest(fridge);
    expect(ideas, hasLength(3));
    expect(pantryIds(ideas.first), contains(spinach.id));
    for (final r in everyDish(fridge)) {
      expect(pantryIds(r), isNot(contains(milk.id)), reason: r.title);
    }
    final expiredChicken = [...fridge]..[4] = p('Chicken thighs', q: 500, u: Unit.g, days: -1, cat: 'Meat');
    for (final r in everyDish(expiredChicken)) {
      expect(r.ingredients.any((i) => i.name == 'Chicken thighs'), isFalse, reason: r.title);
    }
  });

  test('vegan: no animal products from the pantry and none suggested to buy', () {
    final ideas = engine.suggest(fridge, count: 10, prefs: const RecipePreferences(diets: {Diet.vegan}));
    expect(ideas, isNotEmpty);
    for (final r in ideas) {
      expect(pantryIds(r).intersection({chicken.id, eggs.id, feta.id, yogurt.id, milk.id}), isEmpty, reason: r.title);
      expect(r.ingredients.map((i) => i.name), isNot(anyOf(contains('Eggs'), contains('Cheese'), contains('Butter'))), reason: r.title);
    }
  });

  test('"leave out" also rules out buying it; time limit and servings are respected', () {
    final noEggs = engine.suggest(fridge, count: 20, prefs: const RecipePreferences(avoid: 'egg'));
    expect(noEggs.every((r) => r.ingredients.every((i) => !i.name.toLowerCase().contains('egg'))), isTrue);
    final quick = engine.suggest(fridge, count: 20, prefs: const RecipePreferences(maxMinutes: 15));
    expect(quick, isNotEmpty);
    expect(quick.every((r) => r.minutes! <= 15), isTrue);
    // Compare the same ingredient: build both around the spaghetti (every pasta dish uses 90 g a serving).
    final pasta = fridge.firstWhere((i) => i.name == 'Spaghetti').id!;
    final two = engine.suggest(fridge, focusIds: {pasta}).first;
    final four = engine.suggest(fridge, focusIds: {pasta}, prefs: const RecipePreferences(servings: 4)).first;
    expect(four.servings, 4);
    double grams(Recipe r) => r.ingredients.firstWhere((i) => i.name == 'Spaghetti').amount!;
    expect(grams(four), grams(two) * 2);
  });

  test('amounts are realistic and in the pantry item\'s own unit', () {
    final pasta = engine.suggest(fridge).firstWhere((r) => r.title.startsWith('Spaghetti'));
    final onion = pasta.ingredients.firstWhere((i) => i.name == 'Onion');
    expect([onion.unit, onion.amount], [Unit.count, 1]); // one onion for two, not two
    expect(pasta.ingredients.firstWhere((i) => i.name == 'Spinach').unit, Unit.g);
  });

  test('build around: every idea uses the chosen item', () {
    final ideas = engine.suggest(fridge, focusIds: {bananas.id!});
    expect(ideas, isNotEmpty);
    expect(ideas.every((r) => pantryIds(r).contains(bananas.id)), isTrue);
  });

  test('more ideas never repeat, and run out instead of looping', () {
    final seen = <String>[];
    for (var round = 0; round < 15; round++) {
      final more = engine.suggest(fridge, avoidTitles: seen);
      if (more.isEmpty) break;
      for (final r in more) {
        expect(seen.map((t) => t.toLowerCase()), isNot(contains(r.title.toLowerCase())));
        seen.add(r.title);
      }
    }
    expect(seen.length, greaterThan(6));
    expect(engine.suggest(fridge, avoidTitles: seen), isEmpty);
  });

  test('a week of dinners: mains only, all different, spread across the food', () {
    final week = engine.suggest(fridge, count: 5, mainsOnly: true, forPlan: true);
    expect(week, hasLength(5));
    expect(week.map((r) => r.title).toSet(), hasLength(5));
    final lower = week.map((r) => r.title.toLowerCase()).join(' ');
    for (final w in ['smoothie', 'porridge', 'pancake', 'crumble']) {
      expect(lower, isNot(contains(w)));
    }
    // Sharing an item is fine while there's enough; the week doesn't plan more than you have.
    final planned = <int, double>{};
    for (final r in week) {
      for (final i in r.ingredients.where((i) => i.pantryId != null)) {
        planned[i.pantryId!] = (planned[i.pantryId!] ?? 0) + (i.amount ?? 0);
      }
    }
    final over = [for (final item in fridge) if ((planned[item.id] ?? 0) > item.quantity + 1e-9) item.name];
    expect(over, isEmpty);
  });

  test('shopping-list items fill gaps but the pantry comes first', () {
    final student = [p('Pasta', q: 500, u: Unit.g), p('Cheddar', q: 200, u: Unit.g, days: 10, cat: 'Dairy')];
    final ideas = engine.suggest(student, shoppingList: ['Broccoli']);
    final withBroccoli = ideas.where((r) => r.ingredients.any((i) => i.name == 'Broccoli'));
    expect(withBroccoli, isNotEmpty);
    expect(withBroccoli.first.ingredients.firstWhere((i) => i.name == 'Broccoli').pantryId, isNull);
    expect(isOnList(withBroccoli.first.ingredients.firstWhere((i) => i.name == 'Broccoli'), ['broccoli']), isTrue);
  });

  test('titles read naturally', () {
    final titles = everyDish(fridge).map((r) => r.title);
    expect(titles, contains('Banana smoothie')); // singular, not "Bananas smoothie"
    expect(titles, contains('Spinach & feta frittata')); // main item per slot, not every item
    for (final t in titles) {
      expect(' and '.allMatches(t).length, lessThan(2), reason: t);
    }
  });

  test('every language renders with no placeholders left, for every dish', () {
    final rich = [
      ...fridge, p('Tortillas', q: 6), p('Cheddar', q: 200, u: Unit.g, days: 9, cat: 'Dairy'), p('Oats', q: 500, u: Unit.g),
      p('Flour', q: 1, u: Unit.kg), p('Butter', q: 250, u: Unit.g, days: 30, cat: 'Dairy'), p('Apples', q: 4, days: 3),
      p('Potatoes', q: 6, days: 10), p('Coconut milk', q: 400, u: Unit.ml), p('Kidney beans', q: 400, u: Unit.g),
      p('Sourdough bread', q: 1, days: 2, cat: 'Bakery'), p('Tofu', q: 400, u: Unit.g, days: 5, cat: 'PlantProtein'),
      p('Basil', q: 1, days: 3, cat: 'Produce'), p('Vegetable stock', q: 500, u: Unit.ml),
      p('Fresh milk', q: 1, u: Unit.l, days: 5, cat: 'Dairy'), p('Red lentils', q: 500, u: Unit.g),
      p('Egg noodles', q: 300, u: Unit.g),
    ];
    for (final lang in ['en', 'es', 'de', 'fr']) {
      final rs = everyDish(rich, lang: lang);
      expect(rs.length, greaterThanOrEqualTo(25), reason: lang); // all 25 dishes, some in two versions
      expect({for (final r in rs) r.dish}.length, 25, reason: lang); // every dish, tagged with its id
      for (final text in allText(rs)) {
        expect(text, isNot(contains('{')), reason: '$lang: $text');
        expect(text.trim(), isNotEmpty);
      }
      for (final r in rs) {
        expect(r.steps, isNotEmpty, reason: '$lang ${r.title}');
      }
    }
    final es = engine.suggest(fridge, language: 'es').map((r) => r.title).join(' | ');
    expect(es, anyOf(contains(' con '), contains(' de ')));
  });

  test('output works with cooking deductions and the week\'s shopping', () {
    final r = engine.suggest(fridge).first;
    final plan = planDeductions(r, fridge);
    expect(plan, isNotEmpty);
    expect(plan.every((d) => d.amount <= d.item.quantity), isTrue);
    expect(plan.map((d) => d.item.name), isNot(contains('Oil'))); // staples are never deducted
    final needs = shoppingForPlan([r], fridge);
    expect(needs.map((n) => n.name), isNot(anyOf(contains('Salt'), contains('Oil'), contains('Pepper'))));
  });

  test('nothing to work with gives nothing, not an error', () {
    expect(engine.suggest(const []), isEmpty);
    expect(engine.suggest([p('Dish soap'), p('Mystery box'), p('Peanut butter')]), isEmpty);
    expect(engine.suggest([p('Spinach', q: 0, days: 1)]), isEmpty); // used up
  });

  group('learning from the user', () {
    final now = DateTime.now();
    late List<PantryItem> veg;
    setUp(() => veg = [
          p('Spinach', q: 200, u: Unit.g, days: 3, cat: 'Produce'), p('Feta', q: 150, u: Unit.g, days: 6, cat: 'Dairy'),
          p('Eggs', q: 6, days: 12), p('Mushrooms', q: 250, u: Unit.g, days: 3, cat: 'Produce'),
          p('Carrots', q: 4, days: 6, cat: 'Produce'), p('Red lentils', q: 500, u: Unit.g), p('Rice', q: 1, u: Unit.kg),
          p('Onion', q: 3, days: 20), p('Parmesan', q: 100, u: Unit.g, days: 30), p('Vegetable stock', q: 1, u: Unit.l),
        ]);
    TasteProfile loves(String dish) {
      var t = const TasteProfile();
      for (var i = 0; i < 3; i++) {
        t = t.cookedIt(dish, now.subtract(Duration(days: 10 + i * 5)));
      }
      return t;
    }

    test('a dish the user keeps cooking rises to the top', () {
      expect(engine.suggest(veg, now: now).first.dish, isNot('frittata'));
      expect(engine.suggest(veg, taste: loves('frittata'), now: now).first.dish, 'frittata');
    });

    test('but not the day after cooking it', () {
      final yesterday = loves('frittata').cookedIt('frittata', now.subtract(const Duration(days: 1)));
      expect(engine.suggest(veg, taste: yesterday, now: now).map((r) => r.dish), isNot(contains('frittata')));
    });

    test('"not for me" hides that recipe; disliking only nudges', () {
      final first = engine.suggest(veg, now: now).first;
      final hidden = const TasteProfile().notForMe(first.dish, first.title, now);
      expect(engine.suggest(veg, count: 25, taste: hidden, now: now).map((r) => r.title), isNot(contains(first.title)));
      // Disliking a dish moves it down, it doesn't ban it: other dishes from the same food come first,
      // and it is still further down the list.
      final eggsAndSpinach = [p('Eggs', q: 6), p('Spinach', q: 200, u: Unit.g, days: 1)];
      var hates = const TasteProfile();
      for (var i = 0; i < 6; i++) {
        hates = hates.swappedAway('frittata', now);
      }
      final ranked = engine.suggest(eggsAndSpinach, count: 25, taste: hates, now: now).map((r) => r.dish).toList();
      expect(ranked.first, isNot('frittata'));
      expect(ranked, contains('frittata'));
    });

    test('taste never overrides diet or safety', () {
      final vegan = engine.suggest(veg, count: 10, taste: loves('frittata'), now: now, prefs: const RecipePreferences(diets: {Diet.vegan}));
      expect(vegan.map((r) => r.dish), isNot(contains('frittata')));
    });
  });

  test('flavour pairing: mushroom risotto takes parmesan over the more urgent feta', () {
    final pantry = [
      p('Mushrooms', q: 250, u: Unit.g, days: 2, cat: 'Produce'), p('Rice', q: 1, u: Unit.kg),
      p('Feta', q: 150, u: Unit.g, days: 4, cat: 'Dairy'), p('Parmesan', q: 100, u: Unit.g, days: 30, cat: 'Dairy'),
    ];
    final risotto = engine.suggest(pantry, count: 25).firstWhere((r) => r.dish == 'risotto');
    expect(risotto.title, 'Mushroom & parmesan risotto');
  });

  test('dal is made with lentils, never kidney beans', () {
    final pantry = [p('Kidney beans', q: 400, u: Unit.g), p('Onion', q: 2), p('Chopped tomatoes', q: 400, u: Unit.g)];
    for (final r in engine.suggest(pantry, count: 25).where((r) => r.dish == 'dal')) {
      expect(r.ingredients.map((i) => i.name), isNot(contains('Kidney beans')));
    }
  });
}
