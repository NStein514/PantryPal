import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pantrypal/screens/shopping_screen.dart';
import 'package:pantrypal/state/pantry_store.dart';
import 'package:pantrypal/state/shopping_store.dart';
import '../helpers.dart';
import '../state/pantry_store_test.dart' show FakeDb, FakeNotifs;
import '../state/shopping_store_test.dart' show FakeShoppingDb;

void main() {
  testWidgets('add, check, and move to pantry', (t) async {
    final shop = ShoppingStore(FakeShoppingDb());
    final pantry = PantryStore(FakeDb(), FakeNotifs());
    await t.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: shop),
        ChangeNotifierProvider.value(value: pantry),
      ],
      child: testApp(const ShoppingScreen()),
    ));
    expect(find.text('Your list is empty.'), findsOneWidget);

    await t.enterText(find.byType(TextField), 'Basil');
    await t.tap(find.byIcon(Icons.add));
    await t.pumpAndSettle();
    expect(find.text('Basil'), findsOneWidget);
    expect(find.text('To pantry'), findsNothing);

    await t.tap(find.byType(CheckboxListTile));
    await t.pumpAndSettle();
    await t.tap(find.text('To pantry'));
    await t.pumpAndSettle();

    expect(pantry.items.single.name, 'Basil');
    expect(shop.items, isEmpty);
  });
}
