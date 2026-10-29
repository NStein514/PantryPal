import 'package:flutter_test/flutter_test.dart';
import 'package:pantrypal/data/shopping_db.dart';
import 'package:pantrypal/models/shopping_item.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late ShoppingDb db;
  setUp(() => db = ShoppingDb(path: inMemoryDatabasePath));

  test('all() lists unchecked first, then insertion order', () async {
    final a = await db.insert(const ShoppingItem(name: 'A'));
    await db.insert(const ShoppingItem(name: 'B'));
    await db.setChecked(a, true);
    expect((await db.all()).map((i) => i.name), ['B', 'A']);
    expect((await db.all()).last.checked, isTrue);
  });

  test('setChecked can uncheck again', () async {
    final id = await db.insert(const ShoppingItem(name: 'A'));
    await db.setChecked(id, true);
    await db.setChecked(id, false);
    expect((await db.all()).single.checked, isFalse);
  });

  test('delete and deleteChecked', () async {
    final a = await db.insert(const ShoppingItem(name: 'A'));
    final b = await db.insert(const ShoppingItem(name: 'B'));
    await db.insert(const ShoppingItem(name: 'C'));
    await db.delete(a);
    await db.setChecked(b, true);
    await db.deleteChecked();
    expect((await db.all()).map((i) => i.name), ['C']);
  });
}
