// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'PantryPal';

  @override
  String get aiLanguage => 'Spanish';

  @override
  String get navPantry => 'Despensa';

  @override
  String get navRecipes => 'Recetas';

  @override
  String get navShopping => 'Compras';

  @override
  String get settings => 'Ajustes';

  @override
  String get cancel => 'Cancelar';

  @override
  String get add => 'Añadir';

  @override
  String get back => 'Volver';

  @override
  String get tryAgain => 'Reintentar';

  @override
  String get undo => 'Deshacer';

  @override
  String get remove => 'Quitar';

  @override
  String get edit => 'Editar';

  @override
  String get delete => 'Eliminar';

  @override
  String get review => 'Revisar';

  @override
  String get catProduce => 'Frutas y verduras';

  @override
  String get catDairy => 'Lácteos y huevos';

  @override
  String get catMeat => 'Carne y aves';

  @override
  String get catPantry => 'Básicos de despensa';

  @override
  String get catFrozen => 'Congelados';

  @override
  String get catBakery => 'Pan y bollería';

  @override
  String get catBeverage => 'Bebidas';

  @override
  String get catOther => 'Otros';

  @override
  String get unitPieces => 'uds';

  @override
  String get statusExpired => 'Caducado';

  @override
  String get statusSoon => 'Usar pronto';

  @override
  String get statusFresh => 'Fresco';

  @override
  String get statusUndated => 'Sin fecha';

  @override
  String get searchHint => 'Buscar en tu despensa';

  @override
  String get clearSearch => 'Borrar búsqueda';

  @override
  String get filterAll => 'Todo';

  @override
  String get noMatches => 'Ningún producto coincide.';

  @override
  String get clearFilters => 'Quitar filtros';

  @override
  String get emptyPantry =>
      'Tu despensa está vacía.\nToca Escanear para añadir un producto.';

  @override
  String get emptyPantryHint =>
      'Escanea un código de barras, haz una foto o importa un ticket entero.';

  @override
  String get scan => 'Escanear';

  @override
  String removedItem(String name) {
    return '$name eliminado';
  }

  @override
  String expiresOn(String date) {
    return 'Caduca el $date';
  }

  @override
  String expiredOn(String date) {
    return 'Caducó el $date';
  }

  @override
  String get expiresToday => 'Caduca hoy';

  @override
  String get noExpiryDate => 'Sin fecha de caducidad';

  @override
  String get usedOne => 'Usé uno';

  @override
  String leftAfterThis(String amount) {
    return 'Quedarán $amount';
  }

  @override
  String get removesFromPantry => 'Lo quita de la despensa';

  @override
  String get usedSome => 'Usé una parte…';

  @override
  String amountLeft(String amount) {
    return 'Quedan $amount';
  }

  @override
  String get addToShoppingList => 'Añadir a la lista de la compra';

  @override
  String alreadyOnList(String name) {
    return '$name ya está en tu lista';
  }

  @override
  String addedToList(String name) {
    return '$name añadido a tu lista';
  }

  @override
  String get badgeNoDate => 'sin fecha';

  @override
  String get badgeAgo => 'd atrás';

  @override
  String get badgeToday => 'hoy';

  @override
  String badgeDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'días',
      one: 'día',
    );
    return '$_temp0';
  }

  @override
  String expiresInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Caduca en $count días',
      one: 'Caduca en 1 día',
    );
    return '$_temp0';
  }

  @override
  String expiredDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Caducó hace $count días',
      one: 'Caducó hace 1 día',
    );
    return '$_temp0';
  }

  @override
  String get addToPantry => 'Añadir a la despensa';

  @override
  String get sourceCamera => 'Cámara';

  @override
  String get sourcePhotos => 'Fotos';

  @override
  String get oneItem => 'Un producto';

  @override
  String get severalAtOnce => 'Varios a la vez';

  @override
  String get modeBarcode => 'Código de barras';

  @override
  String get modeBarcodeDesc => 'Busca un producto por su código de barras';

  @override
  String get modeDateLabel => 'Fecha impresa';

  @override
  String get modeDateLabelDesc =>
      'Lee la fecha de caducidad impresa (sin salir del móvil)';

  @override
  String get modeManual => 'Escribirlo';

  @override
  String get modeManualDesc => 'Introduce los datos tú mismo';

  @override
  String get modeBarcodeRun => 'Escaneo continuo';

  @override
  String get modeBarcodeRunDesc =>
      'Escanea un producto tras otro y revisa al final';

  @override
  String get modeReceipt => 'Ticket';

  @override
  String get modeReceiptDesc =>
      'Importa todos los alimentos de un ticket de compra';

  @override
  String get reviewScanned => 'Revisar productos escaneados';

  @override
  String get reviewReceipt => 'Revisar ticket';

  @override
  String addedToPantry(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count productos añadidos a tu despensa',
      one: '1 producto añadido a tu despensa',
    );
    return '$_temp0';
  }

  @override
  String get selectAll => 'Marcar todo';

  @override
  String get selectNone => 'Desmarcar todo';

  @override
  String get scanReadError => 'No se pudo leer el escaneo.';

  @override
  String get readingScan => 'Leyendo el escaneo…';

  @override
  String get readingScanHint => 'Puede tardar unos segundos.';

  @override
  String get noFoodFound => 'No se encontraron alimentos.';

  @override
  String get noFoodFoundHint =>
      'Prueba con una foto más nítida y con buena luz, o añade los productos de uno en uno.';

  @override
  String foundIntro(int count) {
    return 'Encontrados: $count. Corrige lo que no cuadre y desmarca lo que no quieras.';
  }

  @override
  String get itemNameHint => 'Nombre del producto';

  @override
  String barcodeHelper(String code) {
    return 'Código $code';
  }

  @override
  String get notFoundTypeName => 'No encontrado: escribe un nombre';

  @override
  String get removeFromList => 'Quitar de la lista';

  @override
  String get addDate => 'Añadir fecha';

  @override
  String estimatedDate(String date) {
    return '$date (estim.)';
  }

  @override
  String addItemsButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Añadir $count productos a la despensa',
      one: 'Añadir 1 producto a la despensa',
    );
    return '$_temp0';
  }

  @override
  String get less => 'Menos';

  @override
  String get more => 'Más';

  @override
  String get addItem => 'Añadir producto';

  @override
  String get editItem => 'Editar producto';

  @override
  String get fillAutomatically => 'Rellenar automáticamente';

  @override
  String get scanDate => 'Escanear fecha';

  @override
  String get fieldName => 'Nombre';

  @override
  String get fieldCategory => 'Categoría';

  @override
  String get fieldQuantity => 'Cantidad';

  @override
  String get setExpiry => 'Fijar fecha de caducidad';

  @override
  String get clearDate => 'Borrar fecha';

  @override
  String get quick3Days => '+3 días';

  @override
  String get quick1Week => '+1 semana';

  @override
  String get quick2Weeks => '+2 semanas';

  @override
  String get quick1Month => '+1 mes';

  @override
  String get saveToPantry => 'Guardar en la despensa';

  @override
  String get saveChanges => 'Guardar cambios';

  @override
  String get nameFirst => 'Primero ponle un nombre al producto.';

  @override
  String foundFromBarcode(String name) {
    return 'Encontrado «$name» por su código de barras.';
  }

  @override
  String readDate(String date) {
    return 'Fecha leída en la etiqueta: $date.';
  }

  @override
  String failed(String error) {
    return 'Error: $error';
  }

  @override
  String get scanBarcode => 'Escanear código';

  @override
  String get torchOn => 'Encender linterna';

  @override
  String get torchOff => 'Apagar linterna';

  @override
  String get typeCode => 'Escribir un código';

  @override
  String get enterBarcode => 'Introduce el código';

  @override
  String get barcodeDigitsHint => 'Los números bajo el código';

  @override
  String get runInstructions =>
      'Escanea cada producto. Si escaneas uno otra vez, se suma otra unidad.';

  @override
  String get singleInstructions =>
      'Encuadra el código de barras dentro del marco.';

  @override
  String get nothingScanned => 'Aún no has escaneado nada';

  @override
  String scannedSummary(int total, int products) {
    return '$total escaneados · $products productos';
  }

  @override
  String get useItUp => 'Aprovéchalo';

  @override
  String get recipesEmpty =>
      'Añade productos a tu despensa para recibir ideas de recetas.';

  @override
  String get newIdeas => 'Otras ideas';

  @override
  String get alreadyOnShoppingList => 'Ya está en tu lista de la compra';

  @override
  String addedNToList(int count) {
    return '$count añadidos a tu lista de la compra';
  }

  @override
  String get shoppingList => 'Lista de la compra';

  @override
  String get toPantry => 'A la despensa';

  @override
  String get listEmpty => 'Tu lista está vacía.';

  @override
  String get addItemHint => 'Añadir producto';

  @override
  String movedToPantry(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pasados a tu despensa',
      one: '1 pasado a tu despensa',
    );
    return '$_temp0';
  }

  @override
  String get remindersHeader => 'Recordatorios';

  @override
  String get remindBefore => 'Avisarme antes de que caduque';

  @override
  String dayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String get timeOfDay => 'Hora del día';

  @override
  String get rescheduleNote =>
      'Al cambiar esto se reprograman los recordatorios de todos los productos con fecha.';

  @override
  String get yourData => 'Tus datos';

  @override
  String get exportBackup => 'Exportar copia de seguridad';

  @override
  String get exportBackupDesc =>
      'Despensa, lista de la compra, recordatorios y productos recordados en un archivo JSON';

  @override
  String get importBackup => 'Importar copia de seguridad';

  @override
  String get importBackupDesc => 'Restaurar desde una copia de PantryPal';

  @override
  String get backupNote =>
      'Las copias se quedan en tu dispositivo hasta que decidas adónde enviarlas.';

  @override
  String exportFailed(String error) {
    return 'Error al exportar: $error';
  }

  @override
  String openFileFailed(String error) {
    return 'No se pudo abrir el archivo: $error';
  }

  @override
  String get backupNotJson => 'Ese archivo no es un JSON válido.';

  @override
  String get backupNotPantryPal => 'Ese archivo no es una copia de PantryPal.';

  @override
  String get backupTooNew =>
      'Esta copia se hizo con una versión más reciente de PantryPal. Actualiza la app primero.';

  @override
  String get restoreTitle => '¿Restaurar la copia?';

  @override
  String pantryItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count productos de la despensa',
      one: '1 producto de la despensa',
    );
    return '$_temp0';
  }

  @override
  String shoppingItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count productos de la lista',
      one: '1 producto de la lista',
    );
    return '$_temp0';
  }

  @override
  String restoreSummary(String pantry, String shopping) {
    return 'Esta copia tiene $pantry y $shopping.';
  }

  @override
  String restoreSummaryDated(String date, String pantry, String shopping) {
    return 'Esta copia del $date tiene $pantry y $shopping.';
  }

  @override
  String get restoreExplain =>
      'Reemplazar borra primero lo que hay en este móvil y restaura los recordatorios. Combinar añade la copia a lo que ya tienes.';

  @override
  String get merge => 'Combinar';

  @override
  String get replace => 'Reemplazar';

  @override
  String restoredSummary(int pantry, int shopping) {
    return 'Restaurados $pantry de la despensa y $shopping de la lista';
  }

  @override
  String useAmountTitle(String name) {
    return '¿Cuánto $name has usado?';
  }

  @override
  String youHave(String amount) {
    return 'Tienes $amount.';
  }

  @override
  String get useAll => 'Todo';

  @override
  String get use => 'Usar';

  @override
  String notifTitle(String name) {
    return '$name caduca pronto';
  }

  @override
  String notifBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Caduca en $count días: toca para ver ideas de recetas.',
      one: 'Caduca en 1 día: toca para ver ideas de recetas.',
    );
    return '$_temp0';
  }

  @override
  String get notifChannel => 'Avisos de caducidad';

  @override
  String get widgetEmpty => 'Nada caduca en las próximas 2 semanas';

  @override
  String widgetDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
      zero: 'hoy',
    );
    return '$_temp0';
  }

  @override
  String get widgetExpired => 'caducado';

  @override
  String get languageHeader => 'Idioma';

  @override
  String get appLanguage => 'Idioma de la app';

  @override
  String get languageSystem => 'Predeterminado del sistema';

  @override
  String barcodeRemembered(String name) {
    return 'Reconocido «$name» de tus escaneos anteriores.';
  }

  @override
  String barcodeNotFoundLearn(String code) {
    return 'El código $code no está en la base de datos de productos. Ponle nombre una vez y PantryPal lo recordará.';
  }

  @override
  String get addExpiryNow => 'Añadir la fecha de la etiqueta';

  @override
  String get otherDatesFound => 'Fechas encontradas en la etiqueta:';

  @override
  String endOfMonth(String month) {
    return 'fin de $month';
  }

  @override
  String usuallyLasts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Suele durar $count días',
      one: 'Suele durar 1 día',
    );
    return '$_temp0';
  }

  @override
  String get estimatedFromHistory =>
      'Estimada según lo que te suele durar: compruébala en el envase.';

  @override
  String get saveAndAddAnother => 'Guardar y añadir otro';

  @override
  String savedItem(String name) {
    return '$name guardado';
  }

  @override
  String get offlineError =>
      'Sin conexión. Revisa tu internet e inténtalo de nuevo.';

  @override
  String get aiUnavailable =>
      'El servicio de IA no responde ahora mismo. Inténtalo de nuevo o rellena los datos tú mismo.';

  @override
  String get invalidBarcode =>
      'Eso no parece un código de barras válido. Revisa los números.';

  @override
  String get addSeveral => 'Añadir varios a la vez';

  @override
  String get quickListTitle => 'Añadir varios';

  @override
  String get quickListHint =>
      'Un producto por línea, por ejemplo:\n2 x leche\nharina 1 kg\nhuevos 12\nplátanos';

  @override
  String get quickListEmpty => 'Escribe al menos un producto.';

  @override
  String get reviewList => 'Revisar productos';

  @override
  String get noDateFoundTitle => 'No se encontró la fecha';

  @override
  String get noDateFoundBody =>
      'Esto es lo que leyó la cámara. Elige la fecha tú mismo o inténtalo de nuevo más cerca y con mejor luz.';

  @override
  String get nothingReadable =>
      'No se pudo leer texto en esa foto. Inténtalo más cerca y con mejor luz.';

  @override
  String get pickDate => 'Elegir fecha';

  @override
  String get barcodeFromPhoto => 'Código de una foto';

  @override
  String get noBarcodeInPhoto =>
      'No se encontró ningún código de barras en esa foto.';

  @override
  String dateYearAssumed(String date) {
    return '$date (año supuesto)';
  }

  @override
  String get rememberedProducts => 'Productos recordados';

  @override
  String get rememberedProductsDesc =>
      'Lo que PantryPal ha aprendido de tus escaneos';

  @override
  String rememberedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count productos recordados',
      one: '1 producto recordado',
    );
    return '$_temp0';
  }

  @override
  String get noRememberedProducts =>
      'Aún no hay nada recordado. Los productos que añadas se recuerdan aquí para que el próximo escaneo sea más rápido.';

  @override
  String get forgetAll => 'Olvidar todo';

  @override
  String get forgetAllConfirm =>
      '¿Olvidar todos los productos recordados y las búsquedas de códigos guardadas? Tu despensa no cambia.';

  @override
  String forgotProduct(String name) {
    return '$name olvidado';
  }

  @override
  String get forgetProduct => 'Olvidar';

  @override
  String get searchRemembered => 'Buscar productos recordados';

  @override
  String get recipesIdeas => 'Ideas';

  @override
  String get recipesSaved => 'Guardadas';

  @override
  String get recipesBuildAround => 'Basar en';

  @override
  String get recipesMore => 'Más ideas';

  @override
  String get recipesNoSaved =>
      'Aún no hay recetas guardadas. Toca el marcador de una receta para guardarla.';

  @override
  String recipeMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String recipeServings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count raciones',
      one: '1 ración',
    );
    return '$_temp0';
  }

  @override
  String recipeUsesExpiring(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'aprovecha $count productos a punto de caducar',
      one: 'aprovecha 1 producto a punto de caducar',
    );
    return '$_temp0';
  }

  @override
  String recipeToBuyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count por comprar',
      one: '1 por comprar',
      zero: 'nada que comprar',
    );
    return '$_temp0';
  }

  @override
  String get recipeIngredients => 'Ingredientes';

  @override
  String get recipeSteps => 'Pasos';

  @override
  String get addMissingToList => 'Añadir lo que falta a la lista';

  @override
  String get saveRecipe => 'Guardar receta';

  @override
  String get unsaveRecipe => 'Quitar de guardadas';

  @override
  String get cookedThis => 'Lo he cocinado';

  @override
  String get cookSheetTitle => 'Actualiza tu despensa';

  @override
  String get cookSheetHint =>
      'Desmarca lo que no usaste y ajusta las cantidades. Las cantidades que la receta no aclaraba empiezan desmarcadas.';

  @override
  String get cookUsesAll => 'se usa todo';

  @override
  String cookLeftAfter(String amount) {
    return 'quedarán $amount';
  }

  @override
  String get updatePantry => 'Actualizar despensa';

  @override
  String pantryUpdated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count productos actualizados',
      one: '1 producto actualizado',
    );
    return '$_temp0';
  }

  @override
  String get recipePrefsTitle => 'Preferencias de recetas';

  @override
  String get prefsDiet => 'Dieta';

  @override
  String get dietVegetarian => 'Vegetariana';

  @override
  String get dietVegan => 'Vegana';

  @override
  String get dietGlutenFree => 'Sin gluten';

  @override
  String get dietDairyFree => 'Sin lácteos';

  @override
  String get prefsServings => 'Raciones';

  @override
  String get prefsTime => 'Tiempo';

  @override
  String get prefsAnyTime => 'Cualquiera';

  @override
  String get prefsAvoid => 'Evitar';

  @override
  String get prefsAvoidHint => 'p. ej. champiñones, cacahuetes';

  @override
  String get prefsAllergyNote =>
      'Las sugerencias las genera la IA y pueden incluir cosas que pediste evitar. Si tienes alergias, revisa siempre los ingredientes.';

  @override
  String get prefsApply => 'Aplicar';

  @override
  String get catSeafood => 'Pescado y marisco';

  @override
  String get catPlantProtein => 'Tofu y proteína vegetal';

  @override
  String get catDeli => 'Platos preparados';

  @override
  String get catGrains => 'Arroz, pasta y legumbres';

  @override
  String get catBaking => 'Repostería';

  @override
  String get catCanned => 'Conservas';

  @override
  String get catCondiments => 'Salsas, aceites y condimentos';

  @override
  String get catSpices => 'Especias';

  @override
  String get catSpreads => 'Untables y endulzantes';

  @override
  String get catSnacks => 'Snacks y dulces';

  @override
  String get catAlcohol => 'Cerveza, vino y licores';

  @override
  String get catBaby => 'Bebé';

  @override
  String get catPet => 'Mascotas';

  @override
  String get catHousehold => 'Hogar y limpieza';

  @override
  String get recipesPlan => 'Plan';

  @override
  String get planIntro =>
      'Planifica las cenas de la semana. Primero van las comidas con lo que caduca antes.';

  @override
  String get planMyWeek => 'Planificar mi semana';

  @override
  String get planHowManyDays => 'Planificar cenas para';

  @override
  String get planFull => 'Todos los días de ese periodo ya tienen comida.';

  @override
  String get weekShopping => 'Compra de la semana';

  @override
  String get weekShoppingTitle => 'Por comprar para tus comidas planificadas';

  @override
  String get weekShoppingNone => 'Tienes todo para tus comidas planificadas.';

  @override
  String weekShoppingFor(String recipes) {
    return 'para $recipes';
  }

  @override
  String addNToShoppingList(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Añadir $count a la lista',
      one: 'Añadir 1 a la lista',
    );
    return '$_temp0';
  }

  @override
  String get planToday => 'Hoy';

  @override
  String get planTomorrow => 'Mañana';

  @override
  String get planNothing => 'Nada planificado';

  @override
  String get planSwap => 'Cambiar por otra idea';

  @override
  String get planRemove => 'Quitar del plan';

  @override
  String get planCooked => 'Cocinado';

  @override
  String get addToPlan => 'Añadir al plan';

  @override
  String get planWhichDay => '¿Qué día?';

  @override
  String plannedAdded(String day) {
    return 'Añadido a $day';
  }

  @override
  String get appearanceHeader => 'Apariencia';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get scanFirstItem => 'Escanea tu primer producto';

  @override
  String get introAddTitle => 'Añade lo que compras';

  @override
  String get introAddBody =>
      'Escanea un código de barras, un ticket o una fecha, o escríbelo. PantryPal recuerda los productos para la próxima vez.';

  @override
  String get introRemindTitle => 'Sabe qué usar primero';

  @override
  String get introRemindBody =>
      'Ve de un vistazo lo que caduca y recibe un aviso antes de que se estropee.';

  @override
  String get introCookTitle => 'Cocina con lo que tienes';

  @override
  String get introCookBody =>
      'Recibe ideas de recetas con tu despensa, planifica la semana y haz una sola lista de la compra.';

  @override
  String get introSkip => 'Saltar';

  @override
  String get introNext => 'Siguiente';

  @override
  String get introStart => 'Empezar';

  @override
  String introPage(int current, int total) {
    return 'Página $current de $total';
  }

  @override
  String get recipesNoMatch =>
      'Ninguna idea encaja con tus preferencias y lo que tienes. Prueba con menos filtros o añade algunos productos más.';

  @override
  String get recipesNoMore =>
      'Esas son todas las ideas para lo que tienes ahora.';

  @override
  String get onYourList => 'En tu lista de la compra';

  @override
  String get recipeBasics => 'Básicos de cocina';

  @override
  String get notForMe => 'No es para mí';

  @override
  String get fewerLikeThis => 'Entendido: menos ideas como esta.';

  @override
  String get recipeLearningHeader => 'Sugerencias de recetas';

  @override
  String get resetTaste => 'Restablecer lo que PantryPal ha aprendido';

  @override
  String get resetTasteBody =>
      'Las sugerencias se adaptan a los platos que cocinas, guardas, planificas o descartas. Todo queda en tu teléfono.';

  @override
  String get resetTasteConfirm => 'Restablecer';

  @override
  String get resetTasteDone => 'Las sugerencias empiezan de cero.';
}
