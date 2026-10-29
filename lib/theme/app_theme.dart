import 'package:flutter/material.dart';

/// PantryPal's look: neutral surfaces (warm off-white in light mode, grey in dark mode) with
/// green kept as an accent for primary actions. Every text/background pair in both palettes
/// meets WCAG AA contrast (4.5:1 for text, 3:1 for icons and outlines; see tools/palette.py).
class AppTheme {
  AppTheme._();

  static const ColorScheme lightScheme = ColorScheme(
        brightness: Brightness.light,
        surface: Color(0xFFFAF8F4),
        surfaceContainerLowest: Color(0xFFFFFFFF),
        surfaceContainerLow: Color(0xFFF5F2EC),
        surfaceContainer: Color(0xFFEFEBE4),
        surfaceContainerHigh: Color(0xFFE9E5DD),
        surfaceContainerHighest: Color(0xFFE3DED5),
        onSurface: Color(0xFF1F1E1B),
        onSurfaceVariant: Color(0xFF57534B),
        outline: Color(0xFF86817A),
        outlineVariant: Color(0xFFD3CEC4),
        primary: Color(0xFF2F6B3A),
        onPrimary: Color(0xFFFFFFFF),
        primaryContainer: Color(0xFFE6E2D9),
        onPrimaryContainer: Color(0xFF1F1E1B),
        secondary: Color(0xFF5C5850),
        onSecondary: Color(0xFFFFFFFF),
        secondaryContainer: Color(0xFFE2DDD3),
        onSecondaryContainer: Color(0xFF1F1E1B),
        tertiary: Color(0xFF7A5A3A),
        onTertiary: Color(0xFFFFFFFF),
        tertiaryContainer: Color(0xFFEFE3D6),
        onTertiaryContainer: Color(0xFF2B1F12),
        error: Color(0xFFB3261E),
        onError: Color(0xFFFFFFFF),
        errorContainer: Color(0xFFF9DEDC),
        onErrorContainer: Color(0xFF410E0B),
        inverseSurface: Color(0xFF32302C),
        onInverseSurface: Color(0xFFF3EFE8),
        inversePrimary: Color(0xFF9CD3A8),
        // No tinted elevation: cards and bars stay neutral instead of picking up the accent.
        surfaceTint: Colors.transparent,
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
      );

  static const ColorScheme darkScheme = ColorScheme(
        brightness: Brightness.dark,
        surface: Color(0xFF1E1F21),
        surfaceContainerLowest: Color(0xFF17181A),
        surfaceContainerLow: Color(0xFF222326),
        surfaceContainer: Color(0xFF27282B),
        surfaceContainerHigh: Color(0xFF2E2F32),
        surfaceContainerHighest: Color(0xFF37383B),
        onSurface: Color(0xFFE6E4E1),
        onSurfaceVariant: Color(0xFFBDBAB4),
        outline: Color(0xFF8E8B86),
        outlineVariant: Color(0xFF45464A),
        primary: Color(0xFF93CFA0),
        onPrimary: Color(0xFF0C3916),
        primaryContainer: Color(0xFF3A3B3F),
        onPrimaryContainer: Color(0xFFE6E4E1),
        secondary: Color(0xFFC9C5BE),
        onSecondary: Color(0xFF2F2E2B),
        secondaryContainer: Color(0xFF3E3F43),
        onSecondaryContainer: Color(0xFFE6E4E1),
        tertiary: Color(0xFFE0C0A0),
        onTertiary: Color(0xFF3F2B16),
        tertiaryContainer: Color(0xFF4A4036),
        onTertiaryContainer: Color(0xFFF3E3D3),
        error: Color(0xFFF2B8B5),
        onError: Color(0xFF601410),
        errorContainer: Color(0xFF8C1D18),
        onErrorContainer: Color(0xFFF9DEDC),
        inverseSurface: Color(0xFFE6E4E1),
        onInverseSurface: Color(0xFF2F3033),
        inversePrimary: Color(0xFF2F6B3A),
        surfaceTint: Colors.transparent,
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
      );

  static ThemeData get light => _build(lightScheme);
  static ThemeData get dark => _build(darkScheme);

  static ThemeData _build(ColorScheme s) => ThemeData(
        useMaterial3: true,
        colorScheme: s,
        scaffoldBackgroundColor: s.surface,
        appBarTheme: AppBarTheme(backgroundColor: s.surface, foregroundColor: s.onSurface, scrolledUnderElevation: 0),
        navigationBarTheme: NavigationBarThemeData(backgroundColor: s.surfaceContainer, indicatorColor: s.secondaryContainer),
        dividerTheme: DividerThemeData(color: s.outlineVariant),
        // On tablets, sheets stay a comfortable width instead of spanning the screen.
        bottomSheetTheme: const BottomSheetThemeData(constraints: BoxConstraints(maxWidth: 640)),
        // Floating snackbars sit above the navigation instead of covering it.
        snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      );
}
