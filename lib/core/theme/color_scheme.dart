import 'package:flutter/material.dart';

/// The entire app is built from exactly two brand colors. Every other tone —
/// hovers, borders, disabled states, elevation, surfaces, dark mode — is
/// derived programmatically from these two. No additional hues are introduced.
class BrandPalette {
  BrandPalette._();

  /// Primary brand color (slate). Used for actions, emphasis, and text.
  static const Color primary = Color(0xFF50586C);

  /// Secondary / background color (mist). The calm canvas of the app.
  static const Color secondary = Color(0xFFDCE2F0);

  // --- shade helpers ---------------------------------------------------------

  /// Lightens [c] toward white by [amount] (0..1) in HSL space.
  static Color lighten(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  /// Darkens [c] toward black by [amount] (0..1) in HSL space.
  static Color darken(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  /// Mixes [a] and [b] by [t] (0..1).
  static Color mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

  // --- light derived tones ---------------------------------------------------

  static final Color canvasLight = secondary; // app background
  static final Color surfaceLight = lighten(secondary, 0.085); // panels
  static final Color surfaceHighLight = lighten(secondary, 0.05); // raised
  static final Color cardLight = lighten(secondary, 0.10);
  static final Color borderLight = darken(secondary, 0.08);
  static final Color borderStrongLight = darken(secondary, 0.16);
  static final Color textLight = darken(primary, 0.06);
  static final Color textMutedLight = mix(primary, secondary, 0.42);
  static final Color disabledLight = mix(primary, secondary, 0.62);

  // --- dark derived tones ----------------------------------------------------

  static final Color canvasDark = darken(primary, 0.34); // ~#20242E
  static final Color surfaceDark = darken(primary, 0.28);
  static final Color surfaceHighDark = darken(primary, 0.24);
  static final Color cardDark = darken(primary, 0.22);
  static final Color borderDark = darken(primary, 0.14);
  static final Color borderStrongDark = darken(primary, 0.06);
  static final Color textDark = lighten(secondary, 0.04);
  static final Color textMutedDark = mix(secondary, primary, 0.40);

  // --- status (derived only; differentiated by tone + iconography) -----------

  /// Strong, confident fill for completed work.
  static final Color statusDone = primary;

  /// Active/running emphasis — a lighter primary.
  static final Color statusRunning = lighten(primary, 0.12);

  /// Failure — a deep, darkened primary that reads as heavier/alert. With no
  /// second hue allowed, failure is reinforced by weight + alert iconography.
  static final Color statusFailed = darken(primary, 0.16);

  /// Idle / pending — muted.
  static final Color statusIdle = mix(primary, secondary, 0.5);

  // --- color schemes ---------------------------------------------------------

  static ColorScheme lightScheme() => ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: secondary,
        primaryContainer: lighten(primary, 0.40),
        onPrimaryContainer: darken(primary, 0.10),
        secondary: darken(secondary, 0.30),
        onSecondary: secondary,
        secondaryContainer: lighten(secondary, 0.02),
        onSecondaryContainer: darken(primary, 0.05),
        tertiary: primary,
        onTertiary: secondary,
        error: statusFailed,
        onError: secondary,
        surface: surfaceLight,
        onSurface: textLight,
        onSurfaceVariant: textMutedLight,
        surfaceContainerLowest: lighten(secondary, 0.12),
        surfaceContainerLow: lighten(secondary, 0.10),
        surfaceContainer: lighten(secondary, 0.07),
        surfaceContainerHigh: lighten(secondary, 0.04),
        surfaceContainerHighest: secondary,
        outline: borderStrongLight,
        outlineVariant: borderLight,
        shadow: darken(primary, 0.20),
        scrim: darken(primary, 0.30),
        inverseSurface: darken(primary, 0.24),
        onInverseSurface: lighten(secondary, 0.04),
        inversePrimary: lighten(primary, 0.30),
        surfaceTint: primary,
      );

  static ColorScheme darkScheme() => ColorScheme(
        brightness: Brightness.dark,
        primary: lighten(primary, 0.34),
        onPrimary: darken(primary, 0.28),
        primaryContainer: darken(primary, 0.10),
        onPrimaryContainer: lighten(secondary, 0.04),
        secondary: lighten(secondary, 0.02),
        onSecondary: darken(primary, 0.24),
        secondaryContainer: darken(primary, 0.16),
        onSecondaryContainer: lighten(secondary, 0.04),
        tertiary: lighten(secondary, 0.02),
        onTertiary: darken(primary, 0.24),
        error: lighten(primary, 0.40),
        onError: darken(primary, 0.28),
        surface: surfaceDark,
        onSurface: textDark,
        onSurfaceVariant: textMutedDark,
        surfaceContainerLowest: darken(primary, 0.34),
        surfaceContainerLow: darken(primary, 0.30),
        surfaceContainer: darken(primary, 0.26),
        surfaceContainerHigh: darken(primary, 0.22),
        surfaceContainerHighest: darken(primary, 0.18),
        outline: borderStrongDark,
        outlineVariant: borderDark,
        shadow: const Color(0xFF000000),
        scrim: const Color(0xFF000000),
        inverseSurface: lighten(secondary, 0.04),
        onInverseSurface: darken(primary, 0.24),
        inversePrimary: primary,
        surfaceTint: lighten(primary, 0.34),
      );
}
