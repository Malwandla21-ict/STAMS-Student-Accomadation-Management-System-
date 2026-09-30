import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../data/api_client.dart';
import '../../models/property.dart';
import '../../providers/data.dart';
import '../../router.dart';
import '../../utils/format.dart';
import '../../widgets/buttons.dart';
import '../../widgets/common.dart';
import '../../widgets/list_states.dart';
import '../auth/auth_widgets.dart';

/// L7 - add or edit a property.
class PropertyFormScreen extends ConsumerWidget {
  const PropertyFormScreen({super.key, this.propertyId});

  /// Null when adding.
  final int? propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (propertyId == null) return const _PropertyForm();
    final value = ref.watch(propertyProvider(propertyId!));
    return value.hasValue
        ? _PropertyForm(existing: value.requireValue)
        : Scaffold(
            appBar: AppBar(leading: const CloseButton(), title: const Text('Edit property')),
            body: AsyncBody(
              value: value,
              onRetry: () => ref.invalidate(propertyProvider(propertyId!)),
              data: (_) => const SizedBox.shrink(),
            ),
          );
  }
}

class _PropertyForm extends ConsumerStatefulWidget {
  const _PropertyForm({this.existing});

  final Property? existing;

  @override
  ConsumerState<_PropertyForm> createState() => _PropertyFormState();
}

class _PropertyFormState extends ConsumerState<_PropertyForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _line1 = TextEditingController(text: widget.existing?.addressLine1);
  late final _line2 = TextEditingController(text: widget.existing?.addressLine2);
  late final _city = TextEditingController(text: widget.existing?.city);
  late final _postcode = TextEditingController(text: widget.existing?.postalCode);
  bool _saving = false;
  bool _deleting = false;
  String? _error;
  Map<String, String> _fieldErrors = const {};

  bool get _editing => widget.existing != null;

  @override
  void dispose() {
    for (final c in [_name, _line1, _line2, _city, _postcode]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v, String field, String message) =>
      (v ?? '').trim().isEmpty ? message : _fieldErrors[field];

  /// UK-style postcodes must be complete ("LS6 2QT"); other formats just need 3+ characters.
  String? _validatePostcode(String? v) {
    final value = (v ?? '').trim().toUpperCase();
    if (value.isEmpty) return 'Enter a postcode';
    final ukLike = RegExp(r'^[A-Z]').hasMatch(value);
    if (ukLike && !RegExp(r'^[A-Z]{1,2}\d[A-Z\d]? ?\d[A-Z]{2}$').hasMatch(value)) return 'Enter a full postcode';
    if (!ukLike && value.length < 3) return 'Enter a full postcode';
    return _fieldErrors['postalCode'];
  }

  Future<void> _save() async {
    setState(() {
      _error = null;
      _fieldErrors = const {};
    });
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final saved = await ref.read(actionsProvider).saveProperty(
            widget.existing?.id,
            PropertyInput(
              name: _name.text.trim(),
              addressLine1: _line1.text.trim(),
              addressLine2: _line2.text.trim(),
              city: _city.text.trim(),
              postalCode: _postcode.text.trim().toUpperCase(),
            ),
          );
      if (!mounted) return;
      if (_editing) {
        context.pop();
        showMessage(context, 'Property saved');
      } else {
        context.pushReplacement(Routes.property(saved.id));
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _fieldErrors = e.fieldErrors;
          _error = e.fieldErrors.isEmpty ? e.message : null;
        });
        _form.currentState!.validate();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await confirm(
      context,
      title: 'Delete property?',
      message: '${widget.existing!.name} and its rooms will be removed. This can’t be undone.',
      action: 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _deleting = true);
    try {
      await ref.read(actionsProvider).deleteProperty(widget.existing!.id);
      if (mounted) {
        context.go(Routes.landlordProperties);
        showMessage(context, 'Property deleted');
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration field(String label) => InputDecoration(labelText: label);
    return Scaffold(
      appBar: AppBar(
        leading: const CloseButton(),
        title: Text(_editing ? 'Edit property' : 'Add property'),
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
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: field('Property name'),
              validator: (v) => _required(v, 'name', 'Give the property a name'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _line1,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: field('Address line 1'),
              validator: (v) => _required(v, 'addressLine1', 'Enter the street address'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _line2,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: field('Address line 2 (optional)'),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 14,
                  child: TextFormField(
                    controller: _city,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: field('City'),
                    validator: (v) => _required(v, 'city', 'Enter a city'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 10,
                  child: TextFormField(
                    controller: _postcode,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _save(),
                    decoration: field('Postcode'),
                    validator: _validatePostcode,
                  ),
                ),
              ],
            ),
            if (_error != null) ...[const SizedBox(height: 16), FormErrorBanner(_error!)],
            if (_editing) ...[
              const SizedBox(height: 24),
              InfoNote(
                '${Fmt.plural(widget.existing!.roomCount, 'room')} — add or edit rooms from the property page.',
                icon: Symbols.meeting_room_rounded,
              ),
              const SizedBox(height: 40),
              BigButton(
                label: 'Delete property',
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
