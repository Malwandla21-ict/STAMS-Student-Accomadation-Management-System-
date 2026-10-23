import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'semantic_colors.dart';

abstract final class AppTheme {
  static const colorScheme = ColorScheme.light(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    secondary: AppColors.secondary,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.secondaryContainer,
    onSecondaryContainer: AppColors.onSecondaryContainer,
    tertiary: AppColors.tertiary,
    onTertiary: Colors.white,
    tertiaryContainer: AppColors.tertiaryContainer,
    onTertiaryContainer: AppColors.onTertiaryContainer,
    error: AppColors.error,
    onError: Colors.white,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.onErrorContainer,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    onSurfaceVariant: AppColors.onSurfaceVariant,
    surfaceContainerLowest: AppColors.surfaceLowest,
    surfaceContainerLow: AppColors.surfaceLow,
    surfaceContainer: AppColors.surfaceContainer,
    surfaceContainerHigh: AppColors.surfaceHigh,
    surfaceContainerHighest: AppColors.surfaceHighest,
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineVariant,
    inverseSurface: AppColors.inverseSurface,
    onInverseSurface: AppColors.chalk,
    inversePrimary: AppColors.inversePrimary,
    scrim: AppColors.scrim,
    surfaceTint: Colors.transparent,
  );

  static TextStyle _archivo(double size, double lineHeight, FontWeight weight) => GoogleFonts.archivo(
        fontSize: size,
        height: lineHeight / size,
        fontWeight: weight,
        color: AppColors.onSurface,
        letterSpacing: 0,
      );

  /// Archivo, sizes from the design system (size / line height / weight).
  static TextTheme get textTheme => TextTheme(
        displaySmall: _archivo(36, 44, FontWeight.w800),
        // Page titles. A notch smaller and lighter than the original 28/700 so screens feel calmer.
        headlineMedium: _archivo(24, 32, FontWeight.w600),
        headlineSmall: _archivo(22, 28, FontWeight.w600),
        titleLarge: _archivo(20, 26, FontWeight.w600),
        titleMedium: _archivo(16, 22, FontWeight.w600),
        titleSmall: _archivo(14, 20, FontWeight.w600),
        bodyLarge: _archivo(16, 24, FontWeight.w400),
        bodyMedium: _archivo(14, 20, FontWeight.w400),
        bodySmall: _archivo(12, 16, FontWeight.w400),
        labelLarge: _archivo(14, 20, FontWeight.w600),
        labelMedium: _archivo(12, 16, FontWeight.w600),
        labelSmall: _archivo(11, 16, FontWeight.w600),
      );

