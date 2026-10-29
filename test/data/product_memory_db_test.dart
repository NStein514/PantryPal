import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantrypal/data/product_memory_db.dart';
import 'package:pantrypal/models/known_product.dart';
import 'package:pantrypal/models/pantry_item.dart';
import 'package:pantrypal/models/unit.dart';
import 'package:pantrypal/services/product_lookup_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late ProductMemoryDb db;
  final today = DateTime(2026, 10, 28, 15);
  setUp(() => db = ProductMemoryDb(path: inMemoryDatabasePath));

  test('remembers category, unit, size and barcode; names match case-insensitively', () async {
    await db.remember(PantryItem(name: 'Oat Milk', category: 'Dairy', quantity: 1, unit: Unit.l), barcode: '123', now: today);
    final k = (await db.byName('  oat   milk '))!;
    expect([k.name, k.category, k.unit, k.quantity, k.barcode, k.uses], ['Oat Milk', 'Dairy', Unit.l, 1, '123', 1]);
    expect((await db.byBarcode('123'))!.name, 'Oat Milk');
    expect(await db.byBarcode('999'), isNull);
  });

  test('confirmed expiry dates teach the usual shelf life (averaged); estimates do not', () async {
    await db.remember(PantryItem(name: 'Milk', expiry: DateTime(2026, 11, 4)), now: today); // 7 days
    expect((await db.byName('Milk'))!.shelfDays, 7);
    await db.remember(PantryItem(name: 'Milk', expiry: DateTime(2026, 11, 8)), now: today); // 11 days
    expect((await db.byName('Milk'))!.shelfDays, 9);
    await db.remember(PantryItem(name: 'Milk', expiry: DateTime(2027, 1, 1)), expiryEstimated: true, now: today);
    final m = (await db.byName('Milk'))!;
    expect([m.shelfDays, m.uses], [9, 3]);
  });

  test('a barcode moves to the product it was last saved with', () async {
    await db.remember(PantryItem(name: 'Mystery'), barcode: '555', now: today);
    await db.remember(PantryItem(name: 'Crackers', category: 'Pantry'), barcode: '555', now: today);
    expect((await db.byBarcode('555'))!.name, 'Crackers');
    expect((await db.byName('Mystery'))!.barcode, isNull);
  });

  test('saving without a barcode keeps the known one', () async {
    await db.remember(PantryItem(name: 'Jam'), barcode: '777', now: today);
    await db.remember(PantryItem(name: 'Jam', quantity: 2), now: today);
    expect((await db.byName('Jam'))!.barcode, '777');
  });

  test('all() lists most-used first', () async {
    await db.remember(PantryItem(name: 'A'), now: today);
    await db.remember(PantryItem(name: 'B'), now: today);
    await db.remember(PantryItem(name: 'B'), now: today);
    expect((await db.all()).map((k) => k.name), ['B', 'A']);
  });

  group('barcode lookup cache', () {
    const info = ProductInfo(name: 'Oat milk', category: 'Dairy', brand: 'Oaty', quantity: 1, unit: Unit.l);

    test('round-trips per language and respects max age', () async {
      await db.cacheLookup('123', info, language: 'en', now: today);
      final hit = (await db.cachedLookup('123', language: 'en', maxAge: const Duration(days: 90), now: today))!;
      expect([hit.name, hit.brand, hit.quantity, hit.unit], ['Oat milk', 'Oaty', 1, Unit.l]);
      expect(await db.cachedLookup('123', language: 'es', now: today), isNull);
      final later = today.add(const Duration(days: 120));
      expect(await db.cachedLookup('123', language: 'en', maxAge: const Duration(days: 90), now: later), isNull);
      expect(await db.cachedLookup('123', language: 'en', now: later), isNotNull); // any age
    });
  });

  test('upgrades a v1 memory database by adding the lookup cache', () async {
    final dir = Directory.systemTemp.createTempSync('pantrypal_mem');
    final path = '${dir.path}/v1.db';
    final v1 = await databaseFactory.openDatabase(path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (d, _) => d.execute('CREATE TABLE known_products(key TEXT PRIMARY KEY, name TEXT NOT NULL, '
              'category TEXT NOT NULL, unit TEXT NOT NULL, quantity REAL NOT NULL, barcode TEXT, '
              'shelf_days INTEGER, uses INTEGER NOT NULL, last_used TEXT NOT NULL)'),
        ));
    await v1.insert('known_products', {
      'key': 'jam', 'name': 'Jam', 'category': 'Pantry', 'unit': 'count', 'quantity': 1, 'uses': 1,
      'last_used': '2026-10-01T00:00:00.000',
    });
    await v1.close();

    final upgraded = ProductMemoryDb(path: path);
    expect((await upgraded.byName('jam'))!.name, 'Jam');
    await upgraded.cacheLookup('9', const ProductInfo(name: 'Tea', category: 'Beverage'), now: today);
    expect((await upgraded.cachedLookup('9', now: today))!.name, 'Tea');
    dir.deleteSync(recursive: true);
  });

  group('forget, clear and import', () {
    test('forget one product (case-insensitive) or clear everything incl. the lookup cache', () async {
      await db.remember(PantryItem(name: 'Jam'), now: today);
      await db.remember(PantryItem(name: 'Tea'), now: today);
      await db.cacheLookup('1', const ProductInfo(name: 'X', category: 'Other'), now: today);
      expect(await db.forget(' JAM '), isTrue);
      expect(await db.forget('Jam'), isFalse);
      expect((await db.all()).map((k) => k.name), ['Tea']);
      await db.clear();
      expect(await db.all(), isEmpty);
      expect(await db.cachedLookup('1', now: today), isNull);
    });

    test('merge keeps what the device knows, fills gaps, adds up uses', () async {
      await db.remember(PantryItem(name: 'Milk', category: 'Dairy', quantity: 1, unit: Unit.l), now: today);
      final n = await db.importAll([
        KnownProduct(name: 'MILK', category: 'Beverage', unit: Unit.ml, quantity: 500, barcode: '111', shelfDays: 8, uses: 3,
            lastUsed: DateTime(2026, 1, 1)),
        KnownProduct(name: 'Rice', category: 'Pantry', unit: Unit.kg, quantity: 2, uses: 2, lastUsed: DateTime(2026, 9, 1)),
      ], replace: false);
      expect(n, 2);
      final milk = (await db.byName('milk'))!;
      expect([milk.name, milk.category, milk.unit, milk.barcode, milk.shelfDays, milk.uses, milk.lastUsed],
          ['Milk', 'Dairy', Unit.l, '111', 8, 4, today]);
      expect((await db.byName('rice'))!.quantity, 2);
    });

    test('merge: a barcode the device already uses for another product stays there', () async {
      await db.remember(PantryItem(name: 'Crackers'), barcode: '555', now: today);
      await db.importAll([const KnownProduct(name: 'Biscuits', barcode: '555')], replace: false);
      expect((await db.byBarcode('555'))!.name, 'Crackers');
      expect((await db.byName('Biscuits'))!.barcode, isNull);
    });

    test('replace wipes the memory first; the backup wins barcode clashes', () async {
      await db.remember(PantryItem(name: 'Old thing'), barcode: '555', now: today);
      await db.importAll(const [KnownProduct(name: 'A', barcode: '555'), KnownProduct(name: 'B', barcode: '555')],
          replace: true);
      expect((await db.all()).map((k) => k.name).toSet(), {'A', 'B'});
      expect((await db.byBarcode('555'))!.name, 'B'); // later entry wins within the backup
      expect((await db.byName('A'))!.barcode, isNull);
    });
  });

  test('upgrading to v3 drops cached lookups (old rules) and re-files remembered drinks that are food', () async {
    final dir = Directory.systemTemp.createTempSync('pantrypal_mem_v2');
    final path = '${dir.path}/v2.db';
    final v2 = await databaseFactory.openDatabase(path,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: (d, _) async {
            await d.execute('CREATE TABLE known_products(key TEXT PRIMARY KEY, name TEXT NOT NULL, category TEXT NOT NULL, '
                'unit TEXT NOT NULL, quantity REAL NOT NULL, barcode TEXT, shelf_days INTEGER, uses INTEGER NOT NULL, last_used TEXT NOT NULL)');
            await d.execute('CREATE TABLE barcode_lookups(code TEXT NOT NULL, language TEXT NOT NULL, name TEXT NOT NULL, '
                'category TEXT NOT NULL, brand TEXT, quantity REAL, unit TEXT, fetched_at TEXT NOT NULL, PRIMARY KEY (code, language))');
          },
        ));
    await v2.insert('known_products', {'key': 'rice', 'name': 'Rice', 'category': 'Beverage', 'unit': 'kg', 'quantity': 1,
        'barcode': '123', 'uses': 2, 'last_used': '2026-10-01T00:00:00.000'});
    await v2.insert('barcode_lookups', {'code': '123', 'language': 'en', 'name': 'Rice', 'category': 'Beverage',
        'fetched_at': '2026-10-27T00:00:00.000'});
    await v2.close();

    final upgraded = ProductMemoryDb(path: path);
    expect(await upgraded.cachedLookup('123', language: 'en', now: today), isNull);
    final rice = (await upgraded.byBarcode('123'))!;
    expect([rice.category, rice.uses, rice.barcode], ['Grains', 2, '123']);
    dir.deleteSync(recursive: true);
  });
}
