import 'dart:math' as math;
import '../models/categories.dart';
import '../models/pantry_item.dart';
import '../models/recipe.dart';
import '../models/recipe_preferences.dart';
import '../models/taste_profile.dart';
import '../models/unit.dart';

/// PantryPal's own recipe engine: on-device, offline, instant.
///
/// 1. **Understand the pantry.** Each item gets culinary *roles* (eggs, leafy greens, cheese,
///    rice, a protein…) from a multilingual lexicon, with its category as a fallback, plus
///    diet flags (meat, fish, animal product, dairy, gluten) and an *urgency* from its expiry.
/// 2. **Fill dish templates.** A knowledge base of flexible dishes has role slots; each slot is
///    filled with the best fitting item, most urgent first. Optional slots enrich a dish; at most
///    one required slot may be missing (it becomes "to buy").
/// 3. **Score.** Urgency of what a dish uses up, build-around items, coverage, minus missing
///    ingredients; items already on the shopping list count, but less than the pantry.
/// 4. **Pick a diverse set.** Greedy selection that penalises reusing the same item, so several
///    ideas use up different food.
///
/// Rules always applied: diet, time limit and "leave out" preferences; never expired meat, fish,
/// dairy, deli or tofu. Output is a normal [Recipe] in the user's language, with ingredient
/// amounts in each pantry item's own unit and links to it, so cooking, planning and the week's
/// shopping all work on it.
class RecipeEngine {
  const RecipeEngine();

