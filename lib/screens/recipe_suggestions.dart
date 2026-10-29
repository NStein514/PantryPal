import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../models/recipe_preferences.dart';
import '../services/recipe_engine.dart';
import '../state/pantry_store.dart';
import '../models/taste_profile.dart';
import '../state/saved_recipes.dart';
import '../state/shopping_store.dart';
import '../state/taste_store.dart';

/// Recipe ideas from what the user has: the pantry first, then unchecked shopping-list items
/// ("coming soon"), in the app's language. Instant and offline (see RecipeEngine).
List<Recipe> suggestRecipes(
  BuildContext context, {
  RecipePreferences prefs = const RecipePreferences(),
  Set<int> focusIds = const {},
  List<String> avoidTitles = const [],
  int count = 3,
  bool forPlan = false,
}) =>
    const RecipeEngine().suggest(
      context.read<PantryStore>().items,
      shoppingList: shoppingNames(context),
      prefs: prefs,
      focusIds: focusIds,
      avoidTitles: avoidTitles,
      count: count,
      // A plan is dinners that will all be cooked: mains only, and stock is spent day by day.
      mainsOnly: forPlan,
      forPlan: forPlan,
      language: Localizations.localeOf(context).languageCode,
      taste: context.read<TasteStore?>()?.profile ?? const TasteProfile(),
    );

/// Names on the shopping list that haven't been bought yet.
List<String> shoppingNames(BuildContext context) =>
    [for (final i in context.read<ShoppingStore?>()?.items ?? const []) if (!i.checked) i.name];

/// Saves or unsaves [r]; saving teaches the engine the user likes this dish.
Future<void> toggleSaved(BuildContext context, Recipe r) async {
  final saved = context.read<SavedRecipes>();
  final taste = context.read<TasteStore?>();
  final wasSaved = saved.isSaved(r);
  await saved.toggle(r);
  if (!wasSaved) await taste?.saved(r);
}
