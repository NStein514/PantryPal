import 'package:flutter/material.dart';
import '../ui/motion.dart';
import '../l10n/l10n.dart';

/// Rounded days-left badge: green > 3 days, orange 0–3, red expired, grey undated.
class ExpiryBadge extends StatelessWidget {
  const ExpiryBadge({super.key, required this.daysLeft, this.size = 48});
  final int? daysLeft;
  final double size;

  /// White text on each of these is at least 5:1 (the old orange was 2.7:1).
  static const expiredColor = Color(0xFFC62828), soonColor = Color(0xFFB45309), freshColor = Color(0xFF2E7D32),
      undatedColor = Color(0xFF546E7A);

  /// For the badge colour used as *text* on a neutral card: the deep tones in light mode, light
  /// tints in dark mode (deep red on dark grey is 2:1; the tints are 5.4:1 or better).
  static Color textColorFor(int? d, Brightness brightness) {
    if (brightness == Brightness.light) return colorFor(d);
    return d == null
        ? const Color(0xFFB0BEC5)
        : d < 0
            ? const Color(0xFFEF9A9A)
            : d <= 3
                ? const Color(0xFFFFCC80)
                : const Color(0xFFA5D6A7);
  }

  static Color colorFor(int? d) => d == null
      ? undatedColor
      : d < 0
          ? expiredColor
          : d <= 3
              ? soonColor
              : freshColor;

  @override
  Widget build(BuildContext context) {
    final d = daysLeft;
    final l = context.l10n;
    final value = d == null ? '–' : '${d.abs()}';
    final caption = d == null
        ? l.badgeNoDate
        : d < 0
            ? l.badgeAgo
            : d == 0
                ? l.badgeToday
                : l.badgeDays(d);
    final label = d == null
        ? l.noExpiryDate
        : d < 0
            ? l.expiredDaysAgo(-d)
            : l.expiresInDays(d);
    return Semantics(
      label: label,
      child: AnimatedContainer(
        duration: Motion.of(context, Motion.short),
        width: size,
        height: size,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: colorFor(d), borderRadius: BorderRadius.circular(12)),
        child: FittedBox(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            Text(caption, style: const TextStyle(color: Colors.white, fontSize: 10)),
          ]),
        ),
      ),
    );
  }
}
