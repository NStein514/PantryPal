import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantrypal/data/pantry_db.dart';
import 'package:pantrypal/models/pantry_item.dart';
import 'package:pantrypal/models/unit.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Integration tests against a real (in-memory) SQLite engine via FFI.
void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late PantryDb db;
  setUp(() => db = PantryDb(path: inMemoryDatabasePath));

  test('insert assigns ids and all() returns items soonest-expiry first, undated last', () async {
    await db.insert(PantryItem(name: 'Rice'));
    await db.insert(PantryItem(name: 'Cheese', expiry: DateTime(2026, 12, 1)));
    await db.insert(PantryItem(name: 'Milk', expiry: DateTime(2026, 11, 1)));
    final items = await db.all();
    expect(items.map((i) => i.name), ['Milk', 'Cheese', 'Rice']);
    expect(items.every((i) => i.id != null), isTrue);
    expect(items.last.expiry, isNull);
  });

  test('update changes a row in place', () async {
    final id = await db.insert(PantryItem(name: 'Eggs', quantity: 12));
    final item = (await db.all()).single;
    expect(item.id, id);
    await db.update(item.copyWith(quantity: 6, category: 'Dairy'));
    final after = (await db.all()).single;
    expect([after.quantity, after.category], [6, 'Dairy']);
  });

  test('delete removes only the targeted row', () async {
    final a = await db.insert(PantryItem(name: 'A'));
    await db.insert(PantryItem(name: 'B'));
    await db.delete(a);
    expect((await db.all()).map((i) => i.name), ['B']);
  });

  test('stores decimal quantities with a unit', () async {
    await db.insert(PantryItem(name: 'Flour', quantity: 1.25, unit: Unit.kg));
    final f = (await db.all()).single;
    expect([f.quantity, f.unit], [1.25, Unit.kg]);
  });

  test('upgrades a v1 database: adds unit, keeps rows as counted items', () async {
    final dir = Directory.systemTemp.createTempSync('pantrypal');
    final path = '${dir.path}/v1.db';
    final v1 = await databaseFactory.openDatabase(path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (d, _) => d.execute('CREATE TABLE items(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, '
              'category TEXT NOT NULL, quantity INTEGER NOT NULL, expiry TEXT, added_at TEXT NOT NULL)'),
        ));
    await v1.insert('items', {'name': 'Eggs', 'category': 'Dairy', 'quantity': 6, 'added_at': '2026-01-01T00:00:00.000'});
    await v1.close();

    final upgraded = PantryDb(path: path);
    final eggs = (await upgraded.all()).single;
    expect([eggs.name, eggs.quantity, eggs.unit], ['Eggs', 6, Unit.count]);
    await upgraded.insert(PantryItem(name: 'Milk', quantity: 1.5, unit: Unit.l));
    expect((await upgraded.all()).map((i) => i.quantityLabel), containsAll(['×6', '1.5 L']));
    dir.deleteSync(recursive: true);
  });

  test('upgrading to v3 re-files food misfiled as drinks and refines Pantry; nothing else changes', () async {
    final dir = Directory.systemTemp.createTempSync('pantrypal_v2');
    final path = '${dir.path}/v2.db';
    final v2 = await databaseFactory.openDatabase(path,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: (d, _) => d.execute('CREATE TABLE items(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, '
              "category TEXT NOT NULL, quantity REAL NOT NULL, unit TEXT NOT NULL DEFAULT 'count', expiry TEXT, added_at TEXT NOT NULL)"),
        ));
    const added = '2026-10-01T00:00:00.000';
    for (final (name, cat) in const [
      ('Long grain rice', 'Beverage'), ('Orange juice', 'Beverage'), ('Flour', 'Pantry'), ('Mystery jar', 'Pantry'),
      ('Whole milk', 'Dairy'), ('Rice', 'Produce'), // the user's own odd choice stays
    ]) {
      await v2.insert('items', {'name': name, 'category': cat, 'quantity': 1, 'added_at': added});
    }
    await v2.close();

    final upgraded = PantryDb(path: path);
    expect({for (final i in await upgraded.all()) i.name: i.category}, {
      'Long grain rice': 'Grains', 'Orange juice': 'Beverage', 'Flour': 'Baking', 'Mystery jar': 'Pantry',
      'Whole milk': 'Dairy', 'Rice': 'Produce',
    });
    dir.deleteSync(recursive: true);
  });
}
