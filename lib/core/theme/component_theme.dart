import 'package:flutter/material.dart';

import 'color_scheme.dart';
import 'tokens.dart';

/// Builds the heavily-customized Material 3 component themes so the app does not
/// resemble default Flutter. Everything derives from the scheme + tokens.
class ComponentTheme {
  ComponentTheme._();

  static CardThemeData card(ColorScheme s, bool dark) => CardThemeData(
        elevation: 0,
        color: dark ? BrandPalette.cardDark : BrandPalette.cardLight,
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.card,
          side: BorderSide(color: s.outlineVariant, width: Borders.thin),
        ),
      );

  static AppBarTheme appBar(ColorScheme s) => AppBarTheme(
        backgroundColor: s.surface,
        foregroundColor: s.onSurface,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: null,
        toolbarHeight: Sizes.topBar,
      );

  static FilledButtonThemeData filledButton(ColorScheme s) =>
      FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStatePropertyAll(
            Size(0, Sizes.buttonHeight),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: Spacing.lg),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: Radii.button),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return s.primary.withValues(alpha: 0.35);
            }
            if (states.contains(WidgetState.hovered)) {
              return BrandPalette.lighten(s.primary, 0.05);
            }
            return s.primary;
          }),
          foregroundColor: WidgetStatePropertyAll(s.onPrimary),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          elevation: const WidgetStatePropertyAll(0),
          overlayColor: WidgetStatePropertyAll(
            s.onPrimary.withValues(alpha: 0.08),
          ),
          animationDuration: Motion.fast,
        ),
      );

  static OutlinedButtonThemeData outlinedButton(ColorScheme s) =>
      OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStatePropertyAll(Size(0, Sizes.buttonHeight)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: Spacing.lg),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: Radii.button),
          ),
          side: WidgetStateProperty.resolveWith((states) {
            final c = states.contains(WidgetState.hovered)
                ? s.primary
                : s.outline;
            return BorderSide(color: c, width: Borders.thin);
          }),
          foregroundColor: WidgetStatePropertyAll(s.onSurface),
          overlayColor: WidgetStatePropertyAll(
            s.primary.withValues(alpha: 0.06),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          animationDuration: Motion.fast,
        ),
      );

  static TextButtonThemeData textButton(ColorScheme s) => TextButtonThemeData(
        style: ButtonStyle(
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.xs),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: Radii.button),
          ),
          foregroundColor: WidgetStatePropertyAll(s.onSurface),
          overlayColor: WidgetStatePropertyAll(
            s.primary.withValues(alpha: 0.06),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ),
      );

  static InputDecorationTheme input(ColorScheme s, bool dark) =>
      InputDecorationTheme(
        filled: true,
        fillColor: dark
            ? BrandPalette.surfaceHighDark
            : BrandPalette.lighten(BrandPalette.secondary, 0.06),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
        hintStyle: TextStyle(color: s.onSurfaceVariant),
        enabledBorder: OutlineInputBorder(
          borderRadius: Radii.field,
          borderSide: BorderSide(color: s.outlineVariant, width: Borders.thin),
        ),
        border: OutlineInputBorder(
          borderRadius: Radii.field,
          borderSide: BorderSide(color: s.outlineVariant, width: Borders.thin),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: Radii.field,
          borderSide: BorderSide(color: s.primary, width: Borders.medium),
        ),
      );

  static ChipThemeData chip(ColorScheme s) => ChipThemeData(
        backgroundColor: s.surfaceContainerHigh,
        side: BorderSide(color: s.outlineVariant, width: Borders.thin),
        shape: RoundedRectangleBorder(borderRadius: Radii.chip),
        labelStyle: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          color: s.onSurface,
        ),
        padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 6),
      );

  static NavigationRailThemeData navRail(ColorScheme s) =>
      NavigationRailThemeData(
        backgroundColor: s.surface,
        indicatorColor: s.primary.withValues(alpha: 0.12),
        indicatorShape: RoundedRectangleBorder(borderRadius: Radii.button),
        selectedIconTheme: IconThemeData(color: s.primary, size: IconSizes.md),
        unselectedIconTheme:
            IconThemeData(color: s.onSurfaceVariant, size: IconSizes.md),
        selectedLabelTextStyle: TextStyle(
          color: s.primary,
          fontWeight: FontWeight.w600,
          fontSize: 12.5,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: s.onSurfaceVariant,
          fontWeight: FontWeight.w500,
          fontSize: 12.5,
        ),
      );

  static DialogThemeData dialog(ColorScheme s) => DialogThemeData(
        backgroundColor: s.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.xl),
          side: BorderSide(color: s.outlineVariant),
        ),
      );

  static TooltipThemeData tooltip(ColorScheme s, bool dark) => TooltipThemeData(
        decoration: BoxDecoration(
          color: s.inverseSurface,
          borderRadius: Radii.field,
        ),
        textStyle: TextStyle(color: s.onInverseSurface, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        waitDuration: const Duration(milliseconds: 400),
      );

  static DividerThemeData divider(ColorScheme s) => DividerThemeData(
        color: s.outlineVariant,
        thickness: Borders.thin,
        space: Borders.thin,
      );

  static ProgressIndicatorThemeData progress(ColorScheme s) =>
      ProgressIndicatorThemeData(
        color: s.primary,
        linearTrackColor: s.primary.withValues(alpha: 0.12),
        circularTrackColor: s.primary.withValues(alpha: 0.12),
      );

  static SwitchThemeData switchTheme(ColorScheme s) => SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((st) =>
            st.contains(WidgetState.selected) ? s.onPrimary : s.onSurfaceVariant),
        trackColor: WidgetStateProperty.resolveWith((st) =>
            st.contains(WidgetState.selected)
                ? s.primary
                : s.surfaceContainerHighest),
        trackOutlineColor: WidgetStatePropertyAll(s.outlineVariant),
      );
}
