import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../data/settings_repo.dart';
import '../l10n/l10n.dart';
import '../models/meal_plan.dart';
import '../models/recipe.dart';
import '../services/meal_shopping.dart';
import '../services/recipe_planner.dart';
import '../state/meal_plan_store.dart';
import '../state/pantry_store.dart';
import '../state/shopping_store.dart';
import '../state/taste_store.dart';
import '../ui/layout.dart';
import '../ui/motion.dart';
import 'recipe_detail_screen.dart';
import 'recipe_suggestions.dart';

const planDays = 7;

/// "Today", "Tomorrow", or "Fri, Oct 30" in the app's locale.
String planDayLabel(AppLocalizations l, DateTime day, DateTime today) {
  final d = DateTime(day.year, day.month, day.day), t = DateTime(today.year, today.month, today.day);
  if (d == t) return l.planToday;
  if (d == DateTime(t.year, t.month, t.day + 1)) return l.planTomorrow;
  return DateFormat.MMMEd().format(d);
}

/// Next 7 days of planned meals, AI "plan my week", and the week's combined shopping list.
class MealPlanView extends StatefulWidget {
  const MealPlanView({super.key});
  @override
  State<MealPlanView> createState() => _MealPlanViewState();
}

class _MealPlanViewState extends State<MealPlanView> {

  Future<void> _planWeek() async {
    final l = context.l10n;
    final store = context.read<MealPlanStore>();
    final messenger = ScaffoldMessenger.of(context);
    if (context.read<PantryStore>().items.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l.recipesEmpty)));
      return;
    }
    final days = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (s) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: const EdgeInsets.all(16), child: Text(l.planHowManyDays, style: Theme.of(s).textTheme.titleMedium)),
          for (final n in const [3, 5, 7]) ListTile(title: Text(l.dayCount(n)), onTap: () => Navigator.pop(s, n)),
        ]),
      ),
    );
    if (days == null || !mounted) return;
    final empty = store.plan.emptyDays(store.today, days);
    if (empty.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l.planFull)));
      return;
    }
    final prefs = await SettingsRepo().loadRecipePreferences();
    if (!mounted) return;
    // Dinners in cooking order: the engine ranks food that expires soonest first and spreads
    // ingredients across the days.
    final recipes = suggestRecipes(context,
        prefs: prefs, count: empty.length, forPlan: true, avoidTitles: [for (final m in store.plan.meals) m.recipe.title]);
    if (recipes.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l.recipesNoMatch)));
      return;
    }
    await store.addAll({for (var i = 0; i < empty.length && i < recipes.length; i++) empty[i]: recipes[i]});
  }

  Future<void> _swap(PlannedMeal meal) async {
    final l = context.l10n;
    final store = context.read<MealPlanStore>();
    final messenger = ScaffoldMessenger.of(context);
    final prefs = await SettingsRepo().loadRecipePreferences();
    if (!mounted) return;
    final got = suggestRecipes(context,
        prefs: prefs, count: 1, forPlan: true, avoidTitles: [for (final m in store.plan.meals) m.recipe.title]);
    if (got.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l.recipesNoMore)));
      return;
    }
    await context.read<TasteStore?>()?.swappedAway(meal.recipe);
    await store.replace(meal, got.first);
  }

  Future<void> _weekShopping() async {
    final store = context.read<MealPlanStore>();
    final needs = shoppingForPlan(
      [for (final m in store.plan.upcoming(store.today)) m.recipe],
      context.read<PantryStore>().items,
    );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => WeekShoppingSheet(needs: needs),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final store = context.watch<MealPlanStore>();
    final pantry = context.watch<PantryStore>().items;
    final today = store.today;
    return ReadableWidth(
      maxWidth: 840,
      child: ListView(padding: const EdgeInsets.only(bottom: 24), children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(l.planIntro, style: Theme.of(context).textTheme.bodySmall),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton.tonalIcon(
                onPressed: _planWeek, icon: const Icon(Icons.auto_awesome), label: Text(l.planMyWeek)),
            OutlinedButton.icon(
              onPressed: store.plan.upcoming(today).isEmpty ? null : _weekShopping,
              icon: const Icon(Icons.shopping_cart_outlined),
              label: Text(l.weekShopping),
            ),
          ]),
        ),
        for (final day in MealPlan.nextDays(today, planDays)) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(planDayLabel(l, day, today), style: Theme.of(context).textTheme.titleSmall),
          ),
          if (store.plan.on(day).isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(l.planNothing, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
          for (final meal in store.plan.on(day))
            _MealTile(
                meal: meal,
                pantryCount: [
              for (final i in checkPantry(meal.recipe, pantry).missing)
                if (!isOnList(i, shoppingNames(context))) i
            ].length,
                onSwap: () => _swap(meal)),
        ],
      ]),
    );
  }
}

