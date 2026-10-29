import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/product_memory_db.dart';
import '../l10n/l10n.dart';
import '../models/known_product.dart';
import '../widgets/category_style.dart';
import '../ui/layout.dart';

/// What PantryPal has learned from scans: review it, forget one product (with undo),
/// or forget everything. Forgetting never touches the pantry itself.
class RememberedProductsScreen extends StatefulWidget {
  const RememberedProductsScreen({super.key});
  @override
  State<RememberedProductsScreen> createState() => _RememberedProductsScreenState();
}

class _RememberedProductsScreenState extends State<RememberedProductsScreen> {
  final _search = TextEditingController();
  List<KnownProduct>? _products; // null while loading

  ProductMemoryDb? get _memory => context.read<ProductMemoryDb?>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final all = await _memory?.all(limit: 100000) ?? const <KnownProduct>[];
    if (mounted) setState(() => _products = all);
  }

  Future<void> _forget(KnownProduct k) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final memory = _memory;
    setState(() => _products = [...?_products]..remove(k));
    await memory?.forget(k.name);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(l.forgotProduct(k.name)),
        action: SnackBarAction(
          label: l.undo,
          onPressed: () async {
            await memory?.importAll([k], replace: false);
            await _load();
          },
        ),
      ));
  }

  Future<void> _forgetAll() async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(l.forgetAll),
        content: Text(l.forgetAllConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(l.forgetAll)),
        ],
      ),
    );
    if (ok != true) return;
    await _memory?.clear();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final all = _products;
    final q = KnownProduct.keyFor(_search.text);
    final shown = all == null ? const <KnownProduct>[] : [for (final k in all) if (q.isEmpty || k.key.contains(q)) k];
    return Scaffold(
      appBar: AppBar(title: Text(l.rememberedProducts), actions: [
        if (all != null && all.isNotEmpty)
          IconButton(tooltip: l.forgetAll, icon: const Icon(Icons.delete_sweep_outlined), onPressed: _forgetAll),
      ]),
      body: ReadableWidth(child: all == null
          ? const Center(child: CircularProgressIndicator())
          : all.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(l.noRememberedProducts, textAlign: TextAlign.center),
                  ),
                )
              : ListView(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: l.searchRemembered,
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    child: Text(l.rememberedCount(all.length), style: Theme.of(context).textTheme.bodySmall),
                  ),
                  for (final k in shown)
                    Dismissible(
                      key: ValueKey(k.key),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Theme.of(context).colorScheme.errorContainer,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.onErrorContainer),
                      ),
                      onDismissed: (_) => _forget(k),
                      child: ListTile(
                        leading: Icon(categoryIcon(k.category)),
                        title: Text(k.name),
                        subtitle: Text([
                          categoryLabel(l, k.category),
                          k.quantityLabel,
                          if (k.shelfDays != null) l.usuallyLasts(k.shelfDays!),
                          if (k.barcode != null) l.barcodeHelper(k.barcode!),
                        ].join(' · ')),
                        trailing: IconButton(
                          tooltip: l.forgetProduct,
                          icon: const Icon(Icons.close),
                          onPressed: () => _forget(k),
                        ),
                      ),
                    ),
                ])),
    );
  }
}
