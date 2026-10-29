import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pantrypal/data/settings_repo.dart';
import 'package:pantrypal/models/reminder_settings.dart';
import 'package:pantrypal/data/pantry_db.dart';
import 'package:pantrypal/models/pantry_item.dart';
import 'package:pantrypal/models/unit.dart';
import 'package:pantrypal/services/notification_service.dart';
import 'package:pantrypal/state/pantry_store.dart';

class FakeDb implements PantryDb {
  final rows = <PantryItem>[];
  int _next = 1;
  @override
  Future<List<PantryItem>> all() async => [...rows];
  @override
  Future<int> insert(PantryItem i) async {
    final id = _next++;
    rows.add(PantryItem(
        id: id, name: i.name, category: i.category, quantity: i.quantity, unit: i.unit, expiry: i.expiry, addedAt: i.addedAt));
    return id;
  }
  @override
  Future<void> update(PantryItem i) async {
    final idx = rows.indexWhere((r) => r.id == i.id);
    rows[idx] = i;
  }
  @override
  Future<void> delete(int id) async => rows.removeWhere((r) => r.id == id);
}

class FakeNotifs implements NotificationService {
  final scheduled = <int>[];
  final cancelled = <int>[];
  int? lastLead;
  int? lastHour;
  @override
  Future<void> init({void Function()? onTap, bool requestPermission = true}) async {}
  @override
  Future<bool> launchedFromNotification() async => false;
  @override
  Future<void> scheduleFor(int id, PantryItem item, {int leadDays = 2, int hour = 9}) async {
    scheduled.add(id);
    lastLead = leadDays;
    lastHour = hour;
  }
  @override
  Future<void> cancel(int id) async => cancelled.add(id);
}

void main() {
  late FakeDb db;
  late FakeNotifs notifs;
  late PantryStore store;

  setUp(() {
    db = FakeDb();
    notifs = FakeNotifs();
    store = PantryStore(db, notifs);
  });

  test('add persists, schedules a reminder, and notifies listeners', () async {
    var notified = 0;
    store.addListener(() => notified++);
    await store.add(PantryItem(name: 'Milk', expiry: DateTime(2030, 1, 1)));
    expect(store.items.single.name, 'Milk');
    expect(notifs.scheduled, [1]);
    expect(notified, greaterThan(0));
  });

  test('remove deletes the item and cancels its reminder', () async {
    await store.add(PantryItem(name: 'Eggs'));
    await store.remove(store.items.single);
    expect(store.items, isEmpty);
    expect(notifs.cancelled, [1]);
  });

  test('update persists changes and reschedules the reminder', () async {
    await store.add(PantryItem(name: 'Milk', quantity: 2));
    await store.update(store.items.single.copyWith(quantity: 5));
    expect(store.items.single.quantity, 5);
    expect(notifs.cancelled, [1]);
    expect(notifs.scheduled, [1, 1]);
  });

  test('useOne decrements, then removes at zero', () async {
    await store.add(PantryItem(name: 'Eggs', quantity: 2));
    await store.useOne(store.items.single);
    expect(store.items.single.quantity, 1);
    await store.useOne(store.items.single);
    expect(store.items, isEmpty);
  });

  test('setReminders persists and reschedules dated items with the new values', () async {
    SharedPreferences.setMockInitialValues({});
    final s = PantryStore(db, notifs, SettingsRepo());
    await s.add(PantryItem(name: 'Milk', expiry: DateTime(2030, 1, 1)));
    await s.add(PantryItem(name: 'Rice'));
    notifs.scheduled.clear();
    notifs.cancelled.clear();
    await s.setReminders(const ReminderSettings(leadDays: 3, hour: 18));
    expect(notifs.cancelled, [1]);
    expect(notifs.scheduled, [1]);
    expect([notifs.lastLead, notifs.lastHour], [3, 18]);
    expect((await SettingsRepo().load()).leadDays, 3);
  });

  test('resyncReminders re-registers only dated items', () async {
    await db.insert(PantryItem(name: 'Milk', expiry: DateTime(2030, 1, 1)));
    await db.insert(PantryItem(name: 'Rice'));
    await store.load();
    notifs.scheduled.clear();
    notifs.cancelled.clear();
    await store.resyncReminders();
    expect(notifs.cancelled, [1]);
    expect(notifs.scheduled, [1]);
  });

  test('load restores persisted reminder settings', () async {
    SharedPreferences.setMockInitialValues({'lead_days': 4, 'reminder_hour': 7});
    final s = PantryStore(db, notifs, SettingsRepo());
    await s.load();
    expect([s.reminders.leadDays, s.reminders.hour], [4, 7]);
  });

  test('addAll inserts every item, schedules dated ones, and returns the count', () async {
    final n = await store.addAll([
      PantryItem(name: 'Milk', expiry: DateTime(2030, 1, 1)),
      PantryItem(name: 'Rice'),
    ]);
    expect(n, 2);
    expect(store.items.map((i) => i.name), ['Milk', 'Rice']);
    expect(notifs.scheduled, [1, 2]); // the fake records every call; the real service skips undated items
    expect(await store.addAll([]), 0);
  });

  test('useAmount subtracts in the item unit and removes when nothing is left', () async {
    await store.add(PantryItem(name: 'Flour', quantity: 1, unit: Unit.kg));
    await store.useAmount(store.items.single, 0.3);
    expect(store.items.single.quantity, 0.7);
    expect(store.items.single.unit, Unit.kg);
    await store.useAmount(store.items.single, 0.7);
    expect(store.items, isEmpty);
  });

  test('restore merges or replaces, cancelling replaced reminders', () async {
    await store.add(PantryItem(name: 'Old'));
    expect(await store.restore([PantryItem(name: 'A')], replace: false), 1);
    expect(store.items.map((i) => i.name), ['Old', 'A']);
    expect(await store.restore([PantryItem(name: 'B', quantity: 250, unit: Unit.g)], replace: true), 1);
    expect(store.items.map((i) => '${i.name} ${i.quantityLabel}'), ['B 250 g']);
    expect(notifs.cancelled, containsAll([1, 2]));
    expect(await store.restore([], replace: true), 0);
    expect(store.items, isEmpty);
  });

  test('addAll merges duplicates into existing items and within the batch', () async {
    final exp = DateTime(2030, 1, 1);
    await store.add(PantryItem(name: 'Flour', quantity: 1, unit: Unit.kg, expiry: exp));
    final n = await store.addAll([
      PantryItem(name: 'flour', quantity: 250, unit: Unit.g, expiry: exp),
      PantryItem(name: 'Eggs', quantity: 6),
      PantryItem(name: 'Eggs', quantity: 6),
      PantryItem(name: 'Flour', quantity: 1, unit: Unit.kg, expiry: DateTime(2030, 2, 1)), // other batch
    ]);
    expect(n, 4);
    expect(store.items.map((i) => '${i.name} ${i.quantityLabel}'), ['Flour 1.25 kg', 'Eggs ×12', 'Flour 1 kg']);
    expect(notifs.scheduled, [1, 2, 3]); // merges don't add reminders
  });
}
