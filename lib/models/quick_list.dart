import 'categories.dart';
import 'known_product.dart';
import 'scan_draft.dart';
import 'unit.dart';

/// Parses a typed list ("2 x milk", "flour 1 kg", "eggs 12", one per line or comma-separated)
/// into review drafts. Products the user has added before ([known], keyed by
/// [KnownProduct.keyFor]) supply their usual name spelling, category, size and shelf life.
List<ScanDraft> parseQuickList(String text, {Map<String, KnownProduct> known = const {}, DateTime? today}) {
  final now = today ?? DateTime.now();
  // Split on newlines, semicolons and commas, but not decimal commas ("1,5 kg").
  final entries = text.split(RegExp(r'\n|;|(?<!\d),|,(?!\d)'));
  final drafts = <ScanDraft>[];
  for (final raw in entries) {
    var s = raw.trim().replaceFirst(RegExp(r'^[-*•·]\s*'), '').trim();
    if (s.isEmpty) continue;

    // 1. Pack size anywhere in the entry ("flour 1 kg", "500 g butter", "6 x 330 ml cola").
    final size = matchPackageSize(s);
    if (size != null) s = '${s.substring(0, size.start)} ${s.substring(size.end)}'.replaceAll(RegExp(r'\s+'), ' ').trim();

    // 2. A count: "2 x milk", "2 milk", "milk x2", "milk 2x", "eggs 12", "milk (2)",
    //    or a dozen ("1 dozen eggs", "docena de huevos", "Dutzend Eier", "douzaine d'œufs").
    var count = 1;
    final dozen = RegExp(r"^(?:(\d{1,2})\s+)?(?:dozen|docenas?|dutzend|douzaines?)(?:\s+(?:of|de|d'))?\s*(.+)$",
            caseSensitive: false)
        .firstMatch(s);
    final lead = RegExp(r'^(\d{1,3})\s*[x×]?\s+(.+)$').firstMatch(s);
    final trail = RegExp(r'^(.+?)\s+(?:[x×]\s*)?(\d{1,3})(?:\s*[x×])?$').firstMatch(s);
    final paren = RegExp(r'^(.+?)\s*\((\d{1,3})\)$').firstMatch(s);
    if (dozen != null) {
      count = 12 * (dozen[1] == null ? 1 : int.parse(dozen[1]!));
      s = dozen[2]!.trim();
    } else if (lead != null) {
      count = int.parse(lead[1]!);
      s = lead[2]!.trim();
    } else if (paren != null) {
      count = int.parse(paren[2]!);
      s = paren[1]!.trim();
    } else if (trail != null) {
      count = int.parse(trail[2]!);
      s = trail[1]!.trim();
    }
    if (count < 1) count = 1;
    if (s.isEmpty) continue;

    final k = known[KnownProduct.keyFor(s)];
    final name = k?.name ?? '${s[0].toUpperCase()}${s.substring(1)}';
    final double quantity;
    final Unit unit;
    if (size != null) {
      quantity = size.quantity * count; // 2 x "1 kg" = 2 kg; 2 x "6 x 330 ml" = ×12
      unit = size.unit;
    } else if (k != null && !k.unit.isCount) {
      quantity = k.quantity * count; // "flour" with flour usually 1 kg
      unit = k.unit;
    } else {
      quantity = count.toDouble();
      unit = Unit.count;
    }
    final shelf = k?.shelfDays;
    drafts.add(ScanDraft(
      name: name,
      category: k?.category ?? guessCategory(name) ?? 'Other',
      quantity: quantity,
      unit: unit,
      expiry: shelf == null ? null : DateTime(now.year, now.month, now.day + shelf),
      expiryEstimated: shelf != null,
    ));
  }
  return drafts;
}
