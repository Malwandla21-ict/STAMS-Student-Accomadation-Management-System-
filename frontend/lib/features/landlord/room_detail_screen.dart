import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../data/api_client.dart';
import '../../models/property.dart';
import '../../models/user.dart';
import '../../providers/data.dart';
import '../../router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/format.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cards.dart';
import '../../widgets/common.dart';
import '../../widgets/issue_badges.dart';
import '../../widgets/list_states.dart';

/// L8 - who lives here, assign/remove students, issues in this room.
class RoomDetailScreen extends ConsumerWidget {
  const RoomDetailScreen({super.key, required this.roomId});

  final int roomId;

  Future<void> _remove(BuildContext context, WidgetRef ref, Room room, StudentSummary s) async {
    final ok = await confirm(
      context,
      title: 'Remove ${s.name.split(' ').first}?',
      message: '${s.name} will no longer be in ${room.name} and won’t be able to report issues until they’re assigned again.',
      action: 'Remove',
      destructive: true,
    );
    if (!ok) return;
    try {
      await ref.read(actionsProvider).removeStudent(room.id, s.id);
      if (context.mounted) showMessage(context, '${s.name} removed from ${room.name}');
    } on ApiException catch (e) {
      if (context.mounted) showMessage(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(roomProvider(roomId));
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        actions: [
          if (value.hasValue)
            IconButton(
              tooltip: 'Edit room',
              icon: const Icon(Symbols.edit_rounded),
              onPressed: () => context.push(Routes.editRoom(roomId)),
            ),
        ],
      ),
      body: AsyncBody(
        value: value,
        onRetry: () => ref.invalidate(roomProvider(roomId)),
        errorTitle: 'Couldn’t load this room',
        data: (room) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            Row(children: [
              IconTile(room.type.icon, size: 56, radius: AppRadius.large, background: AppColors.primary, foreground: Colors.white, iconSize: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(room.name, style: t.headlineSmall),
                  const SizedBox(height: 2),
                  Text('${room.description} · ${room.propertyName}', style: t.bodyMedium!.copyWith(color: AppColors.onSurfaceVariant)),
                ]),
              ),
            ]),
            const SizedBox(height: 20),
            if (room.isCommunal)
              InfoNote(
                'Communal — nobody is assigned here. Every student at ${room.propertyName} can report issues in this room.',
                icon: Symbols.groups_rounded,
              )
            else
              _StudentsCard(room: room, onRemove: (s) => _remove(context, ref, room, s)),
            const SizedBox(height: 20),
            _RoomIssues(roomId: room.id),
          ],
        ),
      ),
    );
  }
}

class _StudentsCard extends StatelessWidget {
  const _StudentsCard({required this.room, required this.onRemove});

  final Room room;
  final ValueChanged<StudentSummary> onRemove;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return OutlinedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(child: Text('Students', style: t.titleMedium)),
            Text.rich(TextSpan(style: t.bodyMedium, children: [
              TextSpan(text: '${room.occupied} / ${room.capacity ?? 0}', style: const TextStyle(fontWeight: FontWeight.w700)),
              const TextSpan(text: ' occupied'),
            ])),
            const SizedBox(width: 8),
            OccupancyBars(occupied: room.occupied, capacity: room.capacity ?? 0),
          ]),
          const SizedBox(height: 6),
          if (room.students.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text('Nobody lives here yet.', style: t.bodyMedium!.copyWith(color: AppColors.onSurfaceVariant)),
            ),
          for (final (i, s) in room.students.indexed)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(children: [
                InitialsAvatar(
                  s.initials,
                  background: i.isEven ? AppColors.primaryContainer : AppColors.secondaryContainer,
                  foreground: i.isEven ? AppColors.onPrimaryContainer : AppColors.onSecondaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    Text(s.email,
                        overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
                  ]),
                ),
                Transform.translate(
                  offset: const Offset(12, 0),
                  child: IconButton(
                    tooltip: 'Remove ${s.name}',
                    icon: const Icon(Symbols.person_remove_rounded, size: 22, color: AppColors.onSurfaceVariant),
                    onPressed: () => onRemove(s),
                  ),
                ),
              ]),
            ),
          const SizedBox(height: 14),
          BigButton(
            label: 'Assign student',
            icon: Symbols.person_add_rounded,
            variant: BigButtonVariant.tonal,
            height: 48,
            fontSize: 14,
            onPressed: room.isFull ? null : () => context.push(Routes.assignStudent(room.id)),
          ),
          if (room.isFull) ...[
            const SizedBox(height: 6),
            const Text(
              'Room is at capacity. Remove a student or raise capacity.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoomIssues extends ConsumerWidget {
  const _RoomIssues({required this.roomId});

  final int roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issues = ref.watch(roomIssuesProvider(roomId)).value;
    if (issues == null) return const SizedBox.shrink();
    final open = issues.where((i) => i.isOpen).toList();
    final resolved = issues.length - open.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Issues in this room',
          size: 16,
          trailing: Text('${open.length} open · $resolved resolved', style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
        ),
        const SizedBox(height: 12),
        if (open.isEmpty)
          Text('Nothing open here.', style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: AppColors.onSurfaceVariant)),
        for (final issue in open) ...[
          IssueCard(
            issue: issue,
            location: 'Reported ${Fmt.age(issue.createdAt).toLowerCase()}',
            onTap: () => context.push(Routes.landlordIssue(issue.id)),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
