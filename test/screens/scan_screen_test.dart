import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pantrypal/data/product_memory_db.dart';
import 'package:pantrypal/models/known_product.dart';
import 'package:pantrypal/models/pantry_item.dart';
import 'package:pantrypal/models/scan_mode.dart';
import 'package:pantrypal/models/unit.dart';
import 'package:pantrypal/screens/scan_screen.dart';
import 'package:pantrypal/services/product_lookup_service.dart';
import 'package:pantrypal/state/pantry_store.dart';
import 'package:pantrypal/widgets/quantity_field.dart';
import '../helpers.dart';
import '../state/pantry_store_test.dart' show FakeDb, FakeNotifs;

class FakeMemory implements ProductMemoryDb {
  final products = <KnownProduct>[];
  final remembered = <(PantryItem item, String? barcode, bool estimated)>[];

  KnownProduct? _find(bool Function(KnownProduct) test) {
    for (final p in products) {
      if (test(p)) return p;
    }
    return null;
  }

  @override
  Future<KnownProduct?> byBarcode(String code) async => _find((p) => p.barcode == code);
  @override
  Future<KnownProduct?> byName(String name) async => _find((p) => p.key == KnownProduct.keyFor(name));
  @override
  Future<List<KnownProduct>> all({int limit = 500}) async => [...products];
  @override
  Future<bool> forget(String name) async {
    final before = products.length;
    products.removeWhere((p) => p.key == KnownProduct.keyFor(name));
    return products.length < before;
  }

  @override
  Future<void> clear() async => products.clear();

  @override
  Future<int> importAll(Iterable<KnownProduct> incoming, {required bool replace}) async {
    if (replace) products.clear();
    var n = 0;
    for (final p in incoming) {
      products.removeWhere((x) => x.key == p.key);
      products.add(p);
      n++;
    }
    return n;
  }

  @override
  Future<ProductInfo?> cachedLookup(String code, {String? language, Duration? maxAge, DateTime? now}) async => null;
  @override
  Future<void> cacheLookup(String code, ProductInfo info, {String? language, DateTime? now}) async {}
  @override
  Future<void> remember(PantryItem item, {String? barcode, bool expiryEstimated = false, DateTime? now}) async {
    remembered.add((item, barcode, expiryEstimated));
  }
}

Future<(PantryStore, FakeMemory)> _pump(WidgetTester t, {List<KnownProduct> known = const []}) async {
  await t.binding.setSurfaceSize(const Size(800, 1400));
  addTearDown(() => t.binding.setSurfaceSize(null));
  final store = PantryStore(FakeDb(), FakeNotifs());
  final memory = FakeMemory()..products.addAll(known);
  await t.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: store),
      Provider<ProductMemoryDb>.value(value: memory),
    ],
    child: testApp(const ScanScreen(initialMode: ScanMode.manual)),
  ));
  await t.pumpAndSettle();
  return (store, memory);
}

/// The selected value, not find.text: a dropdown builds every item to measure its width.
String? _category(WidgetTester t) =>
    t.widget<DropdownButtonFormField<String>>(find.byKey(const Key('item-category'))).initialValue;
Unit _unit(WidgetTester t) => t.widget<UnitDropdown>(find.byType(UnitDropdown)).value;
String _nameText(WidgetTester t) => t.widget<TextField>(find.byKey(const Key('item-name'))).controller!.text;

void main() {
  testWidgets('typing a name suggests a category until one is picked', (t) async {
    await _pump(t);
    await t.enterText(find.byKey(const Key('item-name')), 'Whole milk');
    await t.pump();
    expect(_category(t), 'Dairy');
    await t.enterText(find.byKey(const Key('item-name')), 'Chicken breast');
    await t.pump();
    expect(_category(t), 'Meat');
  });

  testWidgets('autocomplete from earlier items fills category, unit, size and usual shelf life', (t) async {
    await _pump(t, known: const [
      KnownProduct(name: 'Oat milk', category: 'Dairy', unit: Unit.l, quantity: 1, shelfDays: 7),
      KnownProduct(name: 'Rice', category: 'Pantry', unit: Unit.kg, quantity: 2),
    ]);
    await t.enterText(find.byKey(const Key('item-name')), 'oat');
    await t.pumpAndSettle();
    expect(find.text('Rice'), findsNothing);
    await t.tap(find.text('Oat milk'));
    await t.pumpAndSettle();
    expect(_nameText(t), 'Oat milk');
    expect(_category(t), 'Dairy');
    expect(_unit(t), Unit.l);
    expect(find.textContaining('how long this usually lasts for you'), findsOneWidget);
    expect(find.text('Usually 7 days'), findsOneWidget);
  });

  testWidgets('Save and add another saves, teaches the memory, and clears the form', (t) async {
    final (store, memory) = await _pump(t);
    await t.enterText(find.byKey(const Key('item-name')), 'Eggs');
    await t.tap(find.text('+1 week'));
    await t.pump();
    await t.tap(find.text('Save and add another'));
    await t.pumpAndSettle();
    expect(store.items.single.name, 'Eggs');
    expect(memory.remembered.single.$1.name, 'Eggs');
    expect(memory.remembered.single.$3, isFalse); // a date the user picked counts as confirmed
    expect(_nameText(t), '');
    expect(find.text('Set expiration date'), findsOneWidget);
    expect(find.text('Saved Eggs'), findsOneWidget);
    expect(find.byType(ScanScreen), findsOneWidget); // still open for the next item
  });

  testWidgets('saving without a name explains why', (t) async {
    final (store, _) = await _pump(t);
    await t.tap(find.text('Save to pantry'));
    await t.pumpAndSettle();
    expect(find.text('Give the item a name first.'), findsOneWidget);
    expect(store.items, isEmpty);
  });
}
