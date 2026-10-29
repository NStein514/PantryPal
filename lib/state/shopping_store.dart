import 'package:flutter/foundation.dart';
import '../data/shopping_db.dart';
import '../models/shopping_item.dart';

class ShoppingStore extends ChangeNotifier {
  ShoppingStore(this._db);
  final ShoppingDb _db;
  List<ShoppingItem> items = [];

  List<ShoppingItem> get checked => items.where((i) => i.checked).toList();

  Future<void> load() async {
    items = await _db.all();
    notifyListeners();
  }

  /// Adds names not already on the list (case-insensitive, trimmed). Returns how many were added.
  Future<int> addAll(Iterable<String> names) async {
    final have = items.map((i) => i.name.toLowerCase()).toSet();
    var added = 0;
    for (final raw in names) {
      final name = raw.trim();
      if (name.isEmpty || !have.add(name.toLowerCase())) continue;
      await _db.insert(ShoppingItem(name: name));
      added++;
    }
    if (added > 0) await load();
    return added;
  }

  Future<void> toggle(ShoppingItem i) async {
    await _db.setChecked(i.id!, !i.checked);
    await load();
  }

  Future<void> remove(ShoppingItem i) async {
    await _db.delete(i.id!);
    await load();
  }

  /// Restores a backed-up list. With [replace], the current list is cleared first.
  /// Names already on the list are skipped; ticked state from the backup is kept for new entries.
  Future<int> restore(Iterable<ShoppingItem> backup, {required bool replace}) async {
    if (replace) {
      for (final i in [...items]) {
        await _db.delete(i.id!);
      }
      await load();
    }
    final before = items.map((i) => i.id).toSet();
    final added = await addAll(backup.map((b) => b.name));
    final ticked = {for (final b in backup) if (b.checked) b.name.trim().toLowerCase()};
    var changed = false;
    for (final i in items.where((i) => !before.contains(i.id) && ticked.contains(i.name.toLowerCase()))) {
      await _db.setChecked(i.id!, true);
      changed = true;
    }
    if (changed || (replace && added == 0)) await load();
    return added;
  }

  Future<void> clearChecked() async {
    await _db.deleteChecked();
    await load();
  }
}
