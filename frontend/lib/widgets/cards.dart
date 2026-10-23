import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../models/issue.dart';
import '../models/property.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/format.dart';
import 'common.dart';
import 'issue_badges.dart';
import 'photos.dart';
import 'progress.dart';

/// Issue list card: thumbnail, title, location, status/priority, nudge pill,
/// and a footer with reporter, age and last nudge.
class IssueCard extends StatelessWidget {
  const IssueCard({super.key, required this.issue, this.onTap, this.reporterIsMe = false, this.location});

  final Issue issue;
  final VoidCallback? onTap;

  /// Student views say "You" instead of their own name.
  final bool reporterIsMe;

  /// Overrides "Room 2 · Parkview Student Residence".
  final String? location;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final footer = t.bodySmall!.copyWith(color: AppColors.onSurfaceVariant);
    final age = issue.isOpen || issue.resolvedAt == null ? Fmt.age(issue.createdAt) : 'Resolved ${Fmt.dayMonth(issue.resolvedAt!)}';
    return Semantics(
      button: onTap != null,
      label: '${issue.title}, ${issue.status.label}, ${issue.priority.label} priority'
          '${issue.nudgeCount > 0 ? ', ${Fmt.plural(issue.nudgeCount, 'nudge')}' : ''}',
      excludeSemantics: true,
      child: OutlinedCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox.square(
                  dimension: 56,
                  child: issue.photos.isNotEmpty
                      ? (issue.photos.first.bytes != null || issue.photos.first.url != null
                          ? IssuePhotoView(issue.photos.first, radius: AppRadius.medium)
                          : const StripedBox(
                              stripe: 6,
                              radius: AppRadius.medium,
                              child: Icon(Symbols.photo_camera_rounded, size: 20, color: AppColors.outline),
                            ))
                      : IconTile(Symbols.build_rounded, size: 56, foreground: AppColors.onSurfaceVariant, iconSize: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(issue.title, style: t.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        location ?? issue.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodyMedium!.copyWith(fontSize: 13, height: 18 / 13, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Students get a friendly "Reported → Seen → Fixing → Fixed" tracker; landlords get the work chips.
            if (reporterIsMe)
              IssueProgress(status: issue.status, landlordFirstName: issue.landlordName.split(' ').first, compact: true)
            else
              Row(
                children: [
                  StatusChip(issue.status),
                  const SizedBox(width: 8),
                  PriorityBadge(issue.priority),
                  const Spacer(),
                  NudgePill(issue.nudgeCount),
                ],
              ),
            const SizedBox(height: 12),
            const Divider(color: AppColors.surfaceContainer),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text('${reporterIsMe ? 'You' : issue.reporterName} · $age',
                      style: footer, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                if (issue.nudgeCount > 0 && issue.lastNudgedAt != null) ...[
                  const SizedBox(width: 8),
                  Text('Last nudged ${Fmt.ago(issue.lastNudgedAt!)}',
                      style: footer.copyWith(color: AppColors.nudgeText)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One bar per bed, filled or outlined - never colour alone.
class OccupancyBars extends StatelessWidget {
  const OccupancyBars({super.key, required this.occupied, required this.capacity});

  final int occupied;
  final int capacity;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < capacity; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Container(
              width: 18,
              height: 6,
              decoration: BoxDecoration(
                color: i < occupied ? AppColors.primary : null,
                borderRadius: BorderRadius.circular(3),
                border: i < occupied ? null : Border.all(color: AppColors.outline, width: 1.5),
              ),
            ),
          ],
        ],
      );
}

/// Room row on the property page (L6).
class RoomCard extends StatelessWidget {
  const RoomCard({super.key, required this.room, this.onTap, this.residentsLabel});

  final Room room;
  final VoidCallback? onTap;

  /// E.g. "Shared by 11 residents" for communal rooms.
  final String? residentsLabel;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final vacant = !room.isCommunal && room.occupied == 0;
    final names = room.students.map((s) => s.name).join(', ');
    final residents = residentsLabel ??
        (vacant
            ? 'Vacant — assign a student'
            : room.freeBeds > 0 && room.occupied > 0
                ? '$names · ${Fmt.plural(room.freeBeds, 'bed')} free'
                : names);
    return Semantics(
      button: onTap != null,
      child: OutlinedCard(
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          children: [
            Row(
              children: [
                IconTile(room.type.icon, size: 44, iconSize: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(room.name, style: t.titleMedium),
                      const SizedBox(height: 2),
                      Text(room.description,
                          style: t.bodyMedium!.copyWith(fontSize: 13, height: 18 / 13, color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ),
                if (room.isCommunal)
                  const SmallTag(
                    label: 'Communal',
                    icon: Symbols.groups_rounded,
                    background: AppColors.surfaceLow,
                    foreground: AppColors.onSurfaceVariant,
                    height: 28,
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text.rich(TextSpan(
                        style: t.bodyMedium,
                        children: [
                          TextSpan(text: '${room.occupied} / ${room.capacity ?? 0}', style: const TextStyle(fontWeight: FontWeight.w700)),
                          const TextSpan(text: ' occupied', style: TextStyle(color: AppColors.onSurfaceVariant)),
                        ],
                      )),
                      const SizedBox(height: 6),
                      OccupancyBars(occupied: room.occupied, capacity: room.capacity ?? 0),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(color: AppColors.surfaceContainer),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  room.isCommunal ? Symbols.groups_rounded : (vacant ? Symbols.person_add_rounded : Symbols.person_rounded),
                  size: 16,
                  color: AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(residents,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodyMedium!.copyWith(fontSize: 13, height: 18 / 13, color: AppColors.onSurfaceVariant)),
                ),
                if (room.openIssueCount > 0)
                  CountChip(icon: Symbols.build_rounded, label: Fmt.plural(room.openIssueCount, 'open issue'), height: 24),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
