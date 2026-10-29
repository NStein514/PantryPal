import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../models/pantry_item.dart';
import '../models/unit.dart';

/// Asks how much of a measured item (500 g, 1 L…) was used. Pops with the amount.
Future<double?> showUseAmountDialog(BuildContext context, PantryItem item) =>
    showDialog<double>(context: context, builder: (_) => _UseAmountDialog(item: item));

class _UseAmountDialog extends StatefulWidget {
  const _UseAmountDialog({required this.item});
  final PantryItem item;
  @override
  State<_UseAmountDialog> createState() => _UseAmountDialogState();
}

class _UseAmountDialogState extends State<_UseAmountDialog> {
  late final _ctrl = TextEditingController(text: formatNumber(widget.item.quantity / 2));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double? get _value {
    final v = double.tryParse(_ctrl.text.replaceAll(',', '.'));
    return v == null || v <= 0 ? null : v;
  }

  @override
  Widget build(BuildContext context) {
    final it = widget.item;
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.useAmountTitle(it.name)),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.youHave(it.quantityLabel)),
        const SizedBox(height: 12),
        TextField(
          key: const Key('use-amount'),
          controller: _ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(suffixText: it.unit.symbol, border: const OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, children: [
          for (final (label, f) in const [('¼', 0.25), ('½', 0.5), ('¾', 0.75)])
            ActionChip(
              label: Text(label),
              onPressed: () => setState(() => _ctrl.text = formatNumber(it.quantity * f)),
            ),
          ActionChip(label: Text(l.useAll), onPressed: () => Navigator.pop(context, it.quantity)),
        ]),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(
          onPressed: _value == null ? null : () => Navigator.pop(context, _value),
          child: Text(l.use),
        ),
      ],
    );
  }
}
