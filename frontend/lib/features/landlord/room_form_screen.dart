import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../data/api_client.dart';
import '../../models/enums.dart';
import '../../models/property.dart';
import '../../providers/data.dart';
import '../../router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/buttons.dart';
import '../../widgets/common.dart';
import '../../widgets/issue_badges.dart';
import '../../widgets/list_states.dart';
import '../auth/auth_widgets.dart';

/// L9 - add a room to a property ([propertyId]) or edit one ([roomId]).
class RoomFormScreen extends ConsumerWidget {
  const RoomFormScreen({super.key, this.propertyId, this.roomId}) : assert(propertyId != null || roomId != null);

  final int? propertyId;
  final int? roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (roomId != null) {
      final room = ref.watch(roomProvider(roomId!));
      if (room.hasValue) {
        final r = room.requireValue;
        return _RoomForm(propertyId: r.propertyId, propertyName: r.propertyName, existing: r);
      }
      return _Loading(value: room, onRetry: () => ref.invalidate(roomProvider(roomId!)));
    }
    final property = ref.watch(propertyProvider(propertyId!));
    if (property.hasValue) return _RoomForm(propertyId: propertyId!, propertyName: property.requireValue.name);
    return _Loading(value: property, onRetry: () => ref.invalidate(propertyProvider(propertyId!)));
  }
}

class _Loading extends StatelessWidget {
  const _Loading({required this.value, required this.onRetry});

  final AsyncValue<Object> value;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(leading: const CloseButton()),
        body: AsyncBody(value: value, onRetry: onRetry, data: (_) => const SizedBox.shrink()),
      );
}

class _RoomForm extends ConsumerStatefulWidget {
  const _RoomForm({required this.propertyId, required this.propertyName, this.existing});

  final int propertyId;
  final String propertyName;
  final Room? existing;

  @override
  ConsumerState<_RoomForm> createState() => _RoomFormState();
}

class _RoomFormState extends ConsumerState<_RoomForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name);
  late RoomType _type = widget.existing?.type ?? RoomType.bedroom;
  late OccupancyMode _mode = widget.existing?.occupancyMode ?? OccupancyMode.single;
  late int _capacity = (widget.existing?.capacity ?? 2).clamp(2, 20);
  bool _saving = false;
  bool _deleting = false;
  String? _error;

  bool get _editing => widget.existing != null;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _pickType(RoomType type) => setState(() {
        _type = type;
        // Kitchens, bathrooms and lounges are almost always shared by the whole house.
        if (type != RoomType.bedroom) _mode = OccupancyMode.communal;
        if (type == RoomType.bedroom && _mode == OccupancyMode.communal) _mode = OccupancyMode.single;
      });

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final saved = await ref.read(actionsProvider).saveRoom(
            propertyId: widget.propertyId,
            roomId: widget.existing?.id,
            input: RoomInput(name: _name.text.trim(), type: _type, occupancyMode: _mode, capacity: _capacity),
          );
      if (!mounted) return;
      context.pop();
      showMessage(context, _editing ? 'Room saved' : '${saved.name} added');
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.fieldErrors.values.firstOrNull ?? e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final room = widget.existing!;
    final ok = await confirm(
      context,
      title: 'Delete ${room.name}?',
      message: 'This room will be removed from ${widget.propertyName}. This can’t be undone.',
      action: 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _deleting = true);
    try {
      await ref.read(actionsProvider).deleteRoom(room.id);
      if (mounted) {
        context.go(Routes.property(widget.propertyId));
        showMessage(context, '${room.name} deleted');
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    Widget label(String text) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(text, style: t.titleSmall));

    return Scaffold(
      appBar: AppBar(
        leading: const CloseButton(),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_editing ? 'Edit room' : 'Add room', style: t.titleLarge!.copyWith(fontSize: 20)),
          Text(widget.propertyName, style: t.bodySmall!.copyWith(color: AppColors.onSurfaceVariant)),
        ]),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(minimumSize: const Size(0, 40), padding: const EdgeInsets.symmetric(horizontal: 20)),
              child: _saving
                  ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save'),
            ),
          ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            TextFormField(
              controller: _name,
              autofocus: !_editing,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 60,
              decoration: const InputDecoration(labelText: 'Room number or name', counterText: ''),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Name the room, e.g. “Room 7” or “Kitchen”' : null,
            ),
            const SizedBox(height: 22),
            label('Type'),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 169 / 56,
              children: [for (final type in RoomType.values) _TypeTile(type: type, selected: _type == type, onTap: () => _pickType(type))],
            ),
            const SizedBox(height: 22),
            label('Occupancy'),
            SegmentedButton<OccupancyMode>(
              segments: [for (final m in OccupancyMode.values) ButtonSegment(value: m, label: Text(m.label))],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),
            const SizedBox(height: 22),
            if (_mode == OccupancyMode.shared)
              OutlinedCard(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                child: Row(children: [
                  const Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Capacity', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      SizedBox(height: 2),
                      Text('Beds in this room', style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
                    ]),
                  ),
                  IconButton.outlined(
                    tooltip: 'Fewer beds',
                    onPressed: _capacity > 2 ? () => setState(() => _capacity--) : null,
                    icon: const Icon(Symbols.remove_rounded),
                  ),
                  SizedBox(
                    width: 44,
                    child: Text('$_capacity',
                        textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
                  ),
                  IconButton.filled(
                    tooltip: 'More beds',
                    onPressed: _capacity < 20 ? () => setState(() => _capacity++) : null,
                    icon: const Icon(Symbols.add_rounded),
                  ),
                ]),
              )
            else if (_mode == OccupancyMode.single)
              const InfoNote('Single rooms have one bed.', icon: Symbols.bed_rounded, background: null),
            const SizedBox(height: 16),
            Text(
              'Communal rooms (kitchens, bathrooms, lounges) have no capacity — every student in the property can report issues there.',
              style: t.bodyMedium!.copyWith(fontSize: 13, height: 18 / 13, color: AppColors.onSurfaceVariant),
            ),
            if (_error != null) ...[const SizedBox(height: 16), FormErrorBanner(_error!)],
            if (_editing) ...[
              const SizedBox(height: 40),
              BigButton(
                label: 'Delete room',
                icon: Symbols.delete_rounded,
                variant: BigButtonVariant.danger,
                height: 48,
                fontSize: 14,
                loading: _deleting,
                onPressed: _delete,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({required this.type, required this.selected, required this.onTap});

  final RoomType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        selected: selected,
        inMutuallyExclusiveGroup: true,
        child: Material(
          color: selected ? AppColors.primaryContainer : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
            side: BorderSide(color: selected ? AppColors.primary : AppColors.outlineVariant, width: selected ? 2 : 1),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(children: [
                Icon(type.icon, size: 22, color: selected ? AppColors.onPrimaryContainer : AppColors.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(type.label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        color: selected ? AppColors.onPrimaryContainer : AppColors.onSurface,
                      )),
                ),
                if (selected) const Icon(Symbols.check_rounded, size: 20, color: AppColors.onPrimaryContainer),
              ]),
            ),
          ),
        ),
      );
}