  static ThemeData get light {
    final text = textTheme;
    const pill = StadiumBorder();
    final buttonText = WidgetStatePropertyAll(text.labelLarge);
    const buttonSize = WidgetStatePropertyAll(Size(64, 48));
    const buttonPadding = WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: AppSpacing.xl));

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.surface,
      fontFamily: GoogleFonts.archivo().fontFamily,
      textTheme: text,
      extensions: const [StatusColors.light, PriorityColors.light],
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,
        titleSpacing: 4,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(pill),
          minimumSize: buttonSize,
          padding: buttonPadding,
          textStyle: buttonText,
          elevation: const WidgetStatePropertyAll(0),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(pill),
          minimumSize: buttonSize,
          padding: buttonPadding,
          textStyle: buttonText,
          foregroundColor: const WidgetStatePropertyAll(AppColors.primary),
          side: WidgetStateProperty.resolveWith(
            (s) => BorderSide(color: s.contains(WidgetState.disabled) ? AppColors.outlineVariant : AppColors.outline),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(pill),
          minimumSize: buttonSize,
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: AppSpacing.sm)),
          textStyle: buttonText,
          foregroundColor: const WidgetStatePropertyAll(AppColors.primary),
        ),
      ),
      iconButtonTheme: const IconButtonThemeData(
        style: ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(48, 48))),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.fromLTRB(AppSpacing.md, 8, AppSpacing.md, 8),
        labelStyle: text.bodyLarge!.copyWith(color: AppColors.onSurfaceVariant),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith((s) {
          final base = text.bodySmall!;
          if (s.contains(WidgetState.error)) return base.copyWith(color: AppColors.error, fontWeight: FontWeight.w600);
          if (s.contains(WidgetState.focused)) return base.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600);
          return base.copyWith(color: AppColors.onSurfaceVariant);
        }),
        hintStyle: text.bodyLarge!.copyWith(color: AppColors.onSurfaceVariant),
        // Fields stay white on hover (web/desktop), like the design.
        hoverColor: Colors.transparent,
        helperStyle: text.bodySmall!.copyWith(color: AppColors.onSurfaceVariant),
        errorStyle: text.bodySmall!.copyWith(color: AppColors.error),
        errorMaxLines: 2,
        helperMaxLines: 2,
        prefixIconColor: WidgetStateColor.resolveWith(
          (s) => s.contains(WidgetState.focused) ? AppColors.primary : AppColors.onSurfaceVariant,
        ),
        suffixIconColor: AppColors.onSurfaceVariant,
        border: _field(AppColors.outline, 1),
        enabledBorder: _field(AppColors.outline, 1),
        focusedBorder: _field(AppColors.primary, 2),
        errorBorder: _field(AppColors.error, 2),
        focusedErrorBorder: _field(AppColors.error, 2),
        disabledBorder: _field(AppColors.outlineVariant, 1),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 80,
        backgroundColor: AppColors.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: AppColors.primaryContainer,
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateTextStyle.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? text.labelMedium!.copyWith(fontWeight: FontWeight.w700, color: AppColors.onSurface)
              : text.labelMedium!.copyWith(fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: 24,
            color: s.contains(WidgetState.selected) ? AppColors.onPrimaryContainer : AppColors.onSurfaceVariant,
          ),
        ),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: AppColors.error,
        textColor: Colors.white,
        textStyle: text.labelSmall!.copyWith(fontWeight: FontWeight.w700),
        largeSize: 18,
        padding: const EdgeInsets.symmetric(horizontal: 5),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.small)),
        side: WidgetStateBorderSide.resolveWith(
          (s) => s.contains(WidgetState.selected) ? BorderSide.none : const BorderSide(color: AppColors.outline),
        ),
        backgroundColor: Colors.transparent,
        selectedColor: AppColors.secondaryContainer,
        checkmarkColor: AppColors.onSecondaryContainer,
        labelStyle: text.bodyMedium!.copyWith(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.onSurface),
        secondaryLabelStyle: text.bodyMedium!.copyWith(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSecondaryContainer),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        showCheckmark: true,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
          textStyle: WidgetStateTextStyle.resolveWith(
            (s) => text.labelLarge!.copyWith(fontWeight: s.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500),
          ),
          side: const WidgetStatePropertyAll(BorderSide(color: AppColors.outline)),
          backgroundColor: WidgetStateColor.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.secondaryContainer : Colors.transparent,
          ),
          foregroundColor: WidgetStateColor.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.onSecondaryContainer : AppColors.onSurface,
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: AppColors.scrim,
        showDragHandle: true,
        dragHandleColor: AppColors.outline,
        dragHandleSize: Size(32, 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.extraLarge))),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.inverseSurface,
        contentTextStyle: text.bodyMedium!.copyWith(color: AppColors.chalk),
        actionTextColor: AppColors.inversePrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.small)),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: text.headlineSmall,
        contentTextStyle: text.bodyMedium!.copyWith(color: AppColors.onSurfaceVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.extraLarge)),
      ),
      switchTheme: SwitchThemeData(
        thumbIcon: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? const Icon(Icons.check, size: 16, color: AppColors.primary) : null,
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateColor.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.primary : AppColors.onSurfaceVariant,
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.surfaceHighest, thickness: 1, space: 1),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primary),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: AppColors.onPrimaryContainer,
        elevation: 3,
        highlightElevation: 4,
        extendedTextStyle: text.labelLarge!.copyWith(fontSize: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.large)),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        iconColor: AppColors.onSurfaceVariant,
        titleTextStyle: text.bodyLarge,
        subtitleTextStyle: text.bodyMedium!.copyWith(fontSize: 13, color: AppColors.onSurfaceVariant),
        minTileHeight: 56,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.onSurfaceVariant,
        labelStyle: text.labelLarge!.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: text.labelLarge!.copyWith(fontWeight: FontWeight.w500),
        dividerColor: AppColors.surfaceHighest,
        indicatorSize: TabBarIndicatorSize.label,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColors.primary, width: 3),
          borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
        ),
      ),
    );
  }

  static InputBorder _field(Color color, double width) => BoxInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        borderSide: BorderSide(color: color, width: width),
      );
}

/// Rounded box border that keeps the floating label *inside* the field
/// (label above the value, like the design) instead of notching the outline.
class BoxInputBorder extends OutlineInputBorder {
  const BoxInputBorder({super.borderSide, super.borderRadius});

  @override
  bool get isOutline => false;

  @override
  BoxInputBorder copyWith({BorderSide? borderSide, BorderRadius? borderRadius, double? gapPadding}) =>
      BoxInputBorder(borderSide: borderSide ?? this.borderSide, borderRadius: borderRadius ?? this.borderRadius);

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) => a is OutlineInputBorder
      ? BoxInputBorder(
          borderSide: BorderSide.lerp(a.borderSide, borderSide, t),
          borderRadius: BorderRadius.lerp(a.borderRadius, borderRadius, t)!,
        )
      : super.lerpFrom(a, t);

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) => b is OutlineInputBorder
      ? BoxInputBorder(
          borderSide: BorderSide.lerp(borderSide, b.borderSide, t),
          borderRadius: BorderRadius.lerp(borderRadius, b.borderRadius, t)!,
        )
      : super.lerpTo(b, t);

  @override
  void paint(Canvas canvas, Rect rect,
          {double? gapStart, double gapExtent = 0.0, double gapPercentage = 0.0, TextDirection? textDirection}) =>
      super.paint(canvas, rect, textDirection: textDirection);
}
