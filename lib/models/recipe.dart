import 'unit.dart';

/// One ingredient line of a recipe.
class RecipeIngredient {
  const RecipeIngredient({required this.name, this.amount, this.unit, this.unitText, this.pantryId, this.staple = false});

  final String name;

  /// How much the recipe uses, if it says (null: "salt to taste").
  final double? amount;

  /// The amount's unit when PantryPal models it (g, ml, pieces…), so it can be converted.
  final Unit? unit;

  /// The unit as written when it isn't one PantryPal models ("cup", "tbsp"); shown, never converted.
  final String? unitText;

  /// The pantry item the AI said this uses. Only a hint: checked against the real pantry.
  final int? pantryId;

  /// A basic assumed to be at hand (oil, salt, pepper): never "to buy", never deducted.
  final bool staple;

  /// "250 ml", "2 cup", "×3", or '' when no amount is given.
  String get amountLabel {
    final a = amount;
    if (a == null) return '';
    if (unit != null) return formatQuantity(a, unit!);
    if (unitText != null && unitText!.isNotEmpty) return '${formatNumber(a)} $unitText';
    return '×${formatNumber(a)}';
  }

  factory RecipeIngredient.fromJson(Object? raw) {
    if (raw is String) return RecipeIngredient(name: raw.trim());
    final m = raw is Map ? raw : const {};
    final rawUnit = '${m['unit'] ?? ''}'.trim();
    final unit = rawUnit.isEmpty ? null : Unit.tryParse(rawUnit);
    final a = m['amount'];
    final id = m['pantry_id'];
    return RecipeIngredient(
      name: '${m['name'] ?? ''}'.trim(),
      amount: a is num && a > 0 ? a.toDouble() : null,
      unit: unit,
      unitText: unit == null && rawUnit.isNotEmpty ? rawUnit : null,
      pantryId: id is int ? id : (id is num ? id.toInt() : null),
      staple: m['staple'] == true,
    );
  }

  Map<String, Object?> toJson() => {
        'name': name,
        if (amount != null) 'amount': amount,
        if (unit != null) 'unit': unit!.name else if (unitText != null) 'unit': unitText,
        if (pantryId != null) 'pantry_id': pantryId,
        if (staple) 'staple': true,
      };
}

/// A recipe suggestion. Parsing is tolerant: AI output varies, and recipes cached by older
/// versions of the app (title / uses_expiring / missing / minutes / steps) still load.
class Recipe {
  const Recipe({
    required this.title,
    this.summary = '',
    this.minutes,
    this.servings,
    this.ingredients = const [],
    this.steps = const [],
    this.dish,
  });

  /// The engine's dish this was made from ("frittata"), so taste learning can attach to it.
  /// Null for recipes from elsewhere (older saves).
  final String? dish;

  final String title;
  final String summary;
  final int? minutes;
  final int? servings;
  final List<RecipeIngredient> ingredients;
  final List<String> steps;

  /// Stable identity for saving and de-duplicating ("Tomato Pasta" == "tomato pasta").
  String get id => title.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  static int? _int(Object? v) => v is num && v > 0 ? v.round() : null;

  /// Null when the entry has no usable title.
  static Recipe? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final title = '${raw['title'] ?? ''}'.trim();
    if (title.isEmpty) return null;
    final ingredients = <RecipeIngredient>[
      for (final i in raw['ingredients'] is List ? raw['ingredients'] as List : const []) RecipeIngredient.fromJson(i),
      // Older cached recipes listed names only.
      if (raw['ingredients'] is! List) ...[
        for (final n in raw['uses_expiring'] is List ? raw['uses_expiring'] as List : const [])
          if (n is String) RecipeIngredient(name: n),
        for (final n in raw['missing'] is List ? raw['missing'] as List : const [])
          if (n is String) RecipeIngredient(name: n),
      ],
    ]..removeWhere((i) => i.name.isEmpty);
    return Recipe(
      title: title,
      summary: '${raw['summary'] ?? ''}'.trim(),
      minutes: _int(raw['minutes']),
      servings: _int(raw['servings']),
      ingredients: ingredients,
      steps: [
        for (final s in raw['steps'] is List ? raw['steps'] as List : const [])
          if ('$s'.trim().isNotEmpty) '$s'.trim(),
      ],
      dish: raw['dish'] is String ? raw['dish'] as String : null,
    );
  }

  /// Parses a list, dropping malformed entries and repeated titles.
  static List<Recipe> parseList(Object? raw) {
    final seen = <String>{};
    return [
      for (final r in raw is List ? raw : const [])
        if (fromJson(r) case final recipe? when seen.add(recipe.id)) recipe,
    ];
  }

  Map<String, Object?> toJson() => {
        'title': title,
        if (summary.isNotEmpty) 'summary': summary,
        if (minutes != null) 'minutes': minutes,
        if (servings != null) 'servings': servings,
        'ingredients': [for (final i in ingredients) i.toJson()],
        'steps': steps,
        if (dish != null) 'dish': dish,
      };
}
