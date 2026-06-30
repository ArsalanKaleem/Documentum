import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized typography built on Poppins. Large, comfortable page titles with
/// excellent readability; weights 400/500/600/700.
class AppTypography {
  AppTypography._();

  static TextTheme textTheme(Color onSurface, Color muted) {
    TextStyle base(double size, FontWeight weight,
        {double? height, double? spacing, Color? color}) =>
        GoogleFonts.poppins(
          fontSize: size,
          fontWeight: weight,
          height: height,
          letterSpacing: spacing,
          color: color ?? onSurface,
        );

    return TextTheme(
      displayLarge: base(40, FontWeight.w700, height: 1.1, spacing: -0.5),
      displayMedium: base(32, FontWeight.w700, height: 1.15, spacing: -0.4),
      displaySmall: base(28, FontWeight.w600, height: 1.2, spacing: -0.3),
      headlineLarge: base(26, FontWeight.w600, height: 1.2, spacing: -0.3),
      headlineMedium: base(22, FontWeight.w600, height: 1.25, spacing: -0.2),
      headlineSmall: base(18, FontWeight.w600, height: 1.3),
      titleLarge: base(17, FontWeight.w600, height: 1.3),
      titleMedium: base(15, FontWeight.w500, height: 1.35),
      titleSmall: base(13, FontWeight.w600, height: 1.35),
      bodyLarge: base(15, FontWeight.w400, height: 1.5),
      bodyMedium: base(14, FontWeight.w400, height: 1.5),
      bodySmall: base(12.5, FontWeight.w400, height: 1.45, color: muted),
      labelLarge: base(14, FontWeight.w600, height: 1.2, spacing: 0.1),
      labelMedium: base(12.5, FontWeight.w500, height: 1.2, spacing: 0.2),
      labelSmall: base(11.5, FontWeight.w500, height: 1.2, spacing: 0.4, color: muted),
    );
  }

  /// Monospace style for code, paths, and metrics.
  static TextStyle mono({double size = 12.5, Color? color}) =>
      GoogleFonts.jetBrainsMono(fontSize: size, color: color, height: 1.45);

  /// Instrument Sans — used for the brand name display only.
  /// Call with a color so it adapts to light/dark.
  static TextStyle brand({
    double size = 22,
    FontWeight weight = FontWeight.w700,
    Color? color,
    double? letterSpacing,
  }) =>
      GoogleFonts.instrumentSans(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing ?? -0.3,
        height: 1.1,
      );
}