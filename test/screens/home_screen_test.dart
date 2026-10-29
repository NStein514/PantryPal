import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pantrypal/models/pantry_item.dart';
import 'package:pantrypal/models/unit.dart';
import 'package:pantrypal/screens/home_screen.dart';
import 'package:pantrypal/state/pantry_store.dart';
import '../helpers.dart';
import '../state/pantry_store_test.dart' show FakeDb, FakeNotifs;

Future<void> _pump(WidgetTester t, PantryStore store) async {
  await t.pumpWidget(ChangeNotifierProvider.value(
    value: store,
    child: testApp(const HomeScreen()),
  ));
  await t.pumpAndSettle();
}

DateTime _inDays(int d) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day + d);
}

void main() {
  testWidgets('shows the empty state', (t) async {
    await _pump(t, PantryStore(FakeDb(), FakeNotifs()));
    expect(find.textContaining('pantry is empty'), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);
  });

  testWidgets('lists items with days-left badge', (t) async {
    final store = PantryStore(FakeDb(), FakeNotifs());
    await store.add(PantryItem(name: 'Milk', category: 'Dairy', expiry: DateTime.now().add(const Duration(days: 2))));
    await _pump(t, store);
    expect(find.text('Milk ×1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('tapping an item and choosing "Used one" decrements it', (t) async {
    final store = PantryStore(FakeDb(), FakeNotifs());
    await store.add(PantryItem(name: 'Milk', quantity: 2));
    await _pump(t, store);
    await t.tap(find.text('Milk ×2'));
    await t.pumpAndSettle();
    await t.tap(find.text('Used one'));
    await t.pumpAndSettle();
    expect(find.text('Milk ×1'), findsOneWidget);
  });

  testWidgets('search and status cards filter the list', (t) async {
    final store = PantryStore(FakeDb(), FakeNotifs());
    await store.add(PantryItem(name: 'Milk', expiry: _inDays(1)));
    await store.add(PantryItem(name: 'Rice', expiry: _inDays(30)));
    await _pump(t, store);
    expect(find.text('USE SOON'), findsOneWidget);
    expect(find.text('FRESH'), findsOneWidget);

    await t.enterText(find.byType(TextField), 'ric');
    await t.pumpAndSettle();
    expect(find.text('Milk ×1'), findsNothing);
    expect(find.text('Rice ×1'), findsOneWidget);

    await t.tap(find.byTooltip('Clear search'));
    await t.tap(find.text('Use soon'));
    await t.pumpAndSettle();
    expect(find.text('Milk ×1'), findsOneWidget);
    expect(find.text('Rice ×1'), findsNothing);
  });

  testWidgets('swipe removes an item and Undo restores it', (t) async {
    final store = PantryStore(FakeDb(), FakeNotifs());
    await store.add(PantryItem(name: 'Milk'));
    await _pump(t, store);
    await t.drag(find.text('Milk ×1'), const Offset(-600, 0));
    await t.pumpAndSettle();
    expect(store.items, isEmpty);
    expect(find.text('Removed Milk'), findsOneWidget);
    await t.tap(find.text('Undo'));
    await t.pumpAndSettle();
    expect(find.text('Milk ×1'), findsOneWidget);
  });

  testWidgets('Scan opens the mode picker', (t) async {
    await _pump(t, PantryStore(FakeDb(), FakeNotifs()));
    await t.tap(find.text('Scan'));
    await t.pumpAndSettle();
    for (final label in ['Barcode', 'Date label', 'Type it in', 'Barcode run', 'Receipt']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text('Photo'), findsNothing); // the AI photo modes were removed
    expect(find.text('Haul photo'), findsNothing);
  });

  testWidgets('measured items offer "Used some…" and subtract the amount', (t) async {
    final store = PantryStore(FakeDb(), FakeNotifs());
    await store.add(PantryItem(name: 'Flour', quantity: 1000, unit: Unit.g));
    await _pump(t, store);
    await t.tap(find.text('Flour 1000 g'));
    await t.pumpAndSettle();
    expect(find.text('Used one'), findsNothing);
    await t.tap(find.text('Used some…'));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('use-amount')), '250');
    await t.tap(find.text('Use'));
    await t.pumpAndSettle();
    expect(find.text('Flour 750 g'), findsOneWidget);
  });
}
