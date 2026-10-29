// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'PantryPal';

  @override
  String get aiLanguage => 'English';

  @override
  String get navPantry => 'Pantry';

  @override
  String get navRecipes => 'Recipes';

  @override
  String get navShopping => 'Shopping';

  @override
  String get settings => 'Settings';

  @override
  String get cancel => 'Cancel';

  @override
  String get add => 'Add';

  @override
  String get back => 'Back';

  @override
  String get tryAgain => 'Try again';

  @override
  String get undo => 'Undo';

  @override
  String get remove => 'Remove';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get review => 'Review';

  @override
  String get catProduce => 'Fruit & veg';

  @override
  String get catDairy => 'Dairy & eggs';

  @override
  String get catMeat => 'Meat & poultry';

  @override
  String get catPantry => 'Pantry staples';

  @override
  String get catFrozen => 'Frozen';

  @override
  String get catBakery => 'Bread & bakery';

  @override
  String get catBeverage => 'Drinks';

  @override
  String get catOther => 'Other';

  @override
  String get unitPieces => 'pcs';

  @override
  String get statusExpired => 'Expired';

  @override
  String get statusSoon => 'Use soon';

  @override
  String get statusFresh => 'Fresh';

  @override
  String get statusUndated => 'No date';

  @override
  String get searchHint => 'Search your pantry';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get filterAll => 'All';

  @override
  String get noMatches => 'No items match.';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get emptyPantry => 'Your pantry is empty.\nTap Scan to add a grocery.';

  @override
  String get emptyPantryHint =>
      'Scan a barcode, snap a photo, or import a whole receipt.';

  @override
  String get scan => 'Scan';

  @override
  String removedItem(String name) {
    return 'Removed $name';
  }

  @override
  String expiresOn(String date) {
    return 'Expires $date';
  }

  @override
  String expiredOn(String date) {
    return 'Expired $date';
  }

  @override
  String get expiresToday => 'Expires today';

  @override
  String get noExpiryDate => 'No expiry date';

  @override
  String get usedOne => 'Used one';

  @override
  String leftAfterThis(String amount) {
    return '$amount left after this';
  }

  @override
  String get removesFromPantry => 'Removes it from the pantry';

  @override
  String get usedSome => 'Used some…';

  @override
  String amountLeft(String amount) {
    return '$amount left';
  }

  @override
  String get addToShoppingList => 'Add to shopping list';

  @override
  String alreadyOnList(String name) {
    return '$name is already on your list';
  }

  @override
  String addedToList(String name) {
    return 'Added $name to your list';
  }

  @override
  String get badgeNoDate => 'no date';

  @override
  String get badgeAgo => 'd ago';

  @override
  String get badgeToday => 'today';

  @override
  String badgeDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'days',
      one: 'day',
    );
    return '$_temp0';
  }

  @override
  String expiresInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Expires in $count days',
      one: 'Expires in 1 day',
    );
    return '$_temp0';
  }

  @override
  String expiredDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Expired $count days ago',
      one: 'Expired 1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get addToPantry => 'Add to pantry';

  @override
  String get sourceCamera => 'Camera';

  @override
  String get sourcePhotos => 'Photos';

  @override
  String get oneItem => 'One item';

  @override
  String get severalAtOnce => 'Several at once';

  @override
  String get modeBarcode => 'Barcode';

  @override
  String get modeBarcodeDesc => 'Look up one product by its barcode';

  @override
  String get modeDateLabel => 'Date label';

  @override
  String get modeDateLabelDesc =>
      'Read a printed expiry date (stays on your phone)';

  @override
  String get modeManual => 'Type it in';

  @override
  String get modeManualDesc => 'Enter the details yourself';

  @override
  String get modeBarcodeRun => 'Barcode run';

  @override
  String get modeBarcodeRunDesc =>
      'Scan product after product, review once at the end';

  @override
  String get modeReceipt => 'Receipt';

  @override
  String get modeReceiptDesc => 'Import every food item from a grocery receipt';

  @override
  String get reviewScanned => 'Review scanned items';

  @override
  String get reviewReceipt => 'Review receipt';

  @override
  String addedToPantry(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Added $count items to your pantry',
      one: 'Added 1 item to your pantry',
    );
    return '$_temp0';
  }

  @override
  String get selectAll => 'Select all';

  @override
  String get selectNone => 'Select none';

  @override
  String get scanReadError => 'Couldn\'t read that scan.';

  @override
  String get readingScan => 'Reading your scan…';

  @override
  String get readingScanHint => 'This can take a few seconds.';

  @override
  String get noFoodFound => 'No food items found.';

  @override
  String get noFoodFoundHint =>
      'Try a sharper, well-lit photo, or add items one at a time.';

  @override
  String foundIntro(int count) {
    return 'Found $count. Fix anything that looks off and untick what you don\'t want.';
  }

  @override
  String get itemNameHint => 'Item name';

  @override
  String barcodeHelper(String code) {
    return 'Barcode $code';
  }

  @override
  String get notFoundTypeName => 'Not found — type a name';

  @override
  String get removeFromList => 'Remove from list';

  @override
  String get addDate => 'Add date';

  @override
  String estimatedDate(String date) {
    return '$date (est.)';
  }

  @override
  String addItemsButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add $count items to pantry',
      one: 'Add 1 item to pantry',
    );
    return '$_temp0';
  }

  @override
  String get less => 'Less';

  @override
  String get more => 'More';

  @override
  String get addItem => 'Add item';

  @override
  String get editItem => 'Edit item';

  @override
  String get fillAutomatically => 'Fill in automatically';

  @override
  String get scanDate => 'Scan date';

  @override
  String get fieldName => 'Name';

  @override
  String get fieldCategory => 'Category';

  @override
  String get fieldQuantity => 'Quantity';

  @override
  String get setExpiry => 'Set expiration date';

  @override
  String get clearDate => 'Clear date';

  @override
  String get quick3Days => '+3 days';

  @override
  String get quick1Week => '+1 week';

  @override
  String get quick2Weeks => '+2 weeks';

  @override
  String get quick1Month => '+1 month';

  @override
  String get saveToPantry => 'Save to pantry';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get nameFirst => 'Give the item a name first.';

  @override
  String foundFromBarcode(String name) {
    return 'Found “$name” from its barcode.';
  }

  @override
  String readDate(String date) {
    return 'Read the date $date from the label.';
  }

  @override
  String failed(String error) {
    return 'Failed: $error';
  }

  @override
  String get scanBarcode => 'Scan barcode';

  @override
  String get torchOn => 'Torch on';

  @override
  String get torchOff => 'Torch off';

  @override
  String get typeCode => 'Type a code';

  @override
  String get enterBarcode => 'Enter barcode';

  @override
  String get barcodeDigitsHint => 'Digits under the barcode';

  @override
  String get runInstructions =>
      'Scan each product in turn. Scanning one again adds another of it.';

  @override
  String get singleInstructions => 'Line up the barcode inside the frame.';

  @override
  String get nothingScanned => 'Nothing scanned yet';

  @override
  String scannedSummary(int total, int products) {
    return '$total scanned · $products products';
  }

  @override
  String get useItUp => 'Use it up';

  @override
  String get recipesEmpty =>
      'Add some items to your pantry to get recipe ideas.';

  @override
  String get newIdeas => 'New ideas';

  @override
  String get alreadyOnShoppingList => 'Already on your shopping list';

  @override
  String addedNToList(int count) {
    return 'Added $count to your shopping list';
  }

  @override
  String get shoppingList => 'Shopping list';

  @override
  String get toPantry => 'To pantry';

  @override
  String get listEmpty => 'Your list is empty.';

  @override
  String get addItemHint => 'Add item';

  @override
  String movedToPantry(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Moved $count to your pantry',
      one: 'Moved 1 to your pantry',
    );
    return '$_temp0';
  }

  @override
  String get remindersHeader => 'Reminders';

  @override
  String get remindBefore => 'Remind me before expiry';

  @override
  String dayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get timeOfDay => 'Time of day';

  @override
  String get rescheduleNote =>
      'Changing these reschedules reminders for every item with an expiry date.';

  @override
  String get yourData => 'Your data';

  @override
  String get exportBackup => 'Export backup';

  @override
  String get exportBackupDesc =>
      'Pantry, shopping list, reminder settings and remembered products as a JSON file';

  @override
  String get importBackup => 'Import backup';

  @override
  String get importBackupDesc => 'Restore from a PantryPal backup file';

  @override
  String get backupNote =>
      'Backups stay on your device until you choose where to send them.';

  @override
  String exportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String openFileFailed(String error) {
    return 'Could not open the file: $error';
  }

  @override
  String get backupNotJson => 'That file isn\'t valid JSON.';

  @override
  String get backupNotPantryPal => 'That file isn\'t a PantryPal backup.';

  @override
  String get backupTooNew =>
      'This backup was made by a newer version of PantryPal. Update the app first.';

  @override
  String get restoreTitle => 'Restore backup?';

  @override
  String pantryItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pantry items',
      one: '1 pantry item',
    );
    return '$_temp0';
  }

  @override
  String shoppingItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count shopping items',
      one: '1 shopping item',
    );
    return '$_temp0';
  }

  @override
  String restoreSummary(String pantry, String shopping) {
    return 'This backup has $pantry and $shopping.';
  }

  @override
  String restoreSummaryDated(String date, String pantry, String shopping) {
    return 'This backup from $date has $pantry and $shopping.';
  }

  @override
  String get restoreExplain =>
      'Replace wipes what\'s on this phone first and restores reminder settings. Merge adds the backup to what you have.';

  @override
  String get merge => 'Merge';

  @override
  String get replace => 'Replace';

  @override
  String restoredSummary(int pantry, int shopping) {
    return 'Restored $pantry pantry and $shopping shopping items';
  }

  @override
  String useAmountTitle(String name) {
    return 'How much $name did you use?';
  }

  @override
  String youHave(String amount) {
    return 'You have $amount.';
  }

  @override
  String get useAll => 'All';

  @override
  String get use => 'Use';

  @override
  String notifTitle(String name) {
    return '$name expires soon';
  }

  @override
  String notifBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Expires in $count days — tap for recipe ideas.',
      one: 'Expires in 1 day — tap for recipe ideas.',
    );
    return '$_temp0';
  }

  @override
  String get notifChannel => 'Expiry reminders';

  @override
  String get widgetEmpty => 'Nothing expiring in the next 2 weeks';

  @override
  String widgetDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
      zero: 'today',
    );
    return '$_temp0';
  }

  @override
  String get widgetExpired => 'expired';

  @override
  String get languageHeader => 'Language';

  @override
  String get appLanguage => 'App language';

  @override
  String get languageSystem => 'System default';

  @override
  String barcodeRemembered(String name) {
    return 'Recognized “$name” from your earlier scans.';
  }

  @override
  String barcodeNotFoundLearn(String code) {
    return 'Barcode $code isn\'t in the product database. Name it once and PantryPal will remember it.';
  }

  @override
  String get addExpiryNow => 'Add the date from the label';

  @override
  String get otherDatesFound => 'Dates found on the label:';

  @override
  String endOfMonth(String month) {
    return 'end of $month';
  }

  @override
  String usuallyLasts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Usually $count days',
      one: 'Usually 1 day',
    );
    return '$_temp0';
  }

  @override
  String get estimatedFromHistory =>
      'Estimated from how long this usually lasts for you — check the package.';

  @override
  String get saveAndAddAnother => 'Save and add another';

  @override
  String savedItem(String name) {
    return 'Saved $name';
  }

  @override
  String get offlineError =>
      'No connection. Check your internet and try again.';

  @override
  String get aiUnavailable =>
      'The AI service isn\'t reachable right now. Try again, or fill in the details yourself.';

  @override
  String get invalidBarcode =>
      'That doesn\'t look like a valid barcode. Check the digits.';

  @override
  String get addSeveral => 'Add several at once';

  @override
  String get quickListTitle => 'Add several';

  @override
  String get quickListHint =>
      'One item per line, for example:\n2 x milk\nflour 1 kg\neggs 12\nbananas';

  @override
  String get quickListEmpty => 'Type at least one item.';

  @override
  String get reviewList => 'Review items';

  @override
  String get noDateFoundTitle => 'No date found';

  @override
  String get noDateFoundBody =>
      'This is what the camera read. Pick the date yourself, or try again closer and in better light.';

  @override
  String get nothingReadable =>
      'No text could be read from that photo. Try again closer and in better light.';

  @override
  String get pickDate => 'Pick date';

  @override
  String get barcodeFromPhoto => 'Barcode from a photo';

  @override
  String get noBarcodeInPhoto => 'No barcode found in that photo.';

  @override
  String dateYearAssumed(String date) {
    return '$date (year assumed)';
  }

  @override
  String get rememberedProducts => 'Remembered products';

  @override
  String get rememberedProductsDesc =>
      'What PantryPal has learned from your scans';

  @override
  String rememberedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count remembered products',
      one: '1 remembered product',
    );
    return '$_temp0';
  }

  @override
  String get noRememberedProducts =>
      'Nothing remembered yet. Products you add are remembered here to make your next scan faster.';

  @override
  String get forgetAll => 'Forget all';

  @override
  String get forgetAllConfirm =>
      'Forget every remembered product and cached barcode lookup? Your pantry isn\'t affected.';

  @override
  String forgotProduct(String name) {
    return 'Forgot $name';
  }

  @override
  String get forgetProduct => 'Forget';

  @override
  String get searchRemembered => 'Search remembered products';

  @override
  String get recipesIdeas => 'Ideas';

  @override
  String get recipesSaved => 'Saved';

  @override
  String get recipesBuildAround => 'Build around';

  @override
  String get recipesMore => 'More ideas';

  @override
  String get recipesNoSaved =>
      'No saved recipes yet. Tap the bookmark on a recipe to keep it.';

  @override
  String recipeMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String recipeServings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count servings',
      one: '1 serving',
    );
    return '$_temp0';
  }

  @override
  String recipeUsesExpiring(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'uses $count expiring items',
      one: 'uses 1 expiring item',
    );
    return '$_temp0';
  }

  @override
  String recipeToBuyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count to buy',
      one: '1 to buy',
      zero: 'nothing to buy',
    );
    return '$_temp0';
  }

  @override
  String get recipeIngredients => 'Ingredients';

  @override
  String get recipeSteps => 'Steps';

  @override
  String get addMissingToList => 'Add missing to shopping list';

  @override
  String get saveRecipe => 'Save recipe';

  @override
  String get unsaveRecipe => 'Remove from saved';

  @override
  String get cookedThis => 'I cooked this';

  @override
  String get cookSheetTitle => 'Update your pantry';

  @override
  String get cookSheetHint =>
      'Untick anything you didn\'t use, and adjust amounts. Amounts the recipe didn\'t make clear start unticked.';

  @override
  String get cookUsesAll => 'uses all of it';

  @override
  String cookLeftAfter(String amount) {
    return '$amount left afterwards';
  }

  @override
  String get updatePantry => 'Update pantry';

  @override
  String pantryUpdated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Updated $count pantry items',
      one: 'Updated 1 pantry item',
    );
    return '$_temp0';
  }

  @override
  String get recipePrefsTitle => 'Recipe preferences';

  @override
  String get prefsDiet => 'Diet';

  @override
  String get dietVegetarian => 'Vegetarian';

  @override
  String get dietVegan => 'Vegan';

  @override
  String get dietGlutenFree => 'Gluten-free';

  @override
  String get dietDairyFree => 'Dairy-free';

  @override
  String get prefsServings => 'Servings';

  @override
  String get prefsTime => 'Time';

  @override
  String get prefsAnyTime => 'Any';

  @override
  String get prefsAvoid => 'Leave out';

  @override
  String get prefsAvoidHint => 'e.g. mushrooms, peanuts';

  @override
  String get prefsAllergyNote =>
      'Suggestions are AI-generated and can still include things you asked to leave out. If you have allergies, always check the ingredients.';

  @override
  String get prefsApply => 'Apply';

  @override
  String get catSeafood => 'Fish & seafood';

  @override
  String get catPlantProtein => 'Tofu & plant protein';

  @override
  String get catDeli => 'Deli & ready meals';

  @override
  String get catGrains => 'Rice, pasta & grains';

  @override
  String get catBaking => 'Baking';

  @override
  String get catCanned => 'Canned & jarred';

  @override
  String get catCondiments => 'Sauces, oils & condiments';

  @override
  String get catSpices => 'Spices & seasonings';

  @override
  String get catSpreads => 'Spreads & sweeteners';

  @override
  String get catSnacks => 'Snacks & sweets';

  @override
  String get catAlcohol => 'Beer, wine & spirits';

  @override
  String get catBaby => 'Baby';

  @override
  String get catPet => 'Pet supplies';

  @override
  String get catHousehold => 'Household';

  @override
  String get recipesPlan => 'Plan';

  @override
  String get planIntro =>
      'Plan dinners for the week. Meals that use food expiring soonest come first.';

  @override
  String get planMyWeek => 'Plan my week';

  @override
  String get planHowManyDays => 'Plan dinners for';

  @override
  String get planFull => 'Every day in that range already has a meal.';

  @override
  String get weekShopping => 'Shopping for the week';

  @override
  String get weekShoppingTitle => 'To buy for your planned meals';

  @override
  String get weekShoppingNone => 'You have everything for your planned meals.';

  @override
  String weekShoppingFor(String recipes) {
    return 'for $recipes';
  }

  @override
  String addNToShoppingList(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add $count to shopping list',
      one: 'Add 1 to shopping list',
    );
    return '$_temp0';
  }

  @override
  String get planToday => 'Today';

  @override
  String get planTomorrow => 'Tomorrow';

  @override
  String get planNothing => 'Nothing planned';

  @override
  String get planSwap => 'Swap for another idea';

  @override
  String get planRemove => 'Remove from plan';

  @override
  String get planCooked => 'Cooked';

  @override
  String get addToPlan => 'Add to plan';

  @override
  String get planWhichDay => 'Which day?';

  @override
  String plannedAdded(String day) {
    return 'Added to $day';
  }

  @override
  String get appearanceHeader => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get scanFirstItem => 'Scan your first item';

  @override
  String get introAddTitle => 'Add what you buy';

  @override
  String get introAddBody =>
      'Scan a barcode, a receipt or a date label, or just type it. PantryPal remembers products for next time.';

  @override
  String get introRemindTitle => 'Know what to use first';

  @override
  String get introRemindBody =>
      'See what is expiring at a glance, and get a reminder before food goes off.';

  @override
  String get introCookTitle => 'Cook what you have';

  @override
  String get introCookBody =>
      'Get recipe ideas from your pantry, plan the week, and make one shopping list for it.';

  @override
  String get introSkip => 'Skip';

  @override
  String get introNext => 'Next';

  @override
  String get introStart => 'Get started';

  @override
  String introPage(int current, int total) {
    return 'Page $current of $total';
  }

  @override
  String get recipesNoMatch =>
      'No ideas fit your preferences with what you have. Try fewer filters in Recipe preferences, or add a few more items.';

  @override
  String get recipesNoMore => 'That\'s every idea for what you have right now.';

  @override
  String get onYourList => 'On your shopping list';

  @override
  String get recipeBasics => 'Kitchen basics';

  @override
  String get notForMe => 'Not for me';

  @override
  String get fewerLikeThis => 'Got it — fewer ideas like this.';

  @override
  String get recipeLearningHeader => 'Recipe suggestions';

  @override
  String get resetTaste => 'Reset what PantryPal has learned';

  @override
  String get resetTasteBody =>
      'Suggestions adapt to the dishes you cook, save, plan or turn down. This stays on your phone.';

  @override
  String get resetTasteConfirm => 'Reset';

  @override
  String get resetTasteDone => 'Suggestions start fresh.';
}
