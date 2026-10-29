import '../data/product_memory_db.dart';
import '../models/known_product.dart';
import '../models/unit.dart';
import '../models/scan_draft.dart';
import 'product_lookup_service.dart';

/// How long an Open Food Facts answer is trusted before asking again.
const lookupCacheMaxAge = Duration(days: 90);

/// Open Food Facts lookup through the local cache in [memory]:
/// a fresh cached answer skips the network; a successful lookup is cached; and when the
/// network fails, an older cached answer is used rather than failing (offline rescans).
/// Network errors are rethrown only when nothing is cached.
Future<ProductInfo?> lookupWithCache(
  String code,
  ProductLookupService lookup, {
  ProductMemoryDb? memory,
  String? language,
  DateTime? now,
}) async {
  Future<ProductInfo?> cached(Duration? maxAge) async {
    try {
      return await memory?.cachedLookup(code, language: language, maxAge: maxAge, now: now);
    } catch (_) {
      return null;
    }
  }

  final fresh = await cached(lookupCacheMaxAge);
  if (fresh != null) return fresh;
  try {
    final info = await lookup.lookup(code, language: language);
    if (info != null) {
      try {
        await memory?.cacheLookup(code, info, language: language, now: now);
      } catch (_) {}
    }
    return info;
  } catch (_) {
    final stale = await cached(null);
    if (stale != null) return stale;
    rethrow;
  }
}

/// Turns a barcode run ({code: times scanned}) into review drafts.
///
/// Each code is checked against the user's own [memory] first (instant, works offline, knows
/// products Open Food Facts doesn't), then looked up online. Lookups run in parallel.
/// Unknown products (or lookup failures) become unnamed, unticked drafts that keep their
/// barcode, so naming one teaches the memory for next time.
Future<List<ScanDraft>> draftsFromBarcodes(
  Map<String, int> codes,
  ProductLookupService lookup, {
  ProductMemoryDb? memory,
  String? language,
  DateTime? today,
}) =>
    Future.wait([for (final e in codes.entries) _draft(e.key, e.value, lookup, memory, language, today)]);

Future<ScanDraft> _draft(
    String code, int count, ProductLookupService lookup, ProductMemoryDb? memory, String? language, DateTime? today) async {
  KnownProduct? known;
  try {
    known = await memory?.byBarcode(code);
  } catch (_) {
    known = null;
  }
  if (known != null) return ScanDraft.fromKnown(known, count: count, barcode: code, today: today);

  ProductInfo? info;
  try {
    info = await lookupWithCache(code, lookup, memory: memory, language: language, now: today);
  } catch (_) {
    info = null; // offline or bad response: treat as not found
  }
  final unit = info?.unit;
  final size = info?.quantity;
  if (info == null) return ScanDraft(quantity: count.toDouble(), barcode: code);
  return ScanDraft(
    name: info.name,
    category: info.category,
    // A measured pack (500 g) scanned twice is 1000 g; a multipack (×6) scanned twice is ×12.
    unit: unit ?? Unit.count,
    quantity: unit == null || size == null ? count.toDouble() : size * count,
    barcode: code,
  );
}
