import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum BigButtonVariant { filled, nudge, tonal, outlined, text, danger }

/// The app's full-height pill buttons (56dp CTAs, 48dp secondary actions).
class BigButton extends StatelessWidget {
  const BigButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = BigButtonVariant.filled,
    this.height = 56,
    this.expand = true,
    this.loading = false,
    this.fontSize = 16,
    this.filledIcon = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final BigButtonVariant variant;
  final double height;
  final bool expand;
  final bool loading;
  final double fontSize;

  /// Material Symbols FILL axis for the icon.
  final bool filledIcon;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme.labelLarge!.copyWith(fontSize: fontSize);
    final (Color? bg, Color fg, BorderSide? side) = switch (variant) {
      BigButtonVariant.filled => (AppColors.primary, Colors.white, null),
      BigButtonVariant.nudge => (AppColors.tertiary, Colors.white, null),
      BigButtonVariant.tonal => (AppColors.secondaryContainer, AppColors.onSecondaryContainer, null),
      BigButtonVariant.outlined => (null, AppColors.primary, const BorderSide(color: AppColors.outline)),
      BigButtonVariant.text => (null, AppColors.primary, null),
      BigButtonVariant.danger => (null, AppColors.error, const BorderSide(color: AppColors.error)),
    };
    final disabled = onPressed == null && !loading;

    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(expand ? double.infinity : 64, height)),
      fixedSize: WidgetStatePropertyAll(Size.fromHeight(height)),
      padding: WidgetStatePropertyAll(EdgeInsets.fromLTRB(icon == null ? 24 : 20, 0, 24, 0)),
      textStyle: WidgetStatePropertyAll(text),
      shape: const WidgetStatePropertyAll(StadiumBorder()),
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: WidgetStateProperty.resolveWith((s) {
        if (disabled && bg != null) return AppColors.surfaceContainer;
        if (variant == BigButtonVariant.nudge && s.contains(WidgetState.pressed)) return AppColors.tertiaryPressed;
        return bg ?? Colors.transparent;
      }),
      foregroundColor: WidgetStatePropertyAll(disabled ? AppColors.onSurfaceVariant : fg),
      side: WidgetStatePropertyAll(
        disabled && bg != null ? const BorderSide(color: AppColors.surfaceHighest) : (side ?? BorderSide.none),
      ),
    );

    final child = loading
        ? SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: fg))
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: fontSize >= 16 ? 22 : 20, fill: filledIcon ? 1 : 0),
                const SizedBox(width: 8),
              ],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    Widget button = TextButton(onPressed: loading ? () {} : onPressed, style: style, child: child);

    // The nudge button floats slightly off the page, like the design.
    if (variant == BigButtonVariant.nudge && !disabled) {
      button = DecoratedBox(
        decoration: const ShapeDecoration(
          shape: StadiumBorder(),
          shadows: [
            BoxShadow(color: Color(0x40102A43), offset: Offset(0, 1), blurRadius: 2),
            BoxShadow(color: Color(0x405A4AE3), offset: Offset(0, 4), blurRadius: 12),
          ],
        ),
        child: button,
      );
    }
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
