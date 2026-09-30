import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Large page title (28/36) used by tab roots, with an optional trailing action.
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.subtitle, this.trailing, this.padding});

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: padding ?? EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs, trailing == null ? AppSpacing.lg : AppSpacing.xs, AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: t.headlineMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: t.bodyMedium!.copyWith(color: AppColors.onSurfaceVariant)),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Section title + optional trailing text/button ("Most nudged ... See all").
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.count, this.icon, this.trailing, this.size = 20});

  final String title;
  final int? count;
  final IconData? icon;
  final Widget? trailing;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 22, color: AppColors.tertiary, fill: 1),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text.rich(
            TextSpan(
              text: title,
              style: t.titleMedium!.copyWith(fontSize: size, fontWeight: size > 16 ? FontWeight.w700 : FontWeight.w600),
              children: [
                if (count != null)
                  TextSpan(
                    text: ' · $count',
                    style: TextStyle(color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// "See all", "Mark all read" - a compact text button that aligns with the gutter.
class InlineAction extends StatelessWidget {
  const InlineAction(this.label, {super.key, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Transform.translate(
        offset: const Offset(12, 0),
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(minimumSize: const Size(48, 48), padding: const EdgeInsets.symmetric(horizontal: 12)),
          child: Text(label),
        ),
      );
}

/// Circle with initials ("AB").
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar(this.initials, {super.key, this.size = 40, this.background = AppColors.primaryContainer, this.foreground = AppColors.onPrimaryContainer});

  final String initials;
  final double size;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Text(
          initials,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: size * 0.35, color: foreground, height: 1),
        ),
      );
}

/// Rounded square holding an icon (room type, property).
class IconTile extends StatelessWidget {
  const IconTile(this.icon, {super.key, this.size = 44, this.radius = AppRadius.medium, this.background = AppColors.surfaceContainer, this.foreground = AppColors.primary, this.iconSize});

  final IconData icon;
  final double size;
  final double radius;
  final Color background;
  final Color foreground;
  final double? iconSize;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(radius)),
        child: Icon(icon, size: iconSize ?? size / 2, color: foreground),
      );
}

/// Round icon badge used in alerts, timelines and stat tiles.
class IconCircle extends StatelessWidget {
  const IconCircle(this.icon, {super.key, required this.background, required this.foreground, this.size = 40, this.filled = true});

  final IconData icon;
  final Color background;
  final Color foreground;
  final double size;
  final bool filled;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Icon(icon, size: size / 2, color: foreground, fill: filled ? 1 : 0),
      );
}

/// Grey "info" note on chalk, used for helper copy (S3, L7, L10).
class InfoNote extends StatelessWidget {
  const InfoNote(this.text, {super.key, this.icon = Symbols.info_rounded, this.background = AppColors.surfaceLow});

  final String text;
  final IconData icon;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 13, height: 18 / 13, color: AppColors.onSurfaceVariant);
    return Container(
      padding: background == null ? const EdgeInsets.symmetric(horizontal: 4) : const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: background == null ? null : BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadius.large)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: style)),
        ],
      ),
    );
  }
}

/// White card with the standard 1dp border and 16dp corners.
class OutlinedCard extends StatelessWidget {
  const OutlinedCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap, this.color = Colors.white, this.radius = AppRadius.large});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: const BorderSide(color: AppColors.surfaceHighest),
    );
    return Material(
      color: color,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
    );
  }
}

/// Small rounded count chip ("5 open", "1 open issue").
class CountChip extends StatelessWidget {
  const CountChip({super.key, required this.icon, required this.label, this.background = AppColors.surfaceContainer, this.foreground = AppColors.onSurface, this.height = 28, this.bold = false, this.filledIcon = false});

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final double height;
  final bool bold;
  final bool filledIcon;

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        padding: const EdgeInsets.fromLTRB(8, 0, 10, 0),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: height > 24 ? 16 : 14, color: foreground, fill: filledIcon ? 1 : 0),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, height: 16 / 12, fontWeight: bold ? FontWeight.w700 : FontWeight.w600, color: foreground),
            ),
          ],
        ),
      );
}

/// Tag with 8dp corners (room chip on S3, role badge on A6, "Communal").
class SmallTag extends StatelessWidget {
  const SmallTag({super.key, required this.label, this.icon, this.background = AppColors.primaryContainer, this.foreground = AppColors.onPrimaryContainer, this.height = 24});

  final String label;
  final IconData? icon;
  final Color background;
  final Color foreground;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        padding: EdgeInsets.fromLTRB(icon == null ? 8 : 6, 0, 8, 0),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadius.small)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: height > 28 ? 16 : 14, color: foreground), const SizedBox(width: 4)],
            Text(label, style: TextStyle(fontSize: height > 28 ? 13 : 12, fontWeight: FontWeight.w600, color: foreground)),
          ],
        ),
      );
}

void showMessage(BuildContext context, String message, {IconData? icon}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(children: [
        if (icon != null) ...[Icon(icon, size: 20, color: AppColors.inversePrimary, fill: 1), const SizedBox(width: 12)],
        Expanded(child: Text(message)),
      ]),
    ));
}

Future<bool> confirm(BuildContext context, {required String title, required String message, required String action, bool destructive = false}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: destructive ? TextButton.styleFrom(foregroundColor: AppColors.error) : null,
          child: Text(action),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Filled/outlined radio dot matching the design (20dp).
class RadioDot extends StatelessWidget {
  const RadioDot({super.key, required this.selected, this.color = AppColors.primary});

  final bool selected;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? color : null,
          border: selected ? null : Border.all(color: AppColors.onSurfaceVariant, width: 2),
        ),
        alignment: Alignment.center,
        child: selected
            ? Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))
            : null,
      );
}
