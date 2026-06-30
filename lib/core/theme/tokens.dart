import 'package:flutter/widgets.dart';

import 'color_scheme.dart';

/// Centralized spacing scale (4px base). Use these instead of literals.
class Spacing {
  Spacing._();
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  /// Standard gutter between large content panels.
  static const double gutter = 24;

  /// Page padding for the center workspace.
  static const EdgeInsets page = EdgeInsets.all(32);
  static const EdgeInsets panel = EdgeInsets.all(24);
}

/// Corner radius scale.
class Radii {
  Radii._();
  static const double xs = 8;
  static const double sm = 10;
  static const double md = 12;
  static const double lg = 16; // cards
  static const double xl = 20;
  static const double pill = 999;

  static const BorderRadius card = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius button = BorderRadius.all(Radius.circular(md));
  static const BorderRadius field = BorderRadius.all(Radius.circular(md));
  static const BorderRadius chip = BorderRadius.all(Radius.circular(pill));
}

/// Motion tokens — subtle only, 150–250ms.
class Motion {
  Motion._();
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 250);
  static const Curve curve = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutQuart;
}

/// Border widths.
class Borders {
  Borders._();
  static const double thin = 1;
  static const double medium = 1.5;
  static const double thick = 2;
}

/// Consistent icon sizes.
class IconSizes {
  IconSizes._();
  static const double xs = 14;
  static const double sm = 16;
  static const double md = 20;
  static const double lg = 24;
  static const double xl = 32;
}

/// Standard component heights for a dense, desktop-first feel.
class Sizes {
  Sizes._();
  static const double topBar = 56;
  static const double sidebarExpanded = 248;
  static const double sidebarCollapsed = 72;
  static const double rightPanel = 320;
  static const double buttonHeight = 44;
  static const double fieldHeight = 44;
  static const double rowHeight = 40;
}

/// Soft, derived shadows (never heavy). Built from the primary tone.
class Shadows {
  Shadows._();

  static List<BoxShadow> card(bool dark) => [
        BoxShadow(
          color: (dark ? const Color(0xFF000000) : BrandPalette.primary)
              .withValues(alpha: dark ? 0.30 : 0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> raised(bool dark) => [
        BoxShadow(
          color: (dark ? const Color(0xFF000000) : BrandPalette.primary)
              .withValues(alpha: dark ? 0.40 : 0.10),
          blurRadius: 28,
          offset: const Offset(0, 10),
        ),
      ];
}
