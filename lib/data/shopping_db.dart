import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/shopping_item.dart';

class ShoppingDb {
  ShoppingDb({String? path}) : _path = path;
  final String? _path;
  Database? _db;

  Future<Database> get _database async => _db ??= await openDatabase(
        _path ?? join(await getDatabasesPath(), 'pantrypal_shopping.db'),
        version: 1,
        onCreate: (db, _) => db.execute('''
          CREATE TABLE shopping(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            checked INTEGER NOT NULL DEFAULT 0)'''),
      );

  /// Unchecked items first, then in insertion order.
  Future<List<ShoppingItem>> all() async =>
      (await (await _database).query('shopping', orderBy: 'checked ASC, id ASC')).map(ShoppingItem.fromMap).toList();

  Future<int> insert(ShoppingItem i) async => (await _database).insert('shopping', {'name': i.name, 'checked': 0});

  Future<void> setChecked(int id, bool checked) async =>
      (await _database).update('shopping', {'checked': checked ? 1 : 0}, where: 'id = ?', whereArgs: [id]);

  Future<void> delete(int id) async => (await _database).delete('shopping', where: 'id = ?', whereArgs: [id]);

  Future<void> deleteChecked() async => (await _database).delete('shopping', where: 'checked = 1');
}
