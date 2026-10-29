import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantrypal/models/known_product.dart';
import 'package:pantrypal/models/pantry_item.dart';
import 'package:pantrypal/models/reminder_settings.dart';
import 'package:pantrypal/models/shopping_item.dart';
import 'package:pantrypal/models/unit.dart';
import 'package:pantrypal/services/backup_service.dart';

void main() {
  test('round-trips items, shopping list and settings (ids are not exported)', () {
    final json = BackupService.encode(
      items: [
        PantryItem(id: 7, name: 'Flour', category: 'Pantry', quantity: 1.5, unit: Unit.kg, expiry: DateTime(2026, 12, 1),
            addedAt: DateTime(2026, 10, 1)),
        PantryItem(id: 8, name: 'Salt'),
      ],
      shopping: const [ShoppingItem(id: 3, name: 'Basil', checked: true)],
      reminders: const ReminderSettings(leadDays: 3, hour: 18),
      now: DateTime(2026, 10, 28, 9),
    );
    expect(json, isNot(contains('"id"')));
    final d = BackupService.decode(json);
    expect(d.items.map((i) => '${i.name} ${i.quantityLabel} ${i.category}'), ['Flour 1.5 kg Pantry', 'Salt ×1 Other']);
    expect(d.items.first.expiry, DateTime(2026, 12, 1));
    expect(d.items.first.addedAt, DateTime(2026, 10, 1));
    expect(d.items.first.id, isNull);
    expect([d.shopping.single.name, d.shopping.single.checked], ['Basil', true]);
    expect([d.reminders!.leadDays, d.reminders!.hour], [3, 18]);
    expect(d.exportedAt, DateTime(2026, 10, 28, 9));
  });

  test('rejects non-JSON, other JSON, and newer versions with readable messages', () {
    expect(() => BackupService.decode('nope'), throwsA(isA<FormatException>().having((e) => e.message, 'msg', contains('JSON'))));
    expect(() => BackupService.decode('{"hello":1}'),
        throwsA(isA<FormatException>().having((e) => e.message, 'msg', contains('PantryPal backup'))));
    expect(() => BackupService.decode(jsonEncode({'format': BackupService.format, 'version': 99})),
        throwsA(isA<FormatException>().having((e) => e.message, 'msg', contains('newer'))));
  });

  test('skips malformed entries, normalises categories, clamps settings', () {
    final d = BackupService.decode(jsonEncode({
      'format': BackupService.format,
      'version': 1,
      'items': [
        {'name': 'Good', 'category': 'dairy', 'quantity': 2},
        {'name': ''},
        {'name': 'Bad date', 'expiry': 'someday'},
        {'name': 'Zero', 'quantity': 0},
        'junk',
      ],
      'shopping': [{'name': ' Tea '}, {'nope': 1}],
      'settings': {'lead_days': 30, 'reminder_hour': -2},
    }));
    expect(d.items.map((i) => '${i.name}/${i.category}/${i.quantityLabel}'), ['Good/Dairy/×2']);
    expect(d.shopping.map((s) => s.name), ['Tea']);
    expect([d.reminders!.leadDays, d.reminders!.hour], [7, 0]);
  });

  test('fileName is dated', () => expect(BackupService.fileName(DateTime(2026, 3, 4)), 'pantrypal-backup-2026-03-04.json'));

  test('errors carry a problem code the UI can translate', () {
    expect(() => BackupService.decode('nope'),
        throwsA(isA<BackupFormatException>().having((e) => e.problem, 'problem', BackupProblem.notJson)));
    expect(() => BackupService.decode('[]'),
        throwsA(isA<BackupFormatException>().having((e) => e.problem, 'problem', BackupProblem.notPantryPal)));
    expect(() => BackupService.decode(jsonEncode({'format': BackupService.format, 'version': BackupService.version + 1})),
        throwsA(isA<BackupFormatException>().having((e) => e.problem, 'problem', BackupProblem.tooNew)));
  });

  group('remembered products (v2)', () {
    test('round-trip without the internal key', () {
      final json = BackupService.encode(
        items: const [],
        shopping: const [],
        reminders: const ReminderSettings(),
        products: [
          KnownProduct(name: 'Oat milk', category: 'Dairy', unit: Unit.l, quantity: 1, barcode: '4006381333931',
              shelfDays: 7, uses: 4, lastUsed: DateTime(2026, 10, 1)),
        ],
      );
      expect(jsonDecode(json)['version'], 2);
      expect(json, isNot(contains('"key"')));
      final p = BackupService.decode(json).products.single;
      expect([p.name, p.category, p.unit, p.quantity, p.barcode, p.shelfDays, p.uses, p.lastUsed],
          ['Oat milk', 'Dairy', Unit.l, 1, '4006381333931', 7, 4, DateTime(2026, 10, 1)]);
    });

    test('v1 backups still import, with no products', () {
      final d = BackupService.decode(jsonEncode({
        'format': BackupService.format,
        'version': 1,
        'items': [{'name': 'Rice'}],
      }));
      expect(d.items.single.name, 'Rice');
      expect(d.products, isEmpty);
    });

    test('bad entries are skipped or cleaned up', () {
      final d = BackupService.decode(jsonEncode({
        'format': BackupService.format,
        'version': 2,
        'products': [
          {'name': ' Jam ', 'category': 'jams', 'quantity': -2, 'barcode': 'abc', 'shelf_days': 99999, 'uses': 0},
          {'name': ''},
          {'name': 'Bad types', 'shelf_days': 'soon'},
          'junk',
        ],
      }));
      final p = d.products.single;
      expect([p.name, p.category, p.quantity, p.barcode, p.shelfDays, p.uses], ['Jam', 'Other', 1, null, null, 1]);
    });
  });
}
