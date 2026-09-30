import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../models/enums.dart';
import '../../models/property.dart';
import '../../providers/data.dart';
import '../../router.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../widgets/cards.dart';
import '../../widgets/common.dart';
import '../../widgets/list_states.dart';
import 'properties_screen.dart';

/// L6 - property summary and its rooms grouped by type.
class PropertyDetailScreen extends ConsumerWidget {
  const PropertyDetailScreen({super.key, required this.propertyId});

  final int propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(propertyProvider(propertyId));
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        actions: [
          if (value.hasValue)
            IconButton(
              tooltip: 'Edit property',
              icon: const Icon(Symbols.edit_rounded),
              onPressed: () => context.push(Routes.editProperty(propertyId)),
            ),
        ],
      ),
      floatingActionButton: value.hasValue
          ? FloatingActionButton.extended(
              onPressed: () => context.push(Routes.newRoom(propertyId)),
              icon: const Icon(Symbols.add_rounded),
              label: const Text('Add room'),
            )
          : null,
      body: AsyncBody(
        value: value,
        onRetry: () => ref.invalidate(propertyProvider(propertyId)),
        errorTitle: 'Couldn’t load this property',
        data: (p) {
          final rooms = p.rooms ?? const <Room>[];
          final freeBeds = rooms.fold<int>(0, (n, r) => n + r.freeBeds);
          return RefreshIndicator(
            onRefresh: () => ref.refresh(propertyProvider(propertyId).future),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
              children: [
                Text(p.name, style: t.headlineSmall),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Symbols.location_on_rounded, size: 18, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(child: Text(p.shortAddress, style: t.bodyMedium!.copyWith(color: AppColors.onSurfaceVariant))),
                ]),
                const SizedBox(height: 18),
                Row(children: [
                  Expanded(child: StatTile(value: '${p.bedsFilled}/${p.bedsTotal}', label: 'Beds filled')),
                  const SizedBox(width: 8),
                  Expanded(child: StatTile(value: '${p.openIssueCount}', label: 'Open issues')),
                  const SizedBox(width: 8),
                  Expanded(child: StatTile(value: '${p.openIssueNudges}', label: 'Nudges', highlight: true)),
                ]),
                if (rooms.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 32),
                    child: InfoNote('No rooms yet. Add bedrooms, then shared spaces like kitchens and bathrooms.', icon: Symbols.meeting_room_rounded),
                  ),
                for (final type in RoomType.values)
                  if (rooms.any((r) => r.type == type)) ...[
                    const SizedBox(height: 20),
                    SectionHeader(
                      title: rooms.where((r) => r.type == type).length == 1 ? type.label : type.pluralLabel,
                      count: rooms.where((r) => r.type == type).length,
                      size: 16,
                      trailing: type == RoomType.bedroom && freeBeds > 0
                          ? Text('${Fmt.plural(freeBeds, 'bed')} free',
                              style: t.bodySmall!.copyWith(fontSize: 13, color: AppColors.onSurfaceVariant))
                          : null,
                    ),
                    const SizedBox(height: 12),
                    for (final r in rooms.where((r) => r.type == type)) ...[
                      RoomCard(
                        room: r,
                        residentsLabel: r.isCommunal ? 'Shared by ${Fmt.plural(p.bedsFilled, 'resident')}' : null,
                        onTap: () => context.push(Routes.room(r.id)),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
              ],
            ),
          );
        },
      ),
    );
  }
}
