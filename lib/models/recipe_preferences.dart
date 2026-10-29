/// Dietary styles the recipe AI is asked to respect.
enum Diet { vegetarian, vegan, glutenFree, dairyFree }

/// What the user wants from recipe suggestions. Persisted by SettingsRepo.
class RecipePreferences {
  const RecipePreferences({this.diets = const {}, this.servings = 2, this.maxMinutes, this.avoid = ''});

  final Set<Diet> diets;
  final int servings;

  /// Upper bound on total time; null means any.
  final int? maxMinutes;

  /// Free text: foods to leave out ("mushrooms, peanuts").
  final String avoid;

  static const maxServings = 12;
  static const timeChoices = [15, 30, 45, 60];

  RecipePreferences copyWith({Set<Diet>? diets, int? servings, int? maxMinutes, bool clearMaxMinutes = false, String? avoid}) =>
      RecipePreferences(
        diets: diets ?? this.diets,
        servings: (servings ?? this.servings).clamp(1, maxServings),
        maxMinutes: clearMaxMinutes ? null : maxMinutes ?? this.maxMinutes,
        avoid: avoid ?? this.avoid,
      );

  /// Constraints for the AI prompt, in English (the AI is told separately which language to write in).
  List<String> promptRules() {
    const names = {
      Diet.vegetarian: 'vegetarian (no meat or fish)',
      Diet.vegan: 'vegan (no animal products at all)',
      Diet.glutenFree: 'gluten-free',
      Diet.dairyFree: 'dairy-free',
    };
    return [
      'Each recipe serves $servings; scale ingredient amounts for that.',
      if (diets.isNotEmpty) 'Every recipe must be ${[for (final d in Diet.values) if (diets.contains(d)) names[d]].join(', ')}; never use pantry items that break this.',
      if (maxMinutes != null) 'Total time (prep + cooking) at most $maxMinutes minutes.',
      if (avoid.trim().isNotEmpty) 'Never use these: ${avoid.trim()}.',
    ];
  }

  Map<String, Object?> toJson() => {
        'diets': [for (final d in diets) d.name],
        'servings': servings,
        if (maxMinutes != null) 'max_minutes': maxMinutes,
        if (avoid.isNotEmpty) 'avoid': avoid,
      };

  factory RecipePreferences.fromJson(Object? raw) {
    final m = raw is Map ? raw : const {};
    final s = m['servings'];
    final t = m['max_minutes'];
    return RecipePreferences(
      diets: {
        for (final n in m['diets'] is List ? m['diets'] as List : const [])
          for (final d in Diet.values)
            if (d.name == n) d,
      },
      servings: s is int ? s.clamp(1, maxServings) : 2,
      maxMinutes: t is int && t > 0 ? t : null,
      avoid: m['avoid'] is String ? (m['avoid'] as String).trim() : '',
    );
  }
}
