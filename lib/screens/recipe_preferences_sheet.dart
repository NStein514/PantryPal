import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../models/recipe_preferences.dart';

/// Diet, servings, time limit and foods to avoid. Pops with the new preferences (or null).
Future<RecipePreferences?> showRecipePreferencesSheet(BuildContext context, RecipePreferences current) =>
    showModalBottomSheet<RecipePreferences>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _PreferencesSheet(initial: current),
    );

String dietLabel(AppLocalizations l, Diet d) => switch (d) {
      Diet.vegetarian => l.dietVegetarian,
      Diet.vegan => l.dietVegan,
      Diet.glutenFree => l.dietGlutenFree,
      Diet.dairyFree => l.dietDairyFree,
    };

class _PreferencesSheet extends StatefulWidget {
  const _PreferencesSheet({required this.initial});
  final RecipePreferences initial;
  @override
  State<_PreferencesSheet> createState() => _PreferencesSheetState();
}

class _PreferencesSheetState extends State<_PreferencesSheet> {
  late RecipePreferences _p = widget.initial;
  late final _avoid = TextEditingController(text: widget.initial.avoid);

  @override
  void dispose() {
    _avoid.dispose();
    super.dispose();
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 6),
        child: Text(text, style: Theme.of(context).textTheme.labelLarge),
      );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(l.recipePrefsTitle, style: Theme.of(context).textTheme.titleLarge),
            _label(l.prefsDiet),
            Wrap(spacing: 8, runSpacing: 4, children: [
              for (final d in Diet.values)
                FilterChip(
                  label: Text(dietLabel(l, d)),
                  selected: _p.diets.contains(d),
                  onSelected: (on) => setState(() => _p = _p.copyWith(diets: on ? {..._p.diets, d} : ({..._p.diets}..remove(d)))),
                ),
            ]),
            _label(l.prefsServings),
            Row(children: [
              IconButton.outlined(
                tooltip: l.less,
                onPressed: _p.servings > 1 ? () => setState(() => _p = _p.copyWith(servings: _p.servings - 1)) : null,
                icon: const Icon(Icons.remove),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(l.recipeServings(_p.servings), style: Theme.of(context).textTheme.titleMedium),
              ),
              IconButton.outlined(
                tooltip: l.more,
                onPressed: _p.servings < RecipePreferences.maxServings
                    ? () => setState(() => _p = _p.copyWith(servings: _p.servings + 1))
                    : null,
                icon: const Icon(Icons.add),
              ),
            ]),
            _label(l.prefsTime),
            Wrap(spacing: 8, runSpacing: 4, children: [
              ChoiceChip(
                label: Text(l.prefsAnyTime),
                selected: _p.maxMinutes == null,
                onSelected: (_) => setState(() => _p = _p.copyWith(clearMaxMinutes: true)),
              ),
              for (final m in RecipePreferences.timeChoices)
                ChoiceChip(
                  label: Text(l.recipeMinutes(m)),
                  selected: _p.maxMinutes == m,
                  onSelected: (_) => setState(() => _p = _p.copyWith(maxMinutes: m)),
                ),
            ]),
            _label(l.prefsAvoid),
            TextField(
              key: const Key('prefs-avoid'),
              controller: _avoid,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(hintText: l.prefsAvoidHint, border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.info_outline, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(child: Text(l.prefsAllergyNote, style: Theme.of(context).textTheme.bodySmall)),
            ]),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, _p.copyWith(avoid: _avoid.text.trim())),
                child: Text(l.prefsApply),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
