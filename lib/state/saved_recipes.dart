import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recipe.dart';

/// Recipes the user bookmarked, newest first. Stored on the device.
class SavedRecipes extends ChangeNotifier {
  static const _key = 'saved_recipes';
  List<Recipe> recipes = [];

  bool isSaved(Recipe r) => recipes.any((x) => x.id == r.id);

  Future<void> load() async {
    final raw = (await SharedPreferences.getInstance()).getString(_key);
    try {
      recipes = raw == null ? [] : Recipe.parseList(jsonDecode(raw));
    } catch (_) {
      recipes = [];
    }
    notifyListeners();
  }

  Future<void> toggle(Recipe r) async {
    recipes = isSaved(r) ? [for (final x in recipes) if (x.id != r.id) x] : [r, ...recipes];
    await (await SharedPreferences.getInstance()).setString(_key, jsonEncode([for (final x in recipes) x.toJson()]));
    notifyListeners();
  }
}
