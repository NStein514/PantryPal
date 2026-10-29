import 'dart:math' as math;
import '../models/pantry_item.dart';
import '../models/recipe.dart';

/// Lower-case words with simple English plurals folded ("Tomatoes" → tomato, "berries" → berry).
List<String> _words(String s) => [
      for (final w in s.toLowerCase().split(RegExp(r"[^a-zà-ÿœß]+")))
        if (w.isNotEmpty) _singular(w),
    ];

String _singular(String w) {
  if (w.length > 4 && w.endsWith('ies')) return '${w.substring(0, w.length - 3)}y';
  if (w.length > 4 && w.endsWith('oes')) return w.substring(0, w.length - 2);
  if (w.length > 4 && RegExp(r'(ches|shes|sses|xes)$').hasMatch(w)) return w.substring(0, w.length - 2);
  if (w.length > 3 && w.endsWith('s') && !w.endsWith('ss')) return w.substring(0, w.length - 1);
  return w;
}

/// How well an ingredient name fits a pantry item name: 3 same words, 2 one name's words
/// contain the other's ("milk" ↔ "whole milk"), 0 otherwise. Partial overlaps don't count
/// ("cream cheese" is not "ice cream").
int nameMatchScore(String ingredient, String pantryName) {
  final a = _words(ingredient), b = _words(pantryName);
  if (a.isEmpty || b.isEmpty) return 0;
  if (a.join(' ') == b.join(' ')) return 3;
  final sa = a.toSet(), sb = b.toSet();
  if (sa.containsAll(sb) || sb.containsAll(sa)) return 2;
  return 0;
}

/// The pantry item an ingredient uses, or null. A valid `pantry_id` from the AI wins when its
/// name plausibly fits; otherwise the best name match (ties: soonest to expire, so it's used first).
PantryItem? matchIngredient(RecipeIngredient ing, List<PantryItem> pantry) {
  if (ing.pantryId != null) {
    for (final p in pantry) {
      if (p.id == ing.pantryId && (nameMatchScore(ing.name, p.name) > 0 || _shares(ing.name, p.name))) return p;
    }
  }
  PantryItem? best;
  var bestScore = 0;
  for (final p in pantry) {
    final s = nameMatchScore(ing.name, p.name);
    if (s == 0) continue;
    if (s > bestScore || (s == bestScore && _expiresSooner(p, best!))) {
      best = p;
      bestScore = s;
    }
  }
  return best;
}

// The AI's id is trusted when the names share any real word ("chopped tomatoes" ↔ "Tomatoes").
bool _shares(String a, String b) => _words(a).toSet().intersection(_words(b).where((w) => w.length >= 3).toSet()).isNotEmpty;

bool _expiresSooner(PantryItem a, PantryItem b) =>
    (a.expiry ?? DateTime(9999)).isBefore(b.expiry ?? DateTime(9999));

/// A recipe checked against the real pantry.
class PantryCheck {
  const PantryCheck(this.have, this.missing);

  /// Ingredient → the pantry item it uses.
  final Map<RecipeIngredient, PantryItem> have;
  final List<RecipeIngredient> missing;

  /// Distinct pantry items that are expired or expire within 3 days.
  int get expiringUsed => {for (final p in have.values) if (p.status == ExpiryStatus.soon || p.status == ExpiryStatus.expired) p.id}.length;
}

PantryCheck checkPantry(Recipe recipe, List<PantryItem> pantry) {
  final have = <RecipeIngredient, PantryItem>{};
  final missing = <RecipeIngredient>[];
  for (final ing in recipe.ingredients) {
    if (ing.staple) continue; // basics are assumed at hand
    final p = matchIngredient(ing, pantry);
    if (p == null) {
      missing.add(ing);
    } else {
      have[ing] = p;
    }
  }
  return PantryCheck(have, missing);
}

/// What "I cooked this" proposes to take out of the pantry for one item.
class CookDeduction {
  const CookDeduction({required this.item, required this.amount, required this.known});
  final PantryItem item;

  /// In the item's own unit, never more than it holds.
  final double amount;

  /// False when the recipe's amount couldn't be converted ("2 cups" of a 1 L carton): the
  /// app then leaves it unticked rather than guessing.
  final bool known;

  bool get usesAll => amount >= item.quantity - 1e-9;
}

/// Pantry deductions for cooking [recipe]. Converts units where it can (250 ml from a 1 L
/// carton), rounds counted items up to whole pieces, adds up ingredients that use the same item,
/// and never deducts more than is there.
List<CookDeduction> planDeductions(Recipe recipe, List<PantryItem> pantry) {
  final byItem = <int, ({PantryItem item, double amount, bool known})>{};
  final order = <int>[];
  for (final entry in checkPantry(recipe, pantry).have.entries) {
    final ing = entry.key, item = entry.value;
    if (item.id == null) continue;
    double? need;
    final a = ing.amount;
    if (a != null && ing.unit != null && ing.unit!.canConvertTo(item.unit)) {
      need = ing.unit!.convert(a, item.unit);
    } else if (a != null && ing.unit == null && ing.unitText == null && item.unit.isCount) {
      need = a; // "3 eggs"
    }
    if (need != null && item.unit.isCount) need = math.max(1, need.ceilToDouble());
    final prev = byItem[item.id!];
    if (prev == null) order.add(item.id!);
    final known = need != null && (prev?.known ?? true);
    final total = (prev?.amount ?? 0) + (need ?? 0);
    byItem[item.id!] = (item: item, amount: total, known: known);
  }
  return [
    for (final id in order)
      if (byItem[id] case final d?)
        CookDeduction(
          item: d.item,
          known: d.known,
          // Unknown amounts propose the whole item, but stay unticked until the user confirms.
          amount: d.known ? (math.min(d.amount, d.item.quantity) * 1000).roundToDouble() / 1000 : d.item.quantity,
        ),
  ];
}

/// Whether an ingredient is already on the shopping list (by name, plurals and extra words
/// allowed), so it shows as "on your list" rather than "to buy".
bool isOnList(RecipeIngredient ing, List<String> shoppingList) =>
    shoppingList.any((n) => nameMatchScore(ing.name, n) > 0);
