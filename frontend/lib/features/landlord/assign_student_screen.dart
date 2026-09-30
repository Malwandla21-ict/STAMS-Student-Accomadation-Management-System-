import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/api_client.dart';
import '../../models/property.dart';
import '../../models/user.dart';
import '../../providers/data.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/list_states.dart';
import 'issues_screen.dart' show SearchField;

/// L10 - find a registered student by email and put them in this room.
class AssignStudentScreen extends ConsumerStatefulWidget {
  const AssignStudentScreen({super.key, required this.roomId});

  final int roomId;

  @override
  ConsumerState<AssignStudentScreen> createState() => _AssignStudentScreenState();
}

class _AssignStudentScreenState extends ConsumerState<AssignStudentScreen> {
  final _search = TextEditingController();
  String _query = '';
  int? _busyId;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _assign(Room room, StudentSearchResult s) async {
    setState(() => _busyId = s.id);
    try {
      await ref.read(actionsProvider).assignStudent(room.id, s.id);
      if (!mounted) return;
      context.pop();
      showMessage(context, '${s.name} added to ${room.name}');
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final room = ref.watch(roomProvider(widget.roomId));
    final t = Theme.of(context).textTheme;
    final r = room.value;

    return Scaffold(
      appBar: AppBar(
        leading: const CloseButton(),
        title: r == null
            ? null
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Assign to ${r.name}', style: t.titleLarge!.copyWith(fontSize: 20)),
                Text(
                  '${r.propertyName.split(' ').first} · ${r.freeBeds} of ${Fmt.plural(r.capacity ?? 0, 'bed')} free',
                  style: t.bodySmall!.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ]),
      ),
      body: AsyncBody(
        value: room,
        onRetry: () => ref.invalidate(roomProvider(widget.roomId)),
        data: (room) {
          final results = ref.watch(studentSearchProvider(_query));
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              SearchField(
                controller: _search,
                hint: 'Search by email',
                onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              ),
              const SizedBox(height: 16),
              if (_query.length < 2)
                const SizedBox.shrink()
              else if (results.isLoading && !results.hasValue)
                const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
              else if (results.hasError)
                Text(ApiException.from(results.error!).message, style: const TextStyle(color: AppColors.error))
              else ...[
                Text(
                  results.requireValue.isEmpty ? 'No students found for “$_query”' : Fmt.plural(results.requireValue.length, 'registered student'),
                  style: t.labelLarge!.copyWith(fontSize: 13, color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                for (final s in results.requireValue) ...[
                  _ResultCard(
                    student: s,
                    query: _query,
                    roomId: room.id,
                    roomFull: room.isFull,
                    busy: _busyId == s.id,
                    onAssign: () => _assign(room, s),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
              const SizedBox(height: 4),
              const InfoNote('Only students with a STAMS account appear. Ask them to sign up with their university email.'),
            ],
          );
        },
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.student,
    required this.query,
    required this.roomId,
    required this.roomFull,
    required this.busy,
    required this.onAssign,
  });

  final StudentSearchResult student;
  final String query;
  final int roomId;
  final bool roomFull;
  final bool busy;
  final VoidCallback onAssign;

  @override
  Widget build(BuildContext context) {
    final s = student;
    final free = s.placement == Placement.notInARoom;
    final alreadyHere = s.currentRoomId == roomId;
    final (String where, Color whereColor) = switch (s.placement) {
      Placement.notInARoom => ('Not in a room', const Color(0xFF0E5C35)),
      Placement.inYourProperty => (alreadyHere ? 'Already in this room' : 'In ${s.currentRoomName} · ${s.currentPropertyName}', AppColors.onSurfaceVariant),
      Placement.withAnotherLandlord => ('Lives with another landlord', AppColors.onSurfaceVariant),
    };

    // Bold the part of the email that matched.
    final at = s.email.indexOf(query);
    final emailStyle = const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant);
    final email = at < 0
        ? TextSpan(text: s.email, style: emailStyle)
        : TextSpan(style: emailStyle, children: [
            TextSpan(text: s.email.substring(0, at)),
            TextSpan(text: query, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.onSurface)),
            TextSpan(text: s.email.substring(at + query.length)),
          ]);

    final canAct = !roomFull && !alreadyHere && s.placement != Placement.withAnotherLandlord;
    final action = busy
        ? const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2.5))
        : s.placement == Placement.withAnotherLandlord || alreadyHere
            ? null
            : free
                ? FilledButton(
                    onPressed: canAct ? onAssign : null,
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 40), padding: const EdgeInsets.symmetric(horizontal: 16)),
                    child: const Text('Assign'),
                  )
                : OutlinedButton(
                    onPressed: canAct ? onAssign : null,
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40), padding: const EdgeInsets.symmetric(horizontal: 14)),
                    child: const Text('Move'),
                  );

    return OutlinedCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(children: [
        InitialsAvatar(
          s.initials,
          background: free ? AppColors.primaryContainer : AppColors.surfaceContainer,
          foreground: free ? AppColors.onPrimaryContainer : AppColors.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 2),
            Text.rich(email, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(where, style: TextStyle(fontSize: 12, fontWeight: free ? FontWeight.w600 : FontWeight.w400, color: whereColor)),
          ]),
        ),
        if (action != null) ...[const SizedBox(width: 8), action],
      ]),
    );
  }
}
