import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantrypal/l10n/l10n.dart';
import 'package:pantrypal/models/pantry_item.dart';
import 'package:pantrypal/models/unit.dart';
import 'package:pantrypal/services/home_widget_service.dart';

void main() {
  final en = l10nFor(const Locale('en'));
  final es = l10nFor(const Locale('es'));

  test('lists dated items soonest first as plain dates; undated items are left out', () {
    final p = buildWidgetPayload([
      PantryItem(id: 1, name: 'Rice'),
      PantryItem(id: 2, name: 'Cheese', expiry: DateTime(2026, 11, 20, 18)),
      PantryItem(id: 3, name: 'Milk', quantity: 1.5, unit: Unit.l, expiry: DateTime(2026, 11, 2)),
    ], en);
    expect(p['items'], [
      {'name': 'Milk', 'qty': '1.5 L', 'expiry': '2026-11-02', 'id': 3, 'useOne': false},
      {'name': 'Cheese', 'qty': '×1', 'expiry': '2026-11-20', 'id': 2, 'useOne': true},
    ]);
  });

  test('precomputes day labels with real plurals for the whole horizon', () {
    final days = buildWidgetPayload([], en)['days'] as Map;
    expect(days.length, widgetHorizonDays + 1);
    expect([days['0'], days['1'], days['5']], ['today', '1 day', '5 days']);
    final esDays = buildWidgetPayload([], es)['days'] as Map;
    expect([esDays['0'], esDays['1'], esDays['14']], ['hoy', '1 día', '14 días']);
  });

  test('carries the translated chrome and thresholds the native code needs', () {
    final p = buildWidgetPayload([], es);
    expect(p['title'], es.useItUp);
    expect(p['recipes'], 'Recetas');
    expect(p['expired'], 'caducado');
    expect([p['soonDays'], p['horizonDays']], [widgetSoonDays, widgetHorizonDays]);
  });

  test('caps the item list', () {
    final many = [for (var i = 0; i < 80; i++) PantryItem(name: 'I$i', expiry: DateTime(2027, 1, 1).add(Duration(days: i)))];
    final items = buildWidgetPayload(many, en, maxItems: 50)['items'] as List;
    expect(items.length, 50);
    expect((items.first as Map)['name'], 'I0');
  });

  test('only recipe links open the recipes screen', () {
    expect(HomeWidgetService.opensRecipes(Uri.parse('pantrypal://recipes?homeWidget')), isTrue);
    expect(HomeWidgetService.opensRecipes(Uri.parse('pantrypal://pantry')), isFalse);
    expect(HomeWidgetService.opensRecipes(null), isFalse);
  });

  test('"used one" is offered only for saved, counted items', () {
    final payload = buildWidgetPayload([
      PantryItem(id: 5, name: 'Eggs', quantity: 6, expiry: DateTime(2026, 11, 1)),
      PantryItem(id: 6, name: 'Flour', quantity: 1, unit: Unit.kg, expiry: DateTime(2026, 11, 1)),
      PantryItem(name: 'Unsaved', expiry: DateTime(2026, 11, 1)),
    ], es);
    final items = payload['items'] as List;
    expect([for (final i in items) (i as Map)['useOne']], [true, false, false]);
    expect(payload['usedLabel'], 'Usé uno');
    expect((items.last as Map).containsKey('id'), isFalse);
  });
}
