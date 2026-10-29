import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/settings_repo.dart';
import '../l10n/l10n.dart';
import '../models/pantry_item.dart';
import '../models/recipe.dart';
import '../models/recipe_preferences.dart';
import '../services/recipe_planner.dart';
import '../state/meal_plan_store.dart';
import '../state/pantry_store.dart';
import '../state/saved_recipes.dart';
import '../state/taste_store.dart';
import '../ui/layout.dart';
import '../ui/motion.dart';
import 'meal_plan_view.dart';
import 'recipe_detail_screen.dart';
import 'recipe_preferences_sheet.dart';
import 'recipe_suggestions.dart';

/// "Use it up": AI recipe ideas from the pantry (offline: the last ideas), plus saved recipes.
class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});
  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  RecipePreferences _prefs = const RecipePreferences();
  final Set<int> _focus = {};
  List<Recipe> _ideas = const [];
  bool _started = false;
  bool _exhausted = false; // "More ideas" found nothing new
  int? _ideasForCount; // pantry size the ideas were made for; re-suggest when it changes from empty
  int _tab = 0; // 0 ideas, 1 plan, 2 saved

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    _prefs = await SettingsRepo().loadRecipePreferences();
    if (!mounted) return;
    _started = true;
    _generate();
  }

  /// Fresh ideas; with [more], adds ideas that differ from the ones shown. Instant and offline.
  void _generate({bool more = false}) {
    final got = suggestRecipes(context,
        prefs: _prefs, focusIds: _focus, avoidTitles: more ? [for (final r in _ideas) r.title] : const []);
    setState(() {
      _ideas = more ? [..._ideas, ...got] : got;
      _exhausted = more && got.isEmpty;
      _ideasForCount = context.read<PantryStore>().items.length;
    });
  }

  /// Removes the idea, teaches the engine, and offers Undo.
  void _notForMe(Recipe r) {
    final l = context.l10n;
    final taste = context.read<TasteStore?>();
    final at = _ideas.indexOf(r);
    setState(() => _ideas = [for (final x in _ideas) if (x.id != r.id) x]);
    taste?.notForMe(r);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(l.fewerLikeThis),
        action: SnackBarAction(
          label: l.undo,
          onPressed: () {
            taste?.undoNotForMe(r);
            if (mounted) setState(() => _ideas = [..._ideas]..insert(at.clamp(0, _ideas.length), r));
          },
        ),
      ));
  }

  Future<void> _editPreferences() async {
    final p = await showRecipePreferencesSheet(context, _prefs);
    if (p == null || !mounted) return;
    await SettingsRepo().saveRecipePreferences(p);
    setState(() => _prefs = p);
    _generate();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final pantry = context.watch<PantryStore>().items;
    final saved = context.watch<SavedRecipes?>();
    final plan = context.watch<MealPlanStore?>();
    return Scaffold(
      appBar: AppBar(title: Text(l.useItUp), actions: [
        IconButton(tooltip: l.recipePrefsTitle, icon: const Icon(Icons.tune), onPressed: _editPreferences),
        if (_tab == 0 && pantry.isNotEmpty)
          IconButton(
              tooltip: l.newIdeas, icon: const Icon(Icons.refresh), onPressed: () => _generate()),
      ]),
      body: Column(children: [
        if (saved != null || plan != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: 0, icon: const Icon(Icons.lightbulb_outline), label: Text(l.recipesIdeas)),
                if (plan != null)
                  ButtonSegment(value: 1, icon: const Icon(Icons.calendar_month_outlined), label: Text(l.recipesPlan)),
                if (saved != null)
                  ButtonSegment(
                      value: 2,
                      icon: const Icon(Icons.bookmark_outline),
                      label: Text('${l.recipesSaved} (${saved.recipes.length})')),
              ],
              selected: {_tab},
              onSelectionChanged: (s) => setState(() => _tab = s.first),
            ),
          ),
        // Ideas / Plan / Saved fade through one another (Material's pattern for sibling views).
        Expanded(
          child: PageTransitionSwitcher(
            duration: Motion.of(context, Motion.medium),
            transitionBuilder: (child, primary, secondary) => FadeThroughTransition(
              animation: primary,
              secondaryAnimation: secondary,
              fillColor: Colors.transparent,
              child: child,
            ),
            child: KeyedSubtree(
              key: ValueKey(_tab),
              child: switch (_tab) {
                1 when plan != null => const MealPlanView(),
                2 when saved != null => _savedList(l, saved, pantry),
                _ => _ideasList(l, pantry),
              },
            ),
          ),
        ),
      ]),
    );
  }

  Widget _savedList(AppLocalizations l, SavedRecipes saved, List<PantryItem> pantry) => saved.recipes.isEmpty
      ? _message(l.recipesNoSaved)
      : ListView(padding: const EdgeInsets.only(bottom: 24), children: [
          AdaptiveColumns(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [for (final r in saved.recipes) _RecipeCard(recipe: r, pantry: pantry)],
          ),
        ]);

  Widget _message(String text) =>
      Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(text, textAlign: TextAlign.center)));

  Widget _ideasList(AppLocalizations l, List<PantryItem> pantry) {
    if (pantry.isEmpty) return _message(l.recipesEmpty);
    if (!_started) return const Center(child: CircularProgressIndicator());
    // First items added since the screen opened: suggest straight away.
    // (Only when the pantry changed since the last try, so an empty result can't loop.)
    if (_ideas.isEmpty && pantry.length != _ideasForCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? _generate() : null);
    }
    // Items worth building around: expiring first, then the rest, at most 10.
    final candidates = [
      ...pantry.where((i) => i.status == ExpiryStatus.expired || i.status == ExpiryStatus.soon),
      ...pantry.where((i) => i.status == ExpiryStatus.fresh || i.status == ExpiryStatus.undated),
    ].where((i) => i.id != null).take(10).toList();
    return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Text(l.recipesBuildAround, style: Theme.of(context).textTheme.labelLarge),
      ),
      SizedBox(
        height: 52,
        child:
            ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: [
          for (final i in candidates)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: FilterChip(
                label: Text(i.name),
                selected: _focus.contains(i.id),
                onSelected: (on) => setState(() => on ? _focus.add(i.id!) : _focus.remove(i.id)),
              ),
            ),
        ]),
      ),
      if (_focus.isNotEmpty)
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextButton.icon(
              onPressed: () => _generate(),
              icon: const Icon(Icons.auto_awesome),
              label: Text(l.newIdeas),
            ),
          ),
        ),
      AdaptiveColumns(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          // New ideas ease in, a little staggered; keyed by recipe so existing ones don't replay.
          for (final (i, r) in _ideas.indexed)
            FadeSlideIn(
                key: ValueKey(r.id), index: i % 3, child: _RecipeCard(recipe: r, pantry: pantry, onNotForMe: () => _notForMe(r))),
        ],
      ),
      if (_ideas.isEmpty)
        Padding(padding: const EdgeInsets.all(32), child: Text(l.recipesNoMatch, textAlign: TextAlign.center))
      else
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: _exhausted
              ? Text(l.recipesNoMore, textAlign: TextAlign.center)
              : OutlinedButton.icon(
                  onPressed: () => _generate(more: true),
                  icon: const Icon(Icons.add),
                  label: Text(l.recipesMore),
                ),
        ),
    ]);
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.recipe, required this.pantry, this.onNotForMe});

  /// Ideas only: "not for me" (saved recipes were chosen by the user).
  final VoidCallback? onNotForMe;
  final Recipe recipe;
  final List<PantryItem> pantry;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final check = checkPantry(recipe, pantry);
    final saved = context.watch<SavedRecipes?>();
    final scheme = Theme.of(context).colorScheme;
    // The card grows into the recipe screen (Material container transform).
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: OpenContainer<void>(
        transitionDuration: Motion.of(context, Motion.long),
        transitionType: ContainerTransitionType.fadeThrough,
        closedElevation: 0,
        openElevation: 0,
        closedColor: scheme.surfaceContainerLow,
        openColor: scheme.surface,
        middleColor: scheme.surface,
        closedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tappable: false,
        openBuilder: (context, _) => RecipeDetailScreen(recipe: recipe),
        closedBuilder: (context, open) => InkWell(
          onTap: open,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(recipe.title, style: Theme.of(context).textTheme.titleMedium),
                  if (recipe.summary.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(recipe.summary, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                  const SizedBox(height: 8),
                  Wrap(spacing: 12, runSpacing: 4, children: [
                    if (recipe.minutes != null) _Meta(Icons.timer_outlined, l.recipeMinutes(recipe.minutes!)),
                    if (recipe.servings != null) _Meta(Icons.people_outline, l.recipeServings(recipe.servings!)),
                    if (check.expiringUsed > 0)
                      _Meta(Icons.eco_outlined, l.recipeUsesExpiring(check.expiringUsed), color: scheme.primary),
                    _Meta(Icons.shopping_cart_outlined,
                      l.recipeToBuyCount([for (final i in check.missing) if (!isOnList(i, shoppingNames(context))) i].length)),
                  ]),
                ]),
              ),
              Column(mainAxisSize: MainAxisSize.min, children: [
                if (saved != null)
                  IconButton(
                    tooltip: saved.isSaved(recipe) ? l.unsaveRecipe : l.saveRecipe,
                    icon: Icon(saved.isSaved(recipe) ? Icons.bookmark : Icons.bookmark_outline),
                    onPressed: () => toggleSaved(context, recipe),
                  ),
                if (onNotForMe != null)
                  IconButton(
                    tooltip: l.notForMe,
                    icon: const Icon(Icons.thumb_down_alt_outlined, size: 20),
                    onPressed: onNotForMe,
                  ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.text, {this.color});
  final IconData icon;
  final String text;
  final Color? color;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color)),
      ]);
}
