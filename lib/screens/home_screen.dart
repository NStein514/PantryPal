import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/l10n.dart';
import '../models/pantry_item.dart';
import '../models/unit.dart';
import '../state/pantry_store.dart';
import '../state/shopping_store.dart';
import '../ui/layout.dart';
import '../ui/motion.dart';
import '../widgets/category_style.dart';
import '../widgets/expiry_badge.dart';
import '../widgets/use_amount_dialog.dart';
import 'scan_mode_sheet.dart';
import 'scan_screen.dart';
import 'settings_screen.dart';

/// The pantry tab: status summary, search, category filters and grouped list.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _search = TextEditingController();
  ExpiryStatus? _status;
  String? _category;
  final _hidden = <int>{}; // swiped away, waiting for the store to reload

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(PantryItem i) {
    final q = _search.text.trim().toLowerCase();
    return (_status == null || i.status == _status) &&
        (_category == null || i.category == _category) &&
        (q.isEmpty || i.name.toLowerCase().contains(q));
  }

  void _clearFilters() => setState(() {
        _status = null;
        _category = null;
        _search.clear();
      });

  void _remove(PantryStore store, PantryItem it) {
    HapticFeedback.lightImpact();
    setState(() => _hidden.add(it.id!));
    store.remove(it);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(context.l10n.removedItem(it.name)),
        action: SnackBarAction(
          label: context.l10n.undo,
          onPressed: () => store.add(PantryItem(
              name: it.name,
              category: it.category,
              quantity: it.quantity,
              unit: it.unit,
              expiry: it.expiry,
              addedAt: it.addedAt)),
        ),
      ));
  }

  static String describe(AppLocalizations l, PantryItem it) {
    final d = it.daysLeft;
    if (d == null) return l.noExpiryDate;
    final date = DateFormat.MMMd().format(it.expiry!);
    if (d < 0) return l.expiredOn(date);
    if (d == 0) return l.expiresToday;
    return l.expiresOn(date);
  }

  void _actions(PantryStore store, PantryItem it) {
    final l = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: ExpiryBadge(daysLeft: it.daysLeft, size: 40),
            title: Text(it.name, style: Theme.of(context).textTheme.titleMedium),
            subtitle: Text('${it.quantityLabel} · ${categoryLabel(l, it.category)} · ${describe(l, it)}'),
          ),
          const Divider(height: 1),
          if (it.unit.isCount)
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: Text(l.usedOne),
              subtitle: Text(
                  it.quantity > 1 ? l.leftAfterThis(formatQuantity(it.quantity - 1, it.unit)) : l.removesFromPantry),
              onTap: () {
                Navigator.pop(sheet);
                HapticFeedback.selectionClick();
                store.useOne(it);
              },
            )
          else
            ListTile(
              leading: const Icon(Icons.pie_chart_outline),
              title: Text(l.usedSome),
              subtitle: Text(l.amountLeft(it.quantityLabel)),
              onTap: () async {
                Navigator.pop(sheet);
                final amount = await showUseAmountDialog(context, it);
                if (amount != null) await store.useAmount(it, amount);
              },
            ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: Text(l.edit),
            onTap: () {
              Navigator.pop(sheet);
              Navigator.push(context, MaterialPageRoute(builder: (_) => ScanScreen(existing: it)));
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_shopping_cart),
            title: Text(l.addToShoppingList),
            onTap: () async {
              Navigator.pop(sheet);
              final messenger = ScaffoldMessenger.of(context);
              final n = await context.read<ShoppingStore>().addAll([it.name]);
              messenger.showSnackBar(
                  SnackBar(content: Text(n == 0 ? l.alreadyOnList(it.name) : l.addedToList(it.name))));
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: Text(l.remove),
            onTap: () {
              Navigator.pop(sheet);
              _remove(store, it);
            },
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PantryStore>();
    final l = context.l10n;
    final all = store.items.where((i) => !_hidden.contains(i.id)).toList();
    final counts = {for (final s in ExpiryStatus.values) s: all.where((i) => i.status == s).length};
    final categories = {for (final i in all) i.category}.toList()..sort();
    final visible = all.where(_matches).toList();

    return Scaffold(
      appBar: AppBar(title: Text(l.appTitle), actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: l.settings,
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
        ),
      ]),
      body: all.isEmpty
          ? const _EmptyPantry()
          : ReadableWidth(
              maxWidth: 1100,
              child: ListView(padding: const EdgeInsets.only(bottom: 96), children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                child: Row(children: [
                  for (final s in [ExpiryStatus.expired, ExpiryStatus.soon, ExpiryStatus.fresh])
                    Expanded(
                      child: _StatusCard(
                        label: statusLabel(l, s),
                        count: counts[s]!,
                        color: ExpiryBadge.textColorFor(
                            switch (s) {
                              ExpiryStatus.expired => -1,
                              ExpiryStatus.soon => 0,
                              _ => 30,
                            },
                            Theme.of(context).brightness),
                        selected: _status == s,
                        onTap: () => setState(() => _status = _status == s ? null : s),
                      ),
                    ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: l.searchHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: l.clearSearch,
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(_search.clear),
                          ),
                    filled: true,
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
                  ),
                ),
              ),
              if (categories.length > 1)
                SizedBox(
                  height: 56,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(l.filterAll),
                          selected: _category == null,
                          onSelected: (_) => setState(() => _category = null),
                        ),
                      ),
                      for (final c in categories)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            avatar: Icon(categoryIcon(c), size: 18),
                            label: Text(categoryLabel(l, c)),
                            selected: _category == c,
                            onSelected: (_) => setState(() => _category = _category == c ? null : c),
                          ),
                        ),
                    ],
                  ),
                )
              else
                const SizedBox(height: 8),
              if (visible.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(children: [
                    Text(l.noMatches),
                    TextButton(onPressed: _clearFilters, child: Text(l.clearFilters)),
                  ]),
                ),
              // Changing a filter cross-fades the list instead of snapping.
              AnimatedSwitcher(
                duration: Motion.of(context, Motion.medium),
                switchInCurve: Motion.emphasized,
                child: Column(
                  key: ValueKey('${_status?.name}|$_category'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final s in ExpiryStatus.values)
                      if (visible.any((i) => i.status == s)) ...[
                        _SectionHeader(label: statusLabel(l, s)),
                        AdaptiveColumns(minItemWidth: 360, gap: 0, children: [
                          for (final it in visible.where((i) => i.status == s))
                            _ItemTile(
                              item: it,
                              onTap: () => _actions(store, it),
                              onDismissed: () => _remove(store, it),
                            ),
                        ]),
                      ],
                  ],
                ),
              ),
            ]),
            ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.document_scanner_outlined),
        label: Text(l.scan),
        onPressed: () => showScanModeSheet(context),
      ),
    );
  }
}

