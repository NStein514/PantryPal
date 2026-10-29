import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../l10n/l10n.dart';
import '../models/pantry_item.dart';

class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();

  /// Notifications are scheduled outside any widget: use the app's language (Settings or device).
  AppLocalizations get _l => l10nFor(currentAppLocale());

  /// [requestPermission] false: set up without prompting (background engines, e.g. widget taps).
  Future<void> init({void Function()? onTap, bool requestPermission = true}) async {
    tzdata.initializeTimeZones();
    await _plugin.initialize(InitializationSettings(
      // Status-bar icons must be a white silhouette; a colour launcher icon shows as a blank square.
      android: const AndroidInitializationSettings('@drawable/ic_stat_pantrypal'),
      // iOS asks during initialize() unless told not to.
      iOS: DarwinInitializationSettings(
        requestAlertPermission: requestPermission,
        requestSoundPermission: requestPermission,
        requestBadgePermission: requestPermission,
      ),
    ), onDidReceiveNotificationResponse: (_) => onTap?.call());
    if (!requestPermission) return;
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// When to remind: [leadDays] before expiry at [hour]:00 local time.
  static DateTime reminderTime(DateTime expiry, int leadDays, int hour) =>
      DateTime(expiry.year, expiry.month, expiry.day - leadDays, hour);

  Future<void> scheduleFor(int id, PantryItem item, {int leadDays = 2, int hour = 9}) async {
    if (item.expiry == null) return;
    final when = reminderTime(item.expiry!, leadDays, hour);
    final delay = when.difference(DateTime.now());
    if (delay.isNegative) return;
    final l = _l;
    await _plugin.zonedSchedule(
      id,
      l.notifTitle(item.name),
      l.notifBody(leadDays),
      tz.TZDateTime.now(tz.UTC).add(delay), // offset from now avoids local-tz lookup
      NotificationDetails(
        android: AndroidNotificationDetails('expiry', l.notifChannel),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'recipes',
    );
  }

  /// True when the app was cold-started by tapping a reminder.
  Future<bool> launchedFromNotification() async =>
      (await _plugin.getNotificationAppLaunchDetails())?.didNotificationLaunchApp ?? false;

  Future<void> cancel(int id) => _plugin.cancel(id);
}
