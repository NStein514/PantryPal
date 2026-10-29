import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/categories.dart';
import '../models/pantry_item.dart';

class PantryDb {
  PantryDb({String? path}) : _path = path;
  final String? _path; // overridable for tests (inMemoryDatabasePath)
  Database? _db;

  /// v1: initial table. v2: `unit` column; `quantity` may hold decimals
  /// (SQLite stores 1.5 as REAL even in an INTEGER-affinity column).
  /// v3: expanded categories; items misfiled as drinks (barcode scans of plant-based food) and
  /// coarse "Pantry" items are re-filed once (see betterCategory).
  static const version = 3;

  static Future<void> _refile(Database db) async {
    for (final r in await db.query('items', columns: ['id', 'name', 'category'])) {
      final better = betterCategory(r['name'] as String, r['category'] as String);
      if (better != null) await db.update('items', {'category': better}, where: 'id = ?', whereArgs: [r['id']]);
    }
  }

  Future<Database> get _database async => _db ??= await openDatabase(
        _path ?? join(await getDatabasesPath(), 'pantrypal.db'),
        version: version,
        onCreate: (db, _) => db.execute('''
          CREATE TABLE items(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL, category TEXT NOT NULL,
            quantity REAL NOT NULL, unit TEXT NOT NULL DEFAULT 'count',
            expiry TEXT, added_at TEXT NOT NULL)'''),
        onUpgrade: (db, from, to) async {
          if (from < 2) await db.execute("ALTER TABLE items ADD COLUMN unit TEXT NOT NULL DEFAULT 'count'");
          if (from < 3) await _refile(db);
        },
      );

  Future<List<PantryItem>> all() async {
    final rows = await (await _database).query('items', orderBy: 'expiry IS NULL, expiry ASC');
    return rows.map(PantryItem.fromMap).toList();
  }

  Future<int> insert(PantryItem i) async => (await _database).insert('items', i.toMap()..remove('id'));

  Future<void> update(PantryItem i) async =>
      (await _database).update('items', i.toMap()..remove('id'), where: 'id = ?', whereArgs: [i.id]);

  Future<void> delete(int id) async => (await _database).delete('items', where: 'id = ?', whereArgs: [id]);
}