  List<Recipe> suggest(
    List<PantryItem> pantry, {
    List<String> shoppingList = const [],
    RecipePreferences prefs = const RecipePreferences(),
    Set<int> focusIds = const {},
    List<String> avoidTitles = const [],
    int count = 3,
    String language = 'en',
    bool mainsOnly = false,
    bool forPlan = false,
    TasteProfile taste = const TasteProfile(),
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final lang = _texts.containsKey(language) ? language : 'en';
    final avoidWords = [
      for (final w in prefs.avoid.toLowerCase().split(RegExp(r'[,;\n]+')))
        if (w.trim().length >= 2) w.trim(),
    ];
    bool allowed(_Item i) {
      if (avoidWords.any(i.lower.contains)) return false;
      final d = prefs.diets;
      if ((d.contains(Diet.vegetarian) || d.contains(Diet.vegan)) && (i.meat || i.fish)) return false;
      if (d.contains(Diet.vegan) && i.animal) return false;
      if (d.contains(Diet.dairyFree) && i.dairy) return false;
      if (d.contains(Diet.glutenFree) && i.gluten) return false;
      return true;
    }

    final items = <_Item>[
      for (final p in pantry)
        if (p.quantity > 0) _Item.of(p),
      for (final n in shoppingList)
        if (n.trim().isNotEmpty) _Item.of(PantryItem(name: n.trim(), category: guessCategory(n) ?? 'Other'), onList: true),
    ].where((i) => i.roles.isNotEmpty && !i.unsafe && allowed(i)).toList();

    final avoid = {for (final t in avoidTitles) _norm(t)};
    final templates = [
      for (final t in _templates)
        if ((prefs.maxMinutes == null || t.minutes <= prefs.maxMinutes!) &&
            (!mainsOnly || t.kind == DishKind.main) &&
            !avoidWords.any((w) => t.staples.any((s) => s.values.any((v) => v.toLowerCase().contains(w)))))
          t,
    ];

    // Ideas are picked one at a time. Ideas are alternatives (you cook one), so each is checked
    // against the whole pantry. With [forPlan] every dish will be cooked: each round re-fills the
    // dishes against what is *left* after the ones already chosen, so the plan never needs more
    // of an item than there is, and a later day uses the next-best item instead.
    final left = <int, double>{for (final p in pantry) if (p.id != null) p.id!: p.quantity};
    final uses = <int, int>{}; // how many chosen ideas use each item (for variety)
    final picked = <Recipe>[];
    final seenTemplates = <String>{};
    final seenTitles = <String>{...avoid};

    for (var round = 0; round < count; round++) {
      _Candidate? best;
      Recipe? bestRecipe;
      var bestScore = double.negativeInfinity;
      for (final t in templates) {
        if (seenTemplates.contains(t.id)) continue;
        for (final variant in [0, 1]) {
          final exclude = <_Item>{for (final i in items) if (i.id != null && (left[i.id] ?? 0) <= 1e-9) i};
          // Variant 1 is the dish without its usual main item, for variety.
          if (variant == 1) {
            final first = _fill(t, items, exclude: exclude, focus: focusIds, diets: prefs.diets, avoidWords: avoidWords);
            final main = first?.mainItem;
            if (main == null) continue;
            exclude.add(main);
          }
          // Set aside items that don't have enough left for this dish, and fill again (a few tries).
          _Candidate? c;
          Recipe? r;
          for (var tries = 0; tries < 4; tries++) {
            c = _fill(t, items, exclude: exclude, focus: focusIds, diets: prefs.diets, avoidWords: avoidWords);
            if (c == null) break;
            r = _render(c, lang, prefs.servings);
            final short = [
              for (final i in c.items)
                if (i.id != null &&
                    r.ingredients.where((x) => x.pantryId == i.id).fold(0.0, (s, x) => s + (x.amount ?? 0)) >
                        (left[i.id] ?? 0) + 1e-9)
                  i,
            ];
            if (short.isEmpty) break;
            exclude.addAll(short);
            c = null;
          }
          if (c == null || r == null) continue;
          if (seenTitles.contains(_norm(r.title)) || taste.isHidden(r.title, clock)) continue;
          if (focusIds.isNotEmpty && !c.usesAnyOf(focusIds)) continue;
          var score = c.score + _tasteAdjustment(t.id, taste, clock);
          for (final i in c.items) {
            final n = i.id == null ? 0 : (uses[i.id] ?? 0);
            // Gentle: using up urgent food across two dinners is good; the same item every night isn't.
            if (n > 0 && !focusIds.contains(i.id)) score -= 0.3 * n + 0.25 * n * n;
          }
          if (score > bestScore) {
            bestScore = score;
            best = c;
            bestRecipe = r;
          }
        }
      }
      if (best == null || bestRecipe == null) break;
      picked.add(bestRecipe);
      seenTemplates.add(best.template.id);
      seenTitles.add(_norm(bestRecipe.title));
      if (forPlan) {
        for (final x in bestRecipe.ingredients) {
          if (x.pantryId == null) continue;
          left[x.pantryId!] = (left[x.pantryId!] ?? 0) - (x.amount ?? 0);
        }
      }
      for (final i in best.items) {
        if (i.id != null) uses[i.id!] = (uses[i.id!] ?? 0) + 1;
      }
    }
    // Build-around found nothing: offer the best of everything rather than nothing.
    if (picked.isEmpty && focusIds.isNotEmpty) {
      return suggest(pantry,
          shoppingList: shoppingList,
          prefs: prefs,
          avoidTitles: avoidTitles,
          count: count,
          language: language,
          mainsOnly: mainsOnly,
          forPlan: forPlan,
          taste: taste,
          now: clock);
    }
    return picked;
  }

  // ---------------------------------------------------------------------------------------------
  // Filling and scoring

  /// Learned taste nudges the ranking (capped, so using up food still comes first); a dish cooked
  /// in the last few days steps back so suggestions don't repeat last night's dinner.
  static double _tasteAdjustment(String dish, TasteProfile taste, DateTime now) {
    var a = (taste.score(dish, now) * 0.35).clamp(-3.0, 2.5);
    final d = taste.cookedDaysAgo(dish, now);
    // Not last night's dinner again: recency outweighs liking a dish.
    if (d != null) a -= d <= 1 ? 4.0 : d <= 3 ? 1.5 : d <= 7 ? 0.5 : 0;
    return a;
  }

  _Candidate? _fill(_Template t, List<_Item> items,
      {required Set<_Item> exclude, required Set<int> focus, required Set<Diet> diets, required List<String> avoidWords}) {
    final used = <_Item>{};
    final fills = <String, List<_Item>>{};
    var missing = 0;
    for (final slot in t.slots) {
      // Required slots take the most urgent item; optional ones also weigh how well an item goes
      // with what the dish already has ("feta" with spinach rather than with nothing in particular).
      double value(_Item i) => i.urgency + (slot.required ? 0 : 0.6 * _pairsWith(i, used));
      final options = items.where((i) => !used.contains(i) && !exclude.contains(i) && slot.roles.any(i.roles.contains)).toList()
        ..sort((a, b) {
          final fa = a.id != null && focus.contains(a.id) ? 1 : 0, fb = b.id != null && focus.contains(b.id) ? 1 : 0;
          if (fa != fb) return fb - fa;
          final u = value(b).compareTo(value(a));
          if (u != 0) return u;
          return (a.onList ? 1 : 0) - (b.onList ? 1 : 0);
        });
      final chosen = options.take(slot.take).toList();
      if (chosen.isEmpty && slot.required) {
        if (!_canBuy(slot, diets, avoidWords)) return null;
        missing++;
      }
      used.addAll(chosen);
      fills[slot.key] = chosen;
    }
    final pantryUsed = used.where((i) => !i.onList).length;
    if (missing > 1 || pantryUsed < t.minPantry) return null;
    var score = 0.0;
    for (final slot in t.slots) {
      for (final i in fills[slot.key]!) {
        score += i.urgency * (slot.required ? 1.0 : 0.6) * (i.onList ? 0.4 : 1.0);
        if (i.id != null && focus.contains(i.id)) score += 4;
        score += 0.15;
      }
    }
    score -= 3.0 * missing;
    final all = used.toList();
    for (var x = 0; x < all.length; x++) {
      score += 0.35 * _pairsWith(all[x], all.sublist(x + 1)); // flavours that go together
    }
    if (t.kind != DishKind.main) score -= 0.3; // ideas lead with meals unless a snack saves more food
    return _Candidate(t, fills, used.toList(), score);
  }

  /// Whether a required slot left empty may become a "to buy" line: not if buying it would break
  /// the diet (eggs for a vegan) or the "leave out" list.
  static bool _canBuy(_Slot slot, Set<Diet> diets, List<String> avoidWords) {
    bool only(Set<_Role> group) => slot.roles.every(group.contains);
    if (diets.contains(Diet.vegan) && only(_animalRoles)) return false;
    if ((diets.contains(Diet.vegetarian) || diets.contains(Diet.vegan)) && only(const {_Role.meat, _Role.fish})) return false;
    if (diets.contains(Diet.dairyFree) && only(_dairyRoles)) return false;
    if (diets.contains(Diet.glutenFree) && only(_glutenRoles)) return false;
    final names = slot.fallback?.values.map((v) => v.toLowerCase()) ?? const <String>[];
    return !avoidWords.any((w) => names.any((n) => n.contains(w)) || slot.key.contains(w));
  }

  // ---------------------------------------------------------------------------------------------
  // Rendering in the user's language

  Recipe _render(_Candidate c, String lang, int servings) {
    final t = c.template;
    String inline(String name) {
      if (lang == 'de' || name.length < 2) return name;
      return name[1] == name[1].toLowerCase() ? name[0].toLowerCase() + name.substring(1) : name;
    }

    final slots = {for (final s in t.slots) s.key: s};
    String fallback(String key) => inline(slots[key]?.fallback?[lang] ?? slots[key]?.fallback?['en'] ?? key);
    bool requiredMissing(String key) => c.fills[key]!.isEmpty && (slots[key]?.required ?? false);
    // Steps name every item in a slot; a required slot with nothing in the pantry uses its generic name.
    String names(String key) => requiredMissing(key) ? fallback(key) : _join([for (final i in c.fills[key]!) inline(i.item.name)], lang);
    // Titles name only a slot's main item ("Spinach & feta frittata"), singular in English ("Banana smoothie").
    String titleName(String key) {
      final n = requiredMissing(key) ? fallback(key) : inline(c.fills[key]!.first.item.name);
      if (lang != 'en') return n;
      final words = n.split(' ');
      return [...words.take(words.length - 1), singularize(words.last)].join(' ');
    }
    bool filled(String key) => c.fills[key]!.isNotEmpty || requiredMissing(key);
    String fillIn(String text, {bool title = false}) =>
        text.replaceAllMapped(RegExp(r'\{(\w+)\}'), (m) => title ? titleName(m[1]!) : names(m[1]!));
    bool usable(String text) => RegExp(r'\{(\w+)\}').allMatches(text).every((m) => filled(m[1]!));

    var title = t.titles.map((v) => v[lang] ?? v['en']!).firstWhere(usable, orElse: () => t.titles.last[lang] ?? t.titles.last['en']!);
    title = fillIn(title, title: true);
    title = title[0].toUpperCase() + title.substring(1);

    final ingredients = <RecipeIngredient>[];
    for (final slot in t.slots) {
      final chosen = c.fills[slot.key]!;
      if (chosen.isEmpty) {
        if (slot.required) {
          ingredients.add(RecipeIngredient(
            name: slot.fallback?[lang] ?? slot.fallback?['en'] ?? slot.key,
            amount: _amountFor(slot, null, servings),
            unit: _unitFor(slot, null),
          ));
        }
        continue;
      }
      for (final i in chosen) {
        ingredients.add(RecipeIngredient(
          name: i.item.name,
          amount: _amountFor(slot, i.item, servings, sharedBy: chosen.length),
          unit: _unitFor(slot, i.item),
          pantryId: i.onList ? null : i.item.id,
        ));
      }
    }
    for (final s in t.staples) {
      ingredients.add(RecipeIngredient(name: s[lang] ?? s['en']!, staple: true));
    }

    final steps = [
      for (final s in t.steps)
        if (usable(s[lang] ?? s['en']!)) fillIn(s[lang] ?? s['en']!),
    ];

    final byUrgency = [...c.items.where((i) => !i.onList)]..sort((a, b) => b.urgency.compareTo(a.urgency));
    final txt = _texts[lang]!;
    final summary = byUrgency.isEmpty
        ? ''
        : txt['uses']!.replaceFirst('{items}', _join([for (final i in byUrgency.take(3)) inline(i.item.name)], lang));

    return Recipe(
      title: title,
      summary: summary,
      minutes: t.minutes,
      servings: servings,
      ingredients: ingredients,
      steps: steps,
      dish: t.id,
    );
  }

  /// The recipe amount in the pantry item's own unit when it can be (so it can be deducted
  /// after cooking), otherwise in the slot's natural unit.
  static double? _amountFor(_Slot slot, PantryItem? item, int servings, {int sharedBy = 1}) {
    final perPieces = slot.pieces * servings;
    if (item == null) {
      if (slot.natural == Unit.count) return math.max(1, perPieces.ceilToDouble());
      return ((slot.natural.dimension == Dimension.volume && slot.ml > 0 ? slot.ml : slot.grams) * servings).toDouble();
    }
    final share = 1 / math.max(1, sharedBy); // the items in a slot share its amount
    if (item.unit.isCount) return math.max(1, (perPieces * share).ceilToDouble());
    final base = (item.unit.dimension == Dimension.volume ? (slot.ml > 0 ? slot.ml : slot.grams) : slot.grams) * servings * share;
    final inUnit = (item.unit.dimension == Dimension.volume ? Unit.ml : Unit.g).convert(base.toDouble(), item.unit);
    return (inUnit * 100).roundToDouble() / 100;
  }

  static Unit? _unitFor(_Slot slot, PantryItem? item) {
    if (item != null) return item.unit;
    return slot.natural;
  }

  static String _join(List<String> parts, String lang) {
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first;
    final and = _texts[lang]!['and']!;
    return '${parts.sublist(0, parts.length - 1).join(', ')} $and ${parts.last}';
  }

  static String _norm(String s) => s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  /// How many of [others] are classic partners of [i] (see [_pairings]).
  static int _pairsWith(_Item i, Iterable<_Item> others) {
    var n = 0;
    for (final o in others) {
      for (final (a, b) in _pairings) {
        if ((i.lower.contains(a) && o.lower.contains(b)) || (i.lower.contains(b) && o.lower.contains(a))) {
          n++;
          break;
        }
      }
    }
    return n;
  }
}

/// Flavour pairings that are reliably good, as name fragments (several languages where the words
/// differ). Used to choose optional ingredients and to favour coherent dishes.
const _pairings = <(String, String)>[
  ('spinach', 'feta'), ('spinach', 'egg'), ('spinach', 'ricotta'), ('spinach', 'chickpea'), ('spinach', 'lentil'),
  ('tomato', 'basil'), ('tomato', 'mozzarella'), ('tomato', 'feta'), ('tomato', 'egg'), ('pepper', 'onion'),
  ('pepper', 'chicken'), ('pepper', 'chorizo'), ('chicken', 'rice'), ('chicken', 'mushroom'), ('chicken', 'lemon'),
  ('mushroom', 'cheese'), ('mushroom', 'parmesan'), ('mushroom', 'cream'), ('mushroom', 'thyme'), ('potato', 'cheese'),
  ('potato', 'rosemary'), ('potato', 'leek'), ('broccoli', 'cheddar'), ('broccoli', 'garlic'), ('courgette', 'feta'),
  ('zucchini', 'feta'), ('carrot', 'ginger'), ('carrot', 'lentil'), ('pea', 'mint'), ('pea', 'ham'), ('salmon', 'dill'),
  ('salmon', 'potato'), ('salmon', 'lemon'), ('tuna', 'sweetcorn'), ('bean', 'cheese'), ('bean', 'tomato'),
  ('tofu', 'ginger'), ('tofu', 'garlic'), ('pumpkin', 'sage'), ('squash', 'sage'), ('cauliflower', 'cheese'),
  ('banana', 'oat'), ('banana', 'yogurt'), ('banana', 'peanut'), ('apple', 'oat'), ('apple', 'cinnamon'), ('pear', 'oat'),
  ('berr', 'yogurt'), ('berr', 'oat'), ('mango', 'yogurt'), ('coconut', 'curry'), ('coconut', 'lentil'),
  ('espinaca', 'queso'), ('tomate', 'albahaca'), ('spinat', 'feta'), ('tomate', 'basilikum'), ('épinard', 'feta'),
];

// -----------------------------------------------------------------------------------------------
// Pantry understanding

enum _Role {
  lentils, egg, meat, fish, plantProtein, beans, pasta, rice, bread, tortilla, potato, oats, flour, veg, leafy, aromatic,
  tomato, fruit, cheese, milk, yogurt, cream, butter, coconutMilk, stock, herb,
}

const _animalRoles = {_Role.egg, _Role.meat, _Role.fish, _Role.cheese, _Role.milk, _Role.yogurt, _Role.cream, _Role.butter};
const _dairyRoles = {_Role.cheese, _Role.milk, _Role.yogurt, _Role.cream, _Role.butter};
const _glutenRoles = {_Role.pasta, _Role.bread, _Role.tortilla, _Role.flour, _Role.oats};

/// Keyword → roles, in English, Spanish, German and French. Keywords of 3 letters or fewer, or
/// starting with "=", match a whole word; longer ones match a word's start ("tomato" → "tomatoes").
const _lexicon = <String, List<_Role>>{
  // eggs
  'egg': [_Role.egg], 'eggs': [_Role.egg], 'huevo': [_Role.egg], 'eier': [_Role.egg], '=ei': [_Role.egg],
  'oeuf': [_Role.egg], 'œuf': [_Role.egg],
  // meat & fish
  'chicken': [_Role.meat], 'beef': [_Role.meat], 'pork': [_Role.meat], 'turkey': [_Role.meat], 'mince': [_Role.meat],
  'sausage': [_Role.meat], 'bacon': [_Role.meat], '=ham': [_Role.meat], 'lamb': [_Role.meat], 'steak': [_Role.meat],
  'chorizo': [_Role.meat], 'pollo': [_Role.meat], 'ternera': [_Role.meat], 'cerdo': [_Role.meat], 'carne': [_Role.meat],
  'jamón': [_Role.meat], 'hähnchen': [_Role.meat], 'huhn': [_Role.meat], 'rind': [_Role.meat], 'hack': [_Role.meat],
  'schinken': [_Role.meat], 'wurst': [_Role.meat], 'poulet': [_Role.meat], 'boeuf': [_Role.meat], 'bœuf': [_Role.meat],
  'porc': [_Role.meat], 'jambon': [_Role.meat], 'viande': [_Role.meat],
  'fish': [_Role.fish], 'salmon': [_Role.fish], 'tuna': [_Role.fish], '=cod': [_Role.fish], 'shrimp': [_Role.fish],
  'prawn': [_Role.fish], 'pescado': [_Role.fish], 'salmón': [_Role.fish], 'atún': [_Role.fish], 'gamba': [_Role.fish],
  'fisch': [_Role.fish], 'lachs': [_Role.fish], 'thunfisch': [_Role.fish], 'poisson': [_Role.fish], 'saumon': [_Role.fish],
  '=thon': [_Role.fish],
  // plant protein & beans
  'tofu': [_Role.plantProtein], 'tempeh': [_Role.plantProtein], 'seitan': [_Role.plantProtein],
  'chickpea': [_Role.beans], 'lentil': [_Role.beans, _Role.lentils], 'bean': [_Role.beans], 'garbanzo': [_Role.beans],
  'lenteja': [_Role.beans, _Role.lentils], 'alubia': [_Role.beans], 'frijol': [_Role.beans], 'linse': [_Role.beans, _Role.lentils],
  'bohne': [_Role.beans], 'kichererbse': [_Role.beans], 'lentille': [_Role.beans, _Role.lentils], 'haricot': [_Role.beans],
  'pois chiche': [_Role.beans], '=dal': [_Role.lentils, _Role.beans], '=dhal': [_Role.lentils, _Role.beans],
  // carbs
  'pasta': [_Role.pasta], 'spaghetti': [_Role.pasta], 'penne': [_Role.pasta], 'fusilli': [_Role.pasta],
  'macaroni': [_Role.pasta], 'noodle': [_Role.pasta], 'linguine': [_Role.pasta], 'tagliatelle': [_Role.pasta],
  'fideo': [_Role.pasta], 'nudel': [_Role.pasta], 'pâtes': [_Role.pasta], 'pates': [_Role.pasta],
  'rice': [_Role.rice], 'quinoa': [_Role.rice], 'couscous': [_Role.rice], 'bulgur': [_Role.rice], 'arroz': [_Role.rice],
  'reis': [_Role.rice], '=riz': [_Role.rice],
  'bread': [_Role.bread], 'baguette': [_Role.bread], 'bagel': [_Role.bread], 'sourdough': [_Role.bread],
  'brot': [_Role.bread], '=pan': [_Role.bread], '=pain': [_Role.bread],
  'tortilla': [_Role.tortilla], 'wrap': [_Role.tortilla], '=pita': [_Role.tortilla],
  'potato': [_Role.potato], 'patata': [_Role.potato], '=papa': [_Role.potato], 'kartoffel': [_Role.potato],
  'pomme de terre': [_Role.potato],
  'oat': [_Role.oats], 'avena': [_Role.oats], 'hafer': [_Role.oats], 'flocons d': [_Role.oats],
  'flour': [_Role.flour], 'harina': [_Role.flour], 'mehl': [_Role.flour], 'farine': [_Role.flour],
  // vegetables
  'spinach': [_Role.leafy, _Role.veg], 'kale': [_Role.leafy, _Role.veg], 'lettuce': [_Role.leafy],
  'rocket': [_Role.leafy], 'arugula': [_Role.leafy], 'chard': [_Role.leafy, _Role.veg], 'salad': [_Role.leafy],
  'espinaca': [_Role.leafy, _Role.veg], 'lechuga': [_Role.leafy], 'spinat': [_Role.leafy, _Role.veg],
  'salat': [_Role.leafy], 'épinard': [_Role.leafy, _Role.veg], 'epinard': [_Role.leafy, _Role.veg], 'laitue': [_Role.leafy],
  'broccoli': [_Role.veg], 'pepper': [_Role.veg], 'zucchini': [_Role.veg], 'courgette': [_Role.veg],
  'carrot': [_Role.veg], 'mushroom': [_Role.veg], 'cabbage': [_Role.veg], 'cauliflower': [_Role.veg],
  '=pea': [_Role.veg], '=peas': [_Role.veg], 'sweetcorn': [_Role.veg], '=corn': [_Role.veg], 'green bean': [_Role.veg],
  'aubergine': [_Role.veg], 'eggplant': [_Role.veg], 'squash': [_Role.veg], 'pumpkin': [_Role.veg], 'leek': [_Role.veg, _Role.aromatic],
  'asparagus': [_Role.veg], 'celery': [_Role.veg], 'cucumber': [_Role.veg], 'beetroot': [_Role.veg],
  'brócoli': [_Role.veg], 'pimiento': [_Role.veg], 'calabacín': [_Role.veg], 'zanahoria': [_Role.veg],
  'champiñón': [_Role.veg], 'seta': [_Role.veg], 'paprika': [_Role.veg], 'karotte': [_Role.veg], 'möhre': [_Role.veg],
  'pilz': [_Role.veg], 'champignon': [_Role.veg], 'brokkoli': [_Role.veg], 'poivron': [_Role.veg], 'carotte': [_Role.veg],
  'tomato': [_Role.tomato, _Role.veg], 'tomate': [_Role.tomato, _Role.veg], 'passata': [_Role.tomato],
  'onion': [_Role.aromatic], 'garlic': [_Role.aromatic], 'shallot': [_Role.aromatic], 'ginger': [_Role.aromatic],
  'cebolla': [_Role.aromatic], '=ajo': [_Role.aromatic], 'zwiebel': [_Role.aromatic], 'knoblauch': [_Role.aromatic],
  'oignon': [_Role.aromatic], '=ail': [_Role.aromatic], 'échalote': [_Role.aromatic],
  // fruit
  'apple': [_Role.fruit], 'banana': [_Role.fruit], 'berr': [_Role.fruit], 'strawberr': [_Role.fruit], 'pear': [_Role.fruit],
  'peach': [_Role.fruit], 'mango': [_Role.fruit], 'plum': [_Role.fruit], 'cherr': [_Role.fruit], 'grape': [_Role.fruit],
  'pineapple': [_Role.fruit], 'kiwi': [_Role.fruit], 'apricot': [_Role.fruit], 'rhubarb': [_Role.fruit],
  'manzana': [_Role.fruit], 'plátano': [_Role.fruit], 'platano': [_Role.fruit], 'fresa': [_Role.fruit],
  'apfel': [_Role.fruit], 'banane': [_Role.fruit], 'erdbeer': [_Role.fruit], 'beere': [_Role.fruit], 'birne': [_Role.fruit],
  'pomme': [_Role.fruit], 'fraise': [_Role.fruit], 'poire': [_Role.fruit],
  // dairy & others
  'cheese': [_Role.cheese], 'cheddar': [_Role.cheese], 'mozzarella': [_Role.cheese], 'parmesan': [_Role.cheese],
  'feta': [_Role.cheese], 'halloumi': [_Role.cheese], 'gouda': [_Role.cheese], 'queso': [_Role.cheese],
  'käse': [_Role.cheese], 'kaese': [_Role.cheese], 'fromage': [_Role.cheese], 'emmental': [_Role.cheese],
  'milk': [_Role.milk], 'leche': [_Role.milk], 'milch': [_Role.milk], '=lait': [_Role.milk],
  'yogurt': [_Role.yogurt], 'yoghurt': [_Role.yogurt], 'yogur': [_Role.yogurt], 'joghurt': [_Role.yogurt],
  'yaourt': [_Role.yogurt], 'skyr': [_Role.yogurt],
  'cream': [_Role.cream], 'crème fraîche': [_Role.cream], 'sour cream': [_Role.cream], '=nata': [_Role.cream],
  'sahne': [_Role.cream], 'crème': [_Role.cream],
  'butter': [_Role.butter], 'mantequilla': [_Role.butter], 'beurre': [_Role.butter],
  'coconut milk': [_Role.coconutMilk], 'leche de coco': [_Role.coconutMilk], 'kokosmilch': [_Role.coconutMilk],
  'lait de coco': [_Role.coconutMilk],
  'stock': [_Role.stock], 'broth': [_Role.stock], 'caldo': [_Role.stock], 'brühe': [_Role.stock], 'bouillon': [_Role.stock],
  'basil': [_Role.herb], 'parsley': [_Role.herb], 'cilantro': [_Role.herb], 'coriander': [_Role.herb], '=dill': [_Role.herb],
  '=mint': [_Role.herb], 'chive': [_Role.herb], 'albahaca': [_Role.herb], 'perejil': [_Role.herb], 'basilikum': [_Role.herb],
  'petersilie': [_Role.herb], 'basilic': [_Role.herb], 'persil': [_Role.herb],
};

/// Phrases that mean something other than their words ("peanut butter" is not butter, "oat milk"
/// is milk, "ice cream" is neither). When one matches, its roles replace the word lexicon's.
const _phraseRoles = <String, List<_Role>>{
  'peanut butter': [], 'almond butter': [], 'nut butter': [], 'ice cream': [], 'tomato ketchup': [], 'ketchup': [],
  'butternut': [_Role.veg], 'sweet potato': [_Role.potato, _Role.veg], 'cream cheese': [_Role.cheese],
  'coconut milk': [_Role.coconutMilk], 'lait de coco': [_Role.coconutMilk], 'kokosmilch': [_Role.coconutMilk],
  'leche de coco': [_Role.coconutMilk], 'egg noodle': [_Role.pasta], 'rice noodle': [_Role.pasta],
  'rice milk': [_Role.milk], 'oat milk': [_Role.milk], 'almond milk': [_Role.milk], 'soy milk': [_Role.milk],
  'buttermilk': [_Role.milk], 'tomato sauce': [_Role.tomato], 'passata': [_Role.tomato], 'chopped tomato': [_Role.tomato],
  'green bean': [_Role.veg], 'spring onion': [_Role.aromatic, _Role.veg], 'chicken stock': [_Role.stock],
  'vegetable stock': [_Role.stock], 'beef stock': [_Role.stock],
};

class _Item {
  _Item(this.item, this.roles, {required this.onList})
      : lower = item.name.toLowerCase(),
        urgency = onList ? 0.1 : _urgency(item);
  final PantryItem item;
  final Set<_Role> roles;
  final bool onList;
  final String lower;
  final double urgency;

