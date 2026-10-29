import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import '../models/pantry_item.dart';
import '../models/scan_mode.dart';
import '../models/unit.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

/// Language chosen in Settings, or null to follow the device. Set by LocaleStore.
/// Read by code that runs outside the widget tree (notifications, home-screen widget).
Locale? appLocaleOverride;

/// The locale the app is showing: the in-app choice if any, else the device locale.
Locale currentAppLocale() => appLocaleOverride ?? PlatformDispatcher.instance.locale;

/// Language codes with translations, in the order the Settings picker lists them.
List<String> get supportedLanguageCodes =>
    [for (final l in AppLocalizations.supportedLocales) l.languageCode]..sort((a, b) {
        // English first (the template), then alphabetical by native name.
        if (a == 'en') return -1;
        if (b == 'en') return 1;
        return languageNativeName(a).compareTo(languageNativeName(b));
      });

/// A language's own name, shown untranslated so people can find theirs in any UI language.
String languageNativeName(String code) => switch (code) {
      'en' => 'English',
      'es' => 'Español',
      'de' => 'Deutsch',
      'fr' => 'Français',
      _ => code,
    };

/// Strings for code that has no BuildContext (notifications). Falls back to English.
AppLocalizations l10nFor(Locale locale) {
  final supported = AppLocalizations.supportedLocales.any((l) => l.languageCode == locale.languageCode);
  return lookupAppLocalizations(supported ? Locale(locale.languageCode) : const Locale('en'));
}

/// Categories are stored as English keys (also used in AI prompts); this is the display name.
String categoryLabel(AppLocalizations l, String key) => switch (key) {
      'Produce' => l.catProduce,
      'Dairy' => l.catDairy,
      'Meat' => l.catMeat,
      'Seafood' => l.catSeafood,
      'PlantProtein' => l.catPlantProtein,
      'Deli' => l.catDeli,
      'Bakery' => l.catBakery,
      'Grains' => l.catGrains,
      'Baking' => l.catBaking,
      'Canned' => l.catCanned,
      'Condiments' => l.catCondiments,
      'Spices' => l.catSpices,
      'Spreads' => l.catSpreads,
      'Snacks' => l.catSnacks,
      'Pantry' => l.catPantry,
      'Frozen' => l.catFrozen,
      'Beverage' => l.catBeverage,
      'Alcohol' => l.catAlcohol,
      'Baby' => l.catBaby,
      'Pet' => l.catPet,
      'Household' => l.catHousehold,
      _ => l.catOther,
    };

String statusLabel(AppLocalizations l, ExpiryStatus s) => switch (s) {
      ExpiryStatus.expired => l.statusExpired,
      ExpiryStatus.soon => l.statusSoon,
      ExpiryStatus.fresh => l.statusFresh,
      ExpiryStatus.undated => l.statusUndated,
    };

String unitLabel(AppLocalizations l, Unit u) => u.isCount ? l.unitPieces : u.label;

String scanModeLabel(AppLocalizations l, ScanMode m) => switch (m) {
      ScanMode.barcode => l.modeBarcode,
      ScanMode.dateLabel => l.modeDateLabel,
      ScanMode.manual => l.modeManual,
      ScanMode.barcodeBatch => l.modeBarcodeRun,
      ScanMode.receipt => l.modeReceipt,
    };

String scanModeDescription(AppLocalizations l, ScanMode m) => switch (m) {
      ScanMode.barcode => l.modeBarcodeDesc,
      ScanMode.dateLabel => l.modeDateLabelDesc,
      ScanMode.manual => l.modeManualDesc,
      ScanMode.barcodeBatch => l.modeBarcodeRunDesc,
      ScanMode.receipt => l.modeReceiptDesc,
    };

/// Whether numeric dates are written day-first in [locale] (default: Intl.defaultLocale).
/// en_US "M/d/y" → false; en_GB "dd/MM/y", es "d/M/y", de "d.M.y" → true; ja "y/M/d" → false.
bool dateFormatIsDayFirst([String? locale]) {
  try {
    final p = DateFormat.yMd(locale).pattern ?? '';
    final d = p.indexOf('d'), m = p.indexOf('M');
    return d >= 0 && m >= 0 && d < m;
  } catch (_) {
    return false; // locale data not loaded: keep the old US behaviour
  }
}

/// The locale string for intl formatting: the device's own region when it speaks a supported
/// language (so en_GB keeps day-first dates), otherwise the resolved app locale.
String intlLocaleFor(Locale device, Locale resolved) =>
    device.languageCode == resolved.languageCode ? device.toString() : resolved.toString();
