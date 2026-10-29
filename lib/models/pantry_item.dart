import 'unit.dart';

/// Where an item stands relative to its expiry date.
enum ExpiryStatus { expired, soon, fresh, undated }

class PantryItem {
  final int? id;
  final String name;
  final String category;

  /// How many (for [Unit.count]) or how much (for measured units).
  final double quantity;
  final Unit unit;
  final DateTime? expiry;
  final DateTime addedAt;

  PantryItem({
    this.id,
    required this.name,
    this.category = 'Other',
    this.quantity = 1.0,
    this.unit = Unit.count,
    this.expiry,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  /// [clearExpiry] removes the date (passing `expiry: null` keeps the old one).
  PantryItem copyWith({
    String? name,
    String? category,
    double? quantity,
    Unit? unit,
    DateTime? expiry,
    bool clearExpiry = false,
  }) =>
      PantryItem(
        id: id,
        name: name ?? this.name,
        category: category ?? this.category,
        quantity: quantity ?? this.quantity,
        unit: unit ?? this.unit,
        expiry: clearExpiry ? null : expiry ?? this.expiry,
        addedAt: addedAt,
      );

  PantryItem withId(int newId) => PantryItem(
      id: newId, name: name, category: category, quantity: quantity, unit: unit, expiry: expiry, addedAt: addedAt);

  /// True when [other] is the same stock as this item and can be folded into it:
  /// same name (case/space-insensitive), same expiry day (or both undated), convertible units.
  /// Different expiry dates stay separate on purpose, so each batch keeps its own reminder.
  bool canMergeWith(PantryItem other) =>
      name.trim().toLowerCase() == other.name.trim().toLowerCase() &&
      _sameDay(expiry, other.expiry) &&
      unit.canConvertTo(other.unit);

  /// Adds [other]'s amount to this item, converted into this item's unit.
  PantryItem mergedWith(PantryItem other) {
    final sum = quantity + other.unit.convert(other.quantity, unit);
    return copyWith(quantity: (sum * 1000).roundToDouble() / 1000);
  }

  static bool _sameDay(DateTime? a, DateTime? b) =>
      a == null || b == null ? a == b : a.year == b.year && a.month == b.month && a.day == b.day;

  /// "×2", "500 g", "1.5 L".
  String get quantityLabel => formatQuantity(quantity, unit);

  int? get daysLeft {
    if (expiry == null) return null;
    final today = DateTime.now();
    return DateTime(expiry!.year, expiry!.month, expiry!.day)
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
  }

  /// expired (< 0 days), soon (0–3 days), fresh (> 3 days) or undated.
  ExpiryStatus get status {
    final d = daysLeft;
    if (d == null) return ExpiryStatus.undated;
    if (d < 0) return ExpiryStatus.expired;
    if (d <= 3) return ExpiryStatus.soon;
    return ExpiryStatus.fresh;
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'category': category,
        'quantity': quantity,
        'unit': unit.name,
        'expiry': expiry?.toIso8601String(),
        'added_at': addedAt.toIso8601String(),
      };

  /// Reads rows from SQLite and backups. Older rows have an INTEGER quantity and no unit.
  factory PantryItem.fromMap(Map<String, Object?> m) => PantryItem(
        id: m['id'] as int?,
        name: m['name'] as String,
        category: (m['category'] as String?) ?? 'Other',
        quantity: ((m['quantity'] as num?) ?? 1).toDouble(),
        unit: Unit.parse(m['unit']),
        expiry: m['expiry'] == null ? null : DateTime.parse(m['expiry'] as String),
        addedAt: m['added_at'] == null ? null : DateTime.parse(m['added_at'] as String),
      );
}
