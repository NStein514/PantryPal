import 'package:flutter_test/flutter_test.dart';
import 'package:pantrypal/models/categories.dart';
import 'package:pantrypal/models/known_product.dart';
import 'package:pantrypal/models/scan_draft.dart';
import 'package:pantrypal/models/unit.dart';

void main() {
  final today = DateTime(2026, 10, 28, 15, 30);

  test('a printed expiry wins and is not marked as estimated', () {
    final d = ScanDraft.fromAi({'name': ' Yogurt ', 'category': 'Dairy', 'expiry': '2026-11-05', 'shelf_life_days': 14},
        today: today);
    expect(d.name, 'Yogurt');
    expect(d.expiry, DateTime(2026, 11, 5));
    expect(d.expiryEstimated, isFalse);
    expect(d.include, isTrue);
  });

  test('shelf_life_days gives a date-only estimate', () {
    final d = ScanDraft.fromAi({'name': 'Bread', 'category': 'Bakery', 'shelf_life_days': 5, 'expiry': null}, today: today);
    expect(d.expiry, DateTime(2026, 11, 2));
    expect(d.expiryEstimated, isTrue);
  });

  test('normalises category and quantity, tolerates missing fields', () {
    final d = ScanDraft.fromAi({'name': 'Cola', 'category': 'beverages', 'quantity': 2.6}, today: today);
    expect(d.category, 'Beverage');
    expect(d.quantity, 3);
    expect(d.expiry, isNull);
    final bad = ScanDraft.fromAi({'category': 'Gadgets', 'quantity': -4}, today: today);
    expect([bad.name, bad.category, bad.quantity, bad.include], ['', 'Other', 1, false]);
  });

  test('isSavable needs a name and the include flag; toItem copies fields', () {
    final d = ScanDraft(name: 'Eggs', category: 'Dairy', quantity: 12);
    expect(d.isSavable, isTrue);
    d.include = false;
    expect(d.isSavable, isFalse);
    final item = d.toItem();
    expect([item.name, item.category, item.quantity], ['Eggs', 'Dairy', 12]);
    expect(ScanDraft(barcode: '123').isSavable, isFalse);
  });

  test('normalizeCategory', () {
    expect(normalizeCategory('PRODUCE'), 'Produce');
    expect(normalizeCategory(null), 'Other');
    expect(normalizeCategory('Candy'), 'Other');
  });

  test('measured units keep decimals; count units round', () {
    final w = ScanDraft.fromAi({'name': 'Bananas', 'category': 'Produce', 'quantity': 2.314, 'unit': 'lbs'}, today: today);
    expect([w.quantity, w.unit], [2.31, Unit.lb]);
    expect(w.toItem().quantityLabel, '2.31 lb');
    final c = ScanDraft.fromAi({'name': 'Eggs', 'quantity': 11.6, 'unit': 'count'}, today: today);
    expect([c.quantity, c.unit], [12, Unit.count]);
  });

  test('fromKnown: counted items take the scan count, measured ones their usual size; shelf life estimates', () {
    const flour = KnownProduct(name: 'Flour', category: 'Pantry', unit: Unit.kg, quantity: 1, shelfDays: 180, barcode: '1');
    final f = ScanDraft.fromKnown(flour, count: 2, today: today);
    expect([f.name, f.quantityLabel, f.expiry, f.expiryEstimated, f.barcode, f.include],
        ['Flour', '2 kg', DateTime(2027, 4, 26), true, '1', true]);
    const eggs = KnownProduct(name: 'Eggs', quantity: 12);
    final e = ScanDraft.fromKnown(eggs, count: 3, barcode: '9', today: today);
    expect([e.quantityLabel, e.expiry, e.barcode], ['×3', null, '9']);
  });

}
