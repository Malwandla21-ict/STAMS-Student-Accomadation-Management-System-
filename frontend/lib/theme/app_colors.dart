import 'package:flutter/material.dart';

/// Raw palette from the STAMS design system. Screens should prefer
/// `Theme.of(context).colorScheme` and reach for these only for the
/// handful of brand/utility colours that have no ColorScheme role.
abstract final class AppColors {
  // Brand (Roofline 1c)
  static const navy = Color(0xFF102A43);
  static const brandIris = Color(0xFF7B6CFF); // logo, splash, illustration only - not for text
  static const chalk = Color(0xFFF5F3EC);

  // ColorScheme roles
  static const primary = navy;
  static const primaryContainer = Color(0xFFD3E1EF);
  static const onPrimaryContainer = Color(0xFF0A1C2E);
  static const secondary = Color(0xFF4A5D70);
  static const secondaryContainer = Color(0xFFDCE4EC);
  static const onSecondaryContainer = Color(0xFF1A2A38);
  static const tertiary = Color(0xFF5A4AE3); // nudge
  static const tertiaryPressed = Color(0xFF4C3DD1);
  static const tertiaryContainer = Color(0xFFE7E3FF);
  static const onTertiaryContainer = Color(0xFF21176B);
  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF410002);
  static const surface = Color(0xFFFAF9F5);
  static const onSurface = Color(0xFF15202B);
  static const onSurfaceVariant = Color(0xFF4B5663);
  static const outline = Color(0xFF737D88);
  static const outlineVariant = Color(0xFFD3D6D9);

  // Surface containers
  static const surfaceLowest = Color(0xFFFFFFFF); // cards
  static const surfaceLow = chalk; // chalk panels
  static const surfaceContainer = Color(0xFFEFEDE6); // nav bar, icon tiles
  static const surfaceHigh = Color(0xFFE9E7E0); // search fields
  static const surfaceHighest = Color(0xFFE3E1DA); // card borders, dividers
  static const cardBorder = Color(0xFFECEAE4); // softer than surfaceHighest for cards
  static const softTint = Color(0xFFEFF3F8); // calm tinted panels (student room card)
  static const softIris = Color(0xFFF4F2FF); // very light iris for unread rows, highlights

  // Utility
  static const hoverBorder = Color(0xFFB9BFC5);
  static const nudgeText = Color(0xFF3D30B0); // "Last nudged 2h ago", "· 4th nudge"
  static const unreadNudge = Color(0xFFF1EFFF); // landlord unread alert row
  static const unreadStatus = Color(0xFFEEF4FC); // student unread alert row
  static const inverseSurface = Color(0xFF1E2B38); // snackbar
  static const inversePrimary = Color(0xFFB9B0FF); // snackbar action / icon
  static const scrim = Color(0x7A0A1622); // rgba(10,22,34,.48)
  static const stripeA = Color(0xFFE6E4DD);
  static const stripeB = Color(0xFFF0EEE8);
  static const onNavyMuted = Color(0xFFB8C6D4);
  static const onNavySoft = Color(0xFFC9D4DF);
}