class _MealTile extends StatelessWidget {
  const _MealTile({required this.meal, required this.pantryCount, required this.onSwap});
  final PlannedMeal meal;
  final int pantryCount;
  final VoidCallback? onSwap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final store = context.read<MealPlanStore>();
    final r = meal.recipe;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: OpenContainer<void>(
        transitionDuration: Motion.of(context, Motion.long),
        transitionType: ContainerTransitionType.fadeThrough,
        closedElevation: 0,
        openElevation: 0,
        closedColor: scheme.surfaceContainerLow,
        openColor: scheme.surface,
        middleColor: scheme.surface,
        closedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tappable: false,
        openBuilder: (context, _) => RecipeDetailScreen(recipe: r, plannedMeal: meal),
        closedBuilder: (context, open) => ListTile(
          leading: Checkbox(
            value: meal.cooked,
            semanticLabel: l.planCooked,
            onChanged: (v) => store.setCooked(meal, v ?? false),
          ),
          // Ticking a meal cooked strikes it through smoothly.
          title: AnimatedDefaultTextStyle(
            duration: Motion.of(context, Motion.short),
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  decoration: meal.cooked ? TextDecoration.lineThrough : TextDecoration.none,
                  color: meal.cooked ? scheme.onSurfaceVariant : scheme.onSurface,
                ),
            child: Text(r.title),
          ),
          subtitle: Text([
            if (r.minutes != null) l.recipeMinutes(r.minutes!),
            if (!meal.cooked) l.recipeToBuyCount(pantryCount),
          ].join(' · ')),
          onTap: open,
          trailing: PopupMenuButton<String>(
            onSelected: (v) => v == 'swap' ? onSwap?.call() : store.remove(meal),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'swap', enabled: onSwap != null, child: Text(l.planSwap)),
              PopupMenuItem(value: 'remove', child: Text(l.planRemove)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The week's combined shopping list; ticked items go onto the shopping list.
class WeekShoppingSheet extends StatefulWidget {
  const WeekShoppingSheet({super.key, required this.needs});
  final List<ShoppingNeed> needs;
  @override
  State<WeekShoppingSheet> createState() => _WeekShoppingSheetState();
}

class _WeekShoppingSheetState extends State<WeekShoppingSheet> {
  late final _on = [for (final _ in widget.needs) true];

  Future<void> _add() async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final n = await context.read<ShoppingStore>().addAll([
      for (var i = 0; i < widget.needs.length; i++)
        if (_on[i]) widget.needs[i].label,
    ]);
    if (mounted) Navigator.pop(context);
    messenger.showSnackBar(SnackBar(content: Text(n == 0 ? l.alreadyOnShoppingList : l.addedNToList(n))));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final count = _on.where((x) => x).length;
    return SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(l.weekShoppingTitle, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (widget.needs.isEmpty)
          Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), child: Text(l.weekShoppingNone))
        else ...[
          Flexible(
            child: ListView(shrinkWrap: true, children: [
              for (final (i, n) in widget.needs.indexed)
                CheckboxListTile(
                  value: _on[i],
                  onChanged: (v) => setState(() => _on[i] = v ?? false),
                  title: Text(n.label),
                  subtitle: Text(l.weekShoppingFor(n.recipes.join(', '))),
                ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: count == 0 ? null : _add, child: Text(l.addNToShoppingList(count))),
            ),
          ),
        ],
      ]),
    );
  }
}

/// Picks one of the next 7 days for [recipe] and adds it to the plan.
Future<void> addRecipeToPlan(BuildContext context, Recipe recipe) async {
  final l = context.l10n;
  final store = context.read<MealPlanStore>();
  final messenger = ScaffoldMessenger.of(context);
  final today = store.today;
  final day = await showModalBottomSheet<DateTime>(
    context: context,
    showDragHandle: true,
    builder: (s) => SafeArea(
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
              padding: const EdgeInsets.all(16), child: Text(l.planWhichDay, style: Theme.of(s).textTheme.titleMedium)),
          for (final d in MealPlan.nextDays(today, planDays))
            ListTile(
              title: Text(planDayLabel(l, d, today)),
              subtitle: store.plan.on(d).isEmpty ? null : Text(store.plan.on(d).map((m) => m.recipe.title).join(', ')),
              onTap: () => Navigator.pop(s, d),
            ),
        ]),
      ),
    ),
  );
  if (day == null || !context.mounted) return;
  await context.read<TasteStore?>()?.planned(recipe);
  await store.add(day, recipe);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(l.plannedAdded(planDayLabel(l, day, today)))));
}
