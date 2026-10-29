import 'package:flutter/foundation.dart';
import '../data/pantry_db.dart';
import '../data/settings_repo.dart';
import '../models/reminder_settings.dart';
import '../models/pantry_item.dart';
import '../services/notification_service.dart';

class PantryStore extends ChangeNotifier {
  PantryStore(this._db, this._notifs, [this._settings]);
  final PantryDb _db;
  final NotificationService _notifs;
  final SettingsRepo? _settings; // null = defaults, nothing persisted
  List<PantryItem> items = [];
  ReminderSettings reminders = const ReminderSettings();
  bool _settingsLoaded = false;

  Future<void> _schedule(int id, PantryItem i) =>
      _notifs.scheduleFor(id, i, leadDays: reminders.leadDays, hour: reminders.hour);

  /// Re-registers every dated item's reminder. Called on app launch so reminders
  /// survive reboots, OS cleanup and timezone changes.
  Future<void> resyncReminders() async {
    for (final i in items.where((i) => i.expiry != null)) {
      await _notifs.cancel(i.id!);
      await _schedule(i.id!, i);
    }
  }

  Future<void> setReminders(ReminderSettings s) async {
    reminders = s;
    await _settings?.save(s);
    await resyncReminders();
    notifyListeners();
  }

  Future<void> load() async {
    if (_settings != null && !_settingsLoaded) {
      reminders = await _settings.load();
      _settingsLoaded = true;
    }
    items = await _db.all();
    notifyListeners();
  }

  Future<void> add(PantryItem item) async {
    await addAll([item]);
  }

  /// Adds several items (e.g. from a receipt) with a single reload. Returns how many were taken in.
  ///
  /// An item that matches an existing one ([PantryItem.canMergeWith]: same name, same expiry
  /// day, convertible unit) is added onto it instead of creating a duplicate, e.g. 500 g of
  /// flour onto 1 kg → 1.5 kg. Matches within the same batch merge too.
  Future<int> addAll(Iterable<PantryItem> newItems) async {
    final working = [...items];
    var added = 0;
    for (final item in newItems) {
      final k = working.indexWhere((e) => e.id != null && e.canMergeWith(item));
      if (k >= 0) {
        final merged = working[k].mergedWith(item);
        await _db.update(merged); // same expiry, so the existing reminder still fits
        working[k] = merged;
      } else {
        final id = await _db.insert(item);
        await _schedule(id, item);
        working.add(item.withId(id));
      }
      added++;
    }
    if (added > 0) await load();
    return added;
  }

  Future<void> update(PantryItem item) async {
    await _db.update(item);
    await _notifs.cancel(item.id!);
    await _schedule(item.id!, item);
    await load();
  }

  /// Marks one as used; removes the item when the last one is gone.
  Future<void> useOne(PantryItem item) => useAmount(item, 1);

  /// Subtracts [amount] (in the item's own unit); removes the item when nothing is left.
  Future<void> useAmount(PantryItem item, double amount) {
    final left = item.quantity - amount;
    if (left <= 1e-6) return remove(item);
    return update(item.copyWith(quantity: (left * 1000).roundToDouble() / 1000)); // trim float noise
  }

  /// Restores items from a backup. With [replace], everything currently in the
  /// pantry (and its reminders) is removed first. Returns how many were added.
  Future<int> restore(Iterable<PantryItem> backup, {required bool replace}) async {
    if (replace) {
      for (final i in [...items]) {
        await _db.delete(i.id!);
        await _notifs.cancel(i.id!);
      }
    }
    final n = await addAll(backup);
    if (n == 0) await load();
    return n;
  }

  Future<void> remove(PantryItem item) async {
    await _db.delete(item.id!);
    await _notifs.cancel(item.id!);
    await load();
  }
}
