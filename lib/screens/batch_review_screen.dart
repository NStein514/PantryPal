import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../data/product_memory_db.dart';
import '../l10n/l10n.dart';
import '../models/categories.dart';
import '../models/scan_draft.dart';
import '../state/pantry_store.dart';
import '../widgets/category_style.dart';
import '../widgets/quantity_field.dart';
import '../ui/layout.dart';

/// Shows the items a batch scan found so the user can fix names, quantities and
/// dates, untick mistakes, then save them all at once. Pops with the number saved.
class BatchReviewScreen extends StatefulWidget {
  const BatchReviewScreen({super.key, required this.title, required this.load});
  final String title;
  final Future<List<ScanDraft>> Function() load;
  @override
  State<BatchReviewScreen> createState() => _BatchReviewScreenState();
}

class _BatchReviewScreenState extends State<BatchReviewScreen> {
  List<ScanDraft>? _drafts;
  Object? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _drafts = null;
      _error = null;
    });
    try {
      final d = await widget.load();
      if (mounted) setState(() => _drafts = d);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  int get _count => _drafts?.where((d) => d.isSavable).length ?? 0;

  Future<void> _save() async {
    final saving = [for (final d in _drafts!) if (d.isSavable) d];
    setState(() => _saving = true);
    final memory = context.read<ProductMemoryDb?>();
    final n = await context.read<PantryStore>().addAll([for (final d in saving) d.toItem()]);
    // Teach the product memory, so these barcodes and names are recognised next time.
    for (final d in saving) {
      try {
        await memory?.remember(d.toItem(), barcode: d.barcode, expiryEstimated: d.expiryEstimated);
      } catch (_) {}
    }
    if (mounted) Navigator.pop(context, n);
  }

  void _setAll(bool include) => setState(() {
        for (final d in _drafts!) {
          d.include = include && d.name.trim().isNotEmpty;
        }
      });

  @override
  Widget build(BuildContext context) {
    final drafts = _drafts;
    final l = context.l10n;
    final allOn = drafts != null && drafts.isNotEmpty && drafts.every((d) => d.include || d.name.trim().isEmpty);
    return Scaffold(
      appBar: AppBar(title: Text(widget.title), actions: [
        if (drafts != null && drafts.isNotEmpty)
          TextButton(onPressed: () => _setAll(!allOn), child: Text(allOn ? l.selectNone : l.selectAll)),
      ]),
      body: ReadableWidth(child: _error != null
          ? _Message(
              icon: Icons.error_outline,
              title: l.scanReadError,
              body: '$_error',
              action: FilledButton.icon(onPressed: _fetch, icon: const Icon(Icons.refresh), label: Text(l.tryAgain)),
            )
          : drafts == null
              ? _Message(icon: null, title: l.readingScan, body: l.readingScanHint)
              : drafts.isEmpty
                  ? _Message(
                      icon: Icons.search_off,
                      title: l.noFoodFound,
                      body: l.noFoodFoundHint,
                      action: OutlinedButton(onPressed: () => Navigator.pop(context, 0), child: Text(l.back)),
                    )
                  : ListView(padding: const EdgeInsets.fromLTRB(12, 8, 12, 24), children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                        child: Text(l.foundIntro(drafts.length)),
                      ),
                      for (final d in drafts)
                        _DraftCard(
                          key: ObjectKey(d),
                          draft: d,
                          onChanged: () => setState(() {}),
                          onDelete: () => setState(() => drafts.remove(d)),
                        ),
                    ])),
      bottomNavigationBar: drafts == null || drafts.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton.icon(
                  onPressed: _count == 0 || _saving ? null : _save,
                  icon: const Icon(Icons.add_task),
                  label: Text(l.addItemsButton(_count)),
                ),
              ),
            ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.title, required this.body, this.action});
  final IconData? icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (icon == null) const CircularProgressIndicator() else Icon(icon, size: 48),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(body, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ]),
        ),
      );
}

class _DraftCard extends StatelessWidget {
  const _DraftCard({super.key, required this.draft, required this.onChanged, required this.onDelete});
  final ScanDraft draft;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  Future<void> _pickDate(BuildContext context) async {
    final d = await showDatePicker(
      context: context,
      initialDate: draft.expiry ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d == null) return;
    draft
      ..expiry = d
      ..expiryEstimated = false;
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final d = draft;
    final l = context.l10n;
    final unnamed = d.name.trim().isEmpty;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Checkbox(
              value: d.include && !unnamed,
              onChanged: unnamed
                  ? null
                  : (v) {
                      d.include = v ?? false;
                      onChanged();
                    },
            ),
            Expanded(
              child: TextFormField(
                initialValue: d.name,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: l.itemNameHint,
                  helperText: d.barcode == null ? null : l.barcodeHelper(d.barcode!),
                  errorText: unnamed && d.barcode != null ? l.notFoundTypeName : null,
                ),
                onChanged: (v) {
                  final wasEmpty = d.name.trim().isEmpty;
                  d.name = v;
                  if (wasEmpty && v.trim().isNotEmpty) d.include = true; // naming an unknown item opts it in
                  onChanged();
                },
              ),
            ),
            IconButton(tooltip: l.removeFromList, icon: const Icon(Icons.close), onPressed: onDelete),
          ]),
          Padding(
            padding: const EdgeInsets.only(left: 48, right: 8),
            child: Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
              DropdownButton<String>(
                value: d.category,
                underline: const SizedBox.shrink(),
                items: [
                  for (final c in kCategories)
                    DropdownMenuItem(
                      value: c,
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(categoryIcon(c), size: 18),
                        const SizedBox(width: 6),
                        Text(categoryLabel(l, c)),
                      ]),
                    ),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  d.category = v;
                  onChanged();
                },
              ),
              QuantityStepper(
                quantity: d.quantity,
                unit: d.unit,
                onChanged: (q, u) {
                  d
                    ..quantity = q
                    ..unit = u;
                  onChanged();
                },
              ),
              ActionChip(
                avatar: const Icon(Icons.event, size: 18),
                label: Text(d.expiry == null
                    ? l.addDate
                    : d.expiryEstimated
                        ? l.estimatedDate(DateFormat.MMMd().format(d.expiry!))
                        : DateFormat.MMMd().format(d.expiry!)),
                onPressed: () => _pickDate(context),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
