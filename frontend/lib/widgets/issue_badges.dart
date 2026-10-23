import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../models/enums.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/semantic_colors.dart';
import '../utils/format.dart';

/// Filled status pill - icon + label, always.
class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});

  final IssueStatus status;

  @override
  Widget build(BuildContext context) {
    final s = context.statusColors.of(status);
    return Container(
      height: 28,
      padding: const EdgeInsets.fromLTRB(8, 0, 12, 0),
      decoration: BoxDecoration(color: s.container, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(s.icon, size: 16, color: s.onContainer, fill: 1),
          const SizedBox(width: 6),
          Text(status.label, style: TextStyle(fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w600, color: s.onContainer)),
        ],
      ),
    );
  }
}

/// Square priority badge with signal bars.
class PriorityBadge extends StatelessWidget {
  const PriorityBadge(this.priority, {super.key});

  final IssuePriority priority;

  @override
  Widget build(BuildContext context) {
    final s = context.priorityColors.of(priority);
    return Container(
      height: 24,
      padding: const EdgeInsets.fromLTRB(5, 0, 8, 0),
      decoration: BoxDecoration(
        color: s.container,
        borderRadius: BorderRadius.circular(AppRadius.extraSmall),
        border: s.border == null ? null : Border.all(color: s.border!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(s.icon, size: 16, color: s.onContainer),
          const SizedBox(width: 4),
          Text(priority.label, style: TextStyle(fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w600, color: s.onContainer)),
        ],
      ),
    );
  }
}

/// Nudge count pill. Always tonal so lists stay calm; 3+ nudges get a thin iris
/// outline so repeat reminders still stand out. Renders nothing for 0.
class NudgePill extends StatelessWidget {
  const NudgePill(this.count, {super.key, this.label});

  final int count;

  /// Overrides "4 nudges".
  final String? label;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final hot = count >= 3;
    const fg = AppColors.onTertiaryContainer;
    return Container(
      height: 28,
      padding: const EdgeInsets.fromLTRB(8, 0, 10, 0),
      decoration: BoxDecoration(
        color: AppColors.tertiaryContainer,
        borderRadius: BorderRadius.circular(999),
        border: hot ? Border.all(color: AppColors.tertiary.withValues(alpha: .45)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Symbols.notifications_active_rounded, size: 16, color: fg, fill: 1),
          const SizedBox(width: 4),
          Text(label ?? Fmt.plural(count, 'nudge'),
              style: TextStyle(fontSize: 12, height: 16 / 12, fontWeight: hot ? FontWeight.w700 : FontWeight.w600, color: fg)),
        ],
      ),
    );
  }
}

extension RoomTypeIcon on RoomType {
  IconData get icon => switch (this) {
        RoomType.bedroom => Symbols.bed_rounded,
        RoomType.kitchen => Symbols.countertops_rounded,
        RoomType.bathroom => Symbols.shower_rounded,
        RoomType.commonArea => Symbols.weekend_rounded,
      };
}
