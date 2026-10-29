import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pantrypal/data/product_memory_db.dart';
import 'package:pantrypal/models/pantry_item.dart';
import 'package:pantrypal/models/unit.dart';
import 'package:pantrypal/services/batch_scan.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pantrypal/services/product_lookup_service.dart';

void main() {
  test('builds drafts in scan order with counts; unknown and failed lookups stay unnamed', () async {
    final lookup = ProductLookupService(client: MockClient((req) async {
      if (req.url.path.contains('111')) {
        return http.Response(
            jsonEncode({'status': 1, 'product': {'product_name': 'Oat milk', 'categories_tags': ['en:milks']}}), 200);
      }
      if (req.url.path.contains('222')) return http.Response('{"status":0}', 200);
      throw http.ClientException('offline');
    }));
    final drafts = await draftsFromBarcodes({'111': 2, '222': 1, '333': 1}, lookup);
    expect(drafts.map((d) => d.barcode), ['111', '222', '333']);
    expect([drafts[0].name, drafts[0].category, drafts[0].quantity, drafts[0].include], ['Oat milk', 'Dairy', 2, true]);
    expect([drafts[1].name, drafts[1].include], ['', false]);
    expect([drafts[2].name, drafts[2].include], ['', false]);
  });

  test('remembered barcodes skip the network and bring their usual size and shelf life', () async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final memory = ProductMemoryDb(path: inMemoryDatabasePath);
    final today = DateTime(2026, 10, 28);
    await memory.remember(PantryItem(name: 'Flour', category: 'Pantry', quantity: 1, unit: Unit.kg, expiry: DateTime(2027, 4, 26)),
        barcode: '111', now: today);
    var calls = 0;
    final lookup = ProductLookupService(client: MockClient((req) async {
      calls++;
      return http.Response(
          jsonEncode({'status': 1, 'product': {'product_name': 'Cola', 'quantity': '6 x 330 ml', 'categories_tags': ['en:sodas']}}), 200);
    }));
    final drafts = await draftsFromBarcodes({'111': 2, '222': 2}, lookup, memory: memory, today: today);
    expect(calls, 1); // only the unknown code went online
    expect([drafts[0].name, drafts[0].quantityLabel, drafts[0].expiry, drafts[0].expiryEstimated],
        ['Flour', '2 kg', DateTime(2027, 4, 26), true]);
    expect([drafts[1].name, drafts[1].quantityLabel], ['Cola', '×12']); // 6-pack scanned twice
  });

  group('lookupWithCache', () {
    late ProductMemoryDb memory;
    final now = DateTime(2026, 10, 28);
    setUp(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      memory = ProductMemoryDb(path: inMemoryDatabasePath);
    });
    http.Response found(String name) => http.Response(jsonEncode({'status': 1, 'product': {'product_name': name}}), 200);

    test('caches a network answer and reuses it without the network', () async {
      var calls = 0;
      final lookup = ProductLookupService(client: MockClient((_) async {
        calls++;
        return found('Crackers');
      }));
      expect((await lookupWithCache('1', lookup, memory: memory, now: now))!.name, 'Crackers');
      expect((await lookupWithCache('1', lookup, memory: memory, now: now))!.name, 'Crackers');
      expect(calls, 1);
    });

    test('offline: an old cached answer beats an error; nothing cached rethrows', () async {
      await memory.cacheLookup('2', const ProductInfo(name: 'Old tea', category: 'Beverage'),
          now: now.subtract(const Duration(days: 400)));
      final offline = ProductLookupService(client: MockClient((_) async => throw http.ClientException('offline')));
      expect((await lookupWithCache('2', offline, memory: memory, now: now))!.name, 'Old tea');
      await expectLater(lookupWithCache('3', offline, memory: memory, now: now), throwsA(isA<http.ClientException>()));
    });

    test('a stale answer is refreshed when online', () async {
      await memory.cacheLookup('4', const ProductInfo(name: 'Old name', category: 'Other'),
          now: now.subtract(const Duration(days: 400)));
      final lookup = ProductLookupService(client: MockClient((_) async => found('New name')));
      expect((await lookupWithCache('4', lookup, memory: memory, now: now))!.name, 'New name');
    });
  });
}
