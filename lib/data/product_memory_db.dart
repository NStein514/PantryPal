import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/categories.dart';
import '../models/known_product.dart';
import '../models/pantry_item.dart';
import '../models/unit.dart';
import '../services/product_lookup_service.dart';

/// Local memory of products the user has added (own SQLite file, never leaves the device).
/// Feeds barcode recognition, name autocomplete and "usually lasts" suggestions.
class ProductMemoryDb {
  ProductMemoryDb({String? path}) : _path = path;
  final String? _path; // overridable for tests (inMemoryDatabasePath)
  Database? _db;

  /// v1: known_products. v2: barcode_lookups (Open Food Facts results cached for offline rescans).
  /// v3: expanded categories. Cached lookups are dropped (they hold categories from the old
  /// rules, which filed rice as a drink) and remembered products are re-filed like the pantry.
  static const version = 3;

  Future<Database> get _database async => _db ??= await openDatabase(
        _path ?? join(await getDatabasesPath(), 'pantrypal_products.db'),
        version: version,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE known_products(
              key TEXT PRIMARY KEY, name TEXT NOT NULL, category TEXT NOT NULL,
              unit TEXT NOT NULL, quantity REAL NOT NULL, barcode TEXT,
              shelf_days INTEGER, uses INTEGER NOT NULL, last_used TEXT NOT NULL)''');
          await db.execute('CREATE INDEX known_products_barcode ON known_products(barcode)');
          await _createLookupCache(db);
        },
        onUpgrade: (db, from, to) async {
          if (from < 2) await _createLookupCache(db);
          if (from < 3) {
            await db.delete('barcode_lookups'); // re-fetched on the next scan, with the new rules
            for (final r in await db.query('known_products', columns: ['key', 'name', 'category'])) {
              final better = betterCategory(r['name'] as String, r['category'] as String);
              if (better != null) {
                await db.update('known_products', {'category': better}, where: 'key = ?', whereArgs: [r['key']]);
              }
            }
          }
        },
      );

  static Future<void> _createLookupCache(Database db) => db.execute('''
        CREATE TABLE barcode_lookups(
          code TEXT NOT NULL, language TEXT NOT NULL, name TEXT NOT NULL, category TEXT NOT NULL,
          brand TEXT, quantity REAL, unit TEXT, fetched_at TEXT NOT NULL,
          PRIMARY KEY (code, language))''');

  /// A cached Open Food Facts result for [code] in [language], or null.
  /// [maxAge] null accepts any age (used as an offline fallback).
  Future<ProductInfo?> cachedLookup(String code, {String? language, Duration? maxAge, DateTime? now}) async {
    final rows = await (await _database).query('barcode_lookups',
        where: 'code = ? AND language = ?', whereArgs: [code, language ?? ''], limit: 1);
    if (rows.isEmpty) return null;
    final r = rows.first;
    final fetched = DateTime.tryParse(r['fetched_at'] as String);
    if (maxAge != null && (fetched == null || (now ?? DateTime.now()).difference(fetched) > maxAge)) return null;
    final unit = r['unit'] as String?;
    return ProductInfo(
      name: r['name'] as String,
      category: r['category'] as String,
      brand: r['brand'] as String?,
      quantity: (r['quantity'] as num?)?.toDouble(),
      unit: unit == null ? null : Unit.parse(unit),
    );
  }

  Future<void> cacheLookup(String code, ProductInfo info, {String? language, DateTime? now}) async {
    await (await _database).insert(
      'barcode_lookups',
      {
        'code': code,
        'language': language ?? '',
        'name': info.name,
        'category': info.category,
        'brand': info.brand,
        'quantity': info.quantity,
        'unit': info.unit?.name,
        'fetched_at': (now ?? DateTime.now()).toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<KnownProduct?> byBarcode(String code) async {
    final rows = await (await _database).query('known_products', where: 'barcode = ?', whereArgs: [code], limit: 1);
    return rows.isEmpty ? null : KnownProduct.fromMap(rows.first);
  }

  Future<KnownProduct?> byName(String name) async {
    final rows = await (await _database)
        .query('known_products', where: 'key = ?', whereArgs: [KnownProduct.keyFor(name)], limit: 1);
    return rows.isEmpty ? null : KnownProduct.fromMap(rows.first);
  }

  /// Most-used first, then most recent; for autocomplete.
  Future<List<KnownProduct>> all({int limit = 500}) async => [
        for (final r in await (await _database)
            .query('known_products', orderBy: 'uses DESC, last_used DESC', limit: limit))
          KnownProduct.fromMap(r),
      ];

  /// Removes one remembered product (by name, case-insensitive). Returns whether it existed.
  Future<bool> forget(String name) async =>
      await (await _database).delete('known_products', where: 'key = ?', whereArgs: [KnownProduct.keyFor(name)]) > 0;

  /// Forgets everything: remembered products and cached barcode lookups. The pantry is untouched.
  Future<void> clear() async {
    final db = await _database;
    await db.transaction((tx) async {
      await tx.delete('known_products');
      await tx.delete('barcode_lookups');
    });
  }

  /// Restores remembered products from a backup (or an undo). With [replace] the current
  /// memory is cleared first and the backup wins barcode clashes. Otherwise products are
  /// merged: what this device already knows (name spelling, category, size, barcode, shelf
  /// life) is kept and only gaps are filled from the backup; use counts add up; and a
  /// barcode that already belongs to another product on this device stays with it.
  /// Returns how many products were imported.
  Future<int> importAll(Iterable<KnownProduct> products, {required bool replace}) async {
    final db = await _database;
    return db.transaction((tx) async {
      if (replace) await tx.delete('known_products');
      var n = 0;
      for (final p in products) {
        if (p.key.isEmpty) continue;
        final rows = await tx.query('known_products', where: 'key = ?', whereArgs: [p.key], limit: 1);
        final old = rows.isEmpty ? null : KnownProduct.fromMap(rows.first);
        var barcode = old?.barcode ?? p.barcode;
        if (barcode != null) {
          final owner = await tx.query('known_products',
              columns: ['key'], where: 'barcode = ? AND key != ?', whereArgs: [barcode, p.key], limit: 1);
          if (owner.isNotEmpty) {
            if (replace) {
              await tx.update('known_products', {'barcode': null}, where: 'barcode = ? AND key != ?', whereArgs: [barcode, p.key]);
            } else if (old?.barcode == null) {
              barcode = null; // merge: the device's own mapping wins
            }
          }
        }
        final a = old?.lastUsed, b = p.lastUsed;
        final merged = old == null
            ? KnownProduct(
                name: p.name.trim(),
                category: p.category,
                unit: p.unit,
                quantity: p.quantity,
                barcode: barcode,
                shelfDays: p.shelfDays,
                uses: p.uses,
                lastUsed: p.lastUsed)
            : KnownProduct(
                name: old.name,
                category: old.category,
                unit: old.unit,
                quantity: old.quantity,
                barcode: barcode,
                shelfDays: old.shelfDays ?? p.shelfDays,
                uses: old.uses + p.uses,
                lastUsed: a == null ? b : (b == null || a.isAfter(b) ? a : b));
        await tx.insert('known_products', merged.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
        n++;
      }
      return n;
    });
  }

  /// Records an added item. A confirmed (not estimated) expiry updates the usual shelf life,
  /// averaged with what was known. A [barcode] moves to this product if another one had it,
  /// so correcting a wrong name once fixes future scans.
  Future<void> remember(PantryItem item, {String? barcode, bool expiryEstimated = false, DateTime? now}) async {
    final key = KnownProduct.keyFor(item.name);
    if (key.isEmpty) return;
    final t = now ?? DateTime.now();
    final old = await byName(item.name);

    var shelf = old?.shelfDays;
    final e = item.expiry;
    if (e != null && !expiryEstimated) {
      final days = (DateTime(e.year, e.month, e.day).difference(DateTime(t.year, t.month, t.day)).inHours / 24).round();
      if (days > 0 && days <= 3650) shelf = shelf == null ? days : ((shelf + days) / 2).round();
    }
    final code = (barcode == null || barcode.isEmpty) ? old?.barcode : barcode;

    final db = await _database;
    await db.transaction((tx) async {
      if (code != null) {
        await tx.update('known_products', {'barcode': null}, where: 'barcode = ? AND key != ?', whereArgs: [code, key]);
      }
      await tx.insert(
        'known_products',
        KnownProduct(
          name: item.name.trim(),
          category: item.category,
          unit: item.unit,
          quantity: item.quantity,
          barcode: code,
          shelfDays: shelf,
          uses: (old?.uses ?? 0) + 1,
          lastUsed: t,
        ).toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }
}
