import 'unit.dart';

/// Something the user has added before, remembered to speed up the next scan:
/// its usual category, unit and size, the barcode it was scanned with, and how long it
/// usually lasts (from expiry dates the user confirmed, not estimates).
class KnownProduct {
  const KnownProduct({
    required this.name,
    this.category = 'Other',
    this.unit = Unit.count,
    this.quantity = 1.0,
    this.barcode,
    this.shelfDays,
    this.uses = 1,
    this.lastUsed,
  });

  final String name;
  final String category;
  final Unit unit;
  final double quantity;
  final String? barcode;
  final int? shelfDays;
  final int uses;
  final DateTime? lastUsed;

  /// Case- and spacing-insensitive identity: "Oat  Milk" and "oat milk" are the same product.
  static String keyFor(String name) => name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  String get key => keyFor(name);
  String get quantityLabel => formatQuantity(quantity, unit);

  Map<String, Object?> toMap() => {
        'key': key,
        'name': name,
        'category': category,
        'unit': unit.name,
        'quantity': quantity,
        'barcode': barcode,
        'shelf_days': shelfDays,
        'uses': uses,
        'last_used': (lastUsed ?? DateTime.now()).toIso8601String(),
      };

  factory KnownProduct.fromMap(Map<String, Object?> m) => KnownProduct(
        name: m['name'] as String,
        category: (m['category'] as String?) ?? 'Other',
        unit: Unit.parse(m['unit']),
        quantity: ((m['quantity'] as num?) ?? 1).toDouble(),
        barcode: m['barcode'] as String?,
        shelfDays: m['shelf_days'] as int?,
        uses: (m['uses'] as int?) ?? 1,
        lastUsed: m['last_used'] == null ? null : DateTime.tryParse(m['last_used'] as String),
      );
}
