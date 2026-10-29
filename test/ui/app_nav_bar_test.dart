import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantrypal/ui/app_nav_bar.dart';
import 'package:pantrypal/ui/nav_icons.dart';
import '../helpers.dart';

const _items = [
  AppNavItem(kind: NavIconKind.pantry, label: 'Pantry'),
  AppNavItem(kind: NavIconKind.recipes, label: 'Recipes'),
  AppNavItem(kind: NavIconKind.shopping, label: 'Shopping', badge: 3),
];

Future<ValueNotifier<int>> _pump(WidgetTester t, {bool reduceMotion = false}) async {
  await t.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => t.binding.setSurfaceSize(null));
  if (reduceMotion) {
    t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }
  final index = ValueNotifier(0);
  await t.pumpWidget(testApp(Scaffold(
    bottomNavigationBar: ValueListenableBuilder<int>(
      valueListenable: index,
      builder: (_, i, __) => AppNavBar(items: _items, selectedIndex: i, onSelected: (v) => index.value = v),
    ),
  )));
  await t.pumpAndSettle();
  return index;
}

double _progress(WidgetTester t, int i) {
  final paint = t.widget<CustomPaint>(
      find.descendant(of: find.byType(AnimatedNavIcon).at(i), matching: find.byType(CustomPaint)).first);
  return (paint.painter! as NavIconPainter).progress.value;
}

void main() {
  testWidgets('three equal boxes; only the selected one is filled', (t) async {
    await _pump(t);
    final boxes = find.byType(AnimatedContainer);
    final widths = [for (var i = 0; i < 3; i++) t.getSize(boxes.at(i)).width];
    expect(widths[0], closeTo(widths[1], 0.01));
    expect(widths[1], closeTo(widths[2], 0.01));
    expect(widths.reduce((a, b) => a + b) + 2, closeTo(390, 0.01)); // plus the two dividers
    Color? fill(int i) => (t.widget<AnimatedContainer>(boxes.at(i)).decoration as BoxDecoration?)?.color;
    expect(fill(0), isNot(fill(1)));
    expect(fill(1), fill(2));
    expect(find.text('3'), findsOneWidget); // shopping badge
  });

  testWidgets('tapping a box selects it and its icon plays, then settles', (t) async {
    final index = await _pump(t);
    expect(_progress(t, 0), 1); // pantry: fridge open
    expect(_progress(t, 1), 0);
    await t.tap(find.text('Recipes'));
    await t.pump(const Duration(milliseconds: 200));
    expect(index.value, 1);
    expect(_progress(t, 1), inExclusiveRange(0, 1)); // the fork and knife are mid-clink
    await t.pumpAndSettle();
    expect([_progress(t, 0), _progress(t, 1)], [0, 1]); // fridge closed again, utensils held up
    // Screen readers hear each box as a button, and which one is selected.
    SemanticsProperties tab(String label) => t
        .widget<Semantics>(find.byWidgetPredicate((w) => w is Semantics && w.properties.label == label))
        .properties;
    expect([tab('Recipes').button, tab('Recipes').selected, tab('Pantry').selected], [true, true, false]);
  });

  testWidgets('with reduced motion the icon jumps to its end state', (t) async {
    await _pump(t, reduceMotion: true);
    await t.tap(find.text('Shopping'));
    await t.pump();
    expect(_progress(t, 2), 1); // cart full at once
  });
}
