import 'package:flutter_test/flutter_test.dart';
import 'package:pantrypal/models/pantry_item.dart';
import 'package:pantrypal/models/unit.dart';

void main() {
  group('PantryItem.daysLeft', () {
    test('is null without an expiry date', () {
      expect(PantryItem(name: 'Rice').daysLeft, isNull);
    });
    test('counts calendar days regardless of time of day', () {
      final now = DateTime.now();
      final inThree = DateTime(now.year, now.month, now.day).add(const Duration(days: 3, hours: 23));
      expect(PantryItem(name: 'Milk', expiry: inThree).daysLeft, 3);
    });
    test('is 0 today and negative when expired', () {
      final now = DateTime.now();
      expect(PantryItem(name: 'A', expiry: now).daysLeft, 0);
      expect(PantryItem(name: 'B', expiry: now.subtract(const Duration(days: 2))).daysLeft, -2);
    });
  });

  group('PantryItem map round-trip', () {
    test('preserves all fields', () {
      final item = PantryItem(
        id: 7, name: 'Yogurt', category: 'Dairy', quantity: 4,
        expiry: DateTime(2026, 11, 5), addedAt: DateTime(2026, 10, 1),
      );
      final copy = PantryItem.fromMap(item.toMap());
      expect(copy.id, 7);
      expect(copy.name, 'Yogurt');
      expect(copy.category, 'Dairy');
      expect(copy.quantity, 4);
      expect(copy.expiry, DateTime(2026, 11, 5));
      expect(copy.addedAt, DateTime(2026, 10, 1));
    });
    test('handles null expiry', () {
      expect(PantryItem.fromMap(PantryItem(name: 'Salt').toMap()).expiry, isNull);
    });
  });

  test('copyWith changes only the given fields', () {
    final a = PantryItem(id: 1, name: 'Milk', category: 'Dairy', quantity: 2, expiry: DateTime(2030, 1, 1));
    final b = a.copyWith(quantity: 1);
    expect(b.quantity, 1);
    expect([b.id, b.name, b.category, b.expiry], [1, 'Milk', 'Dairy', DateTime(2030, 1, 1)]);
  });

  test('copyWith(clearExpiry: true) removes the date', () {
    final a = PantryItem(name: 'Milk', expiry: DateTime(2030, 1, 1));
    expect(a.copyWith(clearExpiry: true).expiry, isNull);
    expect(a.copyWith().expiry, DateTime(2030, 1, 1));
  });

  test('status buckets: expired, soon (0–3 days), fresh, undated', () {
    final now = DateTime.now();
    PantryItem inDays(int d) => PantryItem(name: 'x', expiry: DateTime(now.year, now.month, now.day + d));
    expect(inDays(-1).status, ExpiryStatus.expired);
    expect(inDays(0).status, ExpiryStatus.soon);
    expect(inDays(3).status, ExpiryStatus.soon);
    expect(inDays(4).status, ExpiryStatus.fresh);
    expect(PantryItem(name: 'Salt').status, ExpiryStatus.undated);
  });

  test('unit round-trips; legacy rows (int quantity, no unit) read as count', () {
    final m = PantryItem(name: 'Rice', quantity: 1.5, unit: Unit.kg).toMap();
    final back = PantryItem.fromMap(m);
    expect([back.quantity, back.unit, back.quantityLabel], [1.5, Unit.kg, '1.5 kg']);
    final legacy = PantryItem.fromMap({'id': 1, 'name': 'Eggs', 'category': 'Dairy', 'quantity': 6, 'added_at': '2026-01-01T00:00:00.000'});
    expect([legacy.quantity, legacy.unit, legacy.quantityLabel], [6, Unit.count, '×6']);
  });

  group('merging duplicates', () {
    final exp = DateTime(2026, 12, 1);
    test('same name/day/compatible unit merges, converting into the existing unit', () {
      final a = PantryItem(id: 1, name: 'Flour', quantity: 1, unit: Unit.kg, expiry: exp);
      final b = PantryItem(name: ' flour ', quantity: 500, unit: Unit.g, expiry: DateTime(2026, 12, 1, 18));
      expect(a.canMergeWith(b), isTrue);
      final m = a.mergedWith(b);
      expect([m.id, m.quantity, m.unit], [1, 1.5, Unit.kg]);
    });
    test('different expiry, missing vs present date, or incompatible units stay separate', () {
      final a = PantryItem(name: 'Milk', quantity: 1, unit: Unit.l, expiry: exp);
      expect(a.canMergeWith(PantryItem(name: 'Milk', quantity: 1, unit: Unit.l, expiry: DateTime(2026, 12, 2))), isFalse);
      expect(a.canMergeWith(PantryItem(name: 'Milk', quantity: 1, unit: Unit.l)), isFalse);
      expect(a.canMergeWith(PantryItem(name: 'Milk', quantity: 2, expiry: exp)), isFalse); // count vs litres
      expect(PantryItem(name: 'Salt').canMergeWith(PantryItem(name: 'Salt', quantity: 2)), isTrue);
    });
  });
}
