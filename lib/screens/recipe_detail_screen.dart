import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/l10n.dart';
import '../models/meal_plan.dart';
import '../models/pantry_item.dart';
import '../models/recipe.dart';
import '../models/unit.dart';
import '../services/recipe_planner.dart';
import '../state/meal_plan_store.dart';
import '../state/pantry_store.dart';
import '../state/saved_recipes.dart';
import '../state/shopping_store.dart';
import '../state/taste_store.dart';
import '../ui/breakpoints.dart';
import '../ui/layout.dart';
import '../ui/motion.dart';
import '../widgets/expiry_badge.dart';
import 'meal_plan_view.dart';
import 'recipe_suggestions.dart';

/// One recipe: what you have and what to buy (checked against the real pantry), steps you can
/// tick off while cooking, and "I cooked this" to take the used amounts out of the pantry.
class RecipeDetailScreen extends StatefulWidget {
  const RecipeDetailScreen({super.key, required this.recipe, this.plannedMeal});
  final Recipe recipe;

  /// Set when opened from the meal plan: cooking it marks the planned meal cooked.
  final PlannedMeal? plannedMeal;
  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final _doneSteps = <int>{};

  Future<void> _addMissing(List<RecipeIngredient> missing) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final n = await context.read<ShoppingStore>().addAll([for (final i in missing) i.name]);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(n == 0 ? l.alreadyOnShoppingList : l.addedNToList(n))));
  }

  Future<void> _cooked() async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final plan = planDeductions(widget.recipe, context.read<PantryStore>().items);
    final n = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => CookSheet(deductions: plan),
    );
    if (n != null && n > 0) {
      if (mounted) await context.read<TasteStore?>()?.cooked(widget.recipe); // the strongest signal
      final meal = widget.plannedMeal;
      if (meal != null && mounted) await context.read<MealPlanStore?>()?.setCooked(meal, true);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.pantryUpdated(n))));
    }
  }

  Widget _header(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = widget.recipe;
    final scheme = Theme.of(context).colorScheme;
    final check = checkPantry(r, context.watch<PantryStore>().items);
    context.watch<ShoppingStore?>(); // refresh "on your list" as the list changes
    final onList = shoppingNames(context);
    final toBuy = [for (final i in check.missing) if (!isOnList(i, onList)) i];
    final saved = context.watch<SavedRecipes?>();
    final plan = context.watch<MealPlanStore?>();
    return Scaffold(
      appBar: AppBar(title: Text(r.title), actions: [
        if (plan != null && widget.plannedMeal == null)
          IconButton(tooltip: l.addToPlan, icon: const Icon(Icons.edit_calendar_outlined), onPressed: () => addRecipeToPlan(context, r)),
        if (saved != null)
          IconButton(
            tooltip: saved.isSaved(r) ? l.unsaveRecipe : l.saveRecipe,
            icon: Icon(saved.isSaved(r) ? Icons.bookmark : Icons.bookmark_outline),
            onPressed: () => toggleSaved(context, r),
          ),
      ]),
      body: LayoutBuilder(builder: (context, c) {
        final ingredients = <Widget>[
          _header(l.recipeIngredients),
          for (final ing in r.ingredients)
            ListTile(
              dense: true,
              leading: ing.staple
                  ? Icon(Icons.kitchen_outlined, color: scheme.onSurfaceVariant)
                  : check.have.containsKey(ing)
                      ? Icon(Icons.check_circle, color: scheme.primary)
                      : isOnList(ing, onList)
                          ? Icon(Icons.playlist_add_check, color: scheme.onSurfaceVariant)
                          : Icon(Icons.shopping_cart_outlined, color: scheme.onSurfaceVariant),
              title: Text(ing.name),
              subtitle: switch (check.have[ing]) {
                final PantryItem p => Text('${p.name} · ${p.quantityLabel}'),
                _ => ing.staple
                    ? Text(l.recipeBasics)
                    : isOnList(ing, onList)
                        ? Text(l.onYourList)
                        : null,
              },
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                if (ing.amountLabel.isNotEmpty) Text(ing.amountLabel),
                if (check.have[ing] case final PantryItem p when p.expiry != null) ...[
                  const SizedBox(width: 8),
                  ExpiryBadge(daysLeft: p.daysLeft, size: 32),
                ],
              ]),
            ),
          if (toBuy.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: OutlinedButton.icon(
                onPressed: () => _addMissing(toBuy),
                icon: const Icon(Icons.add_shopping_cart),
                label: Text(l.addMissingToList),
              ),
            ),
        ];
        final d = Motion.of(context, Motion.short);
        final steps = <Widget>[
          _header(l.recipeSteps),
          for (final (i, step) in r.steps.indexed)
            ListTile(
              onTap: () => setState(() => _doneSteps.contains(i) ? _doneSteps.remove(i) : _doneSteps.add(i)),
              leading: AnimatedContainer(
                duration: d,
                curve: Motion.emphasized,
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _doneSteps.contains(i) ? scheme.primary : scheme.secondaryContainer,
                ),
                child: AnimatedSwitcher(
                  duration: d,
                  child: _doneSteps.contains(i)
                      ? Icon(Icons.check, size: 16, color: scheme.onPrimary, key: const ValueKey('done'))
                      : Text('${i + 1}', key: const ValueKey('todo'), style: TextStyle(color: scheme.onSecondaryContainer)),
                ),
              ),
              title: AnimatedDefaultTextStyle(
                duration: d,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      decoration: _doneSteps.contains(i) ? TextDecoration.lineThrough : TextDecoration.none,
                      color: _doneSteps.contains(i) ? scheme.onSurfaceVariant : scheme.onSurface,
                    ),
                child: Text(step),
              ),
            ),
        ];
        final intro = <Widget>[
          if (r.summary.isNotEmpty) Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 0), child: Text(r.summary)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Wrap(spacing: 8, runSpacing: 4, children: [
              if (r.minutes != null)
                Chip(avatar: const Icon(Icons.timer_outlined, size: 18), label: Text(l.recipeMinutes(r.minutes!))),
              if (r.servings != null)
                Chip(avatar: const Icon(Icons.people_outline, size: 18), label: Text(l.recipeServings(r.servings!))),
            ]),
          ),
        ];
        // Wide screens: ingredients beside the steps, so both stay in view while cooking.
        if (WindowSize.of(c.maxWidth) == WindowSize.expanded) {
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: ListView(padding: const EdgeInsets.only(bottom: 24), children: [
                ...intro,
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: ingredients)),
                  const SizedBox(width: 24),
                  Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: steps)),
                ]),
              ]),
            ),
          );
        }
        return ReadableWidth(
          child: ListView(padding: const EdgeInsets.only(bottom: 24), children: [...intro, ...ingredients, ...steps]),
        );
      }),
      bottomNavigationBar: check.have.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton.icon(onPressed: _cooked, icon: const Icon(Icons.restaurant), label: Text(l.cookedThis)),
              ),
            ),
    );
  }
}

