import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantrypal/theme/app_theme.dart';
import 'package:pantrypal/widgets/expiry_badge.dart';

double contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  for (final (name, s) in [('light', AppTheme.lightScheme), ('dark', AppTheme.darkScheme)]) {
    group(name, () {
      test('text meets WCAG AA (4.5:1) on every surface it sits on', () {
        final surfaces = [s.surface, s.surfaceContainerLowest, s.surfaceContainerLow, s.surfaceContainer,
          s.surfaceContainerHigh, s.surfaceContainerHighest];
        for (final bg in surfaces) {
          expect(contrast(s.onSurface, bg), greaterThanOrEqualTo(4.5));
        }
        for (final bg in [s.surface, s.surfaceContainerLow, s.surfaceContainer, s.surfaceContainerHighest]) {
          expect(contrast(s.onSurfaceVariant, bg), greaterThanOrEqualTo(4.5));
        }
        for (final (fg, bg) in [(s.onPrimary, s.primary), (s.onPrimaryContainer, s.primaryContainer),
          (s.onSecondaryContainer, s.secondaryContainer), (s.onError, s.error), (s.onErrorContainer, s.errorContainer),
          (s.primary, s.surface), (s.error, s.surface)]) {
          expect(contrast(fg, bg), greaterThanOrEqualTo(4.5));
        }
        expect(contrast(s.outline, s.surface), greaterThanOrEqualTo(3)); // non-text UI parts
      });

      test('neutral surfaces: no accent tint on elevated cards and bars', () {
        expect(s.surfaceTint, Colors.transparent);
        final hsl = HSLColor.fromColor(s.surface);
        expect(hsl.saturation, lessThan(0.35)); // off-white / grey, not green
        expect(s.primaryContainer, isNot(s.primary));
      });
    });
  }

  test('light is off-white, dark is grey', () {
    expect(AppTheme.lightScheme.brightness, Brightness.light);
    expect(AppTheme.darkScheme.brightness, Brightness.dark);
    expect(AppTheme.lightScheme.surface.computeLuminance(), greaterThan(0.85));
    expect(AppTheme.lightScheme.surface, isNot(Colors.white));
    expect(AppTheme.darkScheme.surface.computeLuminance(), lessThan(0.05));
    expect(AppTheme.light.scaffoldBackgroundColor, AppTheme.lightScheme.surface);
    expect(AppTheme.dark.scaffoldBackgroundColor, AppTheme.darkScheme.surface);
  });

  test('expiry badges keep white text readable (≥ 4.5:1)', () {
    for (final c in [ExpiryBadge.expiredColor, ExpiryBadge.soonColor, ExpiryBadge.freshColor, ExpiryBadge.undatedColor]) {
      expect(contrast(Colors.white, c), greaterThanOrEqualTo(4.5));
    }
  });
}
