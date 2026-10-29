import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'PantryPal'**
  String get appTitle;

  /// Language name in English, sent to the AI so names, recipes and steps come back in this language.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get aiLanguage;

  /// No description provided for @navPantry.
  ///
  /// In en, this message translates to:
  /// **'Pantry'**
  String get navPantry;

  /// No description provided for @navRecipes.
  ///
  /// In en, this message translates to:
  /// **'Recipes'**
  String get navRecipes;

  /// No description provided for @navShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get navShopping;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @catProduce.
  ///
  /// In en, this message translates to:
  /// **'Fruit & veg'**
  String get catProduce;

  /// No description provided for @catDairy.
  ///
  /// In en, this message translates to:
  /// **'Dairy & eggs'**
  String get catDairy;

  /// No description provided for @catMeat.
  ///
  /// In en, this message translates to:
  /// **'Meat & poultry'**
  String get catMeat;

  /// Shelf-stable items that fit no more specific category.
  ///
  /// In en, this message translates to:
  /// **'Pantry staples'**
  String get catPantry;

  /// No description provided for @catFrozen.
  ///
  /// In en, this message translates to:
  /// **'Frozen'**
  String get catFrozen;

  /// No description provided for @catBakery.
  ///
  /// In en, this message translates to:
  /// **'Bread & bakery'**
  String get catBakery;

  /// No description provided for @catBeverage.
  ///
  /// In en, this message translates to:
  /// **'Drinks'**
  String get catBeverage;

  /// No description provided for @catOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get catOther;

  /// Short picker label for counted items (pieces).
  ///
  /// In en, this message translates to:
  /// **'pcs'**
  String get unitPieces;

  /// No description provided for @statusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get statusExpired;

  /// No description provided for @statusSoon.
  ///
  /// In en, this message translates to:
  /// **'Use soon'**
  String get statusSoon;

  /// No description provided for @statusFresh.
  ///
  /// In en, this message translates to:
  /// **'Fresh'**
  String get statusFresh;

  /// No description provided for @statusUndated.
  ///
  /// In en, this message translates to:
  /// **'No date'**
  String get statusUndated;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search your pantry'**
  String get searchHint;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @noMatches.
  ///
  /// In en, this message translates to:
  /// **'No items match.'**
  String get noMatches;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @emptyPantry.
  ///
  /// In en, this message translates to:
  /// **'Your pantry is empty.\nTap Scan to add a grocery.'**
  String get emptyPantry;

  /// No description provided for @emptyPantryHint.
  ///
  /// In en, this message translates to:
  /// **'Scan a barcode, snap a photo, or import a whole receipt.'**
  String get emptyPantryHint;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// No description provided for @removedItem.
  ///
  /// In en, this message translates to:
  /// **'Removed {name}'**
  String removedItem(String name);

  /// No description provided for @expiresOn.
  ///
  /// In en, this message translates to:
  /// **'Expires {date}'**
  String expiresOn(String date);

  /// No description provided for @expiredOn.
  ///
  /// In en, this message translates to:
  /// **'Expired {date}'**
  String expiredOn(String date);

  /// No description provided for @expiresToday.
  ///
  /// In en, this message translates to:
  /// **'Expires today'**
  String get expiresToday;

  /// No description provided for @noExpiryDate.
  ///
  /// In en, this message translates to:
  /// **'No expiry date'**
  String get noExpiryDate;

  /// No description provided for @usedOne.
  ///
  /// In en, this message translates to:
  /// **'Used one'**
  String get usedOne;

  /// No description provided for @leftAfterThis.
  ///
  /// In en, this message translates to:
  /// **'{amount} left after this'**
  String leftAfterThis(String amount);

  /// No description provided for @removesFromPantry.
  ///
  /// In en, this message translates to:
  /// **'Removes it from the pantry'**
  String get removesFromPantry;

  /// No description provided for @usedSome.
  ///
  /// In en, this message translates to:
  /// **'Used some…'**
  String get usedSome;

  /// No description provided for @amountLeft.
  ///
  /// In en, this message translates to:
  /// **'{amount} left'**
  String amountLeft(String amount);

  /// No description provided for @addToShoppingList.
  ///
  /// In en, this message translates to:
  /// **'Add to shopping list'**
  String get addToShoppingList;

  /// No description provided for @alreadyOnList.
  ///
  /// In en, this message translates to:
  /// **'{name} is already on your list'**
  String alreadyOnList(String name);

  /// No description provided for @addedToList.
  ///
  /// In en, this message translates to:
  /// **'Added {name} to your list'**
  String addedToList(String name);

  /// No description provided for @badgeNoDate.
  ///
  /// In en, this message translates to:
  /// **'no date'**
  String get badgeNoDate;

  /// No description provided for @badgeAgo.
  ///
  /// In en, this message translates to:
  /// **'d ago'**
  String get badgeAgo;

  /// No description provided for @badgeToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get badgeToday;

  /// No description provided for @badgeDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{day} other{days}}'**
  String badgeDays(int count);

  /// No description provided for @expiresInDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Expires in 1 day} other{Expires in {count} days}}'**
  String expiresInDays(int count);

  /// No description provided for @expiredDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Expired 1 day ago} other{Expired {count} days ago}}'**
  String expiredDaysAgo(int count);

  /// No description provided for @addToPantry.
  ///
  /// In en, this message translates to:
  /// **'Add to pantry'**
  String get addToPantry;

  /// No description provided for @sourceCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get sourceCamera;

  /// No description provided for @sourcePhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get sourcePhotos;

  /// No description provided for @oneItem.
  ///
  /// In en, this message translates to:
  /// **'One item'**
  String get oneItem;

  /// No description provided for @severalAtOnce.
  ///
  /// In en, this message translates to:
  /// **'Several at once'**
  String get severalAtOnce;

  /// No description provided for @modeBarcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get modeBarcode;

  /// No description provided for @modeBarcodeDesc.
  ///
  /// In en, this message translates to:
  /// **'Look up one product by its barcode'**
  String get modeBarcodeDesc;

  /// No description provided for @modeDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date label'**
  String get modeDateLabel;

  /// No description provided for @modeDateLabelDesc.
  ///
  /// In en, this message translates to:
  /// **'Read a printed expiry date (stays on your phone)'**
  String get modeDateLabelDesc;

  /// No description provided for @modeManual.
  ///
  /// In en, this message translates to:
  /// **'Type it in'**
  String get modeManual;

  /// No description provided for @modeManualDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter the details yourself'**
  String get modeManualDesc;

  /// No description provided for @modeBarcodeRun.
  ///
  /// In en, this message translates to:
  /// **'Barcode run'**
  String get modeBarcodeRun;

  /// No description provided for @modeBarcodeRunDesc.
  ///
  /// In en, this message translates to:
  /// **'Scan product after product, review once at the end'**
  String get modeBarcodeRunDesc;

  /// No description provided for @modeReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get modeReceipt;

  /// No description provided for @modeReceiptDesc.
  ///
  /// In en, this message translates to:
  /// **'Import every food item from a grocery receipt'**
  String get modeReceiptDesc;

  /// No description provided for @reviewScanned.
  ///
  /// In en, this message translates to:
  /// **'Review scanned items'**
  String get reviewScanned;

  /// No description provided for @reviewReceipt.
  ///
  /// In en, this message translates to:
  /// **'Review receipt'**
  String get reviewReceipt;

  /// No description provided for @addedToPantry.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Added 1 item to your pantry} other{Added {count} items to your pantry}}'**
  String addedToPantry(int count);

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// No description provided for @selectNone.
  ///
  /// In en, this message translates to:
  /// **'Select none'**
  String get selectNone;

  /// No description provided for @scanReadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read that scan.'**
  String get scanReadError;

  /// No description provided for @readingScan.
  ///
  /// In en, this message translates to:
  /// **'Reading your scan…'**
  String get readingScan;

  /// No description provided for @readingScanHint.
  ///
  /// In en, this message translates to:
  /// **'This can take a few seconds.'**
  String get readingScanHint;

  /// No description provided for @noFoodFound.
  ///
  /// In en, this message translates to:
  /// **'No food items found.'**
  String get noFoodFound;

  /// No description provided for @noFoodFoundHint.
  ///
  /// In en, this message translates to:
  /// **'Try a sharper, well-lit photo, or add items one at a time.'**
  String get noFoodFoundHint;

  /// No description provided for @foundIntro.
  ///
  /// In en, this message translates to:
  /// **'Found {count}. Fix anything that looks off and untick what you don\'t want.'**
  String foundIntro(int count);

  /// No description provided for @itemNameHint.
  ///
  /// In en, this message translates to:
  /// **'Item name'**
  String get itemNameHint;

  /// No description provided for @barcodeHelper.
  ///
  /// In en, this message translates to:
  /// **'Barcode {code}'**
  String barcodeHelper(String code);

  /// No description provided for @notFoundTypeName.
  ///
  /// In en, this message translates to:
  /// **'Not found — type a name'**
  String get notFoundTypeName;

  /// No description provided for @removeFromList.
  ///
  /// In en, this message translates to:
  /// **'Remove from list'**
  String get removeFromList;

  /// No description provided for @addDate.
  ///
  /// In en, this message translates to:
  /// **'Add date'**
  String get addDate;

  /// No description provided for @estimatedDate.
  ///
  /// In en, this message translates to:
  /// **'{date} (est.)'**
  String estimatedDate(String date);

  /// No description provided for @addItemsButton.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Add 1 item to pantry} other{Add {count} items to pantry}}'**
  String addItemsButton(int count);

  /// No description provided for @less.
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get less;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addItem;

  /// No description provided for @editItem.
  ///
  /// In en, this message translates to:
  /// **'Edit item'**
  String get editItem;

  /// No description provided for @fillAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Fill in automatically'**
  String get fillAutomatically;

  /// No description provided for @scanDate.
  ///
  /// In en, this message translates to:
  /// **'Scan date'**
  String get scanDate;

  /// No description provided for @fieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fieldName;

  /// No description provided for @fieldCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get fieldCategory;

  /// No description provided for @fieldQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get fieldQuantity;

  /// No description provided for @setExpiry.
  ///
  /// In en, this message translates to:
  /// **'Set expiration date'**
  String get setExpiry;

  /// No description provided for @clearDate.
  ///
  /// In en, this message translates to:
  /// **'Clear date'**
  String get clearDate;

  /// No description provided for @quick3Days.
  ///
  /// In en, this message translates to:
  /// **'+3 days'**
  String get quick3Days;

  /// No description provided for @quick1Week.
  ///
  /// In en, this message translates to:
  /// **'+1 week'**
  String get quick1Week;

  /// No description provided for @quick2Weeks.
  ///
  /// In en, this message translates to:
  /// **'+2 weeks'**
  String get quick2Weeks;

  /// No description provided for @quick1Month.
  ///
  /// In en, this message translates to:
  /// **'+1 month'**
  String get quick1Month;

  /// No description provided for @saveToPantry.
  ///
  /// In en, this message translates to:
  /// **'Save to pantry'**
  String get saveToPantry;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @nameFirst.
  ///
  /// In en, this message translates to:
  /// **'Give the item a name first.'**
  String get nameFirst;

  /// No description provided for @foundFromBarcode.
  ///
  /// In en, this message translates to:
  /// **'Found “{name}” from its barcode.'**
  String foundFromBarcode(String name);

  /// No description provided for @readDate.
  ///
  /// In en, this message translates to:
  /// **'Read the date {date} from the label.'**
  String readDate(String date);

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String failed(String error);

  /// No description provided for @scanBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan barcode'**
  String get scanBarcode;

  /// No description provided for @torchOn.
  ///
  /// In en, this message translates to:
  /// **'Torch on'**
  String get torchOn;

  /// No description provided for @torchOff.
  ///
  /// In en, this message translates to:
  /// **'Torch off'**
  String get torchOff;

  /// No description provided for @typeCode.
  ///
  /// In en, this message translates to:
  /// **'Type a code'**
  String get typeCode;

  /// No description provided for @enterBarcode.
  ///
  /// In en, this message translates to:
  /// **'Enter barcode'**
  String get enterBarcode;

  /// No description provided for @barcodeDigitsHint.
  ///
  /// In en, this message translates to:
  /// **'Digits under the barcode'**
  String get barcodeDigitsHint;

  /// No description provided for @runInstructions.
  ///
  /// In en, this message translates to:
  /// **'Scan each product in turn. Scanning one again adds another of it.'**
  String get runInstructions;

  /// No description provided for @singleInstructions.
  ///
  /// In en, this message translates to:
  /// **'Line up the barcode inside the frame.'**
  String get singleInstructions;

  /// No description provided for @nothingScanned.
  ///
  /// In en, this message translates to:
  /// **'Nothing scanned yet'**
  String get nothingScanned;

  /// No description provided for @scannedSummary.
  ///
  /// In en, this message translates to:
  /// **'{total} scanned · {products} products'**
  String scannedSummary(int total, int products);

  /// No description provided for @useItUp.
  ///
  /// In en, this message translates to:
  /// **'Use it up'**
  String get useItUp;

  /// No description provided for @recipesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add some items to your pantry to get recipe ideas.'**
  String get recipesEmpty;

  /// No description provided for @newIdeas.
  ///
  /// In en, this message translates to:
  /// **'New ideas'**
  String get newIdeas;

  /// No description provided for @alreadyOnShoppingList.
  ///
  /// In en, this message translates to:
  /// **'Already on your shopping list'**
  String get alreadyOnShoppingList;

  /// No description provided for @addedNToList.
  ///
  /// In en, this message translates to:
  /// **'Added {count} to your shopping list'**
  String addedNToList(int count);

  /// No description provided for @shoppingList.
  ///
  /// In en, this message translates to:
  /// **'Shopping list'**
  String get shoppingList;

  /// No description provided for @toPantry.
  ///
  /// In en, this message translates to:
  /// **'To pantry'**
  String get toPantry;

  /// No description provided for @listEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your list is empty.'**
  String get listEmpty;

  /// No description provided for @addItemHint.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addItemHint;

  /// No description provided for @movedToPantry.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Moved 1 to your pantry} other{Moved {count} to your pantry}}'**
  String movedToPantry(int count);

  /// No description provided for @remindersHeader.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get remindersHeader;

  /// No description provided for @remindBefore.
  ///
  /// In en, this message translates to:
  /// **'Remind me before expiry'**
  String get remindBefore;

  /// No description provided for @dayCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String dayCount(int count);

  /// No description provided for @timeOfDay.
  ///
  /// In en, this message translates to:
  /// **'Time of day'**
  String get timeOfDay;

  /// No description provided for @rescheduleNote.
  ///
  /// In en, this message translates to:
  /// **'Changing these reschedules reminders for every item with an expiry date.'**
  String get rescheduleNote;

  /// No description provided for @yourData.
  ///
  /// In en, this message translates to:
  /// **'Your data'**
  String get yourData;

  /// No description provided for @exportBackup.
  ///
  /// In en, this message translates to:
  /// **'Export backup'**
  String get exportBackup;

  /// No description provided for @exportBackupDesc.
  ///
  /// In en, this message translates to:
  /// **'Pantry, shopping list, reminder settings and remembered products as a JSON file'**
  String get exportBackupDesc;

  /// No description provided for @importBackup.
  ///
  /// In en, this message translates to:
  /// **'Import backup'**
  String get importBackup;

  /// No description provided for @importBackupDesc.
  ///
  /// In en, this message translates to:
  /// **'Restore from a PantryPal backup file'**
  String get importBackupDesc;

  /// No description provided for @backupNote.
  ///
  /// In en, this message translates to:
  /// **'Backups stay on your device until you choose where to send them.'**
  String get backupNote;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailed(String error);

  /// No description provided for @openFileFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the file: {error}'**
  String openFileFailed(String error);

  /// No description provided for @backupNotJson.
  ///
  /// In en, this message translates to:
  /// **'That file isn\'t valid JSON.'**
  String get backupNotJson;

  /// No description provided for @backupNotPantryPal.
  ///
  /// In en, this message translates to:
  /// **'That file isn\'t a PantryPal backup.'**
  String get backupNotPantryPal;

  /// No description provided for @backupTooNew.
  ///
  /// In en, this message translates to:
  /// **'This backup was made by a newer version of PantryPal. Update the app first.'**
  String get backupTooNew;

  /// No description provided for @restoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore backup?'**
  String get restoreTitle;

  /// No description provided for @pantryItemCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 pantry item} other{{count} pantry items}}'**
  String pantryItemCount(int count);

  /// No description provided for @shoppingItemCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 shopping item} other{{count} shopping items}}'**
  String shoppingItemCount(int count);

  /// No description provided for @restoreSummary.
  ///
  /// In en, this message translates to:
  /// **'This backup has {pantry} and {shopping}.'**
  String restoreSummary(String pantry, String shopping);

  /// No description provided for @restoreSummaryDated.
  ///
  /// In en, this message translates to:
  /// **'This backup from {date} has {pantry} and {shopping}.'**
  String restoreSummaryDated(String date, String pantry, String shopping);

  /// No description provided for @restoreExplain.
  ///
  /// In en, this message translates to:
  /// **'Replace wipes what\'s on this phone first and restores reminder settings. Merge adds the backup to what you have.'**
  String get restoreExplain;

  /// No description provided for @merge.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get merge;

  /// No description provided for @replace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replace;

  /// No description provided for @restoredSummary.
  ///
  /// In en, this message translates to:
  /// **'Restored {pantry} pantry and {shopping} shopping items'**
  String restoredSummary(int pantry, int shopping);

  /// No description provided for @useAmountTitle.
  ///
  /// In en, this message translates to:
  /// **'How much {name} did you use?'**
  String useAmountTitle(String name);

  /// No description provided for @youHave.
  ///
  /// In en, this message translates to:
  /// **'You have {amount}.'**
  String youHave(String amount);

  /// No description provided for @useAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get useAll;

  /// No description provided for @use.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get use;

  /// No description provided for @notifTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} expires soon'**
  String notifTitle(String name);

  /// No description provided for @notifBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Expires in 1 day — tap for recipe ideas.} other{Expires in {count} days — tap for recipe ideas.}}'**
  String notifBody(int count);

  /// No description provided for @notifChannel.
  ///
  /// In en, this message translates to:
  /// **'Expiry reminders'**
  String get notifChannel;

  /// Home-screen widget text when no item expires within 14 days.
  ///
  /// In en, this message translates to:
  /// **'Nothing expiring in the next 2 weeks'**
  String get widgetEmpty;

  /// Home-screen widget: time left for one item.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{today} =1{1 day} other{{count} days}}'**
  String widgetDaysLeft(int count);

  /// Home-screen widget: shown instead of days for an expired item.
  ///
  /// In en, this message translates to:
  /// **'expired'**
  String get widgetExpired;

  /// No description provided for @languageHeader.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageHeader;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get appLanguage;

  /// Language picker option: follow the phone's language.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @barcodeRemembered.
  ///
  /// In en, this message translates to:
  /// **'Recognized “{name}” from your earlier scans.'**
  String barcodeRemembered(String name);

  /// No description provided for @barcodeNotFoundLearn.
  ///
  /// In en, this message translates to:
  /// **'Barcode {code} isn\'t in the product database. Name it once and PantryPal will remember it.'**
  String barcodeNotFoundLearn(String code);

  /// No description provided for @addExpiryNow.
  ///
  /// In en, this message translates to:
  /// **'Add the date from the label'**
  String get addExpiryNow;

  /// No description provided for @otherDatesFound.
  ///
  /// In en, this message translates to:
  /// **'Dates found on the label:'**
  String get otherDatesFound;

  /// Best-before printed as month + year only; {month} is e.g. 'Mar 2027'.
  ///
  /// In en, this message translates to:
  /// **'end of {month}'**
  String endOfMonth(String month);

  /// Quick-date chip using this user's own history for the item.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Usually 1 day} other{Usually {count} days}}'**
  String usuallyLasts(int count);

  /// No description provided for @estimatedFromHistory.
  ///
  /// In en, this message translates to:
  /// **'Estimated from how long this usually lasts for you — check the package.'**
  String get estimatedFromHistory;

  /// No description provided for @saveAndAddAnother.
  ///
  /// In en, this message translates to:
  /// **'Save and add another'**
  String get saveAndAddAnother;

  /// No description provided for @savedItem.
  ///
  /// In en, this message translates to:
  /// **'Saved {name}'**
  String savedItem(String name);

  /// No description provided for @offlineError.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your internet and try again.'**
  String get offlineError;

  /// No description provided for @aiUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The AI service isn\'t reachable right now. Try again, or fill in the details yourself.'**
  String get aiUnavailable;

  /// No description provided for @invalidBarcode.
  ///
  /// In en, this message translates to:
  /// **'That doesn\'t look like a valid barcode. Check the digits.'**
  String get invalidBarcode;

  /// No description provided for @addSeveral.
  ///
  /// In en, this message translates to:
  /// **'Add several at once'**
  String get addSeveral;

  /// No description provided for @quickListTitle.
  ///
  /// In en, this message translates to:
  /// **'Add several'**
  String get quickListTitle;

  /// No description provided for @quickListHint.
  ///
  /// In en, this message translates to:
  /// **'One item per line, for example:\n2 x milk\nflour 1 kg\neggs 12\nbananas'**
  String get quickListHint;

  /// No description provided for @quickListEmpty.
  ///
  /// In en, this message translates to:
  /// **'Type at least one item.'**
  String get quickListEmpty;

  /// No description provided for @reviewList.
  ///
  /// In en, this message translates to:
  /// **'Review items'**
  String get reviewList;

  /// No description provided for @noDateFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'No date found'**
  String get noDateFoundTitle;

  /// No description provided for @noDateFoundBody.
  ///
  /// In en, this message translates to:
  /// **'This is what the camera read. Pick the date yourself, or try again closer and in better light.'**
  String get noDateFoundBody;

  /// No description provided for @nothingReadable.
  ///
  /// In en, this message translates to:
  /// **'No text could be read from that photo. Try again closer and in better light.'**
  String get nothingReadable;

  /// No description provided for @pickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick date'**
  String get pickDate;

  /// No description provided for @barcodeFromPhoto.
  ///
  /// In en, this message translates to:
  /// **'Barcode from a photo'**
  String get barcodeFromPhoto;

  /// No description provided for @noBarcodeInPhoto.
  ///
  /// In en, this message translates to:
  /// **'No barcode found in that photo.'**
  String get noBarcodeInPhoto;

  /// A date printed without a year (e.g. 15.03.); the next such date was assumed.
  ///
  /// In en, this message translates to:
  /// **'{date} (year assumed)'**
  String dateYearAssumed(String date);

  /// No description provided for @rememberedProducts.
  ///
  /// In en, this message translates to:
  /// **'Remembered products'**
  String get rememberedProducts;

  /// No description provided for @rememberedProductsDesc.
  ///
  /// In en, this message translates to:
  /// **'What PantryPal has learned from your scans'**
  String get rememberedProductsDesc;

  /// No description provided for @rememberedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 remembered product} other{{count} remembered products}}'**
  String rememberedCount(int count);

  /// No description provided for @noRememberedProducts.
  ///
  /// In en, this message translates to:
  /// **'Nothing remembered yet. Products you add are remembered here to make your next scan faster.'**
  String get noRememberedProducts;

  /// No description provided for @forgetAll.
  ///
  /// In en, this message translates to:
  /// **'Forget all'**
  String get forgetAll;

  /// No description provided for @forgetAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'Forget every remembered product and cached barcode lookup? Your pantry isn\'t affected.'**
  String get forgetAllConfirm;

  /// No description provided for @forgotProduct.
  ///
  /// In en, this message translates to:
  /// **'Forgot {name}'**
  String forgotProduct(String name);

  /// No description provided for @forgetProduct.
  ///
  /// In en, this message translates to:
  /// **'Forget'**
  String get forgetProduct;

  /// No description provided for @searchRemembered.
  ///
  /// In en, this message translates to:
  /// **'Search remembered products'**
  String get searchRemembered;

  /// No description provided for @recipesIdeas.
  ///
  /// In en, this message translates to:
  /// **'Ideas'**
  String get recipesIdeas;

  /// No description provided for @recipesSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get recipesSaved;

  /// No description provided for @recipesBuildAround.
  ///
  /// In en, this message translates to:
  /// **'Build around'**
  String get recipesBuildAround;

  /// No description provided for @recipesMore.
  ///
  /// In en, this message translates to:
  /// **'More ideas'**
  String get recipesMore;

  /// No description provided for @recipesNoSaved.
  ///
  /// In en, this message translates to:
  /// **'No saved recipes yet. Tap the bookmark on a recipe to keep it.'**
  String get recipesNoSaved;

  /// No description provided for @recipeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String recipeMinutes(int minutes);

  /// No description provided for @recipeServings.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 serving} other{{count} servings}}'**
  String recipeServings(int count);

  /// No description provided for @recipeUsesExpiring.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{uses 1 expiring item} other{uses {count} expiring items}}'**
  String recipeUsesExpiring(int count);

  /// No description provided for @recipeToBuyCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{nothing to buy} =1{1 to buy} other{{count} to buy}}'**
  String recipeToBuyCount(int count);

  /// No description provided for @recipeIngredients.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get recipeIngredients;

  /// No description provided for @recipeSteps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get recipeSteps;

  /// No description provided for @addMissingToList.
  ///
  /// In en, this message translates to:
  /// **'Add missing to shopping list'**
  String get addMissingToList;

  /// No description provided for @saveRecipe.
  ///
  /// In en, this message translates to:
  /// **'Save recipe'**
  String get saveRecipe;

  /// No description provided for @unsaveRecipe.
  ///
  /// In en, this message translates to:
  /// **'Remove from saved'**
  String get unsaveRecipe;

  /// No description provided for @cookedThis.
  ///
  /// In en, this message translates to:
  /// **'I cooked this'**
  String get cookedThis;

  /// No description provided for @cookSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Update your pantry'**
  String get cookSheetTitle;

  /// No description provided for @cookSheetHint.
  ///
  /// In en, this message translates to:
  /// **'Untick anything you didn\'t use, and adjust amounts. Amounts the recipe didn\'t make clear start unticked.'**
  String get cookSheetHint;

  /// No description provided for @cookUsesAll.
  ///
  /// In en, this message translates to:
  /// **'uses all of it'**
  String get cookUsesAll;

  /// No description provided for @cookLeftAfter.
  ///
  /// In en, this message translates to:
  /// **'{amount} left afterwards'**
  String cookLeftAfter(String amount);

  /// No description provided for @updatePantry.
  ///
  /// In en, this message translates to:
  /// **'Update pantry'**
  String get updatePantry;

  /// No description provided for @pantryUpdated.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Updated 1 pantry item} other{Updated {count} pantry items}}'**
  String pantryUpdated(int count);

  /// No description provided for @recipePrefsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recipe preferences'**
  String get recipePrefsTitle;

  /// No description provided for @prefsDiet.
  ///
  /// In en, this message translates to:
  /// **'Diet'**
  String get prefsDiet;

  /// No description provided for @dietVegetarian.
  ///
  /// In en, this message translates to:
  /// **'Vegetarian'**
  String get dietVegetarian;

  /// No description provided for @dietVegan.
  ///
  /// In en, this message translates to:
  /// **'Vegan'**
  String get dietVegan;

  /// No description provided for @dietGlutenFree.
  ///
  /// In en, this message translates to:
  /// **'Gluten-free'**
  String get dietGlutenFree;

  /// Recipe diet filter: no milk products (not only lactose).
  ///
  /// In en, this message translates to:
  /// **'Dairy-free'**
  String get dietDairyFree;

  /// No description provided for @prefsServings.
  ///
  /// In en, this message translates to:
  /// **'Servings'**
  String get prefsServings;

  /// No description provided for @prefsTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get prefsTime;

  /// No description provided for @prefsAnyTime.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get prefsAnyTime;

  /// No description provided for @prefsAvoid.
  ///
  /// In en, this message translates to:
  /// **'Leave out'**
  String get prefsAvoid;

  /// No description provided for @prefsAvoidHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. mushrooms, peanuts'**
  String get prefsAvoidHint;

  /// No description provided for @prefsAllergyNote.
  ///
  /// In en, this message translates to:
  /// **'Suggestions are AI-generated and can still include things you asked to leave out. If you have allergies, always check the ingredients.'**
  String get prefsAllergyNote;

  /// No description provided for @prefsApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get prefsApply;

  /// No description provided for @catSeafood.
  ///
  /// In en, this message translates to:
  /// **'Fish & seafood'**
  String get catSeafood;

  /// No description provided for @catPlantProtein.
  ///
  /// In en, this message translates to:
  /// **'Tofu & plant protein'**
  String get catPlantProtein;

  /// No description provided for @catDeli.
  ///
  /// In en, this message translates to:
  /// **'Deli & ready meals'**
  String get catDeli;

  /// No description provided for @catGrains.
  ///
  /// In en, this message translates to:
  /// **'Rice, pasta & grains'**
  String get catGrains;

  /// No description provided for @catBaking.
  ///
  /// In en, this message translates to:
  /// **'Baking'**
  String get catBaking;

  /// No description provided for @catCanned.
  ///
  /// In en, this message translates to:
  /// **'Canned & jarred'**
  String get catCanned;

  /// No description provided for @catCondiments.
  ///
  /// In en, this message translates to:
  /// **'Sauces, oils & condiments'**
  String get catCondiments;

  /// No description provided for @catSpices.
  ///
  /// In en, this message translates to:
  /// **'Spices & seasonings'**
  String get catSpices;

  /// No description provided for @catSpreads.
  ///
  /// In en, this message translates to:
  /// **'Spreads & sweeteners'**
  String get catSpreads;

  /// No description provided for @catSnacks.
  ///
  /// In en, this message translates to:
  /// **'Snacks & sweets'**
  String get catSnacks;

  /// No description provided for @catAlcohol.
  ///
  /// In en, this message translates to:
  /// **'Beer, wine & spirits'**
  String get catAlcohol;

  /// No description provided for @catBaby.
  ///
  /// In en, this message translates to:
  /// **'Baby'**
  String get catBaby;

  /// No description provided for @catPet.
  ///
  /// In en, this message translates to:
  /// **'Pet supplies'**
  String get catPet;

  /// No description provided for @catHousehold.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get catHousehold;

  /// No description provided for @recipesPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get recipesPlan;

  /// No description provided for @planIntro.
  ///
  /// In en, this message translates to:
  /// **'Plan dinners for the week. Meals that use food expiring soonest come first.'**
  String get planIntro;

  /// No description provided for @planMyWeek.
  ///
  /// In en, this message translates to:
  /// **'Plan my week'**
  String get planMyWeek;

  /// No description provided for @planHowManyDays.
  ///
  /// In en, this message translates to:
  /// **'Plan dinners for'**
  String get planHowManyDays;

  /// No description provided for @planFull.
  ///
  /// In en, this message translates to:
  /// **'Every day in that range already has a meal.'**
  String get planFull;

  /// No description provided for @weekShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping for the week'**
  String get weekShopping;

  /// No description provided for @weekShoppingTitle.
  ///
  /// In en, this message translates to:
  /// **'To buy for your planned meals'**
  String get weekShoppingTitle;

  /// No description provided for @weekShoppingNone.
  ///
  /// In en, this message translates to:
  /// **'You have everything for your planned meals.'**
  String get weekShoppingNone;

  /// No description provided for @weekShoppingFor.
  ///
  /// In en, this message translates to:
  /// **'for {recipes}'**
  String weekShoppingFor(String recipes);

  /// No description provided for @addNToShoppingList.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Add 1 to shopping list} other{Add {count} to shopping list}}'**
  String addNToShoppingList(int count);

  /// No description provided for @planToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get planToday;

  /// No description provided for @planTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get planTomorrow;

  /// No description provided for @planNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing planned'**
  String get planNothing;

  /// No description provided for @planSwap.
  ///
  /// In en, this message translates to:
  /// **'Swap for another idea'**
  String get planSwap;

  /// No description provided for @planRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from plan'**
  String get planRemove;

  /// No description provided for @planCooked.
  ///
  /// In en, this message translates to:
  /// **'Cooked'**
  String get planCooked;

  /// No description provided for @addToPlan.
  ///
  /// In en, this message translates to:
  /// **'Add to plan'**
  String get addToPlan;

  /// No description provided for @planWhichDay.
  ///
  /// In en, this message translates to:
  /// **'Which day?'**
  String get planWhichDay;

  /// {day} is "Today", "Tomorrow" or a short date.
  ///
  /// In en, this message translates to:
  /// **'Added to {day}'**
  String plannedAdded(String day);

  /// No description provided for @appearanceHeader.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceHeader;

  /// Theme follows the device light/dark setting.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @scanFirstItem.
  ///
  /// In en, this message translates to:
  /// **'Scan your first item'**
  String get scanFirstItem;

  /// No description provided for @introAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add what you buy'**
  String get introAddTitle;

  /// No description provided for @introAddBody.
  ///
  /// In en, this message translates to:
  /// **'Scan a barcode, a receipt or a date label, or just type it. PantryPal remembers products for next time.'**
  String get introAddBody;

  /// No description provided for @introRemindTitle.
  ///
  /// In en, this message translates to:
  /// **'Know what to use first'**
  String get introRemindTitle;

  /// No description provided for @introRemindBody.
  ///
  /// In en, this message translates to:
  /// **'See what is expiring at a glance, and get a reminder before food goes off.'**
  String get introRemindBody;

  /// No description provided for @introCookTitle.
  ///
  /// In en, this message translates to:
  /// **'Cook what you have'**
  String get introCookTitle;

  /// No description provided for @introCookBody.
  ///
  /// In en, this message translates to:
  /// **'Get recipe ideas from your pantry, plan the week, and make one shopping list for it.'**
  String get introCookBody;

  /// No description provided for @introSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get introSkip;

  /// No description provided for @introNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get introNext;

  /// No description provided for @introStart.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get introStart;

  /// Screen-reader label for the intro page dots.
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String introPage(int current, int total);

  /// No description provided for @recipesNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No ideas fit your preferences with what you have. Try fewer filters in Recipe preferences, or add a few more items.'**
  String get recipesNoMatch;

  /// No description provided for @recipesNoMore.
  ///
  /// In en, this message translates to:
  /// **'That\'s every idea for what you have right now.'**
  String get recipesNoMore;

  /// No description provided for @onYourList.
  ///
  /// In en, this message translates to:
  /// **'On your shopping list'**
  String get onYourList;

  /// No description provided for @recipeBasics.
  ///
  /// In en, this message translates to:
  /// **'Kitchen basics'**
  String get recipeBasics;

  /// No description provided for @notForMe.
  ///
  /// In en, this message translates to:
  /// **'Not for me'**
  String get notForMe;

  /// No description provided for @fewerLikeThis.
  ///
  /// In en, this message translates to:
  /// **'Got it — fewer ideas like this.'**
  String get fewerLikeThis;

  /// No description provided for @recipeLearningHeader.
  ///
  /// In en, this message translates to:
  /// **'Recipe suggestions'**
  String get recipeLearningHeader;

  /// No description provided for @resetTaste.
  ///
  /// In en, this message translates to:
  /// **'Reset what PantryPal has learned'**
  String get resetTaste;

  /// No description provided for @resetTasteBody.
  ///
  /// In en, this message translates to:
  /// **'Suggestions adapt to the dishes you cook, save, plan or turn down. This stays on your phone.'**
  String get resetTasteBody;

  /// No description provided for @resetTasteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetTasteConfirm;

  /// No description provided for @resetTasteDone.
  ///
  /// In en, this message translates to:
  /// **'Suggestions start fresh.'**
  String get resetTasteDone;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
