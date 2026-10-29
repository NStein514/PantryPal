/// What a unit measures; only units of the same dimension convert into each other.
enum Dimension { count, mass, volume }

/// How an item's quantity is measured.
///
/// [count] is "how many" (shown as ×2); the rest are amounts (500 g, 1.5 L).
/// [step] is the +/− increment used by quantity steppers.
enum Unit {
  count('', 1, 'pcs', Dimension.count, 1),
  g('g', 50, 'g', Dimension.mass, 1),
  kg('kg', 0.25, 'kg', Dimension.mass, 1000),
  ml('ml', 50, 'ml', Dimension.volume, 1),
  l('L', 0.25, 'L', Dimension.volume, 1000),
  oz('oz', 1, 'oz', Dimension.mass, 28.349523125),
  lb('lb', 0.25, 'lb', Dimension.mass, 453.59237);

  const Unit(this.symbol, this.step, this.label, this.dimension, this.toBase);
  final String symbol;
  final double step;
  final Dimension dimension;

  /// Size of one of this unit in the dimension's base unit (pieces, grams, millilitres).
  final double toBase;

  bool canConvertTo(Unit other) => dimension == other.dimension;

  /// Converts [amount] of this unit into [to]. Throws if the dimensions differ.
  double convert(double amount, Unit to) {
    if (!canConvertTo(to)) throw ArgumentError('Cannot convert $name to ${to.name}');
    return amount * toBase / to.toBase;
  }

  /// Short name for pickers.
  final String label;

  bool get isCount => this == Unit.count;

  static const _aliases = {
    'count': Unit.count, 'each': Unit.count, 'ea': Unit.count, 'pc': Unit.count, 'pcs': Unit.count,
    'piece': Unit.count, 'pieces': Unit.count, 'item': Unit.count, 'items': Unit.count, 'x': Unit.count,
    'g': Unit.g, 'gr': Unit.g, 'gram': Unit.g, 'grams': Unit.g,
    'kg': Unit.kg, 'kilo': Unit.kg, 'kilos': Unit.kg, 'kilogram': Unit.kg, 'kilograms': Unit.kg,
    'ml': Unit.ml, 'milliliter': Unit.ml, 'milliliters': Unit.ml, 'millilitre': Unit.ml, 'millilitres': Unit.ml,
    'l': Unit.l, 'liter': Unit.l, 'liters': Unit.l, 'litre': Unit.l, 'litres': Unit.l,
    'oz': Unit.oz, 'ounce': Unit.oz, 'ounces': Unit.oz,
    'lb': Unit.lb, 'lbs': Unit.lb, 'pound': Unit.lb, 'pounds': Unit.lb,
  };

  /// Tolerant parse for stored values and AI output; anything unknown is [count].
  static Unit parse(Object? raw) => tryParse(raw) ?? Unit.count;

  /// Like [parse] but null for units PantryPal doesn't model ("cup", "tbsp", "pinch"), so
  /// callers can keep the original text instead of mistaking it for a count.
  static Unit? tryParse(Object? raw) => _aliases['${raw ?? ''}'.trim().toLowerCase().replaceAll('.', '')];
}

/// Reads a package size such as "500 g", "1,5 L", "75 cl", "16 fl oz" or "6 x 330 ml".
/// Multipacks count as pieces (6 x 330 ml → ×6). Returns null when no size is recognised.
({double quantity, Unit unit})? parsePackageSize(String? raw) {
  final m = matchPackageSize(raw);
  return m == null ? null : (quantity: m.quantity, unit: m.unit);
}

/// Like [parsePackageSize], plus where the size text sits in [raw] (start inclusive, end exclusive).
({double quantity, Unit unit, int start, int end})? matchPackageSize(String? raw) {
  if (raw == null) return null;
  final s = raw.toLowerCase().replaceAll(',', '.'); // same length, so offsets map back to raw
  final multi = RegExp(r'(\d+)\s*[x×]\s*\d+(?:\.\d+)?\s*(?:fl\.?\s*oz|kg|mg|g|ml|cl|dl|lbs?|lt|l|oz)(?![a-z])').firstMatch(s);
  if (multi != null) {
    final n = double.parse(multi[1]!);
    return n > 0 ? (quantity: n, unit: Unit.count, start: multi.start, end: multi.end) : null;
  }
  final m = RegExp(r'(\d+(?:\.\d+)?)\s*(fl\.?\s*oz|kg|mg|g|ml|cl|dl|lbs?|lt|l|oz)(?![a-z])').firstMatch(s);
  if (m == null) return null;
  final v = double.parse(m[1]!);
  if (v <= 0) return null;
  double round(double x) => (x * 100).roundToDouble() / 100;
  final u = m[2]!.replaceAll(RegExp(r'[\s.]'), '');
  final ({double quantity, Unit unit})? size = switch (u) {
    'kg' => (quantity: round(v), unit: Unit.kg),
    'g' => (quantity: round(v), unit: Unit.g),
    'mg' => (quantity: round(v / 1000), unit: Unit.g),
    'ml' => (quantity: round(v), unit: Unit.ml),
    'cl' => (quantity: round(v * 10), unit: Unit.ml),
    'dl' => (quantity: round(v * 100), unit: Unit.ml),
    'l' || 'lt' => (quantity: round(v), unit: Unit.l),
    'floz' => (quantity: (v * 29.5735).roundToDouble(), unit: Unit.ml),
    'oz' => (quantity: round(v), unit: Unit.oz),
    'lb' || 'lbs' => (quantity: round(v), unit: Unit.lb),
    _ => null,
  };
  return size == null ? null : (quantity: size.quantity, unit: size.unit, start: m.start, end: m.end);
}

/// 2 → "2", 1.5 → "1.5", 0.333 → "0.33".
String formatNumber(double v) {
  if (v == v.roundToDouble()) return v.toInt().toString();
  return v.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
}

/// "×2" for counted items, "500 g" / "1.5 L" for measured ones.
String formatQuantity(double quantity, Unit unit) =>
    unit.isCount ? '×${formatNumber(quantity)}' : '${formatNumber(quantity)} ${unit.symbol}';