  int? get id => onList ? null : item.id;
  bool get meat => roles.contains(_Role.meat);
  bool get fish => roles.contains(_Role.fish);
  bool get plantMilk => RegExp(r'\b(oat|soy|almond|rice|coconut)\b|hafer|avena|soja|amande|mandel').hasMatch(lower);
  bool get dairy => roles.any(_dairyRoles.contains) && !plantMilk;
  bool get animal => meat || fish || roles.contains(_Role.egg) || dairy;
  bool get gluten =>
      roles.any(_glutenRoles.contains) && !RegExp(r'gluten.?free|sin gluten|glutenfrei|sans gluten').hasMatch(lower);

  /// Expired perishables are never suggested; expired dry goods and produce may be (marked urgent).
  bool get unsafe {
    final d = item.daysLeft;
    if (onList || d == null || d >= 0) return false;
    const perishable = {'Meat', 'Seafood', 'Dairy', 'Deli', 'PlantProtein'};
    return perishable.contains(item.category) || meat || fish || dairy || roles.contains(_Role.egg);
  }

  static double _urgency(PantryItem i) {
    final d = i.daysLeft;
    if (d == null) return 0.3;
    if (d < 0) return 2.5;
    if (d <= 1) return 3;
    if (d <= 3) return 2;
    if (d <= 7) return 1;
    return 0.5;
  }

  factory _Item.of(PantryItem p, {bool onList = false}) {
    final text = ' ${p.name.toLowerCase()} ';
    final words = text.split(RegExp(r"[^a-zà-ÿœß]+")).where((w) => w.isNotEmpty).toList();
    final roles = <_Role>{};
    final phrases = [for (final e in _phraseRoles.entries) if (text.contains(e.key)) e.value];
    if (phrases.isNotEmpty) {
      for (final r in phrases) {
        roles.addAll(r);
      }
      if (roles.isEmpty) return _Item(p, roles, onList: onList); // a known non-ingredient (ketchup)
    } else {
      for (final e in _lexicon.entries) {
        final kw = e.key;
        final hit = kw.contains(' ')
            ? text.contains(kw)
            : kw.startsWith('=')
                ? words.any((w) => w == kw.substring(1) || singularize(w) == kw.substring(1))
                : words.any((w) => kw.length <= 3 ? (w == kw || singularize(w) == kw) : w.startsWith(kw));
        if (hit) roles.addAll(e.value);
      }
    }
    // Category fallback for things the lexicon doesn't know.
    if (roles.isEmpty) {
      switch (p.category) {
        case 'Produce':
          roles.add(_Role.veg);
        case 'Meat':
          roles.add(_Role.meat);
        case 'Seafood':
          roles.add(_Role.fish);
        case 'PlantProtein':
          roles.add(_Role.plantProtein);
        case 'Bakery':
          roles.add(_Role.bread);
      }
    }
    if (roles.contains(_Role.fruit)) roles.remove(_Role.veg);
    return _Item(p, roles, onList: onList);
  }
}

// -----------------------------------------------------------------------------------------------
// Knowledge base

typedef _L = Map<String, String>;

_L _l(String en, String es, String de, String fr) => {'en': en, 'es': es, 'de': de, 'fr': fr};

const _texts = {
  'en': {'and': 'and', 'uses': 'Uses up your {items}.'},
  'es': {'and': 'y', 'uses': 'Aprovecha {items}.'},
  'de': {'and': 'und', 'uses': 'Verbraucht {items}.'},
  'fr': {'and': 'et', 'uses': 'Utilise {items}.'},
};

class _Slot {
  const _Slot(this.key, this.roles,
      {this.required = true, this.take = 1, this.pieces = 1, this.grams = 100, this.ml = 0, this.natural = Unit.g, this.fallback});
  final String key;
  final Set<_Role> roles;
  final bool required;

  /// How many different items may fill it ("{veg}" can be spinach and peppers).
  final int take;

  /// Per serving: pieces for counted items, grams for weighed ones, ml for liquids (0 = grams).
  final double pieces;
  final int grams;
  final int ml;

