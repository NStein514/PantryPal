import 'dart:math' as math;
import '../models/pantry_item.dart';
import '../models/recipe.dart';
import '../models/unit.dart';
import 'recipe_planner.dart';

/// Something to buy for the planned meals.
class ShoppingNeed {
  ShoppingNeed({required this.name, this.amount, this.unit, this.unitText, required this.recipes});
  final String name;

  /// How much is missing; null when a recipe doesn't say ("basil").
  double? amount;
  Unit? unit;
  String? unitText;
  final List<String> recipes; // titles, for "for: …"

  /// "Milk 500 ml", "Eggs ×3", "Flour 2 cups", "Basil" — written so that the shopping list's
  /// move-to-pantry (parseQuickList) reads the amount back.
  String get label {
    final a = amount;
    if (a == null) return name;
    if (unit != null) return unit!.isCount ? '$name ${formatNumber(a)}' : '$name ${formatQuantity(a, unit!)}';
    if (unitText != null) return '$name ${formatNumber(a)} $unitText';
    return '$name ${formatNumber(a)}';
  }
}

/// Basics the recipe AI is told to assume are at hand.
const _staples = {'salt', 'pepper', 'black pepper', 'water', 'salt and pepper'};

/// The combined shopping list for [recipes] (in the order they'll be cooked).
///
/// Pantry stock is *reserved* as it is used: with 1 L of milk and three recipes needing 500 ml
/// each, the third is short 500 ml. Amounts convert into the pantry item's unit; counted items
/// round up to whole pieces. A pantry item with an unknown recipe amount counts as enough.
/// Missing ingredients of the same name add up across recipes when their units allow.
List<ShoppingNeed> shoppingForPlan(List<Recipe> recipes, List<PantryItem> pantry) {
  final left = {for (final p in pantry) if (p.id != null) p.id!: p.quantity};
  final needs = <String, ShoppingNeed>{};

  void need(String name, double? amount, Unit? unit, String? unitText, String recipe) {
    final dim = unit?.dimension.name ?? (unitText != null ? 'text:${unitText.toLowerCase()}' : 'none');
    final key = '${name.trim().toLowerCase()}|${amount == null ? 'any' : dim}';
    final existing = needs[key];
    if (existing == null) {
      needs[key] = ShoppingNeed(name: name.trim(), amount: amount, unit: unit, unitText: unitText, recipes: [recipe]);
      return;
    }
    if (!existing.recipes.contains(recipe)) existing.recipes.add(recipe);
    if (amount == null || existing.amount == null) return;
    final add = (unit != null && existing.unit != null) ? unit.convert(amount, existing.unit!) : amount;
    existing.amount = ((existing.amount! + add) * 1000).roundToDouble() / 1000;
  }

  for (final r in recipes) {
    for (final ing in r.ingredients) {
      if (ing.staple || _staples.contains(ing.name.trim().toLowerCase())) continue;
      final item = matchIngredient(ing, pantry);
      if (item == null || item.id == null) {
        need(ing.name, ing.amount, ing.unit, ing.unitText, r.title);
        continue;
      }
      double? want;
      final a = ing.amount;
      if (a != null && ing.unit != null && ing.unit!.canConvertTo(item.unit)) {
        want = ing.unit!.convert(a, item.unit);
      } else if (a != null && ing.unit == null && ing.unitText == null && item.unit.isCount) {
        want = a;
      }
      if (want == null) continue; // amount unclear: what's in the pantry is assumed enough
      if (item.unit.isCount) want = math.max(1, want.ceilToDouble());
      final have = left[item.id!] ?? 0;
      if (have >= want - 1e-9) {
        left[item.id!] = have - want;
      } else {
        left[item.id!] = 0;
        var short = want - have;
        if (item.unit.isCount) short = short.ceilToDouble();
        need(item.name, (short * 1000).roundToDouble() / 1000, item.unit, null, r.title);
      }
    }
  }
  return needs.values.toList();
}
