import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pantrypal/models/pantry_item.dart';
import 'package:pantrypal/models/recipe.dart';
import 'package:pantrypal/models/scan_mode.dart';
import 'package:pantrypal/models/unit.dart';
import 'package:pantrypal/screens/app_shell.dart';
import 'package:pantrypal/screens/home_screen.dart';
import 'package:pantrypal/screens/intro_screen.dart';
import 'package:pantrypal/screens/recipe_detail_screen.dart';
import 'package:pantrypal/screens/scan_screen.dart';
import 'package:pantrypal/state/pantry_store.dart';
import 'package:pantrypal/state/shopping_store.dart';
import 'package:pantrypal/ui/app_nav_bar.dart';
import 'package:pantrypal/ui/motion.dart';
import '../helpers.dart';
import '../state/pantry_store_test.dart' show FakeDb, FakeNotifs;
import '../state/shopping_store_test.dart' show FakeShoppingDb;

Future<PantryStore> _pantry() async {
  final s = PantryStore(FakeDb(), FakeNotifs());
  final now = DateTime.now();
  await s.add(PantryItem(name: 'Semi-skimmed organic milk from the local farm', quantity: 1, unit: Unit.l,
      category: 'Dairy', expiry: DateTime(now.year, now.month, now.day + 2)));
  await s.add(PantryItem(name: 'Long grain rice', quantity: 2, unit: Unit.kg, category: 'Grains'));
  return s;
}

Future<void> _size(WidgetTester t, double w, double h, {double text = 1}) async {
  await t.binding.setSurfaceSize(Size(w, h));
  t.platformDispatcher.textScaleFactorTestValue = text;
  addTearDown(() {
    t.binding.setSurfaceSize(null);
    t.platformDispatcher.clearTextScaleFactorTestValue();
  });
}

Widget _shell(PantryStore pantry) => MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: pantry),
        ChangeNotifierProvider(create: (_) => ShoppingStore(FakeShoppingDb())),
      ],
      child: testApp(const AppShell()),
    );

