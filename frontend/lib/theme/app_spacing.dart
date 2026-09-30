/// 4dp grid. Screen gutter is [lg], gap between sections is [xl].
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48; // min tap target
}

/// M3 ShapeScheme corner radii used across the app.
abstract final class AppRadius {
  static const double extraSmall = 4; // priority badge
  static const double small = 8; // tags, filter chips
  static const double medium = 12; // fields, tiles
  static const double large = 16; // cards
  static const double extraLarge = 28; // sheets
}
