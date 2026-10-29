import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pantrypal/data/product_memory_db.dart';
import 'package:pantrypal/models/known_product.dart';
import 'package:pantrypal/models/unit.dart';
import 'package:pantrypal/screens/quick_list_screen.dart';
import 'package:pantrypal/state/pantry_store.dart';
import '../helpers.dart';
import '../state/pantry_store_test.dart' show FakeDb, FakeNotifs;
import 'scan_screen_test.dart' show FakeMemory;

void main() {
  testWidgets('type a list, review it, save it all', (t) async {
    await t.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final store = PantryStore(FakeDb(), FakeNotifs());
    final memory = FakeMemory()
      ..products.add(const KnownProduct(name: 'Flour', category: 'Pantry', unit: Unit.kg, quantity: 1));
    int? result;
    await t.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: store),
        Provider<ProductMemoryDb>.value(value: memory),
      ],
      child: testApp(Builder(
        builder: (ctx) => TextButton(
          onPressed: () async =>
              result = await Navigator.push<int>(ctx, MaterialPageRoute(builder: (_) => const QuickListScreen())),
          child: const Text('open'),
        ),
      )),
    ));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();

    await t.tap(find.text('Review'));
    await t.pumpAndSettle();
    expect(find.text('Type at least one item.'), findsOneWidget);

    await t.enterText(find.byKey(const Key('quick-list')), '2 x milk\nflour\neggs 12');
    await t.tap(find.text('Review'));
    await t.pumpAndSettle();
    expect(find.text('Add 3 items to pantry'), findsOneWidget);
    await t.tap(find.text('Add 3 items to pantry'));
    await t.pumpAndSettle();

    expect(result, 3);
    expect(store.items.map((i) => '${i.name} ${i.quantityLabel}'), ['Milk ×2', 'Flour 1 kg', 'Eggs ×12']);
  });
}
