import 'package:flutter/material.dart';

import 'color_scheme.dart';
import 'component_theme.dart';
import 'tokens.dart';
import 'typography.dart';

/// Assembles the premium light/dark themes from the two-color brand palette,
/// Poppins typography, and the centralized component themes. Nothing here uses
/// ad-hoc colors — all tones derive from [BrandPalette].
class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme =
        dark ? BrandPalette.darkScheme() : BrandPalette.lightScheme();
    final canvas =
        dark ? BrandPalette.canvasDark : BrandPalette.canvasLight;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      canvasColor: canvas,
      textTheme: AppTypography.textTheme(scheme.onSurface, scheme.onSurfaceVariant),
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      cardTheme: ComponentTheme.card(scheme, dark),
      appBarTheme: ComponentTheme.appBar(scheme),
      filledButtonTheme: ComponentTheme.filledButton(scheme),
      outlinedButtonTheme: ComponentTheme.outlinedButton(scheme),
      textButtonTheme: ComponentTheme.textButton(scheme),
      inputDecorationTheme: ComponentTheme.input(scheme, dark),
      chipTheme: ComponentTheme.chip(scheme),
      navigationRailTheme: ComponentTheme.navRail(scheme),
      dialogTheme: ComponentTheme.dialog(scheme),
      tooltipTheme: ComponentTheme.tooltip(scheme, dark),
      dividerTheme: ComponentTheme.divider(scheme),
      progressIndicatorTheme: ComponentTheme.progress(scheme),
      switchTheme: ComponentTheme.switchTheme(scheme),
      iconTheme: IconThemeData(color: scheme.onSurface, size: IconSizes.md),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
