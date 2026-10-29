/// Material 3 window size classes, by available width in logical pixels.
enum WindowSize {
  /// Phones in portrait (< 600): bottom navigation, one column.
  compact,

  /// Large phones in landscape, small tablets (600–839): navigation rail.
  medium,

  /// Tablets, desktops (≥ 840): navigation rail, multiple columns, side-by-side panes.
  expanded;

  static WindowSize of(double width) => width < 600
      ? WindowSize.compact
      : width < 840
          ? WindowSize.medium
          : WindowSize.expanded;
}

/// Comfortable line length for reading and forms; wider screens centre content at this width.
const readableWidth = 720.0;

/// How many columns of at least [minItemWidth] fit in [width] (never fewer than 1, at most [max]).
int columnsFor(double width, {double minItemWidth = 340, double gap = 12, int max = 3}) {
  if (width <= 0) return 1;
  final n = ((width + gap) / (minItemWidth + gap)).floor();
  return n.clamp(1, max);
}
