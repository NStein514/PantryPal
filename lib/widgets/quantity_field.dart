import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../models/unit.dart';

/// Compact "− 500 g +" stepper with a unit picker. Steps follow the unit
/// (1 for pieces, 50 for g/ml, 0.25 for kg/L/lb).
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({super.key, required this.quantity, required this.unit, required this.onChanged});
  final double quantity;
  final Unit unit;
  final void Function(double quantity, Unit unit) onChanged;

  @override
  Widget build(BuildContext context) {
    final min = unit.step;
    final l = context.l10n;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton(
        visualDensity: VisualDensity.compact,
        tooltip: l.less,
        icon: const Icon(Icons.remove_circle_outline),
        onPressed: quantity > min ? () => onChanged(_snap(quantity - unit.step), unit) : null,
      ),
      Text(unit.isCount ? '×${formatNumber(quantity)}' : formatNumber(quantity)),
      IconButton(
        visualDensity: VisualDensity.compact,
        tooltip: l.more,
        icon: const Icon(Icons.add_circle_outline),
        onPressed: () => onChanged(_snap(quantity + unit.step), unit),
      ),
      UnitDropdown(value: unit, onChanged: (u) => onChanged(quantity, u)),
    ]);
  }

  static double _snap(double v) => (v * 1000).roundToDouble() / 1000;
}

class UnitDropdown extends StatelessWidget {
  const UnitDropdown({super.key, required this.value, required this.onChanged});
  final Unit value;
  final void Function(Unit) onChanged;

  @override
  Widget build(BuildContext context) => DropdownButton<Unit>(
        value: value,
        underline: const SizedBox.shrink(),
        items: [for (final u in Unit.values) DropdownMenuItem(value: u, child: Text(unitLabel(context.l10n, u)))],
        onChanged: (u) {
          if (u != null) onChanged(u);
        },
      );
}
