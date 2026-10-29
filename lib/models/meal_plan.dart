import 'recipe.dart';

/// A recipe planned for a day.
class PlannedMeal {
  const PlannedMeal({required this.day, required this.recipe, this.cooked = false});

  /// Local calendar day, "yyyy-MM-dd".
  final String day;
  final Recipe recipe;
  final bool cooked;

  String get id => '$day|${recipe.id}';

  PlannedMeal copyWith({bool? cooked, Recipe? recipe}) =>
      PlannedMeal(day: day, recipe: recipe ?? this.recipe, cooked: cooked ?? this.cooked);

  Map<String, Object?> toJson() => {'day': day, 'recipe': recipe.toJson(), if (cooked) 'cooked': true};

  static PlannedMeal? fromJson(Object? raw) {
    if (raw is! Map || raw['day'] is! String || !MealPlan.isDayKey(raw['day'] as String)) return null;
    final r = Recipe.fromJson(raw['recipe']);
    return r == null ? null : PlannedMeal(day: raw['day'] as String, recipe: r, cooked: raw['cooked'] == true);
  }
}

/// The meal plan: immutable; every change returns a new plan.
class MealPlan {
  const MealPlan([this.meals = const []]);
  final List<PlannedMeal> meals;

  static String dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  static bool isDayKey(String s) => RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s) && DateTime.tryParse(s) != null;
  static DateTime parseDay(String key) => DateTime.parse(key);

  /// Today and the following days, as local midnights (calendar arithmetic, DST-safe).
  static List<DateTime> nextDays(DateTime today, int count) =>
      [for (var i = 0; i < count; i++) DateTime(today.year, today.month, today.day + i)];

  List<PlannedMeal> on(DateTime day) => [for (final m in meals) if (m.day == dayKey(day)) m];

  /// Adds [recipe] on [day]; the same recipe twice on one day is ignored.
  MealPlan add(DateTime day, Recipe recipe) {
    final key = dayKey(day);
    if (meals.any((m) => m.day == key && m.recipe.id == recipe.id)) return this;
    return MealPlan([...meals, PlannedMeal(day: key, recipe: recipe)]..sort((a, b) => a.day.compareTo(b.day)));
  }

  MealPlan remove(PlannedMeal meal) => MealPlan([for (final m in meals) if (m.id != meal.id) m]);

  MealPlan replace(PlannedMeal meal, Recipe recipe) =>
      MealPlan([for (final m in meals) m.id == meal.id ? PlannedMeal(day: m.day, recipe: recipe) : m]);

  MealPlan setCooked(PlannedMeal meal, bool cooked) =>
      MealPlan([for (final m in meals) m.id == meal.id ? m.copyWith(cooked: cooked) : m]);

  /// Drops days before [today]: the plan looks forward.
  MealPlan pruned(DateTime today) {
    final key = dayKey(today);
    return MealPlan([for (final m in meals) if (m.day.compareTo(key) >= 0) m]);
  }

  /// Meals from [today] on that haven't been cooked, in day order (what to shop for).
  List<PlannedMeal> upcoming(DateTime today) {
    final key = dayKey(today);
    return [for (final m in meals) if (!m.cooked && m.day.compareTo(key) >= 0) m];
  }

  /// Days in the next [count] (from [today]) with nothing planned.
  List<DateTime> emptyDays(DateTime today, int count) =>
      [for (final d in nextDays(today, count)) if (on(d).isEmpty) d];

  List<Map<String, Object?>> toJson() => [for (final m in meals) m.toJson()];

  factory MealPlan.fromJson(Object? raw) => MealPlan([
        for (final e in raw is List ? raw : const [])
          if (PlannedMeal.fromJson(e) case final m?) m,
      ]..sort((a, b) => a.day.compareTo(b.day)));
}