void main() {
  group('navigation adapts to the window', () {
    testWidgets('phone: bottom bar', (t) async {
      await _size(t, 390, 844);
      await t.pumpWidget(_shell(await _pantry()));
      await t.pumpAndSettle();
      expect(find.byType(AppNavBar), findsOneWidget); // the three-box bar
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('small tablet / landscape: rail with labels', (t) async {
      await _size(t, 700, 500);
      await t.pumpWidget(_shell(await _pantry()));
      await t.pumpAndSettle();
      final rail = t.widget<NavigationRail>(find.byType(NavigationRail));
      expect([rail.extended, rail.labelType], [false, NavigationRailLabelType.all]);
      expect(find.byType(AppNavBar), findsNothing);
    });

    testWidgets('large tablet: extended rail, pantry in columns', (t) async {
      await _size(t, 1280, 800);
      await t.pumpWidget(_shell(await _pantry()));
      await t.pumpAndSettle();
      expect(t.widget<NavigationRail>(find.byType(NavigationRail)).extended, isTrue);
      expect(find.byType(Wrap), findsWidgets); // AdaptiveColumns switched to columns
    });
  });

  group('no overflow at 320 px wide with 200% text', () {
    testWidgets('pantry', (t) async {
      await _size(t, 320, 700, text: 2);
      await t.pumpWidget(ChangeNotifierProvider.value(value: await _pantry(), child: testApp(const HomeScreen())));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });

    testWidgets('scan form (quantity row wraps)', (t) async {
      await _size(t, 320, 1600, text: 2);
      await t.pumpWidget(ChangeNotifierProvider.value(
          value: await _pantry(), child: testApp(const ScanScreen(initialMode: ScanMode.manual))));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });
  });

  testWidgets('wide recipe: ingredients beside the steps', (t) async {
    await _size(t, 1300, 900);
    final recipe = Recipe.fromJson({'title': 'Soup', 'ingredients': [{'name': 'Milk'}], 'steps': ['Heat']})!;
    await t.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: await _pantry()),
        ChangeNotifierProvider(create: (_) => ShoppingStore(FakeShoppingDb())),
      ],
      child: testApp(RecipeDetailScreen(recipe: recipe)),
    ));
    await t.pumpAndSettle();
    final ing = t.getTopLeft(find.text('Ingredients')), steps = t.getTopLeft(find.text('Steps'));
    expect(ing.dy, steps.dy);
    expect(steps.dx, greaterThan(ing.dx + 300));
  });

  group('motion', () {
    testWidgets('reduce motion turns animations off', (t) async {
      t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
      late Duration d;
      await t.pumpWidget(testApp(Builder(builder: (c) {
        d = Motion.of(c, Motion.long);
        return const SizedBox();
      })));
      expect(d, Duration.zero);
    });

    testWidgets('fading tabs keep their state and only the visible one takes taps', (t) async {
      final a = TextEditingController(), b = TextEditingController();
      var index = 0;
      var tapsOnHidden = 0;
      late StateSetter set;
      await t.pumpWidget(testApp(StatefulBuilder(builder: (c, s) {
        set = s;
        return Scaffold(
          body: FadeIndexedStack(index: index, children: [
            TextField(key: const Key('a'), controller: a),
            GestureDetector(onTap: () => tapsOnHidden++, child: TextField(key: const Key('b'), controller: b)),
          ]),
        );
      })));
      await t.enterText(find.byKey(const Key('a')), 'kept');
      set(() => index = 1);
      await t.pumpAndSettle();
      set(() => index = 0);
      await t.pumpAndSettle();
      expect(a.text, 'kept');
      await t.tap(find.byKey(const Key('a')), warnIfMissed: false);
      expect(tapsOnHidden, 0);
    });
  });

  group('intro', () {
    testWidgets('next, next, get started', (t) async {
      var done = 0;
      await t.pumpWidget(testApp(IntroScreen(onDone: () => done++)));
      expect(find.text('Add what you buy'), findsOneWidget);
      await t.tap(find.text('Next'));
      await t.pumpAndSettle();
      expect(find.text('Know what to use first'), findsOneWidget);
      await t.tap(find.text('Next'));
      await t.pumpAndSettle();
      expect(find.text('Cook what you have'), findsOneWidget);
      expect(find.bySemanticsLabel('Page 3 of 3'), findsOneWidget);
      await t.tap(find.text('Get started'));
      expect(done, 1);
    });

    testWidgets('skip leaves at once', (t) async {
      var done = 0;
      await t.pumpWidget(testApp(IntroScreen(onDone: () => done++)));
      await t.tap(find.text('Skip'));
      expect(done, 1);
    });
  });

  group('tab switching (the Shopping tab bug)', () {
    Future<ShoppingStore> pumpShell(WidgetTester t) async {
      await _size(t, 390, 844);
      final shop = ShoppingStore(FakeShoppingDb());
      await shop.addAll(['Milk', 'Bread']);
      await t.pumpWidget(MultiProvider(
        providers: [ChangeNotifierProvider.value(value: await _pantry()), ChangeNotifierProvider.value(value: shop)],
        child: testApp(const AppShell()),
      ));
      await t.pumpAndSettle();
      await t.tap(find.text('Shopping'));
      await t.pumpAndSettle();
      return shop;
    }

    testWidgets('leaving Shopping while typing: no error, focus released, hidden tab offstage', (t) async {
      await pumpShell(t);
      await t.enterText(find.byType(TextField).last, 'Apples');
      expect(FocusManager.instance.primaryFocus?.context?.widget, isNotNull);
      for (final tab in ['Pantry', 'Recipes', 'Shopping', 'Pantry']) {
        await t.tap(find.text(tab).last);
        await t.pumpAndSettle();
        expect(t.takeException(), isNull, reason: tab);
      }
      expect(find.byType(EditableText, skipOffstage: true), findsNothing); // shopping's field is offstage
      expect(FocusManager.instance.primaryFocus?.context?.widget is EditableText, isFalse);
    });

    testWidgets('swiping an item off the list, then switching tabs: no "dismissed Dismissible" error', (t) async {
      final shop = await pumpShell(t);
      await t.drag(find.text('Milk'), const Offset(-500, 0));
      await t.pump(); // switch tabs before the store has reloaded
      await t.tap(find.text('Pantry').last);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expect(shop.items.map((i) => i.name), ['Bread']);
    });
  });
}
