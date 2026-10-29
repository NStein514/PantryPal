import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'data/pantry_db.dart';
import 'data/product_memory_db.dart';
import 'data/settings_repo.dart';
import 'data/shopping_db.dart';
import 'l10n/l10n.dart';
import 'screens/app_shell.dart';
import 'screens/intro_screen.dart';
import 'ui/motion.dart';
import 'screens/recipes_screen.dart';
import 'services/ai_service.dart';
import 'services/backup_files.dart';
import 'services/home_widget_service.dart';
import 'services/widget_actions.dart';
import 'services/notification_service.dart';
import 'services/ocr_service.dart';
import 'services/product_lookup_service.dart';
import 'state/locale_store.dart';
import 'state/meal_plan_store.dart';
import 'state/pantry_store.dart';
import 'state/saved_recipes.dart';
import 'state/taste_store.dart';
import 'state/theme_store.dart';
import 'theme/app_theme.dart';
import 'state/shopping_store.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void _openRecipes() =>
    navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => const RecipesScreen()));

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final notifs = NotificationService();
  await notifs.init(onTap: _openRecipes);
  final settings = SettingsRepo();
  final language = LocaleStore(settings);
  await language.load(); // before the first frame, so the app never flashes the wrong language
  final introSeen = await settings.loadIntroSeen();
  final appearance = ThemeStore(settings);
  await appearance.load(); // likewise for light/dark
  final store = PantryStore(PantryDb(), notifs, settings);

  // Home-screen widget: republish whenever the pantry changes, and on resume
  // (covers a language change made while the app was in the background).
  final widgets = HomeWidgetService();
  await widgets.init();
  await widgets.registerInteractivity(widgetInteractivityCallback);
  void syncWidget() => widgets.update(store.items, l10nFor(currentAppLocale()));
  store.addListener(syncWidget);
  // A language change rewrites scheduled reminder texts and the widget.
  language.addListener(() {
    store.resyncReminders();
    syncWidget();
  });
  // Back in the foreground: reload first, since widget buttons may have changed the pantry
  // in a background engine (load() notifies listeners, which republishes the widget).
  AppLifecycleListener(onResume: store.load);
  widgets.clicks.listen((uri) {
    if (HomeWidgetService.opensRecipes(uri)) _openRecipes();
  });

  store.load().then((_) => store.resyncReminders());
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: store),
      ChangeNotifierProvider.value(value: language),
      ChangeNotifierProvider.value(value: appearance),
      ChangeNotifierProvider(create: (_) => ShoppingStore(ShoppingDb())..load()),
      Provider(create: (_) => AiService()),
      Provider(create: (_) => OcrService()),
      Provider(create: (_) => ProductLookupService()),
      ChangeNotifierProvider(create: (_) => SavedRecipes()..load()),
      ChangeNotifierProvider(create: (_) => MealPlanStore()..load()),
      ChangeNotifierProvider(create: (_) => TasteStore()..load()),
      Provider(create: (_) => BackupFiles()),
      Provider(create: (_) => ProductMemoryDb()),
    ],
    child: PantryPalApp(showIntro: !introSeen),
  ));
  if (await notifs.launchedFromNotification() || HomeWidgetService.opensRecipes(await widgets.launchUri())) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _openRecipes());
  }
}

class PantryPalApp extends StatelessWidget {
  const PantryPalApp({super.key, this.showIntro = false});

  /// First launch: a short intro before the app (see IntroScreen).
  final bool showIntro;
  @override
  Widget build(BuildContext context) => MaterialApp(
        locale: context.watch<LocaleStore>().locale, // null = follow the device
        onGenerateTitle: (context) => context.l10n.appTitle,
        navigatorKey: navigatorKey,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) {
          // Dates (DateFormat) follow the device region, e.g. en_GB → 28 Oct 2026.
          Intl.defaultLocale =
              intlLocaleFor(WidgetsBinding.instance.platformDispatcher.locale, Localizations.localeOf(context));
          return child!;
        },
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: context.watch<ThemeStore>().mode,
        home: showIntro ? const _IntroGate() : const AppShell(),
      );
}

/// Shows the intro once, then fades into the app and remembers it was seen.
class _IntroGate extends StatelessWidget {
  const _IntroGate();
  @override
  Widget build(BuildContext context) => IntroScreen(onDone: () {
        SettingsRepo().saveIntroSeen();
        final d = Motion.of(context, Motion.long);
        Navigator.of(context).pushReplacement(PageRouteBuilder<void>(
          transitionDuration: d,
          pageBuilder: (_, __, ___) => const AppShell(),
          transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
        ));
      });
}
