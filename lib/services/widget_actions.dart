import '../data/pantry_db.dart';
import '../data/settings_repo.dart';
import '../l10n/l10n.dart';
import '../models/widget_action.dart';
import '../state/locale_store.dart';
import '../state/pantry_store.dart';
import 'home_widget_service.dart';
import 'notification_service.dart';

/// Applies a widget button's action to the pantry. Returns whether anything changed.
/// Only counted items can be "used one" from the widget; others need the app (how much?).
Future<bool> applyWidgetAction(PantryStore store, WidgetAction action) async {
  for (final item in store.items) {
    if (item.id == action.itemId) {
      if (!item.unit.isCount) return false;
      await store.useOne(item); // decrements, removes at zero, reschedules the reminder
      return true;
    }
  }
  return false; // already gone (e.g. used in the app since the widget was drawn)
}

/// Runs in a background Flutter engine when a widget button is tapped, even with the app
/// closed (Android; iOS 17+). Opens the same database the app uses, applies the action,
/// and republishes the widget so it reflects the change. Registered in main().
@pragma('vm:entry-point')
Future<void> widgetInteractivityCallback(Uri? uri) async {
  final action = WidgetAction.parse(uri);
  if (action == null) return;
  final settings = SettingsRepo();
  await LocaleStore(settings).load(); // so rescheduled reminders and the widget use the app's language
  final notifs = NotificationService();
  await notifs.init(requestPermission: false); // never prompt from the background
  final store = PantryStore(PantryDb(), notifs, settings);
  await store.load();
  await applyWidgetAction(store, action);
  final widgets = HomeWidgetService();
  await widgets.init();
  await widgets.update(store.items, l10nFor(currentAppLocale()));
}
