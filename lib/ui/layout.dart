import 'package:flutter/material.dart';
import 'breakpoints.dart';

/// Centres [child] at a comfortable width on tablets and in landscape; full width on phones.
class ReadableWidth extends StatelessWidget {
  const ReadableWidth({super.key, required this.child, this.maxWidth = readableWidth});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
      );
}

/// Lays [children] out in as many equal columns as fit (see [columnsFor]); one column on phones.
/// Use inside scrolling lists: it sizes to its content.
class AdaptiveColumns extends StatelessWidget {
  const AdaptiveColumns({super.key, required this.children, this.minItemWidth = 340, this.gap = 12, this.padding = EdgeInsets.zero});
  final List<Widget> children;
  final double minItemWidth;
  final double gap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: LayoutBuilder(builder: (context, c) {
          final cols = columnsFor(c.maxWidth, minItemWidth: minItemWidth, gap: gap);
          if (cols == 1) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
          final w = (c.maxWidth - gap * (cols - 1)) / cols;
          return Wrap(spacing: gap, runSpacing: 0, children: [for (final ch in children) SizedBox(width: w, child: ch)]);
        }),
      );
}
