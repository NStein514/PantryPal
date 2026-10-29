// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'PantryPal';

  @override
  String get aiLanguage => 'French';

  @override
  String get navPantry => 'Garde-manger';

  @override
  String get navRecipes => 'Recettes';

  @override
  String get navShopping => 'Courses';

  @override
  String get settings => 'Réglages';

  @override
  String get cancel => 'Annuler';

  @override
  String get add => 'Ajouter';

  @override
  String get back => 'Retour';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get undo => 'Annuler';

  @override
  String get remove => 'Retirer';

  @override
  String get edit => 'Modifier';

  @override
  String get delete => 'Supprimer';

  @override
  String get review => 'Vérifier';

  @override
  String get catProduce => 'Fruits et légumes';

  @override
  String get catDairy => 'Produits laitiers et œufs';

  @override
  String get catMeat => 'Viande et volaille';

  @override
  String get catPantry => 'Épicerie';

  @override
  String get catFrozen => 'Surgelés';

  @override
  String get catBakery => 'Pain et viennoiseries';

  @override
  String get catBeverage => 'Boissons';

  @override
  String get catOther => 'Autres';

  @override
  String get unitPieces => 'pcs';

  @override
  String get statusExpired => 'Périmé';

  @override
  String get statusSoon => 'À consommer vite';

  @override
  String get statusFresh => 'Frais';

  @override
  String get statusUndated => 'Sans date';

  @override
  String get searchHint => 'Rechercher dans le garde-manger';

  @override
  String get clearSearch => 'Effacer la recherche';

  @override
  String get filterAll => 'Tout';

  @override
  String get noMatches => 'Aucun produit ne correspond.';

  @override
  String get clearFilters => 'Effacer les filtres';

  @override
  String get emptyPantry =>
      'Ton garde-manger est vide.\nAppuie sur Scanner pour ajouter un produit.';

  @override
  String get emptyPantryHint =>
      'Scanne un code-barres, prends une photo ou importe un ticket de caisse entier.';

  @override
  String get scan => 'Scanner';

  @override
  String removedItem(String name) {
    return '$name retiré';
  }

  @override
  String expiresOn(String date) {
    return 'Périme le $date';
  }

  @override
  String expiredOn(String date) {
    return 'Périmé le $date';
  }

  @override
  String get expiresToday => 'Périme aujourd\'hui';

  @override
  String get noExpiryDate => 'Pas de date de péremption';

  @override
  String get usedOne => 'J\'en ai utilisé un';

  @override
  String leftAfterThis(String amount) {
    return 'Il restera $amount';
  }

  @override
  String get removesFromPantry => 'Le retire du garde-manger';

  @override
  String get usedSome => 'J\'en ai utilisé une partie…';

  @override
  String amountLeft(String amount) {
    return 'Il reste $amount';
  }

  @override
  String get addToShoppingList => 'Ajouter à la liste de courses';

  @override
  String alreadyOnList(String name) {
    return '$name est déjà sur ta liste';
  }

  @override
  String addedToList(String name) {
    return '$name ajouté à ta liste';
  }

  @override
  String get badgeNoDate => 'sans date';

  @override
  String get badgeAgo => 'j passés';

  @override
  String get badgeToday => 'auj.';

  @override
  String badgeDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'jours',
      one: 'jour',
    );
    return '$_temp0';
  }

  @override
  String expiresInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Périme dans $count jours',
      one: 'Périme dans 1 jour',
    );
    return '$_temp0';
  }

  @override
  String expiredDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Périmé depuis $count jours',
      one: 'Périmé depuis 1 jour',
    );
    return '$_temp0';
  }

  @override
  String get addToPantry => 'Ajouter au garde-manger';

  @override
  String get sourceCamera => 'Appareil photo';

  @override
  String get sourcePhotos => 'Photos';

  @override
  String get oneItem => 'Un produit';

  @override
  String get severalAtOnce => 'Plusieurs à la fois';

  @override
  String get modeBarcode => 'Code-barres';

  @override
  String get modeBarcodeDesc => 'Trouver un produit grâce à son code-barres';

  @override
  String get modeDateLabel => 'Date imprimée';

  @override
  String get modeDateLabelDesc =>
      'Lire la date de péremption imprimée (reste sur ton téléphone)';

  @override
  String get modeManual => 'Saisir';

  @override
  String get modeManualDesc => 'Entrer les informations toi-même';

  @override
  String get modeBarcodeRun => 'Scan en série';

  @override
  String get modeBarcodeRunDesc =>
      'Scanner les produits les uns après les autres, vérifier à la fin';

  @override
  String get modeReceipt => 'Ticket de caisse';

  @override
  String get modeReceiptDesc =>
      'Importer tous les aliments d\'un ticket de caisse';

  @override
  String get reviewScanned => 'Vérifier les produits scannés';

  @override
  String get reviewReceipt => 'Vérifier le ticket';

  @override
  String addedToPantry(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count produits ajoutés au garde-manger',
      one: '1 produit ajouté au garde-manger',
    );
    return '$_temp0';
  }

  @override
  String get selectAll => 'Tout cocher';

  @override
  String get selectNone => 'Tout décocher';

  @override
  String get scanReadError => 'Impossible de lire ce scan.';

  @override
  String get readingScan => 'Lecture du scan…';

  @override
  String get readingScanHint => 'Cela peut prendre quelques secondes.';

  @override
  String get noFoodFound => 'Aucun aliment trouvé.';

  @override
  String get noFoodFoundHint =>
      'Essaie une photo plus nette et bien éclairée, ou ajoute les produits un par un.';

  @override
  String foundIntro(int count) {
    return '$count trouvé(s). Corrige ce qui ne va pas et décoche ce que tu ne veux pas.';
  }

  @override
  String get itemNameHint => 'Nom du produit';

  @override
  String barcodeHelper(String code) {
    return 'Code-barres $code';
  }

  @override
  String get notFoundTypeName => 'Introuvable – saisis un nom';

  @override
  String get removeFromList => 'Retirer de la liste';

  @override
  String get addDate => 'Ajouter une date';

  @override
  String estimatedDate(String date) {
    return '$date (estim.)';
  }

  @override
  String addItemsButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ajouter $count produits au garde-manger',
      one: 'Ajouter 1 produit au garde-manger',
    );
    return '$_temp0';
  }

  @override
  String get less => 'Moins';

  @override
  String get more => 'Plus';

  @override
  String get addItem => 'Ajouter un produit';

  @override
  String get editItem => 'Modifier le produit';

  @override
  String get fillAutomatically => 'Remplir automatiquement';

  @override
  String get scanDate => 'Scanner la date';

  @override
  String get fieldName => 'Nom';

  @override
  String get fieldCategory => 'Catégorie';

  @override
  String get fieldQuantity => 'Quantité';

  @override
  String get setExpiry => 'Définir la date de péremption';

  @override
  String get clearDate => 'Effacer la date';

  @override
  String get quick3Days => '+3 jours';

  @override
  String get quick1Week => '+1 semaine';

  @override
  String get quick2Weeks => '+2 semaines';

  @override
  String get quick1Month => '+1 mois';

  @override
  String get saveToPantry => 'Enregistrer dans le garde-manger';

  @override
  String get saveChanges => 'Enregistrer';

  @override
  String get nameFirst => 'Donne d\'abord un nom au produit.';

  @override
  String foundFromBarcode(String name) {
    return '« $name » trouvé grâce au code-barres.';
  }

  @override
  String readDate(String date) {
    return 'Date $date lue sur l\'étiquette.';
  }

  @override
  String failed(String error) {
    return 'Échec : $error';
  }

  @override
  String get scanBarcode => 'Scanner un code-barres';

  @override
  String get torchOn => 'Allumer la lampe';

  @override
  String get torchOff => 'Éteindre la lampe';

  @override
  String get typeCode => 'Saisir un code';

  @override
  String get enterBarcode => 'Saisir le code-barres';

  @override
  String get barcodeDigitsHint => 'Les chiffres sous le code-barres';

  @override
  String get runInstructions =>
      'Scanne chaque produit à tour de rôle. Scanner à nouveau en ajoute un de plus.';

  @override
  String get singleInstructions => 'Place le code-barres dans le cadre.';

  @override
  String get nothingScanned => 'Rien de scanné pour l\'instant';

  @override
  String scannedSummary(int total, int products) {
    return '$total scannés · $products produits';
  }

  @override
  String get useItUp => 'À finir';

  @override
  String get recipesEmpty =>
      'Ajoute des produits à ton garde-manger pour recevoir des idées de recettes.';

  @override
  String get newIdeas => 'Nouvelles idées';

  @override
  String get alreadyOnShoppingList => 'Déjà sur ta liste de courses';

  @override
  String addedNToList(int count) {
    return '$count ajouté(s) à ta liste de courses';
  }

  @override
  String get shoppingList => 'Liste de courses';

  @override
  String get toPantry => 'Au garde-manger';

  @override
  String get listEmpty => 'Ta liste est vide.';

  @override
  String get addItemHint => 'Ajouter un produit';

  @override
  String movedToPantry(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count déplacés au garde-manger',
      one: '1 déplacé au garde-manger',
    );
    return '$_temp0';
  }

  @override
  String get remindersHeader => 'Rappels';

  @override
  String get remindBefore => 'Me prévenir avant la péremption';

  @override
  String dayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String get timeOfDay => 'Heure';

  @override
  String get rescheduleNote =>
      'Modifier ces réglages reprogramme les rappels de tous les produits datés.';

  @override
  String get yourData => 'Tes données';

  @override
  String get exportBackup => 'Exporter une sauvegarde';

  @override
  String get exportBackupDesc =>
      'Garde-manger, liste de courses, rappels et produits mémorisés dans un fichier JSON';

  @override
  String get importBackup => 'Importer une sauvegarde';

  @override
  String get importBackupDesc => 'Restaurer depuis une sauvegarde PantryPal';

  @override
  String get backupNote =>
      'Les sauvegardes restent sur ton appareil jusqu\'à ce que tu choisisses où les envoyer.';

  @override
  String exportFailed(String error) {
    return 'Échec de l\'export : $error';
  }

  @override
  String openFileFailed(String error) {
    return 'Impossible d\'ouvrir le fichier : $error';
  }

  @override
  String get backupNotJson => 'Ce fichier n\'est pas un JSON valide.';

  @override
  String get backupNotPantryPal =>
      'Ce fichier n\'est pas une sauvegarde PantryPal.';

  @override
  String get backupTooNew =>
      'Cette sauvegarde vient d\'une version plus récente de PantryPal. Mets d\'abord l\'appli à jour.';

  @override
  String get restoreTitle => 'Restaurer la sauvegarde ?';

  @override
  String pantryItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count produits du garde-manger',
      one: '1 produit du garde-manger',
    );
    return '$_temp0';
  }

  @override
  String shoppingItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count articles de courses',
      one: '1 article de courses',
    );
    return '$_temp0';
  }

  @override
  String restoreSummary(String pantry, String shopping) {
    return 'Cette sauvegarde contient $pantry et $shopping.';
  }

  @override
  String restoreSummaryDated(String date, String pantry, String shopping) {
    return 'Cette sauvegarde du $date contient $pantry et $shopping.';
  }

  @override
  String get restoreExplain =>
      'Remplacer efface d\'abord ce qu\'il y a sur ce téléphone et restaure les rappels. Fusionner ajoute la sauvegarde à ce que tu as déjà.';

  @override
  String get merge => 'Fusionner';

  @override
  String get replace => 'Remplacer';

  @override
  String restoredSummary(int pantry, int shopping) {
    return '$pantry produits et $shopping articles de courses restaurés';
  }

  @override
  String useAmountTitle(String name) {
    return 'Quelle quantité de $name as-tu utilisée ?';
  }

  @override
  String youHave(String amount) {
    return 'Tu as $amount.';
  }

  @override
  String get useAll => 'Tout';

  @override
  String get use => 'Utiliser';

  @override
  String notifTitle(String name) {
    return '$name périme bientôt';
  }

  @override
  String notifBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Périme dans $count jours – appuie pour des idées de recettes.',
      one: 'Périme dans 1 jour – appuie pour des idées de recettes.',
    );
    return '$_temp0';
  }

  @override
  String get notifChannel => 'Rappels de péremption';

  @override
  String get widgetEmpty => 'Rien ne périme dans les 2 prochaines semaines';

  @override
  String widgetDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '1 jour',
      zero: 'aujourd\'hui',
    );
    return '$_temp0';
  }

  @override
  String get widgetExpired => 'périmé';

  @override
  String get languageHeader => 'Langue';

  @override
  String get appLanguage => 'Langue de l\'appli';

  @override
  String get languageSystem => 'Langue du système';

  @override
  String barcodeRemembered(String name) {
    return '« $name » reconnu grâce à tes scans précédents.';
  }

  @override
  String barcodeNotFoundLearn(String code) {
    return 'Le code-barres $code n\'est pas dans la base de produits. Donne-lui un nom une fois et PantryPal s\'en souviendra.';
  }

  @override
  String get addExpiryNow => 'Ajouter la date de l\'étiquette';

  @override
  String get otherDatesFound => 'Dates trouvées sur l\'étiquette :';

  @override
  String endOfMonth(String month) {
    return 'fin $month';
  }

  @override
  String usuallyLasts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dure en général $count jours',
      one: 'Dure en général 1 jour',
    );
    return '$_temp0';
  }

  @override
  String get estimatedFromHistory =>
      'Estimée d\'après la durée habituelle chez toi – vérifie sur l\'emballage.';

  @override
  String get saveAndAddAnother => 'Enregistrer et en ajouter un autre';

  @override
  String savedItem(String name) {
    return '$name enregistré';
  }

  @override
  String get offlineError =>
      'Pas de connexion. Vérifie ta connexion internet et réessaie.';

  @override
  String get aiUnavailable =>
      'Le service d\'IA est injoignable pour le moment. Réessaie ou saisis les informations toi-même.';

  @override
  String get invalidBarcode =>
      'Ça ne ressemble pas à un code-barres valide. Vérifie les chiffres.';

  @override
  String get addSeveral => 'En ajouter plusieurs';

  @override
  String get quickListTitle => 'Ajouter plusieurs produits';

  @override
  String get quickListHint =>
      'Un produit par ligne, par exemple :\n2 x lait\nfarine 1 kg\nœufs 12\nbananes';

  @override
  String get quickListEmpty => 'Saisis au moins un produit.';

  @override
  String get reviewList => 'Vérifier les produits';

  @override
  String get noDateFoundTitle => 'Aucune date trouvée';

  @override
  String get noDateFoundBody =>
      'Voici ce que l\'appareil photo a lu. Choisis la date toi-même ou réessaie plus près et avec plus de lumière.';

  @override
  String get nothingReadable =>
      'Aucun texte lisible sur cette photo. Réessaie plus près et avec plus de lumière.';

  @override
  String get pickDate => 'Choisir la date';

  @override
  String get barcodeFromPhoto => 'Code-barres depuis une photo';

  @override
  String get noBarcodeInPhoto => 'Aucun code-barres trouvé sur cette photo.';

  @override
  String dateYearAssumed(String date) {
    return '$date (année supposée)';
  }

  @override
  String get rememberedProducts => 'Produits mémorisés';

  @override
  String get rememberedProductsDesc => 'Ce que PantryPal a appris de tes scans';

  @override
  String rememberedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count produits mémorisés',
      one: '1 produit mémorisé',
    );
    return '$_temp0';
  }

  @override
  String get noRememberedProducts =>
      'Rien de mémorisé pour l\'instant. Les produits que tu ajoutes sont mémorisés ici pour accélérer le prochain scan.';

  @override
  String get forgetAll => 'Tout oublier';

  @override
  String get forgetAllConfirm =>
      'Oublier tous les produits mémorisés et les recherches de codes-barres enregistrées ? Ton garde-manger n\'est pas modifié.';

  @override
  String forgotProduct(String name) {
    return '$name oublié';
  }

  @override
  String get forgetProduct => 'Oublier';

  @override
  String get searchRemembered => 'Rechercher dans les produits mémorisés';

  @override
  String get recipesIdeas => 'Idées';

  @override
  String get recipesSaved => 'Enregistrées';

  @override
  String get recipesBuildAround => 'Cuisiner autour de';

  @override
  String get recipesMore => 'Plus d\'idées';

  @override
  String get recipesNoSaved =>
      'Aucune recette enregistrée. Appuie sur le signet d\'une recette pour la garder.';

  @override
  String recipeMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String recipeServings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count portions',
      one: '1 portion',
    );
    return '$_temp0';
  }

  @override
  String recipeUsesExpiring(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'utilise $count produits bientôt périmés',
      one: 'utilise 1 produit bientôt périmé',
    );
    return '$_temp0';
  }

  @override
  String recipeToBuyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count à acheter',
      one: '1 à acheter',
      zero: 'rien à acheter',
    );
    return '$_temp0';
  }

  @override
  String get recipeIngredients => 'Ingrédients';

  @override
  String get recipeSteps => 'Étapes';

  @override
  String get addMissingToList => 'Ajouter ce qui manque à la liste';

  @override
  String get saveRecipe => 'Enregistrer la recette';

  @override
  String get unsaveRecipe => 'Retirer des enregistrées';

  @override
  String get cookedThis => 'Je l\'ai cuisiné';

  @override
  String get cookSheetTitle => 'Mettre à jour le garde-manger';

  @override
  String get cookSheetHint =>
      'Décoche ce que tu n\'as pas utilisé et ajuste les quantités. Les quantités que la recette ne précisait pas sont décochées au départ.';

  @override
  String get cookUsesAll => 'tout est utilisé';

  @override
  String cookLeftAfter(String amount) {
    return 'il restera $amount';
  }

  @override
  String get updatePantry => 'Mettre à jour';

  @override
  String pantryUpdated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count produits mis à jour',
      one: '1 produit mis à jour',
    );
    return '$_temp0';
  }

  @override
  String get recipePrefsTitle => 'Préférences de recettes';

  @override
  String get prefsDiet => 'Régime';

  @override
  String get dietVegetarian => 'Végétarien';

  @override
  String get dietVegan => 'Végan';

  @override
  String get dietGlutenFree => 'Sans gluten';

  @override
  String get dietDairyFree => 'Sans lactose';

  @override
  String get prefsServings => 'Portions';

  @override
  String get prefsTime => 'Temps';

  @override
  String get prefsAnyTime => 'Peu importe';

  @override
  String get prefsAvoid => 'À éviter';

  @override
  String get prefsAvoidHint => 'p. ex. champignons, cacahuètes';

  @override
  String get prefsAllergyNote =>
      'Les suggestions sont générées par une IA et peuvent contenir des choses que tu voulais éviter. En cas d\'allergie, vérifie toujours les ingrédients.';

  @override
  String get prefsApply => 'Appliquer';

  @override
  String get catSeafood => 'Poisson et fruits de mer';

  @override
  String get catPlantProtein => 'Tofu et protéines végétales';

  @override
  String get catDeli => 'Traiteur et plats préparés';

  @override
  String get catGrains => 'Riz, pâtes et céréales';

  @override
  String get catBaking => 'Pâtisserie';

  @override
  String get catCanned => 'Conserves et bocaux';

  @override
  String get catCondiments => 'Sauces, huiles et condiments';

  @override
  String get catSpices => 'Épices et assaisonnements';

  @override
  String get catSpreads => 'Pâtes à tartiner et sucrants';

  @override
  String get catSnacks => 'Snacks et confiseries';

  @override
  String get catAlcohol => 'Bière, vin et spiritueux';

  @override
  String get catBaby => 'Bébé';

  @override
  String get catPet => 'Animaux';

  @override
  String get catHousehold => 'Maison et entretien';

  @override
  String get recipesPlan => 'Planning';

  @override
  String get planIntro =>
      'Planifie les dîners de la semaine. Les repas qui utilisent ce qui périme le plus tôt passent en premier.';

  @override
  String get planMyWeek => 'Planifier ma semaine';

  @override
  String get planHowManyDays => 'Planifier les dîners pour';

  @override
  String get planFull => 'Chaque jour de cette période a déjà un repas.';

  @override
  String get weekShopping => 'Courses de la semaine';

  @override
  String get weekShoppingTitle => 'À acheter pour tes repas planifiés';

  @override
  String get weekShoppingNone => 'Tu as tout pour tes repas planifiés.';

  @override
  String weekShoppingFor(String recipes) {
    return 'pour $recipes';
  }

  @override
  String addNToShoppingList(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ajouter $count à la liste',
      one: 'Ajouter 1 à la liste',
    );
    return '$_temp0';
  }

  @override
  String get planToday => 'Aujourd\'hui';

  @override
  String get planTomorrow => 'Demain';

  @override
  String get planNothing => 'Rien de prévu';

  @override
  String get planSwap => 'Remplacer par une autre idée';

  @override
  String get planRemove => 'Retirer du planning';

  @override
  String get planCooked => 'Cuisiné';

  @override
  String get addToPlan => 'Ajouter au planning';

  @override
  String get planWhichDay => 'Quel jour ?';

  @override
  String plannedAdded(String day) {
    return 'Ajouté à $day';
  }

  @override
  String get appearanceHeader => 'Apparence';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get scanFirstItem => 'Scanne ton premier produit';

  @override
  String get introAddTitle => 'Ajoute ce que tu achètes';

  @override
  String get introAddBody =>
      'Scanne un code-barres, un ticket ou une date, ou saisis-le. PantryPal retient les produits pour la prochaine fois.';

  @override
  String get introRemindTitle => 'Sache quoi utiliser en premier';

  @override
  String get introRemindBody =>
      'Vois d\'un coup d\'œil ce qui périme bientôt et reçois un rappel avant que ça se gâte.';

  @override
  String get introCookTitle => 'Cuisine avec ce que tu as';

  @override
  String get introCookBody =>
      'Reçois des idées de recettes avec ton garde-manger, planifie la semaine et fais une seule liste de courses.';

  @override
  String get introSkip => 'Passer';

  @override
  String get introNext => 'Suivant';

  @override
  String get introStart => 'Commencer';

  @override
  String introPage(int current, int total) {
    return 'Page $current sur $total';
  }

  @override
  String get recipesNoMatch =>
      'Aucune idée ne correspond à tes préférences avec ce que tu as. Essaie moins de filtres ou ajoute quelques produits.';

  @override
  String get recipesNoMore =>
      'Ce sont toutes les idées pour ce que tu as en ce moment.';

  @override
  String get onYourList => 'Sur ta liste de courses';

  @override
  String get recipeBasics => 'Basiques de cuisine';

  @override
  String get notForMe => 'Pas pour moi';

  @override
  String get fewerLikeThis => 'Compris : moins d\'idées comme celle-ci.';

  @override
  String get recipeLearningHeader => 'Suggestions de recettes';

  @override
  String get resetTaste => 'Réinitialiser ce que PantryPal a appris';

  @override
  String get resetTasteBody =>
      'Les suggestions s\'adaptent aux plats que tu cuisines, enregistres, planifies ou refuses. Tout reste sur ton téléphone.';

  @override
  String get resetTasteConfirm => 'Réinitialiser';

  @override
  String get resetTasteDone => 'Les suggestions repartent de zéro.';
}