  /// Unit for the "to buy" line when no pantry item fills a required slot.
  final Unit natural;
  final _L? fallback;
}

/// What a dish is for: meal plans use mains; idea lists favour mains slightly.
enum DishKind { main, breakfast, snack, dessert }

class _Template {
  const _Template(this.id, this.minutes, this.slots, this.titles, this.steps,
      {this.staples = const [], this.minPantry = 2, this.kind = DishKind.main});
  final String id;
  final DishKind kind;
  final int minutes;
  final List<_Slot> slots;
  final List<_L> titles; // first whose placeholders are all filled wins
  final List<_L> steps; // a step naming an empty slot is left out
  final List<_L> staples;
  final int minPantry;
}

class _Candidate {
  _Candidate(this.template, this.fills, this.items, this.score);
  final _Template template;
  final Map<String, List<_Item>> fills;
  final List<_Item> items;
  final double score;

  _Item? get mainItem {
    for (final s in template.slots.where((s) => s.required)) {
      final f = fills[s.key]!;
      if (f.isNotEmpty) return f.first;
    }
    return items.isEmpty ? null : items.first;
  }

  bool usesAnyOf(Set<int> ids) => items.any((i) => i.id != null && ids.contains(i.id));
}

final _oil = _l('Oil', 'Aceite', 'Öl', 'Huile');
final _salt = _l('Salt', 'Sal', 'Salz', 'Sel');
final _pepper = _l('Pepper', 'Pimienta', 'Pfeffer', 'Poivre');
final _sugar = _l('Sugar', 'Azúcar', 'Zucker', 'Sucre');
final _basics = [_oil, _salt, _pepper];

const _proteins = {_Role.meat, _Role.fish, _Role.plantProtein, _Role.beans};
const _greens = {_Role.veg, _Role.leafy};

final _eggs = _l('Eggs', 'Huevos', 'Eier', 'Œufs');

final List<_Template> _templates = [
  _Template('frittata', 25, [
    _Slot('egg', const {_Role.egg}, pieces: 2, natural: Unit.count, fallback: _eggs),
    _Slot('veg', _greens, take: 2, grams: 80, pieces: 0.5, fallback: _l('Vegetables', 'Verduras', 'Gemüse', 'Légumes')),
    const _Slot('cheese', {_Role.cheese}, required: false, grams: 25, pieces: 0.25),
    const _Slot('herb', {_Role.herb}, required: false, grams: 5, pieces: 0.25),
  ], [
    _l('{veg} & {cheese} frittata', 'Frittata de {veg} y {cheese}', '{veg}-{cheese}-Frittata', 'Frittata {veg} et {cheese}'),
    _l('{veg} frittata', 'Frittata de {veg}', '{veg}-Frittata', 'Frittata aux {veg}'),
  ], [
    _l('Heat the grill. Soften {veg} in a little oil in an ovenproof pan for 5 minutes.',
        'Calienta el gratinador. Rehoga {veg} con un poco de aceite en una sartén apta para horno, 5 minutos.',
        'Grill vorheizen. {veg} in etwas Öl in einer ofenfesten Pfanne 5 Minuten andünsten.',
        'Préchauffe le gril. Fais revenir {veg} dans un peu d\'huile, dans une poêle allant au four, 5 minutes.'),
    _l('Whisk {egg} with salt and pepper and pour over.', 'Bate {egg} con sal y pimienta y viértelos por encima.',
        '{egg} mit Salz und Pfeffer verquirlen und darübergießen.', 'Bats {egg} avec sel et poivre et verse par-dessus.'),
    _l('Scatter over {cheese}.', 'Reparte {cheese} por encima.', '{cheese} darüberstreuen.', 'Parsème de {cheese}.'),
    _l('Cook gently for 6–8 minutes until nearly set, then grill for 2–3 minutes until golden.',
        'Cocina a fuego suave 6–8 minutos hasta que casi cuaje y gratina 2–3 minutos.',
        'Bei milder Hitze 6–8 Minuten fast stocken lassen, dann 2–3 Minuten goldbraun grillen.',
        'Cuis doucement 6–8 minutes jusqu\'à ce que ce soit presque pris, puis 2–3 minutes sous le gril.'),
    _l('Finish with {herb}.', 'Termina con {herb}.', 'Mit {herb} bestreuen.', 'Termine avec {herb}.'),
  ], staples: _basics),

  _Template('stirfry', 20, [
    _Slot('veg', _greens, take: 3, grams: 100, pieces: 0.5, fallback: _l('Vegetables', 'Verduras', 'Gemüse', 'Légumes')),
    const _Slot('protein', _proteins, required: false, grams: 120),
    const _Slot('base', {_Role.rice, _Role.pasta}, required: false, grams: 75),
    const _Slot('aromatic', {_Role.aromatic}, required: false, grams: 15, pieces: 0.25),
  ], [
    _l('{protein} & {veg} stir-fry', 'Salteado de {protein} y {veg}', '{protein}-Pfanne mit {veg}', 'Sauté de {protein} et {veg}'),
    _l('{veg} stir-fry', 'Salteado de {veg}', 'Gemüsepfanne mit {veg}', 'Sauté de {veg}'),
  ], [
    _l('Cook {base} as the pack says.', 'Cuece {base} según el paquete.', '{base} nach Packungsangabe garen.',
        'Cuis {base} selon le paquet.'),
    _l('Fry {protein} in a hot pan with oil until cooked through, then set aside.',
        'Saltea {protein} en una sartén caliente con aceite hasta que esté hecho y resérvalo.',
        '{protein} in heißem Öl durchbraten und beiseitestellen.',
        'Fais sauter {protein} à feu vif dans l\'huile jusqu\'à cuisson, puis réserve.'),
    _l('Fry {aromatic} for 30 seconds.', 'Sofríe {aromatic} 30 segundos.', '{aromatic} 30 Sekunden anbraten.',
        'Fais revenir {aromatic} 30 secondes.'),
    _l('Add {veg}, sliced thin, and stir-fry for 3–4 minutes so it stays crisp.',
        'Añade {veg} en tiras finas y saltea 3–4 minutos para que quede crujiente.',
        '{veg} in dünnen Streifen 3–4 Minuten pfannenrühren, damit es knackig bleibt.',
        'Ajoute {veg} en fines lamelles et fais sauter 3–4 minutes pour garder du croquant.'),
    _l('Return everything to the pan, season with salt or soy sauce, and serve.',
        'Junta todo en la sartén, sazona con sal o salsa de soja y sirve.',
        'Alles zurück in die Pfanne geben, mit Salz oder Sojasoße würzen und servieren.',
        'Remets tout dans la poêle, assaisonne de sel ou de sauce soja et sers.'),
  ], staples: _basics),

  _Template('friedrice', 20, [
    _Slot('rice', const {_Role.rice}, grams: 75, fallback: _l('Rice', 'Arroz', 'Reis', 'Riz')),
    _Slot('veg', _greens, take: 2, grams: 80, pieces: 0.5, fallback: _l('Vegetables', 'Verduras', 'Gemüse', 'Légumes')),
    const _Slot('egg', {_Role.egg}, required: false, pieces: 1),
    const _Slot('protein', _proteins, required: false, grams: 80),
    const _Slot('aromatic', {_Role.aromatic}, required: false, grams: 15, pieces: 0.25),
  ], [
    _l('{protein} & {veg} fried rice', 'Arroz frito con {protein} y {veg}', 'Gebratener Reis mit {protein} und {veg}',
        'Riz sauté au {protein} et {veg}'),
    _l('{veg} fried rice', 'Arroz frito con {veg}', 'Gebratener Reis mit {veg}', 'Riz sauté aux {veg}'),
  ], [
    _l('Cook {rice} (or use leftover rice) and let it cool.', 'Cuece {rice} (o usa arroz de otro día) y deja que se enfríe.',
        '{rice} kochen (oder Reis vom Vortag nehmen) und abkühlen lassen.', 'Cuis {rice} (ou utilise un reste de riz) et laisse refroidir.'),
    _l('Fry {aromatic} in oil for 1 minute.', 'Sofríe {aromatic} en aceite 1 minuto.', '{aromatic} 1 Minute in Öl anbraten.',
        'Fais revenir {aromatic} 1 minute dans l\'huile.'),
    _l('Add {veg} and fry for 3–4 minutes.', 'Añade {veg} y saltea 3–4 minutos.', '{veg} dazugeben und 3–4 Minuten braten.',
        'Ajoute {veg} et fais sauter 3–4 minutes.'),
    _l('Add {protein} and cook through.', 'Añade {protein} y cocínalo bien.', '{protein} dazugeben und durchgaren.',
        'Ajoute {protein} et fais cuire à cœur.'),
    _l('Push everything aside and scramble {egg} in the gap.', 'Aparta todo a un lado y revuelve {egg} en el hueco.',
        'Alles zur Seite schieben und {egg} in der Lücke stocken lassen.', 'Pousse tout sur le côté et brouille {egg} dans l\'espace libre.'),
    _l('Stir in the rice, fry until piping hot, season and serve.', 'Incorpora el arroz, saltea hasta que esté muy caliente, sazona y sirve.',
        'Reis unterrühren, kräftig heiß braten, abschmecken und servieren.', 'Incorpore le riz, fais sauter jusqu\'à ce qu\'il soit bien chaud, assaisonne et sers.'),
  ], staples: _basics),

  _Template('pasta', 25, [
    _Slot('pasta', const {_Role.pasta}, grams: 90, fallback: _l('Pasta', 'Pasta', 'Nudeln', 'Pâtes')),
    _Slot('veg', _greens, take: 2, grams: 100, pieces: 0.5, fallback: _l('Vegetables', 'Verduras', 'Gemüse', 'Légumes')),
    const _Slot('protein', _proteins, required: false, grams: 80),
    const _Slot('sauce', {_Role.tomato, _Role.cream}, required: false, grams: 120, ml: 120),
    const _Slot('aromatic', {_Role.aromatic}, required: false, grams: 15, pieces: 0.25),
    const _Slot('cheese', {_Role.cheese}, required: false, grams: 20, pieces: 0.25),
  ], [
    _l('{pasta} with {veg} and {protein}', '{pasta} con {veg} y {protein}', '{pasta} mit {veg} und {protein}',
        '{pasta} aux {veg} et {protein}'),
    _l('{pasta} with {veg}', '{pasta} con {veg}', '{pasta} mit {veg}', '{pasta} aux {veg}'),
  ], [
    _l('Cook {pasta} in well-salted water.', 'Cuece {pasta} en agua con sal.', '{pasta} in Salzwasser kochen.',
        'Cuis {pasta} dans de l\'eau bien salée.'),
    _l('Fry {aromatic} in oil for 2 minutes.', 'Sofríe {aromatic} en aceite 2 minutos.', '{aromatic} 2 Minuten in Öl anbraten.',
        'Fais revenir {aromatic} 2 minutes dans l\'huile.'),
    _l('Add {protein} and cook through.', 'Añade {protein} y cocínalo bien.', '{protein} dazugeben und durchgaren.',
        'Ajoute {protein} et fais cuire à cœur.'),
    _l('Add {veg} and cook for 4–5 minutes.', 'Añade {veg} y cocina 4–5 minutos.', '{veg} dazugeben und 4–5 Minuten garen.',
        'Ajoute {veg} et fais cuire 4–5 minutes.'),
    _l('Stir in {sauce} and simmer for 5 minutes.', 'Incorpora {sauce} y cuece 5 minutos.', '{sauce} unterrühren und 5 Minuten köcheln.',
        'Ajoute {sauce} et laisse mijoter 5 minutes.'),
    _l('Toss with the drained pasta and a splash of the cooking water.', 'Mezcla con la pasta escurrida y un chorrito del agua de cocción.',
        'Mit den abgegossenen Nudeln und etwas Kochwasser vermengen.', 'Mélange avec les pâtes égouttées et un peu d\'eau de cuisson.'),
    _l('Top with {cheese}.', 'Sirve con {cheese} por encima.', 'Mit {cheese} bestreuen.', 'Parsème de {cheese}.'),
  ], staples: _basics),

  _Template('soup', 35, [
    _Slot('veg', _greens, take: 3, grams: 150, pieces: 0.5, fallback: _l('Vegetables', 'Verduras', 'Gemüse', 'Légumes')),
    const _Slot('aromatic', {_Role.aromatic}, required: false, grams: 30, pieces: 0.25),
    const _Slot('potato', {_Role.potato}, required: false, grams: 100, pieces: 1),
    const _Slot('stock', {_Role.stock}, required: false, grams: 250, ml: 250),
    const _Slot('cream', {_Role.cream, _Role.milk}, required: false, grams: 30, ml: 30),
  ], [
    _l('{veg} soup', 'Sopa de {veg}', '{veg}-Suppe', 'Soupe de {veg}'),
  ], [
    _l('Soften {aromatic} in oil for 5 minutes.', 'Pocha {aromatic} en aceite 5 minutos.', '{aromatic} 5 Minuten in Öl andünsten.',
        'Fais suer {aromatic} 5 minutes dans l\'huile.'),
    _l('Add {veg}, chopped, and cook for 5 minutes.', 'Añade {veg} troceado y cocina 5 minutos.', '{veg} klein schneiden, dazugeben und 5 Minuten garen.',
        'Ajoute {veg} coupé et fais cuire 5 minutes.'),
    _l('Add {potato}, diced.', 'Añade {potato} en dados.', '{potato} gewürfelt dazugeben.', 'Ajoute {potato} en dés.'),
    _l('Cover with stock or water and simmer for 20 minutes until soft.', 'Cubre con caldo o agua y cuece 20 minutos hasta que esté tierno.',
        'Mit Brühe oder Wasser bedecken und 20 Minuten weich köcheln.', 'Couvre de bouillon ou d\'eau et laisse mijoter 20 minutes.'),
    _l('Blend until smooth and season to taste.', 'Tritura hasta que quede fina y sazona.', 'Fein pürieren und abschmecken.',
        'Mixe jusqu\'à obtenir un velouté et assaisonne.'),
    _l('Stir in {cream}.', 'Añade {cream}.', '{cream} unterrühren.', 'Ajoute {cream}.'),
  ], staples: _basics, minPantry: 1),

  _Template('traybake', 45, [
    _Slot('veg', _greens, take: 3, grams: 150, pieces: 0.5, fallback: _l('Vegetables', 'Verduras', 'Gemüse', 'Légumes')),
    const _Slot('protein', _proteins, required: false, grams: 150),
    const _Slot('potato', {_Role.potato}, required: false, grams: 150, pieces: 1),
    const _Slot('herb', {_Role.herb}, required: false, grams: 5, pieces: 0.25),
  ], [
    _l('{protein} & {veg} traybake', 'Bandeja de {protein} y {veg} al horno', 'Blech mit {protein} und {veg}',
        'Plaque de {protein} et {veg} rôtis'),
    _l('Roasted {veg}', '{veg} asado', 'Ofengemüse mit {veg}', '{veg} rôti'),
  ], [
    _l('Heat the oven to 200 °C (180 °C fan).', 'Precalienta el horno a 200 °C (180 °C con ventilador).',
        'Backofen auf 200 °C (Umluft 180 °C) vorheizen.', 'Préchauffe le four à 200 °C (180 °C chaleur tournante).'),
    _l('Cut {potato} into chunks and roast for 15 minutes.', 'Corta {potato} en trozos y asa 15 minutos.',
        '{potato} in Stücke schneiden und 15 Minuten rösten.', 'Coupe {potato} en morceaux et fais rôtir 15 minutes.'),
    _l('Add {veg}, cut into chunks, with oil, salt and pepper.', 'Añade {veg} en trozos con aceite, sal y pimienta.',
        '{veg} in Stücken mit Öl, Salz und Pfeffer dazugeben.', 'Ajoute {veg} en morceaux avec huile, sel et poivre.'),
    _l('Nestle {protein} among the vegetables.', 'Coloca {protein} entre las verduras.', '{protein} zwischen das Gemüse legen.',
        'Place {protein} entre les légumes.'),
    _l('Roast for 25–30 minutes until everything is cooked and golden.', 'Asa 25–30 minutos hasta que todo esté hecho y dorado.',
        '25–30 Minuten rösten, bis alles gar und goldbraun ist.', 'Fais rôtir 25–30 minutes jusqu\'à ce que tout soit cuit et doré.'),
    _l('Finish with {herb}.', 'Termina con {herb}.', 'Mit {herb} bestreuen.', 'Termine avec {herb}.'),
  ], staples: _basics),

  _Template('quesadilla', 15, [
    _Slot('tortilla', const {_Role.tortilla}, pieces: 2, natural: Unit.count, fallback: _l('Tortillas', 'Tortillas', 'Tortillas', 'Tortillas')),
    _Slot('cheese', const {_Role.cheese}, grams: 50, pieces: 0.25, fallback: _l('Cheese', 'Queso', 'Käse', 'Fromage')),
    const _Slot('protein', _proteins, required: false, grams: 60),
    const _Slot('veg', _greens, required: false, take: 2, grams: 60, pieces: 0.5),
  ], [
    _l('{protein} & {cheese} quesadillas', 'Quesadillas de {protein} y {cheese}', 'Quesadillas mit {protein} und {cheese}',
        'Quesadillas au {protein} et {cheese}'),
    _l('{veg} & {cheese} quesadillas', 'Quesadillas de {veg} y {cheese}', 'Quesadillas mit {veg} und {cheese}',
        'Quesadillas aux {veg} et {cheese}'),
    _l('{cheese} quesadillas', 'Quesadillas de {cheese}', '{cheese}-Quesadillas', 'Quesadillas au {cheese}'),
  ], [
    _l('Cook {veg} in a little oil for 3 minutes.', 'Cocina {veg} con un poco de aceite 3 minutos.', '{veg} in wenig Öl 3 Minuten braten.',
        'Fais cuire {veg} 3 minutes dans un peu d\'huile.'),
    _l('Heat {protein} through.', 'Calienta bien {protein}.', '{protein} gut erhitzen.', 'Réchauffe bien {protein}.'),
    _l('Cover half of each of {tortilla} with {cheese} and the filling, then fold over.',
        'Cubre media {tortilla} con {cheese} y el relleno y dóblala.', 'Eine Hälfte von {tortilla} mit {cheese} und Füllung belegen und zuklappen.',
        'Garnis une moitié de {tortilla} de {cheese} et de la garniture, puis replie.'),
    _l('Toast in a dry pan for 2–3 minutes per side until the cheese melts.', 'Tuesta en sartén sin aceite 2–3 minutos por lado hasta que se funda el queso.',
        'In einer Pfanne ohne Fett pro Seite 2–3 Minuten rösten, bis der Käse schmilzt.', 'Fais dorer à sec 2–3 minutes par face jusqu\'à ce que le fromage fonde.'),
  ], minPantry: 1),

  _Template('curry', 35, [
    _Slot('veg', _greens, take: 2, grams: 120, pieces: 0.5, fallback: _l('Vegetables', 'Verduras', 'Gemüse', 'Légumes')),
    const _Slot('protein', _proteins, required: false, grams: 120),
    const _Slot('base', {_Role.coconutMilk, _Role.tomato}, required: false, grams: 150, ml: 150),
    const _Slot('rice', {_Role.rice}, required: false, grams: 75),
    const _Slot('aromatic', {_Role.aromatic}, required: false, grams: 30, pieces: 0.25),
    const _Slot('leafy', {_Role.leafy}, required: false, grams: 40),
  ], [
    _l('{protein} & {veg} curry', 'Curry de {protein} y {veg}', 'Curry mit {protein} und {veg}', 'Curry de {protein} et {veg}'),
    _l('{veg} curry', 'Curry de {veg}', '{veg}-Curry', 'Curry de {veg}'),
  ], [
    _l('Cook {rice}.', 'Cuece {rice}.', '{rice} kochen.', 'Cuis {rice}.'),
    _l('Soften {aromatic} in oil, add curry powder or the spices you have, and cook for 1 minute.',
        'Pocha {aromatic} en aceite, añade curry o las especias que tengas y cocina 1 minuto.',
        '{aromatic} in Öl andünsten, Currypulver oder vorhandene Gewürze dazugeben und 1 Minute rösten.',
        'Fais suer {aromatic} dans l\'huile, ajoute du curry ou tes épices et fais cuire 1 minute.'),
    _l('Add {protein} and brown.', 'Añade {protein} y dóralo.', '{protein} dazugeben und anbraten.', 'Ajoute {protein} et fais dorer.'),
    _l('Add {veg} with a splash of water.', 'Añade {veg} con un chorrito de agua.', '{veg} mit einem Schuss Wasser dazugeben.',
        'Ajoute {veg} avec un peu d\'eau.'),
    _l('Pour in {base}.', 'Vierte {base}.', '{base} angießen.', 'Verse {base}.'),
    _l('Simmer for 15–20 minutes until tender.', 'Cuece a fuego lento 15–20 minutos hasta que esté tierno.', '15–20 Minuten köcheln, bis alles weich ist.',
        'Laisse mijoter 15–20 minutes jusqu\'à ce que ce soit tendre.'),
    _l('Stir in {leafy} until wilted.', 'Incorpora {leafy} hasta que se ablande.', '{leafy} unterrühren, bis es zusammenfällt.',
        'Ajoute {leafy} jusqu\'à ce qu\'il tombe.'),
  ], staples: _basics),

  _Template('bowl', 15, [
    _Slot('veg', const {_Role.leafy, _Role.veg}, take: 3, grams: 80, pieces: 0.5, fallback: _l('Salad vegetables', 'Verduras para ensalada', 'Salatgemüse', 'Crudités')),
    const _Slot('grain', {_Role.rice}, required: false, grams: 60),
    const _Slot('protein', {_Role.meat, _Role.fish, _Role.plantProtein, _Role.beans, _Role.egg}, required: false, grams: 80, pieces: 1),
    const _Slot('cheese', {_Role.cheese}, required: false, grams: 30, pieces: 0.25),
  ], [
    _l('{protein} & {veg} bowl', 'Bol de {protein} y {veg}', 'Bowl mit {protein} und {veg}', 'Bol de {protein} et {veg}'),
    _l('{veg} bowl', 'Bol de {veg}', 'Bowl mit {veg}', 'Bol de {veg}'),
  ], [
    _l('Cook {grain} and let it cool a little.', 'Cuece {grain} y deja que se temple.', '{grain} kochen und etwas abkühlen lassen.',
        'Cuis {grain} et laisse tiédir.'),
    _l('Cook or warm {protein}.', 'Cocina o calienta {protein}.', '{protein} garen oder erwärmen.', 'Fais cuire ou réchauffe {protein}.'),
    _l('Chop {veg} and arrange in bowls.', 'Trocea {veg} y repártelo en boles.', '{veg} schneiden und in Schalen anrichten.',
        'Coupe {veg} et répartis dans des bols.'),
    _l('Top with {cheese}.', 'Añade {cheese} por encima.', 'Mit {cheese} toppen.', 'Ajoute {cheese} par-dessus.'),
    _l('Dress with oil, salt, pepper and a squeeze of lemon if you have one.', 'Aliña con aceite, sal, pimienta y un chorrito de limón si tienes.',
        'Mit Öl, Salz, Pfeffer und etwas Zitrone (falls da) anmachen.', 'Assaisonne d\'huile, sel, poivre et d\'un filet de citron si tu en as.'),
  ], staples: _basics),

  _Template('shakshuka', 30, [
    _Slot('egg', const {_Role.egg}, pieces: 2, natural: Unit.count, fallback: _eggs),
    _Slot('tomato', const {_Role.tomato}, grams: 200, ml: 200, pieces: 1, fallback: _l('Chopped tomatoes', 'Tomate triturado', 'Gehackte Tomaten', 'Tomates concassées')),
    const _Slot('veg', {_Role.veg, _Role.aromatic}, required: false, take: 2, grams: 80, pieces: 0.5),
    const _Slot('cheese', {_Role.cheese}, required: false, grams: 25, pieces: 0.25),
    const _Slot('herb', {_Role.herb}, required: false, grams: 5, pieces: 0.25),
  ], [
    _l('Shakshuka with {veg}', 'Shakshuka con {veg}', 'Shakshuka mit {veg}', 'Chakchouka aux {veg}'),
    _l('Shakshuka', 'Shakshuka', 'Shakshuka', 'Chakchouka'),
  ], [
    _l('Soften {veg} in oil for 5 minutes.', 'Pocha {veg} en aceite 5 minutos.', '{veg} 5 Minuten in Öl andünsten.',
        'Fais revenir {veg} 5 minutes dans l\'huile.'),
    _l('Add {tomato} with salt, pepper and any paprika or cumin you have; simmer for 10 minutes.',
        'Añade {tomato} con sal, pimienta y pimentón o comino si tienes; cuece 10 minutos.',
        '{tomato} mit Salz, Pfeffer und etwas Paprika oder Kreuzkümmel dazugeben; 10 Minuten köcheln.',
        'Ajoute {tomato} avec sel, poivre et paprika ou cumin si tu en as ; laisse mijoter 10 minutes.'),
    _l('Make hollows and crack in {egg}; cover and cook for 6–8 minutes.', 'Haz huecos, casca {egg}, tapa y cocina 6–8 minutos.',
        'Mulden formen, {egg} hineinschlagen, zudecken und 6–8 Minuten garen.', 'Creuse des puits, casse {egg}, couvre et fais cuire 6–8 minutes.'),
    _l('Crumble over {cheese}.', 'Desmenuza {cheese} por encima.', '{cheese} darüberbröseln.', 'Émiette {cheese} par-dessus.'),
    _l('Scatter over {herb}.', 'Esparce {herb} por encima.', 'Mit {herb} bestreuen.', 'Parsème de {herb}.'),
  ], staples: _basics),

  _Template('chili', 45, [
    _Slot('protein', const {_Role.beans, _Role.meat, _Role.plantProtein}, grams: 120, fallback: _l('Beans', 'Alubias', 'Bohnen', 'Haricots')),
    _Slot('tomato', const {_Role.tomato}, grams: 200, ml: 200, pieces: 1, fallback: _l('Chopped tomatoes', 'Tomate triturado', 'Gehackte Tomaten', 'Tomates concassées')),
    const _Slot('aromatic', {_Role.aromatic}, required: false, grams: 40, pieces: 0.25),
    const _Slot('veg', _greens, required: false, take: 2, grams: 80, pieces: 0.5),
  ], [
    _l('{protein} chili', 'Chili de {protein}', '{protein}-Chili', 'Chili au {protein}'),
  ], [
    _l('Soften {aromatic} in oil for 5 minutes.', 'Pocha {aromatic} en aceite 5 minutos.', '{aromatic} 5 Minuten in Öl andünsten.',
        'Fais suer {aromatic} 5 minutes dans l\'huile.'),
    _l('Add {protein} and brown or warm through.', 'Añade {protein} y dóralo o caliéntalo.', '{protein} dazugeben und anbraten oder erwärmen.',
        'Ajoute {protein} et fais dorer ou réchauffer.'),
    _l('Add {veg}, chopped.', 'Añade {veg} troceado.', '{veg} gehackt dazugeben.', 'Ajoute {veg} coupé.'),
    _l('Add {tomato}, chilli or paprika if you have it, salt and a splash of water.',
        'Añade {tomato}, guindilla o pimentón si tienes, sal y un chorrito de agua.',
        '{tomato}, Chili oder Paprika (falls da), Salz und einen Schuss Wasser dazugeben.',
        'Ajoute {tomato}, du piment ou du paprika si tu en as, du sel et un peu d\'eau.'),
    _l('Simmer for 25–30 minutes until thick.', 'Cuece 25–30 minutos hasta que espese.', '25–30 Minuten sämig einköcheln.',
        'Laisse mijoter 25–30 minutes jusqu\'à épaississement.'),
  ], staples: _basics, minPantry: 1),

  _Template('smoothie', 5, [
    _Slot('fruit', const {_Role.fruit}, take: 2, grams: 120, pieces: 0.5, fallback: _l('Fruit', 'Fruta', 'Obst', 'Fruits')),
    _Slot('liquid', const {_Role.milk, _Role.yogurt}, grams: 150, ml: 150, fallback: _l('Milk or yogurt', 'Leche o yogur', 'Milch oder Joghurt', 'Lait ou yaourt')),
    const _Slot('oats', {_Role.oats}, required: false, grams: 20),
  ], [
    _l('{fruit} smoothie', 'Batido de {fruit}', '{fruit}-Smoothie', 'Smoothie {fruit}'),
  ], [
    _l('Put {fruit} and {liquid} in a blender.', 'Pon {fruit} y {liquid} en la batidora.', '{fruit} und {liquid} in den Mixer geben.',
        'Mets {fruit} et {liquid} dans le blender.'),
    _l('Add {oats} for a thicker smoothie.', 'Añade {oats} para que quede más espeso.', 'Für mehr Sämigkeit {oats} dazugeben.',
        'Ajoute {oats} pour un smoothie plus épais.'),
    _l('Blend until smooth, adding a little water if it is too thick.', 'Tritura hasta que quede fino; añade un poco de agua si está muy espeso.',
        'Glatt mixen; bei Bedarf etwas Wasser zugeben.', 'Mixe jusqu\'à ce que ce soit lisse ; ajoute un peu d\'eau si c\'est trop épais.'),
  ], minPantry: 1, kind: DishKind.snack),

  _Template('porridge', 10, [
    _Slot('oats', const {_Role.oats}, grams: 50, fallback: _l('Oats', 'Avena', 'Haferflocken', 'Flocons d\'avoine')),
    const _Slot('liquid', {_Role.milk}, required: false, grams: 200, ml: 200),
    const _Slot('fruit', {_Role.fruit}, required: false, take: 2, grams: 60, pieces: 0.5),
    const _Slot('yogurt', {_Role.yogurt}, required: false, grams: 40),
  ], [
    _l('{fruit} porridge', 'Gachas de avena con {fruit}', 'Porridge mit {fruit}', 'Porridge aux {fruit}'),
    _l('Porridge', 'Gachas de avena', 'Porridge', 'Porridge'),
  ], [
    _l('Simmer {oats} with milk or water for 5 minutes, stirring.', 'Cuece {oats} con leche o agua 5 minutos, removiendo.',
        '{oats} mit Milch oder Wasser 5 Minuten unter Rühren köcheln.', 'Fais cuire {oats} avec du lait ou de l\'eau 5 minutes en remuant.'),
    _l('Top with {fruit}.', 'Pon {fruit} por encima.', 'Mit {fruit} toppen.', 'Garnis de {fruit}.'),
    _l('Add a spoonful of {yogurt}.', 'Añade una cucharada de {yogurt}.', 'Einen Löffel {yogurt} daraufgeben.', 'Ajoute une cuillerée de {yogurt}.'),
  ], minPantry: 1, kind: DishKind.breakfast),

  _Template('toastie', 10, [
    _Slot('bread', const {_Role.bread}, pieces: 2, natural: Unit.count, fallback: _l('Bread', 'Pan', 'Brot', 'Pain')),
    const _Slot('cheese', {_Role.cheese}, required: false, grams: 40, pieces: 0.25),
    const _Slot('protein', {_Role.meat, _Role.plantProtein}, required: false, grams: 40),
    const _Slot('veg', {_Role.leafy, _Role.veg}, required: false, grams: 40, pieces: 0.5), // fresh only, not canned
  ], [
    _l('{cheese} & {protein} toastie', 'Sándwich tostado de {cheese} y {protein}', 'Toast mit {cheese} und {protein}',
        'Croque au {cheese} et {protein}'),
    _l('{cheese} & {veg} toastie', 'Sándwich tostado de {cheese} y {veg}', 'Toast mit {cheese} und {veg}', 'Croque au {cheese} et {veg}'),
    _l('{cheese} toastie', 'Sándwich tostado de {cheese}', '{cheese}-Toast', 'Croque au {cheese}'),
    _l('{veg} toastie', 'Sándwich tostado de {veg}', 'Toast mit {veg}', 'Croque aux {veg}'),
  ], [
    _l('Oil or butter the outside of {bread}.', 'Unta el exterior de {bread} con aceite o mantequilla.', '{bread} außen mit Öl oder Butter bestreichen.',
        'Huile ou beurre l\'extérieur de {bread}.'),
    _l('Layer in {cheese}.', 'Pon {cheese}.', '{cheese} darauflegen.', 'Ajoute {cheese}.'),
    _l('Add {protein}.', 'Añade {protein}.', '{protein} dazulegen.', 'Ajoute {protein}.'),
    _l('Add {veg}.', 'Añade {veg}.', '{veg} dazulegen.', 'Ajoute {veg}.'),
    _l('Toast in a pan for about 3 minutes per side, pressing down, until golden.', 'Tuesta en la sartén unos 3 minutos por lado, presionando, hasta que se dore.',
        'In der Pfanne pro Seite etwa 3 Minuten unter Andrücken goldbraun rösten.', 'Fais dorer à la poêle environ 3 minutes par face en appuyant.'),
  ]),

  _Template('bakedpotato', 50, [
    _Slot('potato', const {_Role.potato}, pieces: 1, grams: 250, natural: Unit.count, fallback: _l('Potatoes', 'Patatas', 'Kartoffeln', 'Pommes de terre')),
    const _Slot('cheese', {_Role.cheese}, required: false, grams: 30, pieces: 0.25),
    const _Slot('beans', {_Role.beans}, required: false, grams: 100),
    const _Slot('veg', _greens, required: false, grams: 60, pieces: 0.5),
    const _Slot('cream', {_Role.cream, _Role.yogurt}, required: false, grams: 30),
  ], [
    _l('Baked potatoes with {beans} and {cheese}', 'Patatas asadas con {beans} y {cheese}', 'Ofenkartoffeln mit {beans} und {cheese}',
        'Pommes de terre au four, {beans} et {cheese}'),
    _l('Baked potatoes with {cheese}', 'Patatas asadas con {cheese}', 'Ofenkartoffeln mit {cheese}', 'Pommes de terre au four et {cheese}'),
    _l('Loaded baked potatoes', 'Patatas asadas rellenas', 'Gefüllte Ofenkartoffeln', 'Pommes de terre garnies'),
  ], [
    _l('Prick {potato}, rub with oil and salt, and bake at 200 °C for 50–60 minutes (or microwave for 8–10 minutes, then crisp in the oven).',
        'Pincha {potato}, úntalas con aceite y sal y hornéalas a 200 °C 50–60 minutos (o 8–10 minutos al microondas y luego al horno).',
        '{potato} einstechen, mit Öl und Salz einreiben und bei 200 °C 50–60 Minuten backen (oder 8–10 Minuten Mikrowelle, dann knusprig backen).',
        'Pique {potato}, frotte d\'huile et de sel et cuis à 200 °C 50–60 minutes (ou 8–10 minutes au micro-ondes puis au four).'),
    _l('Warm {beans}.', 'Calienta {beans}.', '{beans} erwärmen.', 'Réchauffe {beans}.'),
    _l('Cook {veg} briefly.', 'Cocina brevemente {veg}.', '{veg} kurz garen.', 'Fais cuire brièvement {veg}.'),
    _l('Split open and top with {cheese}.', 'Ábrelas y pon {cheese} por encima.', 'Aufschneiden und mit {cheese} belegen.', 'Ouvre-les et garnis de {cheese}.'),
    _l('Add a spoonful of {cream}.', 'Añade una cucharada de {cream}.', 'Einen Löffel {cream} daraufgeben.', 'Ajoute une cuillerée de {cream}.'),
  ], staples: [_oil, _salt], minPantry: 1),

  _Template('pancakes', 25, [
    _Slot('flour', const {_Role.flour}, grams: 50, fallback: _l('Flour', 'Harina', 'Mehl', 'Farine')),
    _Slot('milk', const {_Role.milk}, grams: 80, ml: 80, natural: Unit.ml, fallback: _l('Milk', 'Leche', 'Milch', 'Lait')),
    _Slot('egg', const {_Role.egg}, pieces: 0.5, natural: Unit.count, fallback: _eggs),
    const _Slot('fruit', {_Role.fruit}, required: false, take: 2, grams: 60, pieces: 0.5),
  ], [
    _l('Pancakes with {fruit}', 'Tortitas con {fruit}', 'Pfannkuchen mit {fruit}', 'Pancakes aux {fruit}'),
    _l('Pancakes', 'Tortitas', 'Pfannkuchen', 'Pancakes'),
  ], [
    _l('Whisk {flour}, {milk} and {egg} into a smooth batter with a pinch of salt.', 'Bate {flour}, {milk} y {egg} con una pizca de sal hasta obtener una masa fina.',
        '{flour}, {milk} und {egg} mit einer Prise Salz zu einem glatten Teig verrühren.', 'Fouette {flour}, {milk} et {egg} avec une pincée de sel pour une pâte lisse.'),
    _l('Cook spoonfuls in a lightly oiled pan for 1–2 minutes per side.', 'Cocina cucharadas en una sartén con poco aceite, 1–2 minutos por lado.',
        'Löffelweise in einer leicht geölten Pfanne pro Seite 1–2 Minuten backen.', 'Cuis des cuillerées dans une poêle légèrement huilée, 1–2 minutes par face.'),
    _l('Serve with {fruit}.', 'Sirve con {fruit}.', 'Mit {fruit} servieren.', 'Sers avec {fruit}.'),
  ], staples: [_oil, _salt], minPantry: 1, kind: DishKind.breakfast),

  _Template('crumble', 40, [
    _Slot('fruit', const {_Role.fruit}, take: 2, grams: 150, pieces: 0.5, fallback: _l('Fruit', 'Fruta', 'Obst', 'Fruits')),
    _Slot('topping', const {_Role.flour, _Role.oats}, grams: 40, fallback: _l('Flour', 'Harina', 'Mehl', 'Farine')),
    _Slot('butter', const {_Role.butter}, grams: 25, fallback: _l('Butter', 'Mantequilla', 'Butter', 'Beurre')),
  ], [
    _l('{fruit} crumble', 'Crumble de {fruit}', '{fruit}-Crumble', 'Crumble aux {fruit}'),
  ], [
    _l('Heat the oven to 190 °C (170 °C fan).', 'Precalienta el horno a 190 °C (170 °C con ventilador).',
        'Backofen auf 190 °C (Umluft 170 °C) vorheizen.', 'Préchauffe le four à 190 °C (170 °C chaleur tournante).'),
    _l('Slice {fruit} into a baking dish with a little sugar.', 'Corta {fruit} en una fuente con un poco de azúcar.',
        '{fruit} in Scheiben mit etwas Zucker in eine Form geben.', 'Coupe {fruit} dans un plat avec un peu de sucre.'),
    _l('Rub {butter} into {topping} with 2 tablespoons of sugar until crumbly.', 'Mezcla {butter} con {topping} y 2 cucharadas de azúcar hasta que forme migas.',
        '{butter} mit {topping} und 2 EL Zucker zu Streuseln verreiben.', 'Sable {butter} avec {topping} et 2 cuillères de sucre.'),
    _l('Scatter over the fruit and bake for 25–30 minutes until golden.', 'Repártelo sobre la fruta y hornea 25–30 minutos hasta que se dore.',
        'Über das Obst streuen und 25–30 Minuten goldbraun backen.', 'Répartis sur les fruits et cuis 25–30 minutes jusqu\'à ce que ce soit doré.'),
  ], staples: [_sugar], kind: DishKind.dessert),

  _Template('risotto', 35, [
    _Slot('rice', const {_Role.rice}, grams: 80, fallback: _l('Risotto rice', 'Arroz para risotto', 'Risottoreis', 'Riz à risotto')),
    _Slot('veg', _greens, take: 2, grams: 100, pieces: 0.5, fallback: _l('Vegetables', 'Verduras', 'Gemüse', 'Légumes')),
    const _Slot('aromatic', {_Role.aromatic}, required: false, grams: 30, pieces: 0.25),
    const _Slot('stock', {_Role.stock}, required: false, grams: 300, ml: 300),
    const _Slot('cheese', {_Role.cheese}, required: false, grams: 20, pieces: 0.25),
  ], [
    _l('{veg} & {cheese} risotto', 'Risotto de {veg} y {cheese}', '{veg}-Risotto mit {cheese}', 'Risotto aux {veg} et {cheese}'),
    _l('{veg} risotto', 'Risotto de {veg}', '{veg}-Risotto', 'Risotto aux {veg}'),
  ], [
    _l('Soften {aromatic} in oil for 3 minutes.', 'Pocha {aromatic} en aceite 3 minutos.', '{aromatic} 3 Minuten in Öl andünsten.',
        'Fais suer {aromatic} 3 minutes dans l\'huile.'),
    _l('Stir in {rice} for 1 minute.', 'Añade {rice} y remueve 1 minuto.', '{rice} 1 Minute mitrühren.', 'Ajoute {rice} et remue 1 minute.'),
    _l('Add hot stock or water a ladle at a time, stirring, for about 18 minutes until creamy.',
        'Añade caldo o agua caliente cucharón a cucharón, removiendo, unos 18 minutos hasta que esté cremoso.',
        'Heiße Brühe oder Wasser kellenweise unter Rühren zugeben, etwa 18 Minuten, bis es cremig ist.',
        'Ajoute du bouillon ou de l\'eau chaude louche par louche en remuant, environ 18 minutes, jusqu\'à ce que ce soit crémeux.'),
    _l('Stir in {veg} for the last 5 minutes.', 'Incorpora {veg} en los últimos 5 minutos.', '{veg} in den letzten 5 Minuten unterrühren.',
        'Incorpore {veg} pendant les 5 dernières minutes.'),
    _l('Finish with {cheese} and season.', 'Termina con {cheese} y sazona.', 'Mit {cheese} verfeinern und abschmecken.',
        'Termine avec {cheese} et assaisonne.'),
  ], staples: _basics),

  _Template('tacos', 20, [
    _Slot('tortilla', const {_Role.tortilla}, pieces: 2, natural: Unit.count, fallback: _l('Tortillas', 'Tortillas', 'Tortillas', 'Tortillas')),
    _Slot('protein', _proteins, grams: 100, fallback: _l('Beans', 'Alubias', 'Bohnen', 'Haricots')),
    const _Slot('veg', _greens, required: false, take: 2, grams: 60, pieces: 0.5),
    const _Slot('cheese', {_Role.cheese}, required: false, grams: 25, pieces: 0.25),
    const _Slot('cream', {_Role.cream, _Role.yogurt}, required: false, grams: 20),
  ], [
    _l('{protein} tacos', 'Tacos de {protein}', 'Tacos mit {protein}', 'Tacos au {protein}'),
  ], [
    _l('Cook {protein} in oil with salt and any cumin, paprika or chilli you have, 6–8 minutes.',
        'Cocina {protein} en aceite con sal y comino, pimentón o guindilla si tienes, 6–8 minutos.',
        '{protein} in Öl mit Salz und etwas Kreuzkümmel, Paprika oder Chili 6–8 Minuten braten.',
        'Fais cuire {protein} dans l\'huile avec sel et cumin, paprika ou piment si tu en as, 6–8 minutes.'),
    _l('Slice {veg}.', 'Corta {veg}.', '{veg} in Streifen schneiden.', 'Émince {veg}.'),
    _l('Warm {tortilla} in a dry pan.', 'Calienta {tortilla} en una sartén sin aceite.', '{tortilla} in einer Pfanne ohne Fett erwärmen.',
        'Réchauffe {tortilla} dans une poêle sèche.'),
    _l('Fill with everything and top with {cheese}.', 'Rellena con todo y pon {cheese} por encima.', 'Alles einfüllen und mit {cheese} bestreuen.',
        'Garnis avec le tout et ajoute {cheese}.'),
    _l('Add a spoonful of {cream}.', 'Añade una cucharada de {cream}.', 'Einen Löffel {cream} daraufgeben.', 'Ajoute une cuillerée de {cream}.'),
  ], staples: _basics, minPantry: 1),

  _Template('noodlesoup', 20, [
    _Slot('noodles', const {_Role.pasta}, grams: 70, fallback: _l('Noodles', 'Fideos', 'Nudeln', 'Nouilles')),
    _Slot('veg', _greens, take: 2, grams: 80, pieces: 0.5, fallback: _l('Vegetables', 'Verduras', 'Gemüse', 'Légumes')),
    const _Slot('protein', {_Role.meat, _Role.fish, _Role.plantProtein, _Role.egg}, required: false, grams: 80, pieces: 1),
    const _Slot('aromatic', {_Role.aromatic}, required: false, grams: 10, pieces: 0.25),
    const _Slot('stock', {_Role.stock}, required: false, grams: 350, ml: 350),
  ], [
    _l('{protein} noodle soup', 'Sopa de fideos con {protein}', 'Nudelsuppe mit {protein}', 'Soupe de nouilles au {protein}'),
    _l('{veg} noodle soup', 'Sopa de fideos con {veg}', 'Nudelsuppe mit {veg}', 'Soupe de nouilles aux {veg}'),
  ], [
    _l('Fry {aromatic} in a little oil for 1 minute.', 'Sofríe {aromatic} en un poco de aceite 1 minuto.', '{aromatic} in etwas Öl 1 Minute anbraten.',
        'Fais revenir {aromatic} 1 minute dans un peu d\'huile.'),
    _l('Add about 350 ml of stock or water per person and bring to the boil.', 'Añade unos 350 ml de caldo o agua por persona y lleva a ebullición.',
        'Etwa 350 ml Brühe oder Wasser pro Person zugeben und aufkochen.', 'Ajoute environ 350 ml de bouillon ou d\'eau par personne et porte à ébullition.'),
    _l('Add {protein} and simmer until cooked.', 'Añade {protein} y cuece hasta que esté hecho.', '{protein} dazugeben und garziehen lassen.',
        'Ajoute {protein} et laisse frémir jusqu\'à cuisson.'),
    _l('Add {noodles} and {veg}; cook for 4–5 minutes.', 'Añade {noodles} y {veg}; cuece 4–5 minutos.', '{noodles} und {veg} dazugeben, 4–5 Minuten garen.',
        'Ajoute {noodles} et {veg} ; fais cuire 4–5 minutes.'),
    _l('Season with salt or soy sauce and serve.', 'Sazona con sal o salsa de soja y sirve.', 'Mit Salz oder Sojasoße abschmecken und servieren.',
        'Assaisonne de sel ou de sauce soja et sers.'),
  ], staples: _basics),

  _Template('dal', 35, [
    _Slot('lentils', const {_Role.lentils}, grams: 80, fallback: _l('Red lentils', 'Lentejas rojas', 'Rote Linsen', 'Lentilles corail')),
    const _Slot('aromatic', {_Role.aromatic}, required: false, grams: 30, pieces: 0.25),
    const _Slot('base', {_Role.tomato, _Role.coconutMilk}, required: false, grams: 150, ml: 150),
    const _Slot('leafy', {_Role.leafy}, required: false, grams: 40),
    const _Slot('rice', {_Role.rice}, required: false, grams: 75),
  ], [
    _l('{lentils} dal', 'Dal de {lentils}', '{lentils}-Dal', 'Dal de {lentils}'),
  ], [
    _l('Rinse {lentils}.', 'Lava {lentils}.', '{lentils} abspülen.', 'Rince {lentils}.'),
    _l('Soften {aromatic} in oil with curry powder, cumin or turmeric if you have them.',
        'Pocha {aromatic} en aceite con curry, comino o cúrcuma si tienes.',
        '{aromatic} in Öl mit Currypulver, Kreuzkümmel oder Kurkuma (falls da) andünsten.',
        'Fais suer {aromatic} dans l\'huile avec du curry, du cumin ou du curcuma si tu en as.'),
    _l('Add the lentils with three times their volume of water and simmer for 20–25 minutes until soft.',
        'Añade las lentejas con el triple de agua y cuece 20–25 minutos hasta que estén tiernas.',
        'Linsen mit der dreifachen Menge Wasser zugeben und 20–25 Minuten weich köcheln.',
        'Ajoute les lentilles avec trois fois leur volume d\'eau et laisse mijoter 20–25 minutes.'),
    _l('Stir in {base} and simmer for 5 more minutes.', 'Incorpora {base} y cuece 5 minutos más.', '{base} unterrühren und 5 Minuten weiterköcheln.',
        'Ajoute {base} et laisse mijoter encore 5 minutes.'),
    _l('Stir in {leafy} until wilted.', 'Incorpora {leafy} hasta que se ablande.', '{leafy} unterrühren, bis es zusammenfällt.',
        'Ajoute {leafy} jusqu\'à ce qu\'il tombe.'),
    _l('Serve with {rice}.', 'Sirve con {rice}.', 'Mit {rice} servieren.', 'Sers avec {rice}.'),
  ], staples: _basics, minPantry: 1),

  _Template('hash', 30, [
    _Slot('potato', const {_Role.potato}, pieces: 1, grams: 200, natural: Unit.count, fallback: _l('Potatoes', 'Patatas', 'Kartoffeln', 'Pommes de terre')),
    const _Slot('veg', _greens, required: false, take: 2, grams: 80, pieces: 0.5),
    const _Slot('protein', {_Role.meat, _Role.plantProtein, _Role.beans}, required: false, grams: 80),
    const _Slot('egg', {_Role.egg}, required: false, pieces: 1),
    const _Slot('aromatic', {_Role.aromatic}, required: false, grams: 30, pieces: 0.25),
  ], [
    _l('{protein} & potato hash', 'Salteado de patata con {protein}', 'Kartoffelpfanne mit {protein}', 'Poêlée de pommes de terre au {protein}'),
    _l('{veg} & potato hash', 'Salteado de patata con {veg}', 'Kartoffelpfanne mit {veg}', 'Poêlée de pommes de terre aux {veg}'),
    _l('Potato hash', 'Salteado de patata', 'Kartoffelpfanne', 'Poêlée de pommes de terre'),
  ], [
    _l('Dice {potato} and fry in oil for 12–15 minutes, turning, until crisp.', 'Corta {potato} en dados y fríe en aceite 12–15 minutos, dándoles la vuelta, hasta que estén crujientes.',
        '{potato} würfeln und in Öl 12–15 Minuten unter Wenden knusprig braten.', 'Coupe {potato} en dés et fais-les dorer à l\'huile 12–15 minutes en remuant.'),
    _l('Add {aromatic} for the last 5 minutes.', 'Añade {aromatic} en los últimos 5 minutos.', '{aromatic} in den letzten 5 Minuten dazugeben.',
        'Ajoute {aromatic} pendant les 5 dernières minutes.'),
    _l('Add {veg} and cook for 5 minutes.', 'Añade {veg} y cocina 5 minutos.', '{veg} dazugeben und 5 Minuten braten.', 'Ajoute {veg} et fais cuire 5 minutes.'),
    _l('Add {protein} and heat through.', 'Añade {protein} y caliéntalo bien.', '{protein} dazugeben und durchwärmen.', 'Ajoute {protein} et réchauffe bien.'),
    _l('Make hollows and fry {egg} in them until set.', 'Haz huecos y fríe {egg} en ellos hasta que cuajen.', 'Mulden formen und {egg} darin stocken lassen.',
        'Creuse des puits et fais-y cuire {egg}.'),
    _l('Season and serve.', 'Sazona y sirve.', 'Abschmecken und servieren.', 'Assaisonne et sers.'),
  ], staples: _basics, minPantry: 1),

  _Template('pastabake', 40, [
    _Slot('pasta', const {_Role.pasta}, grams: 90, fallback: _l('Pasta', 'Pasta', 'Nudeln', 'Pâtes')),
    _Slot('cheese', const {_Role.cheese}, grams: 40, pieces: 0.25, fallback: _l('Cheese', 'Queso', 'Käse', 'Fromage')),
    const _Slot('veg', _greens, required: false, take: 2, grams: 100, pieces: 0.5),
    const _Slot('sauce', {_Role.tomato, _Role.cream, _Role.milk}, required: false, grams: 150, ml: 150),
    const _Slot('protein', _proteins, required: false, grams: 80),
  ], [
    _l('{veg} & {cheese} pasta bake', 'Pasta al horno con {veg} y {cheese}', 'Nudelauflauf mit {veg} und {cheese}', 'Gratin de pâtes aux {veg} et {cheese}'),
    _l('{cheese} pasta bake', 'Pasta al horno con {cheese}', 'Nudelauflauf mit {cheese}', 'Gratin de pâtes au {cheese}'),
  ], [
    _l('Heat the oven to 200 °C (180 °C fan). Cook {pasta} for 2 minutes less than the pack says.',
        'Precalienta el horno a 200 °C (180 °C con ventilador). Cuece {pasta} 2 minutos menos de lo que indica el paquete.',
        'Backofen auf 200 °C (Umluft 180 °C) vorheizen. {pasta} 2 Minuten kürzer als angegeben kochen.',
        'Préchauffe le four à 200 °C (180 °C chaleur tournante). Cuis {pasta} 2 minutes de moins qu\'indiqué.'),
    _l('Fry {protein} until cooked.', 'Saltea {protein} hasta que esté hecho.', '{protein} durchbraten.', 'Fais cuire {protein}.'),
    _l('Cook {veg} in oil for 5 minutes.', 'Cocina {veg} en aceite 5 minutos.', '{veg} 5 Minuten in Öl garen.', 'Fais cuire {veg} 5 minutes dans l\'huile.'),
    _l('Mix everything with {sauce}.', 'Mezcla todo con {sauce}.', 'Alles mit {sauce} vermengen.', 'Mélange le tout avec {sauce}.'),
    _l('Spread in a dish, cover with {cheese} and bake for 15–20 minutes until bubbling.',
        'Pásalo a una fuente, cubre con {cheese} y hornea 15–20 minutos hasta que burbujee.',
        'In eine Form geben, mit {cheese} bedecken und 15–20 Minuten backen, bis es blubbert.',
        'Verse dans un plat, couvre de {cheese} et enfourne 15–20 minutes jusqu\'à ce que ça bouillonne.'),
  ], staples: _basics),

  _Template('parfait', 5, [
    _Slot('yogurt', const {_Role.yogurt}, grams: 150, fallback: _l('Yogurt', 'Yogur', 'Joghurt', 'Yaourt')),
    const _Slot('fruit', {_Role.fruit}, required: false, take: 2, grams: 80, pieces: 0.5),
    const _Slot('oats', {_Role.oats}, required: false, grams: 30),
  ], [
    _l('{fruit} yogurt pot', 'Vasito de yogur con {fruit}', 'Joghurt mit {fruit}', 'Yaourt aux {fruit}'),
    _l('Yogurt pot', 'Vasito de yogur', 'Joghurtschale', 'Bol de yaourt'),
  ], [
    _l('Spoon {yogurt} into glasses or bowls.', 'Reparte {yogurt} en vasos o boles.', '{yogurt} in Gläser oder Schalen füllen.',
        'Répartis {yogurt} dans des verres ou des bols.'),
    _l('Add {fruit}, chopped.', 'Añade {fruit} troceado.', '{fruit} klein geschnitten dazugeben.', 'Ajoute {fruit} coupé.'),
    _l('Top with {oats}, toasted in a dry pan if you like.', 'Cubre con {oats}, tostada en una sartén si quieres.',
        'Mit {oats} bestreuen, nach Belieben ohne Fett geröstet.', 'Parsème de {oats}, grillés à sec si tu veux.'),
  ], minPantry: 1, kind: DishKind.breakfast),

  _Template('fruitloaf', 70, [
    _Slot('fruit', const {_Role.fruit}, take: 2, grams: 100, pieces: 1, fallback: _l('Ripe bananas', 'Plátanos maduros', 'Reife Bananen', 'Bananes mûres')),
    _Slot('flour', const {_Role.flour}, grams: 60, fallback: _l('Flour', 'Harina', 'Mehl', 'Farine')),
    _Slot('egg', const {_Role.egg}, pieces: 0.5, natural: Unit.count, fallback: _eggs),
    const _Slot('butter', {_Role.butter}, required: false, grams: 25),
  ], [
    _l('{fruit} bread', 'Bizcocho de {fruit}', 'Rührkuchen mit {fruit}', 'Cake aux {fruit}'),
  ], [
    _l('Heat the oven to 180 °C (160 °C fan) and line a loaf tin.', 'Precalienta el horno a 180 °C (160 °C con ventilador) y forra un molde alargado.',
        'Backofen auf 180 °C (Umluft 160 °C) vorheizen und eine Kastenform auslegen.', 'Préchauffe le four à 180 °C (160 °C chaleur tournante) et chemise un moule à cake.'),
    _l('Mash or grate {fruit}.', 'Aplasta o ralla {fruit}.', '{fruit} zerdrücken oder reiben.', 'Écrase ou râpe {fruit}.'),
    _l('Mix with {flour}, {egg}, 3 tablespoons of sugar, a pinch of salt and 3 tablespoons of oil.',
        'Mezcla con {flour}, {egg}, 3 cucharadas de azúcar, una pizca de sal y 3 cucharadas de aceite.',
        'Mit {flour}, {egg}, 3 EL Zucker, einer Prise Salz und 3 EL Öl verrühren.',
        'Mélange avec {flour}, {egg}, 3 cuillères de sucre, une pincée de sel et 3 cuillères d\'huile.'),
    _l('For a richer loaf, use melted {butter} instead of the oil.', 'Para un bizcocho más rico, usa {butter} derretida en lugar del aceite.',
        'Für einen saftigeren Kuchen geschmolzene {butter} statt Öl nehmen.', 'Pour un cake plus riche, utilise {butter} fondu à la place de l\'huile.'),
    _l('Bake for 45–55 minutes until a skewer comes out clean.', 'Hornea 45–55 minutos hasta que un palillo salga limpio.',
        '45–55 Minuten backen, bis an einem Holzstäbchen nichts mehr klebt.', 'Fais cuire 45–55 minutes jusqu\'à ce qu\'une lame ressorte sèche.'),
  ], staples: [_oil, _salt, _sugar], kind: DishKind.dessert),
];
