import 'categories.dart';
import 'known_product.dart';
import 'pantry_item.dart';
import 'unit.dart';

/// An editable, not-yet-saved item produced by a scan (receipt, haul photo,
/// barcode run). Mutable on purpose: the review screen edits it in place.
class ScanDraft {
  ScanDraft({
    this.name = '',
    this.category = 'Other',
    this.quantity = 1.0,
    this.unit = Unit.count,
    this.expiry,
    this.expiryEstimated = false,
    this.barcode,
    bool? include,
  }) : include = include ?? name.trim().isNotEmpty;

  String name;
  String category;
  double quantity;
  Unit unit;
  DateTime? expiry;

  /// True when [expiry] was derived from a typical shelf life rather than read from a label.
  bool expiryEstimated;

  /// Set for drafts that came from a barcode, so unknown products can still be identified.
  final String? barcode;

  /// Whether the user wants this draft saved.
  bool include;

  bool get isSavable => include && name.trim().isNotEmpty;

  /// "×2", "500 g".
  String get quantityLabel => formatQuantity(quantity, unit);

  /// Builds a draft from one AI item: {name, category, quantity?, unit?, shelf_life_days?, expiry?}.
  /// A printed expiry wins; otherwise shelf_life_days gives an estimated date.
  factory ScanDraft.fromAi(Map<String, dynamic> m, {DateTime? today}) {
    final now = today ?? DateTime.now();
    DateTime? expiry;
    var estimated = false;
    final printed = m['expiry'] is String ? DateTime.tryParse(m['expiry'] as String) : null;
    final shelf = m['shelf_life_days'];
    if (printed != null) {
      expiry = DateTime(printed.year, printed.month, printed.day);
    } else if (shelf is num && shelf > 0) {
      // Calendar arithmetic (not Duration) so DST changes can't shift the date.
      expiry = DateTime(now.year, now.month, now.day + shelf.round());
      estimated = true;
    }
    final unit = Unit.parse(m['unit']);
    final q = m['quantity'];
    final double quantity;
    if (q is! num || q <= 0) {
      quantity = 1;
    } else if (unit.isCount) {
      quantity = q.round().clamp(1, 999).toDouble();
    } else {
      quantity = (q * 100).roundToDouble() / 100;
    }
    return ScanDraft(
      name: '${m['name'] ?? ''}'.trim(),
      category: normalizeCategory(m['category']),
      quantity: quantity,
      unit: unit,
      expiry: expiry,
      expiryEstimated: estimated,
    );
  }

  /// A draft from a remembered product. Counted products take [count] (times scanned);
  /// measured ones take their usual size × count. A known shelf life gives an estimated date.
  factory ScanDraft.fromKnown(KnownProduct k, {int count = 1, String? barcode, DateTime? today}) {
    final now = today ?? DateTime.now();
    final shelf = k.shelfDays;
    return ScanDraft(
      name: k.name,
      category: k.category,
      unit: k.unit,
      quantity: k.unit.isCount ? count.toDouble() : k.quantity * count,
      expiry: shelf == null ? null : DateTime(now.year, now.month, now.day + shelf),
      expiryEstimated: shelf != null,
      barcode: barcode ?? k.barcode,
      include: true,
    );
  }

  PantryItem toItem() =>
      PantryItem(name: name.trim(), category: category, quantity: quantity, unit: unit, expiry: expiry);
}