/// "I cooked this": the pantry deductions, ticked when the amount is known, adjustable per item.
/// Pops with the number of pantry items updated.
class CookSheet extends StatefulWidget {
  const CookSheet({super.key, required this.deductions});
  final List<CookDeduction> deductions;
  @override
  State<CookSheet> createState() => _CookSheetState();
}

class _CookSheetState extends State<CookSheet> {
  late final List<bool> _on = [for (final d in widget.deductions) d.known];
  late final List<double> _amount = [for (final d in widget.deductions) d.amount];
  bool _saving = false;

  void _step(int i, int dir) {
    final item = widget.deductions[i].item;
    final step = item.unit.step;
    final next = ((_amount[i] + dir * step) * 1000).roundToDouble() / 1000;
    setState(() => _amount[i] = next.clamp(step < item.quantity ? step : item.quantity, item.quantity).toDouble());
  }

  Future<void> _apply() async {
    setState(() => _saving = true);
    final store = context.read<PantryStore>();
    var n = 0;
    for (var i = 0; i < widget.deductions.length; i++) {
      if (!_on[i]) continue;
      await store.useAmount(widget.deductions[i].item, _amount[i]);
      n++;
    }
    if (mounted) Navigator.pop(context, n);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final count = _on.where((x) => x).length;
    return SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
          child: Text(l.cookSheetTitle, style: Theme.of(context).textTheme.titleLarge),
        ),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text(l.cookSheetHint)),
        Flexible(
          child: ListView(shrinkWrap: true, children: [
            for (final (i, d) in widget.deductions.indexed)
              ListTile(
                leading: Checkbox(value: _on[i], onChanged: (v) => setState(() => _on[i] = v ?? false)),
                title: Text(d.item.name),
                subtitle: Text(_amount[i] >= d.item.quantity - 1e-9
                    ? l.cookUsesAll
                    : l.cookLeftAfter(formatQuantity(d.item.quantity - _amount[i], d.item.unit))),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(tooltip: l.less, icon: const Icon(Icons.remove_circle_outline), onPressed: _on[i] ? () => _step(i, -1) : null),
                  Text(formatQuantity(_amount[i], d.item.unit)),
                  IconButton(tooltip: l.more, icon: const Icon(Icons.add_circle_outline), onPressed: _on[i] ? () => _step(i, 1) : null),
                ]),
              ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: count == 0 || _saving ? null : _apply, child: Text(l.updatePantry)),
          ),
        ),
      ]),
    );
  }
}
