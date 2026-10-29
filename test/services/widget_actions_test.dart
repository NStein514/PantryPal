import 'package:flutter_test/flutter_test.dart';
import 'package:pantrypal/models/pantry_item.dart';
import 'package:pantrypal/models/unit.dart';
import 'package:pantrypal/models/widget_action.dart';
import 'package:pantrypal/services/widget_actions.dart';
import 'package:pantrypal/state/pantry_store.dart';
import '../state/pantry_store_test.dart' show FakeDb, FakeNotifs;

void main() {
  late PantryStore store;
  setUp(() async {
    store = PantryStore(FakeDb(), FakeNotifs());
    await store.add(PantryItem(name: 'Eggs', quantity: 2, expiry: DateTime(2030, 1, 1))); // id 1
    await store.add(PantryItem(name: 'Flour', quantity: 1, unit: Unit.kg)); // id 2
  });

  test('used one from the widget decrements, then removes at zero', () async {
    expect(await applyWidgetAction(store, const WidgetAction.useOne(1)), isTrue);
    expect(store.items.first.quantityLabel, '×1');
    expect(await applyWidgetAction(store, const WidgetAction.useOne(1)), isTrue);
    expect(store.items.map((i) => i.name), ['Flour']);
  });

  test('measured items and unknown ids are left alone', () async {
    expect(await applyWidgetAction(store, const WidgetAction.useOne(2)), isFalse); // "used one" kg of flour?
    expect(await applyWidgetAction(store, const WidgetAction.useOne(99)), isFalse); // already gone
    expect(store.items.map((i) => i.quantityLabel), ['×2', '1 kg']);
  });
}
