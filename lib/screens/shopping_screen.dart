import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/l10n.dart';
import '../models/pantry_item.dart';
import '../models/quick_list.dart';
import '../state/pantry_store.dart';
import '../state/shopping_store.dart';
import '../ui/layout.dart';

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});
  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  final _input = TextEditingController();
  // Swiped away, waiting for the store to reload: a dismissed Dismissible must leave the tree at once.
  final _hidden = <int>{};

  Future<void> _submit() async {
    final text = _input.text;
    _input.clear();
    await context.read<ShoppingStore>().addAll([text]);
  }

  Future<void> _moveToPantry() async {
    final shop = context.read<ShoppingStore>();
    final pantry = context.read<PantryStore>();
    final l = context.l10n;
    final bought = shop.checked;
    // "Milk 500 ml" (e.g. from the week's shopping) arrives as 500 ml of milk, filed under its category.
    final known = {for (final i in pantry.items) i.name.trim().toLowerCase(): i};
    for (final i in bought) {
      final drafts = parseQuickList(i.name); // "salt, pepper" is two items
      for (final item in drafts.isEmpty ? [PantryItem(name: i.name)] : [for (final d in drafts) d.toItem()]) {
        final existing = known[item.name.trim().toLowerCase()];
        await pantry.add(existing == null ? item : item.copyWith(category: existing.category));
      }
    }
    await shop.clearChecked();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.movedToPantry(bought.length))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShoppingStore>();
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.shoppingList), actions: [
        if (shop.checked.isNotEmpty) TextButton(onPressed: _moveToPantry, child: Text(l.toPantry)),
      ]),
      body: ReadableWidth(child: Column(children: [
        Expanded(
          child: shop.items.isEmpty
              ? Center(child: Text(l.listEmpty))
              : ListView(children: [
                  for (final i in shop.items.where((i) => !_hidden.contains(i.id)))
                    Dismissible(
                      key: ValueKey(i.id),
                      background: Container(color: Theme.of(context).colorScheme.errorContainer),
                      onDismissed: (_) {
                        setState(() => _hidden.add(i.id!));
                        shop.remove(i);
                      },
                      child: CheckboxListTile(
                        value: i.checked,
                        onChanged: (_) => shop.toggle(i),
                        title: Text(i.name, style: i.checked ? const TextStyle(decoration: TextDecoration.lineThrough) : null),
                      ),
                    ),
                ]),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _input,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: l.addItemHint,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(icon: const Icon(Icons.add), onPressed: _submit),
              ),
            ),
          ),
        ),
      ])),
    );
  }
}