class _EmptyPantry extends StatelessWidget {
  const _EmptyPantry();
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.kitchen_outlined, size: 72, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(context.l10n.emptyPantry, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              context.l10n.emptyPantryHint,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => showScanModeSheet(context),
              icon: const Icon(Icons.add),
              label: Text(context.l10n.scanFirstItem),
            ),
          ]),
        ),
      );
}

class _StatusCard extends StatelessWidget {
  const _StatusCard(
      {required this.label, required this.count, required this.color, required this.selected, required this.onTap});
  final String label;
  final int count;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final d = Motion.of(context, Motion.short);
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Semantics(
        button: true,
        selected: selected,
        child: AnimatedContainer(
          duration: d,
          curve: Motion.emphasized,
          decoration: BoxDecoration(
            color: selected ? color.withAlpha(46) : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? color : Colors.transparent, width: 2),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                child: Column(children: [
                  // The count ticks over when it changes.
                  AnimatedSwitcher(
                    duration: d,
                    transitionBuilder: (child, a) => FadeTransition(opacity: a, child: ScaleTransition(scale: a, child: child)),
                    child: Text('$count',
                        key: ValueKey(count),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.bold)),
                  ),
                  Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelMedium),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(label.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: 1.1,
                )),
      );
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.item, required this.onTap, required this.onDismissed});
  final PantryItem item;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    final it = item;
    final l = context.l10n;
    return Dismissible(
      key: ValueKey(it.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.onErrorContainer),
      ),
      onDismissed: (_) => onDismissed(),
      child: ListTile(
        leading: ExpiryBadge(daysLeft: it.daysLeft),
        onTap: onTap,
        title: Text('${it.name} ${it.quantityLabel}'),
        subtitle: Text(it.expiry == null
            ? categoryLabel(l, it.category)
            : '${categoryLabel(l, it.category)} · ${DateFormat.yMMMd().format(it.expiry!)}'),
        trailing: Icon(categoryIcon(it.category), color: Theme.of(context).colorScheme.outline),
      ),
    );
  }
}
