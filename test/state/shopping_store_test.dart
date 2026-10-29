import 'package:flutter_test/flutter_test.dart';
import 'package:pantrypal/data/shopping_db.dart';
import 'package:pantrypal/models/shopping_item.dart';
import 'package:pantrypal/state/shopping_store.dart';

class FakeShoppingDb implements ShoppingDb {
  final rows = <ShoppingItem>[];
  int _next = 1;
  @override
  Future<List<ShoppingItem>> all() async =>
      [...rows.where((r) => !r.checked), ...rows.where((r) => r.checked)];
  @override
  Future<int> insert(ShoppingItem i) async {
    final id = _next++;
    rows.add(ShoppingItem(id: id, name: i.name));
    return id;
  }
  @override
  Future<void> setChecked(int id, bool checked) async {
    final k = rows.indexWhere((r) => r.id == id);
    rows[k] = ShoppingItem(id: id, name: rows[k].name, checked: checked);
  }
  @override
  Future<void> delete(int id) async => rows.removeWhere((r) => r.id == id);
  @override
  Future<void> deleteChecked() async => rows.removeWhere((r) => r.checked);
}

void main() {
  late ShoppingStore store;
  setUp(() => store = ShoppingStore(FakeShoppingDb()));

  test('addAll trims, ignores blanks, and dedupes case-insensitively', () async {
    expect(await store.addAll([' Basil ', 'basil', '', 'Tomatoes']), 2);
    expect(store.items.map((i) => i.name), ['Basil', 'Tomatoes']);
    expect(await store.addAll(['BASIL']), 0);
  });

  test('toggle checks and unchecks; checked items sort last', () async {
    await store.addAll(['A', 'B']);
    await store.toggle(store.items.first);
    expect(store.items.map((i) => i.name), ['B', 'A']);
    expect(store.checked.single.name, 'A');
    await store.toggle(store.checked.single);
    expect(store.checked, isEmpty);
  });

  test('remove and clearChecked', () async {
    await store.addAll(['A', 'B', 'C']);
    await store.remove(store.items.first);
    await store.toggle(store.items.first);
    await store.clearChecked();
    expect(store.items.map((i) => i.name), ['C']);
  });

  test('restore keeps ticks for new names, skips duplicates, and can replace', () async {
    await store.addAll(['Milk']);
    final n = await store.restore(
        const [ShoppingItem(name: 'milk'), ShoppingItem(name: 'Eggs', checked: true), ShoppingItem(name: 'Jam')],
        replace: false);
    expect(n, 2);
    expect(store.items.map((i) => '${i.name}:${i.checked}'), ['Milk:false', 'Jam:false', 'Eggs:true']);
    await store.restore(const [ShoppingItem(name: 'Tea')], replace: true);
    expect(store.items.map((i) => i.name), ['Tea']);
  });
}
