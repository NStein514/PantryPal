import 'package:flutter/material.dart';
import 'motion.dart';
import 'nav_icons.dart';

class AppNavItem {
  const AppNavItem({required this.kind, required this.label, this.badge = 0});
  final NavIconKind kind;
  final String label;
  final int badge;
}

/// Bottom navigation for phones: the bar is split into equal boxes, and the selected box is
/// filled (not a pill), with its icon acting out the tab.
class AppNavBar extends StatelessWidget {
  const AppNavBar({super.key, required this.items, required this.selectedIndex, required this.onSelected});
  final List<AppNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      child: DecoratedBox(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: scheme.outlineVariant))),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 72,
            child: Row(children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) VerticalDivider(width: 1, thickness: 1, color: scheme.outlineVariant),
                Expanded(child: _NavBox(item: items[i], selected: i == selectedIndex, onTap: () => onSelected(i))),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

class _NavBox extends StatelessWidget {
  const _NavBox({required this.item, required this.selected, required this.onTap});
  final AppNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final d = Motion.of(context, Motion.short);
    final bg = selected ? scheme.secondaryContainer : scheme.surfaceContainerLow;
    final fg = selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: d,
        curve: Motion.emphasized,
        color: bg,
        child: InkWell(
          onTap: onTap,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Badge(
              isLabelVisible: item.badge > 0,
              label: Text('${item.badge}'),
              child: AnimatedNavIcon(kind: item.kind, selected: selected, color: fg, background: bg),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: d,
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: fg,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
              child: Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ]),
        ),
      ),
    );
  }
}
