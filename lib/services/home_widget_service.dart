import 'dart:async';
import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import '../l10n/l10n.dart';
import '../models/pantry_item.dart';

/// Window the widget lists items for; labels are precomputed for 0…[widgetHorizonDays].
const widgetHorizonDays = 14;

/// "Soon" threshold, matching [ExpiryStatus.soon].
const widgetSoonDays = 3;

/// Data for the home-screen widget, as written to shared storage.
///
/// Native code computes days-left from each `expiry` itself (so the widget stays right after
/// midnight without the app running) and only looks up display text here, which is why
/// labels are precomputed with real plural rules instead of being formatted natively.
Map<String, Object?> buildWidgetPayload(List<PantryItem> items, AppLocalizations l, {int maxItems = 50}) {
  String ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  final dated = items.where((i) => i.expiry != null).toList()..sort((a, b) => a.expiry!.compareTo(b.expiry!));
  return {
    'v': 1,
    'title': l.useItUp,
    'recipes': l.navRecipes,
    'empty': l.widgetEmpty,
    'expired': l.widgetExpired,
    'expiredLabel': l.statusExpired,
    'usedLabel': l.usedOne, // accessibility label for the per-row "used one" button
    'soonLabel': l.statusSoon,
    'soonDays': widgetSoonDays,
    'horizonDays': widgetHorizonDays,
    'days': {for (var d = 0; d <= widgetHorizonDays; d++) '$d': l.widgetDaysLeft(d)},
    'items': [
      for (final i in dated.take(maxItems))
        {
          'name': i.name,
          'qty': i.quantityLabel,
          'expiry': ymd(i.expiry!),
          if (i.id != null) 'id': i.id,
          // A one-tap "used one" only makes sense for counted items (not "some flour").
          'useOne': i.id != null && i.unit.isCount,
        },
    ],
  };
}

/// Publishes pantry data to the native home-screen widgets and reports widget taps.
///
/// Every call is best-effort: before the native widget code is installed (see README →
/// Home-screen widget), the platform calls fail and are ignored.
class HomeWidgetService {
  /// Must match PANTRYPAL_APP_GROUP in ios/Flutter/Identity.xcconfig (tools/set_identity.py keeps
  /// them in step). Overridable with --dart-define=WIDGET_APP_GROUP=… .
  static const appGroupId = String.fromEnvironment('WIDGET_APP_GROUP', defaultValue: 'group.com.nathanielstein.pantrypal');
  static const dataKey = 'pantry_widget';
  static const androidName = 'PantryWidgetProvider'; // resolved against the app's package name
  static const iOSName = 'PantryWidget'; // the widget's `kind`

  Future<void> init() async {
    try {
      await HomeWidget.setAppGroupId(appGroupId);
    } catch (_) {}
  }

  Future<void> update(List<PantryItem> items, AppLocalizations l) async {
    try {
      await HomeWidget.saveWidgetData<String>(dataKey, jsonEncode(buildWidgetPayload(items, l)));
      await HomeWidget.updateWidget(androidName: androidName, iOSName: iOSName);
    } catch (_) {
      // Widget code not installed yet, or no widget on the home screen: nothing to update.
    }
  }

  /// Lets the widget's buttons run [callback] in the background (see widget_actions.dart).
  Future<void> registerInteractivity(FutureOr<void> Function(Uri?) callback) async {
    try {
      await HomeWidget.registerInteractivityCallback(callback);
    } catch (_) {}
  }

  /// The link that cold-started the app from the widget, if any.
  Future<Uri?> launchUri() async {
    try {
      return await HomeWidget.initiallyLaunchedFromHomeWidget();
    } catch (_) {
      return null;
    }
  }

  /// Links tapped while the app is already running.
  Stream<Uri?> get clicks => HomeWidget.widgetClicked;

  /// Widget links are pantrypal://pantry or pantrypal://recipes (iOS adds ?homeWidget).
  static bool opensRecipes(Uri? uri) => uri?.host == 'recipes';
}
