import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meal_plan.dart';
import '../models/recipe.dart';

/// The user's meal plan, stored on the device. Past days are dropped when it loads.
class MealPlanStore extends ChangeNotifier {
  MealPlanStore({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;
  static const _key = 'meal_plan';
  final DateTime Function() _clock;
  MealPlan plan = const MealPlan();

  DateTime get today => _clock();

  Future<void> load() async {
    final raw = (await SharedPreferences.getInstance()).getString(_key);
    try {
      plan = raw == null ? const MealPlan() : MealPlan.fromJson(jsonDecode(raw)).pruned(today);
    } catch (_) {
      plan = const MealPlan();
    }
    notifyListeners();
  }

  Future<void> _set(MealPlan p) async {
    plan = p;
    notifyListeners();
    await (await SharedPreferences.getInstance()).setString(_key, jsonEncode(p.toJson()));
  }

  Future<void> add(DateTime day, Recipe r) => _set(plan.add(day, r));
  Future<void> addAll(Map<DateTime, Recipe> byDay) {
    var p = plan;
    for (final e in byDay.entries) {
      p = p.add(e.key, e.value);
    }
    return _set(p);
  }

  Future<void> remove(PlannedMeal m) => _set(plan.remove(m));
  Future<void> replace(PlannedMeal m, Recipe r) => _set(plan.replace(m, r));
  Future<void> setCooked(PlannedMeal m, bool cooked) => _set(plan.setCooked(m, cooked));
}
