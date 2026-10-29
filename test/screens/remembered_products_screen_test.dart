import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pantrypal/data/product_memory_db.dart';
import 'package:pantrypal/models/known_product.dart';
import 'package:pantrypal/models/unit.dart';
import 'package:pantrypal/screens/remembered_products_screen.dart';
import '../helpers.dart';
import 'scan_screen_test.dart' show FakeMemory;

Future<FakeMemory> _pump(WidgetTester t, List<KnownProduct> products) async {
  final memory = FakeMemory()..products.addAll(products);
  await t.pumpWidget(Provider<ProductMemoryDb>.value(
    value: memory,
    child: testApp(const RememberedProductsScreen()),
  ));
  await t.pumpAndSettle();
  return memory;
}

void main() {
  const jam = KnownProduct(name: 'Jam', category: 'Pantry');
  const milk = KnownProduct(name: 'Oat milk', category: 'Dairy', unit: Unit.l, quantity: 1, shelfDays: 7, barcode: '123');

  testWidgets('explains itself when nothing is remembered', (t) async {
    await _pump(t, const []);
    expect(find.textContaining('Nothing remembered yet'), findsOneWidget);
    expect(find.byTooltip('Forget all'), findsNothing);
  });

  testWidgets('lists what was learned and filters by search', (t) async {
    await _pump(t, const [jam, milk]);
    expect(find.text('2 remembered products'), findsOneWidget);
    expect(find.textContaining('Usually 7 days'), findsOneWidget);
    expect(find.textContaining('Barcode 123'), findsOneWidget);
    await t.enterText(find.byType(TextField), 'oat');
    await t.pump();
    expect(find.text('Oat milk'), findsOneWidget);
    expect(find.text('Jam'), findsNothing);
  });

  testWidgets('forget one product, then undo', (t) async {
    final memory = await _pump(t, const [jam, milk]);
    await t.tap(find.byTooltip('Forget').first);
    await t.pumpAndSettle();
    expect(memory.products.map((p) => p.name), ['Oat milk']);
    expect(find.text('Forgot Jam'), findsOneWidget);
    await t.tap(find.text('Undo'));
    await t.pumpAndSettle();
    expect(memory.products.map((p) => p.name).toSet(), {'Jam', 'Oat milk'});
    expect(find.text('Jam'), findsOneWidget);
  });

  testWidgets('Forget all asks first, then empties the memory', (t) async {
    final memory = await _pump(t, const [jam, milk]);
    await t.tap(find.byTooltip('Forget all'));
    await t.pumpAndSettle();
    await t.tap(find.text('Cancel'));
    await t.pumpAndSettle();
    expect(memory.products, hasLength(2));
    await t.tap(find.byTooltip('Forget all'));
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(FilledButton, 'Forget all'));
    await t.pumpAndSettle();
    expect(memory.products, isEmpty);
    expect(find.textContaining('Nothing remembered yet'), findsOneWidget);
  });
}
