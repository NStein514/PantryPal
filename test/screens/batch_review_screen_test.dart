import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pantrypal/models/scan_draft.dart';
import 'package:pantrypal/screens/batch_review_screen.dart';
import 'package:pantrypal/state/pantry_store.dart';
import '../helpers.dart';
import '../state/pantry_store_test.dart' show FakeDb, FakeNotifs;

/// Pushes the review screen from a launcher so it can pop with a result.
Future<PantryStore> _pump(WidgetTester t, Future<List<ScanDraft>> Function() load, void Function(int?) onResult) async {
  final store = PantryStore(FakeDb(), FakeNotifs());
  await t.pumpWidget(ChangeNotifierProvider.value(
    value: store,
    child: testApp(
      Builder(
        builder: (ctx) => TextButton(
          onPressed: () async => onResult(await Navigator.push<int>(
              ctx, MaterialPageRoute(builder: (_) => BatchReviewScreen(title: 'Review', load: load)))),
          child: const Text('open'),
        ),
      ),
    ),
  ));
  await t.tap(find.text('open'));
  await t.pumpAndSettle();
  return store;
}

void main() {
  testWidgets('saves ticked drafts; naming an unknown barcode opts it in', (t) async {
    int? result;
    final store = await _pump(
      t,
      () async => [ScanDraft(name: 'Oat milk', category: 'Dairy', quantity: 2), ScanDraft(barcode: '999')],
      (r) => result = r,
    );
    expect(find.text('Add 1 item to pantry'), findsOneWidget);
    expect(find.text('Not found — type a name'), findsOneWidget);

    await t.enterText(find.byType(TextFormField).at(1), 'Crackers');
    await t.pumpAndSettle();
    expect(find.text('Add 2 items to pantry'), findsOneWidget);

    await t.tap(find.text('Add 2 items to pantry'));
    await t.pumpAndSettle();
    expect(result, 2);
    expect(store.items.map((i) => '${i.name} ${i.quantityLabel}'), ['Oat milk ×2', 'Crackers ×1']);
  });

  testWidgets('unticking a draft leaves it out', (t) async {
    final store = await _pump(t, () async => [ScanDraft(name: 'A'), ScanDraft(name: 'B')], (_) {});
    await t.tap(find.byType(Checkbox).first);
    await t.pumpAndSettle();
    await t.tap(find.text('Add 1 item to pantry'));
    await t.pumpAndSettle();
    expect(store.items.map((i) => i.name), ['B']);
  });

  testWidgets('shows an error with retry, and an empty state', (t) async {
    var calls = 0;
    await _pump(t, () async {
      calls++;
      if (calls == 1) throw Exception('AI error 500');
      return <ScanDraft>[];
    }, (_) {});
    expect(find.textContaining("Couldn't read"), findsOneWidget);
    await t.tap(find.text('Try again'));
    await t.pumpAndSettle();
    expect(find.text('No food items found.'), findsOneWidget);
  });
}
