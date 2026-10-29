import 'dart:math' as math;

/// What PantryPal has learned about which dishes this user likes, from what they do:
///
///   cooked it +3 · saved it +2 · planned it +1 · swapped it out of the plan −1.5 · "not for me" −3
///
/// Scores fade with a half-life of [halfLife], so tastes can change. Recently cooked dishes are
/// remembered for a while, so suggestions don't repeat last night's dinner. "Not for me" also
/// hides that exact recipe for [hideFor]. Immutable: every signal returns a new profile.
/// Stored on the device only.
class TasteProfile {
  const TasteProfile({this.dishes = const {}, this.cooked = const {}, this.hidden = const {}, this.updated});

  /// Dish id → (score, when it was last updated; decay is applied from that moment).
  final Map<String, ({double score, DateTime at})> dishes;

  /// Dish id → when it was last cooked.
  final Map<String, DateTime> cooked;

  /// Normalised recipe title → when "not for me" was tapped.
  final Map<String, DateTime> hidden;
  final DateTime? updated;

  static const halfLife = Duration(days: 30);
  static const hideFor = Duration(days: 30);
  static const maxScore = 12.0;

  static String norm(String title) => title.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  bool get isEmpty => dishes.isEmpty && cooked.isEmpty && hidden.isEmpty;

  /// The dish's score now, faded since it was last updated.
  double score(String dish, DateTime now) {
    final d = dishes[dish];
    if (d == null) return 0;
    final days = now.difference(d.at).inMinutes / Duration.minutesPerDay;
    return d.score * math.pow(0.5, math.max(0, days) / halfLife.inDays);
  }

  /// Days since the dish was last cooked, or null if never (or longer ago than a fortnight).
  int? cookedDaysAgo(String dish, DateTime now) {
    final at = cooked[dish];
    if (at == null) return null;
    final d = DateTime(now.year, now.month, now.day).difference(DateTime(at.year, at.month, at.day)).inDays;
    return d <= 14 ? d : null;
  }

  bool isHidden(String title, DateTime now) {
    final at = hidden[norm(title)];
    return at != null && now.difference(at) < hideFor;
  }

  TasteProfile _bump(String? dish, double by, DateTime now, {bool cookedNow = false}) {
    if (dish == null) return this;
    final next = (score(dish, now) + by).clamp(-maxScore, maxScore).toDouble();
    return TasteProfile(
      dishes: {...dishes, dish: (score: next, at: now)},
      cooked: cookedNow ? {...cooked, dish: now} : cooked,
      hidden: hidden,
      updated: now,
    );
  }

  TasteProfile cookedIt(String? dish, DateTime now) => _bump(dish, 3, now, cookedNow: true);
  TasteProfile savedIt(String? dish, DateTime now) => _bump(dish, 2, now);
  TasteProfile plannedIt(String? dish, DateTime now) => _bump(dish, 1, now);
  TasteProfile swappedAway(String? dish, DateTime now) => _bump(dish, -1.5, now);

  TasteProfile notForMe(String? dish, String title, DateTime now) {
    final p = _bump(dish, -3, now);
    return TasteProfile(dishes: p.dishes, cooked: p.cooked, hidden: {...hidden, norm(title): now}, updated: now);
  }

  /// Takes back a "not for me" (Undo).
  TasteProfile undoNotForMe(String? dish, String title, DateTime now) {
    final p = _bump(dish, 3, now);
    return TasteProfile(dishes: p.dishes, cooked: p.cooked, hidden: {...hidden}..remove(norm(title)), updated: now);
  }

  /// Drops faded scores, old cooking dates and expired hides so the stored profile stays small.
  TasteProfile pruned(DateTime now) => TasteProfile(
        dishes: {
          for (final e in dishes.entries)
            if (score(e.key, now).abs() >= 0.05) e.key: (score: score(e.key, now), at: now),
        },
        cooked: {for (final e in cooked.entries) if (now.difference(e.value).inDays <= 14) e.key: e.value},
        hidden: {for (final e in hidden.entries) if (now.difference(e.value) < hideFor) e.key: e.value},
        updated: updated,
      );

  Map<String, Object?> toJson() => {
        'dishes': {for (final e in dishes.entries) e.key: {'score': e.value.score, 'at': e.value.at.toIso8601String()}},
        'cooked': {for (final e in cooked.entries) e.key: e.value.toIso8601String()},
        'hidden': {for (final e in hidden.entries) e.key: e.value.toIso8601String()},
        if (updated != null) 'updated': updated!.toIso8601String(),
      };

  /// Tolerant: anything malformed is skipped rather than failing.
  factory TasteProfile.fromJson(Object? raw) {
    final m = raw is Map ? raw : const {};
    DateTime? date(Object? v) => v is String ? DateTime.tryParse(v) : null;
    Map<String, DateTime> dates(Object? v) => {
          for (final e in (v is Map ? v : const {}).entries)
            if (e.key is String && date(e.value) != null) e.key as String: date(e.value)!,
        };
    return TasteProfile(
      dishes: {
        for (final e in (m['dishes'] is Map ? m['dishes'] as Map : const {}).entries)
          if (e.key is String && e.value is Map && (e.value as Map)['score'] is num && date((e.value as Map)['at']) != null)
            e.key as String: (
              score: ((e.value as Map)['score'] as num).toDouble().clamp(-maxScore, maxScore).toDouble(),
              at: date((e.value as Map)['at'])!,
            ),
      },
      cooked: dates(m['cooked']),
      hidden: dates(m['hidden']),
      updated: date(m['updated']),
    );
  }
}
