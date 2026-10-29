// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'PantryPal';

  @override
  String get aiLanguage => 'German';

  @override
  String get navPantry => 'Vorrat';

  @override
  String get navRecipes => 'Rezepte';

  @override
  String get navShopping => 'Einkauf';

  @override
  String get settings => 'Einstellungen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get add => 'Hinzufügen';

  @override
  String get back => 'Zurück';

  @override
  String get tryAgain => 'Erneut versuchen';

  @override
  String get undo => 'Rückgängig';

  @override
  String get remove => 'Entfernen';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get delete => 'Löschen';

  @override
  String get review => 'Prüfen';

  @override
  String get catProduce => 'Obst & Gemüse';

  @override
  String get catDairy => 'Milchprodukte & Eier';

  @override
  String get catMeat => 'Fleisch & Geflügel';

  @override
  String get catPantry => 'Grundvorrat';

  @override
  String get catFrozen => 'Tiefkühl';

  @override
  String get catBakery => 'Brot & Backwaren';

  @override
  String get catBeverage => 'Getränke';

  @override
  String get catOther => 'Sonstiges';

  @override
  String get unitPieces => 'Stk.';

  @override
  String get statusExpired => 'Abgelaufen';

  @override
  String get statusSoon => 'Bald verbrauchen';

  @override
  String get statusFresh => 'Frisch';

  @override
  String get statusUndated => 'Ohne Datum';

  @override
  String get searchHint => 'Vorrat durchsuchen';

  @override
  String get clearSearch => 'Suche löschen';

  @override
  String get filterAll => 'Alle';

  @override
  String get noMatches => 'Keine passenden Einträge.';

  @override
  String get clearFilters => 'Filter zurücksetzen';

  @override
  String get emptyPantry =>
      'Dein Vorrat ist leer.\nTippe auf Scannen, um etwas hinzuzufügen.';

  @override
  String get emptyPantryHint =>
      'Scanne einen Barcode, mach ein Foto oder importiere einen ganzen Kassenbon.';

  @override
  String get scan => 'Scannen';

  @override
  String removedItem(String name) {
    return '$name entfernt';
  }

  @override
  String expiresOn(String date) {
    return 'Läuft ab am $date';
  }

  @override
  String expiredOn(String date) {
    return 'Abgelaufen am $date';
  }

  @override
  String get expiresToday => 'Läuft heute ab';

  @override
  String get noExpiryDate => 'Kein Ablaufdatum';

  @override
  String get usedOne => 'Eins verbraucht';

  @override
  String leftAfterThis(String amount) {
    return 'Danach noch $amount';
  }

  @override
  String get removesFromPantry => 'Entfernt es aus dem Vorrat';

  @override
  String get usedSome => 'Etwas verbraucht…';

  @override
  String amountLeft(String amount) {
    return 'Noch $amount';
  }

  @override
  String get addToShoppingList => 'Auf die Einkaufsliste';

  @override
  String alreadyOnList(String name) {
    return '$name steht schon auf deiner Liste';
  }

  @override
  String addedToList(String name) {
    return '$name zur Liste hinzugefügt';
  }

  @override
  String get badgeNoDate => 'k. Datum';

  @override
  String get badgeAgo => 'T. her';

  @override
  String get badgeToday => 'heute';

  @override
  String badgeDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tage',
      one: 'Tag',
    );
    return '$_temp0';
  }

  @override
  String expiresInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Läuft in $count Tagen ab',
      one: 'Läuft in 1 Tag ab',
    );
    return '$_temp0';
  }

  @override
  String expiredDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Seit $count Tagen abgelaufen',
      one: 'Seit 1 Tag abgelaufen',
    );
    return '$_temp0';
  }

  @override
  String get addToPantry => 'Zum Vorrat hinzufügen';

  @override
  String get sourceCamera => 'Kamera';

  @override
  String get sourcePhotos => 'Fotos';

  @override
  String get oneItem => 'Ein Artikel';

  @override
  String get severalAtOnce => 'Mehrere auf einmal';

  @override
  String get modeBarcode => 'Barcode';

  @override
  String get modeBarcodeDesc => 'Ein Produkt über seinen Barcode finden';

  @override
  String get modeDateLabel => 'Datumsaufdruck';

  @override
  String get modeDateLabelDesc =>
      'Aufgedrucktes Ablaufdatum lesen (bleibt auf dem Handy)';

  @override
  String get modeManual => 'Eintippen';

  @override
  String get modeManualDesc => 'Angaben selbst eingeben';

  @override
  String get modeBarcodeRun => 'Barcode-Serie';

  @override
  String get modeBarcodeRunDesc =>
      'Ein Produkt nach dem anderen scannen, am Ende prüfen';

  @override
  String get modeReceipt => 'Kassenbon';

  @override
  String get modeReceiptDesc =>
      'Alle Lebensmittel von einem Kassenbon übernehmen';

  @override
  String get reviewScanned => 'Gescannte Artikel prüfen';

  @override
  String get reviewReceipt => 'Kassenbon prüfen';

  @override
  String addedToPantry(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Artikel zum Vorrat hinzugefügt',
      one: '1 Artikel zum Vorrat hinzugefügt',
    );
    return '$_temp0';
  }

  @override
  String get selectAll => 'Alle auswählen';

  @override
  String get selectNone => 'Keine auswählen';

  @override
  String get scanReadError => 'Der Scan konnte nicht gelesen werden.';

  @override
  String get readingScan => 'Scan wird gelesen…';

  @override
  String get readingScanHint => 'Das kann einige Sekunden dauern.';

  @override
  String get noFoodFound => 'Keine Lebensmittel gefunden.';

  @override
  String get noFoodFoundHint =>
      'Versuche ein schärferes, gut beleuchtetes Foto oder füge die Artikel einzeln hinzu.';

  @override
  String foundIntro(int count) {
    return '$count gefunden. Korrigiere, was nicht stimmt, und entferne die Haken bei allem, was du nicht willst.';
  }

  @override
  String get itemNameHint => 'Artikelname';

  @override
  String barcodeHelper(String code) {
    return 'Barcode $code';
  }

  @override
  String get notFoundTypeName => 'Nicht gefunden – Namen eingeben';

  @override
  String get removeFromList => 'Aus der Liste entfernen';

  @override
  String get addDate => 'Datum hinzufügen';

  @override
  String estimatedDate(String date) {
    return '$date (gesch.)';
  }

  @override
  String addItemsButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Artikel zum Vorrat hinzufügen',
      one: '1 Artikel zum Vorrat hinzufügen',
    );
    return '$_temp0';
  }

  @override
  String get less => 'Weniger';

  @override
  String get more => 'Mehr';

  @override
  String get addItem => 'Artikel hinzufügen';

  @override
  String get editItem => 'Artikel bearbeiten';

  @override
  String get fillAutomatically => 'Automatisch ausfüllen';

  @override
  String get scanDate => 'Datum scannen';

  @override
  String get fieldName => 'Name';

  @override
  String get fieldCategory => 'Kategorie';

  @override
  String get fieldQuantity => 'Menge';

  @override
  String get setExpiry => 'Ablaufdatum festlegen';

  @override
  String get clearDate => 'Datum löschen';

  @override
  String get quick3Days => '+3 Tage';

  @override
  String get quick1Week => '+1 Woche';

  @override
  String get quick2Weeks => '+2 Wochen';

  @override
  String get quick1Month => '+1 Monat';

  @override
  String get saveToPantry => 'Im Vorrat speichern';

  @override
  String get saveChanges => 'Änderungen speichern';

  @override
  String get nameFirst => 'Gib dem Artikel zuerst einen Namen.';

  @override
  String foundFromBarcode(String name) {
    return '„$name“ über den Barcode gefunden.';
  }

  @override
  String readDate(String date) {
    return 'Datum $date vom Etikett gelesen.';
  }

  @override
  String failed(String error) {
    return 'Fehler: $error';
  }

  @override
  String get scanBarcode => 'Barcode scannen';

  @override
  String get torchOn => 'Taschenlampe an';

  @override
  String get torchOff => 'Taschenlampe aus';

  @override
  String get typeCode => 'Code eintippen';

  @override
  String get enterBarcode => 'Barcode eingeben';

  @override
  String get barcodeDigitsHint => 'Ziffern unter dem Barcode';

  @override
  String get runInstructions =>
      'Scanne ein Produkt nach dem anderen. Nochmal scannen zählt ein weiteres Stück.';

  @override
  String get singleInstructions => 'Richte den Barcode im Rahmen aus.';

  @override
  String get nothingScanned => 'Noch nichts gescannt';

  @override
  String scannedSummary(int total, int products) {
    return '$total gescannt · $products Produkte';
  }

  @override
  String get useItUp => 'Aufbrauchen';

  @override
  String get recipesEmpty =>
      'Füge Artikel zu deinem Vorrat hinzu, um Rezeptideen zu bekommen.';

  @override
  String get newIdeas => 'Neue Ideen';

  @override
  String get alreadyOnShoppingList => 'Steht schon auf deiner Einkaufsliste';

  @override
  String addedNToList(int count) {
    return '$count zur Einkaufsliste hinzugefügt';
  }

  @override
  String get shoppingList => 'Einkaufsliste';

  @override
  String get toPantry => 'In den Vorrat';

  @override
  String get listEmpty => 'Deine Liste ist leer.';

  @override
  String get addItemHint => 'Artikel hinzufügen';

  @override
  String movedToPantry(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count in den Vorrat verschoben',
      one: '1 in den Vorrat verschoben',
    );
    return '$_temp0';
  }

  @override
  String get remindersHeader => 'Erinnerungen';

  @override
  String get remindBefore => 'Erinnern vor Ablauf';

  @override
  String dayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage',
      one: '1 Tag',
    );
    return '$_temp0';
  }

  @override
  String get timeOfDay => 'Uhrzeit';

  @override
  String get rescheduleNote =>
      'Eine Änderung plant die Erinnerungen für alle Artikel mit Ablaufdatum neu.';

  @override
  String get yourData => 'Deine Daten';

  @override
  String get exportBackup => 'Sicherung exportieren';

  @override
  String get exportBackupDesc =>
      'Vorrat, Einkaufsliste, Erinnerungen und gemerkte Produkte als JSON-Datei';

  @override
  String get importBackup => 'Sicherung importieren';

  @override
  String get importBackupDesc =>
      'Aus einer PantryPal-Sicherung wiederherstellen';

  @override
  String get backupNote =>
      'Sicherungen bleiben auf deinem Gerät, bis du entscheidest, wohin du sie schickst.';

  @override
  String exportFailed(String error) {
    return 'Export fehlgeschlagen: $error';
  }

  @override
  String openFileFailed(String error) {
    return 'Datei konnte nicht geöffnet werden: $error';
  }

  @override
  String get backupNotJson => 'Diese Datei ist kein gültiges JSON.';

  @override
  String get backupNotPantryPal => 'Diese Datei ist keine PantryPal-Sicherung.';

  @override
  String get backupTooNew =>
      'Diese Sicherung stammt aus einer neueren PantryPal-Version. Bitte zuerst die App aktualisieren.';

  @override
  String get restoreTitle => 'Sicherung wiederherstellen?';

  @override
  String pantryItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Vorratsartikel',
      one: '1 Vorratsartikel',
    );
    return '$_temp0';
  }

  @override
  String shoppingItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einkaufsartikel',
      one: '1 Einkaufsartikel',
    );
    return '$_temp0';
  }

  @override
  String restoreSummary(String pantry, String shopping) {
    return 'Diese Sicherung enthält $pantry und $shopping.';
  }

  @override
  String restoreSummaryDated(String date, String pantry, String shopping) {
    return 'Diese Sicherung vom $date enthält $pantry und $shopping.';
  }

  @override
  String get restoreExplain =>
      'Ersetzen löscht zuerst alles auf diesem Gerät und stellt die Erinnerungen wieder her. Zusammenführen ergänzt die Sicherung zu deinen Daten.';

  @override
  String get merge => 'Zusammenführen';

  @override
  String get replace => 'Ersetzen';

  @override
  String restoredSummary(int pantry, int shopping) {
    return '$pantry Vorrats- und $shopping Einkaufsartikel wiederhergestellt';
  }

  @override
  String useAmountTitle(String name) {
    return 'Wie viel $name hast du verbraucht?';
  }

  @override
  String youHave(String amount) {
    return 'Du hast $amount.';
  }

  @override
  String get useAll => 'Alles';

  @override
  String get use => 'Verbrauchen';

  @override
  String notifTitle(String name) {
    return '$name läuft bald ab';
  }

  @override
  String notifBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Läuft in $count Tagen ab – tippe für Rezeptideen.',
      one: 'Läuft in 1 Tag ab – tippe für Rezeptideen.',
    );
    return '$_temp0';
  }

  @override
  String get notifChannel => 'Ablauf-Erinnerungen';

  @override
  String get widgetEmpty => 'In den nächsten 2 Wochen läuft nichts ab';

  @override
  String widgetDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage',
      one: '1 Tag',
      zero: 'heute',
    );
    return '$_temp0';
  }

  @override
  String get widgetExpired => 'abgelaufen';

  @override
  String get languageHeader => 'Sprache';

  @override
  String get appLanguage => 'App-Sprache';

  @override
  String get languageSystem => 'Systemsprache';

  @override
  String barcodeRemembered(String name) {
    return '„$name“ aus deinen früheren Scans erkannt.';
  }

  @override
  String barcodeNotFoundLearn(String code) {
    return 'Barcode $code ist nicht in der Produktdatenbank. Gib ihm einmal einen Namen, dann merkt sich PantryPal ihn.';
  }

  @override
  String get addExpiryNow => 'Datum vom Etikett hinzufügen';

  @override
  String get otherDatesFound => 'Auf dem Etikett gefundene Daten:';

  @override
  String endOfMonth(String month) {
    return 'Ende $month';
  }

  @override
  String usuallyLasts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hält meist $count Tage',
      one: 'Hält meist 1 Tag',
    );
    return '$_temp0';
  }

  @override
  String get estimatedFromHistory =>
      'Geschätzt danach, wie lange es bei dir meist hält – bitte auf der Packung prüfen.';

  @override
  String get saveAndAddAnother => 'Speichern und weiteren hinzufügen';

  @override
  String savedItem(String name) {
    return '$name gespeichert';
  }

  @override
  String get offlineError =>
      'Keine Verbindung. Prüfe dein Internet und versuche es erneut.';

  @override
  String get aiUnavailable =>
      'Der KI-Dienst ist gerade nicht erreichbar. Versuche es erneut oder gib die Angaben selbst ein.';

  @override
  String get invalidBarcode =>
      'Das sieht nicht nach einem gültigen Barcode aus. Prüfe die Ziffern.';

  @override
  String get addSeveral => 'Mehrere auf einmal hinzufügen';

  @override
  String get quickListTitle => 'Mehrere hinzufügen';

  @override
  String get quickListHint =>
      'Ein Artikel pro Zeile, zum Beispiel:\n2 x Milch\nMehl 1 kg\nEier 12\nBananen';

  @override
  String get quickListEmpty => 'Gib mindestens einen Artikel ein.';

  @override
  String get reviewList => 'Artikel prüfen';

  @override
  String get noDateFoundTitle => 'Kein Datum gefunden';

  @override
  String get noDateFoundBody =>
      'Das hat die Kamera gelesen. Wähle das Datum selbst oder versuche es näher und bei besserem Licht.';

  @override
  String get nothingReadable =>
      'Auf dem Foto war kein Text lesbar. Versuche es näher und bei besserem Licht.';

  @override
  String get pickDate => 'Datum wählen';

  @override
  String get barcodeFromPhoto => 'Barcode aus Foto';

  @override
  String get noBarcodeInPhoto => 'Auf dem Foto wurde kein Barcode gefunden.';

  @override
  String dateYearAssumed(String date) {
    return '$date (Jahr angenommen)';
  }

  @override
  String get rememberedProducts => 'Gemerkte Produkte';

  @override
  String get rememberedProductsDesc =>
      'Was PantryPal aus deinen Scans gelernt hat';

  @override
  String rememberedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gemerkte Produkte',
      one: '1 gemerktes Produkt',
    );
    return '$_temp0';
  }

  @override
  String get noRememberedProducts =>
      'Noch nichts gemerkt. Produkte, die du hinzufügst, werden hier gemerkt, damit der nächste Scan schneller geht.';

  @override
  String get forgetAll => 'Alles vergessen';

  @override
  String get forgetAllConfirm =>
      'Alle gemerkten Produkte und gespeicherten Barcode-Abfragen vergessen? Dein Vorrat bleibt unverändert.';

  @override
  String forgotProduct(String name) {
    return '$name vergessen';
  }

  @override
  String get forgetProduct => 'Vergessen';

  @override
  String get searchRemembered => 'Gemerkte Produkte durchsuchen';

  @override
  String get recipesIdeas => 'Ideen';

  @override
  String get recipesSaved => 'Gespeichert';

  @override
  String get recipesBuildAround => 'Aufbauen auf';

  @override
  String get recipesMore => 'Mehr Ideen';

  @override
  String get recipesNoSaved =>
      'Noch keine gespeicherten Rezepte. Tippe auf das Lesezeichen eines Rezepts, um es zu behalten.';

  @override
  String recipeMinutes(int minutes) {
    return '$minutes Min.';
  }

  @override
  String recipeServings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Portionen',
      one: '1 Portion',
    );
    return '$_temp0';
  }

  @override
  String recipeUsesExpiring(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'verbraucht $count bald ablaufende Artikel',
      one: 'verbraucht 1 bald ablaufenden Artikel',
    );
    return '$_temp0';
  }

  @override
  String recipeToBuyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zu kaufen',
      one: '1 zu kaufen',
      zero: 'nichts zu kaufen',
    );
    return '$_temp0';
  }

  @override
  String get recipeIngredients => 'Zutaten';

  @override
  String get recipeSteps => 'Schritte';

  @override
  String get addMissingToList => 'Fehlendes auf die Einkaufsliste';

  @override
  String get saveRecipe => 'Rezept speichern';

  @override
  String get unsaveRecipe => 'Aus Gespeicherten entfernen';

  @override
  String get cookedThis => 'Habe ich gekocht';

  @override
  String get cookSheetTitle => 'Vorrat aktualisieren';

  @override
  String get cookSheetHint =>
      'Entferne die Haken bei allem, was du nicht verwendet hast, und passe die Mengen an. Unklare Mengen sind zunächst nicht angehakt.';

  @override
  String get cookUsesAll => 'wird ganz verbraucht';

  @override
  String cookLeftAfter(String amount) {
    return 'danach noch $amount';
  }

  @override
  String get updatePantry => 'Vorrat aktualisieren';

  @override
  String pantryUpdated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Vorratsartikel aktualisiert',
      one: '1 Vorratsartikel aktualisiert',
    );
    return '$_temp0';
  }

  @override
  String get recipePrefsTitle => 'Rezept-Einstellungen';

  @override
  String get prefsDiet => 'Ernährung';

  @override
  String get dietVegetarian => 'Vegetarisch';

  @override
  String get dietVegan => 'Vegan';

  @override
  String get dietGlutenFree => 'Glutenfrei';

  @override
  String get dietDairyFree => 'Laktosefrei';

  @override
  String get prefsServings => 'Portionen';

  @override
  String get prefsTime => 'Zeit';

  @override
  String get prefsAnyTime => 'Beliebig';

  @override
  String get prefsAvoid => 'Weglassen';

  @override
  String get prefsAvoidHint => 'z. B. Pilze, Erdnüsse';

  @override
  String get prefsAllergyNote =>
      'Die Vorschläge stammen von einer KI und können trotzdem Dinge enthalten, die du weglassen wolltest. Bei Allergien immer die Zutaten prüfen.';

  @override
  String get prefsApply => 'Übernehmen';

  @override
  String get catSeafood => 'Fisch & Meeresfrüchte';

  @override
  String get catPlantProtein => 'Tofu & pflanzliches Eiweiß';

  @override
  String get catDeli => 'Feinkost & Fertiggerichte';

  @override
  String get catGrains => 'Reis, Nudeln & Getreide';

  @override
  String get catBaking => 'Backzutaten';

  @override
  String get catCanned => 'Konserven & Gläser';

  @override
  String get catCondiments => 'Soßen, Öle & Würzmittel';

  @override
  String get catSpices => 'Gewürze';

  @override
  String get catSpreads => 'Aufstriche & Süßungsmittel';

  @override
  String get catSnacks => 'Snacks & Süßigkeiten';

  @override
  String get catAlcohol => 'Bier, Wein & Spirituosen';

  @override
  String get catBaby => 'Baby';

  @override
  String get catPet => 'Tierbedarf';

  @override
  String get catHousehold => 'Haushalt';

  @override
  String get recipesPlan => 'Plan';

  @override
  String get planIntro =>
      'Plane die Abendessen der Woche. Gerichte mit bald ablaufenden Zutaten kommen zuerst.';

  @override
  String get planMyWeek => 'Woche planen';

  @override
  String get planHowManyDays => 'Abendessen planen für';

  @override
  String get planFull =>
      'Für jeden Tag in diesem Zeitraum ist schon ein Gericht geplant.';

  @override
  String get weekShopping => 'Einkauf für die Woche';

  @override
  String get weekShoppingTitle => 'Für deine geplanten Gerichte einkaufen';

  @override
  String get weekShoppingNone => 'Du hast alles für deine geplanten Gerichte.';

  @override
  String weekShoppingFor(String recipes) {
    return 'für $recipes';
  }

  @override
  String addNToShoppingList(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count auf die Einkaufsliste',
      one: '1 auf die Einkaufsliste',
    );
    return '$_temp0';
  }

  @override
  String get planToday => 'Heute';

  @override
  String get planTomorrow => 'Morgen';

  @override
  String get planNothing => 'Nichts geplant';

  @override
  String get planSwap => 'Gegen andere Idee tauschen';

  @override
  String get planRemove => 'Aus dem Plan entfernen';

  @override
  String get planCooked => 'Gekocht';

  @override
  String get addToPlan => 'Zum Plan hinzufügen';

  @override
  String get planWhichDay => 'Welcher Tag?';

  @override
  String plannedAdded(String day) {
    return 'Zu $day hinzugefügt';
  }

  @override
  String get appearanceHeader => 'Darstellung';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get scanFirstItem => 'Ersten Artikel scannen';

  @override
  String get introAddTitle => 'Füge hinzu, was du kaufst';

  @override
  String get introAddBody =>
      'Scanne einen Barcode, einen Kassenbon oder ein Datum, oder tippe es ein. PantryPal merkt sich Produkte fürs nächste Mal.';

  @override
  String get introRemindTitle => 'Wisse, was zuerst weg muss';

  @override
  String get introRemindBody =>
      'Sieh auf einen Blick, was bald abläuft, und lass dich erinnern, bevor etwas schlecht wird.';

  @override
  String get introCookTitle => 'Koche mit dem, was da ist';

  @override
  String get introCookBody =>
      'Hol dir Rezeptideen aus deinem Vorrat, plane die Woche und erstelle eine Einkaufsliste dafür.';

  @override
  String get introSkip => 'Überspringen';

  @override
  String get introNext => 'Weiter';

  @override
  String get introStart => 'Los geht\'s';

  @override
  String introPage(int current, int total) {
    return 'Seite $current von $total';
  }

  @override
  String get recipesNoMatch =>
      'Mit deinen Einstellungen und deinem Vorrat passt gerade nichts. Lockere die Rezept-Einstellungen oder füge ein paar Artikel hinzu.';

  @override
  String get recipesNoMore =>
      'Das sind alle Ideen für deinen aktuellen Vorrat.';

  @override
  String get onYourList => 'Auf deiner Einkaufsliste';

  @override
  String get recipeBasics => 'Küchen-Basics';

  @override
  String get notForMe => 'Nichts für mich';

  @override
  String get fewerLikeThis => 'Verstanden – weniger Ideen wie diese.';

  @override
  String get recipeLearningHeader => 'Rezeptvorschläge';

  @override
  String get resetTaste => 'Gelerntes zurücksetzen';

  @override
  String get resetTasteBody =>
      'Vorschläge passen sich an die Gerichte an, die du kochst, speicherst, planst oder ablehnst. Das bleibt auf deinem Handy.';

  @override
  String get resetTasteConfirm => 'Zurücksetzen';

  @override
  String get resetTasteDone => 'Vorschläge starten neu.';
}
