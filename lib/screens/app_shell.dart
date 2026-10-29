import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/l10n.dart';
import '../state/shopping_store.dart';
import '../ui/breakpoints.dart';
import '../ui/app_nav_bar.dart';
import '../ui/motion.dart';
import '../ui/nav_icons.dart';
import 'home_screen.dart';
import 'recipes_screen.dart';
import 'shopping_screen.dart';

/// Top-level navigation. Phones get a bottom bar; landscape and tablets a side rail (labels
/// beside icons on wide screens). Tabs are built on first visit, kept alive, and cross-fade.
class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _pages = [HomeScreen(), RecipesScreen(), ShoppingScreen()];
  var _index = 0;
  final _visited = <int>{0};

  void _select(int i) {
    if (i == _index) return;
    // Don't leave a text field (e.g. "add item" on the shopping list) focused in a hidden tab:
    // it would keep the keyboard up and hold text input in a page that can't be seen.
    FocusManager.instance.primaryFocus?.unfocus();
    HapticFeedback.selectionClick();
    setState(() {
      _index = i;
      _visited.add(i);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final toBuy = context.watch<ShoppingStore>().items.where((i) => !i.checked).length;
    final items = [
      AppNavItem(kind: NavIconKind.pantry, label: l.navPantry),
      AppNavItem(kind: NavIconKind.recipes, label: l.navRecipes),
      AppNavItem(kind: NavIconKind.shopping, label: l.navShopping, badge: toBuy),
    ];
    final body = FadeIndexedStack(index: _index, children: [
      for (var i = 0; i < _pages.length; i++) _visited.contains(i) ? _pages[i] : const SizedBox.shrink(),
    ]);
    return LayoutBuilder(builder: (context, c) {
      final size = WindowSize.of(c.maxWidth);
      if (size == WindowSize.compact) {
        return Scaffold(
          body: body,
          bottomNavigationBar: AppNavBar(items: items, selectedIndex: _index, onSelected: _select),
        );
      }
      final scheme = Theme.of(context).colorScheme;
      final extended = size == WindowSize.expanded;
      Widget icon(int i) {
        final selected = i == _index;
        final fg = selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant;
        final bg = selected ? scheme.secondaryContainer : scheme.surface;
        final child = AnimatedNavIcon(kind: items[i].kind, selected: selected, color: fg, background: bg, size: 26);
        return items[i].badge > 0 ? Badge(label: Text('${items[i].badge}'), child: child) : child;
      }

      return Scaffold(
        body: SafeArea(
          right: false,
          child: Row(children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: _select,
              extended: extended,
              labelType: extended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
              minExtendedWidth: 200,
              // A squared highlight, like the boxes on the phone bar.
              indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              indicatorColor: scheme.secondaryContainer,
              destinations: [
                // The same icon widget whether selected or not, so it can animate between them.
                for (var i = 0; i < items.length; i++)
                  NavigationRailDestination(icon: icon(i), selectedIcon: icon(i), label: Text(items[i].label)),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ]),
        ),
      );
    });
  }
}
