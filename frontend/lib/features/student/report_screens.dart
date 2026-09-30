import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../data/api_client.dart';
import '../../models/enums.dart';
import '../../models/issue.dart';
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

/// Header shared by both report steps: title, "Step n of 2", progress bars.
PreferredSizeWidget _reportAppBar(BuildContext context, {required int step, required Widget leading}) => AppBar(
      leading: leading,
      title: const Text('Report an issue'),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(child: Text('Step $step of 2', style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant))),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            for (var i = 1; i <= 2; i++) ...[
              if (i > 1) const SizedBox(width: 6),
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= step ? AppColors.tertiary : AppColors.surfaceHighest,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ]),
        ),
      ),
    );

Widget _bottomBar(Widget child) => SafeArea(
      child: Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 12), child: child),
    );

/// S2 - my room or one of the property's shared spaces.
class ReportWhereScreen extends ConsumerWidget {
  const ReportWhereScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(studentHomeProvider);
    final draft = ref.watch(reportDraftProvider);
    final selected = draft.roomId ?? home.value?.room.id;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: _reportAppBar(context, step: 1, leading: const CloseButton()),
      body: AsyncBody(
        value: home,
        onRetry: () => ref.invalidate(studentHomeProvider),
        data: (home) {
          if (home == null) {
            return const StateMessage(
              icon: Symbols.hourglass_top_rounded,
              title: 'You’re not in a room yet',
              message: 'You can report issues once your landlord adds you to a room.',
            );
          }
          void pick(Room r) => ref.read(reportDraftProvider.notifier).selectRoom(r.id);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              Text('Where’s the problem?', style: t.headlineSmall),
              const SizedBox(height: 16),
              Text('My room', style: t.labelLarge!.copyWith(fontSize: 13, color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 12),
              _RoomOption(room: home.room, subtitle: home.room.description, selected: selected == home.room.id, onTap: () => pick(home.room)),
              if (home.sharedSpaces.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('Shared spaces at ${home.propertyName.split(' ').first}',
                    style: t.labelLarge!.copyWith(fontSize: 13, color: AppColors.onSurfaceVariant)),
                for (final r in home.sharedSpaces) ...[
                  const SizedBox(height: 12),
                  _RoomOption(
                    room: r,
                    subtitle: r.type == RoomType.commonArea ? 'Common area' : 'Communal',
                    selected: selected == r.id,
                    onTap: () => pick(r),
                  ),
                ],
              ],
            ],
          );
        },
      ),
      bottomNavigationBar: _bottomBar(BigButton(
        label: 'Continue',
        onPressed: selected == null
            ? null
            : () {
                ref.read(reportDraftProvider.notifier).selectRoom(selected);
                context.push(Routes.reportDetails);
              },
      )),
    );
  }
}

class _RoomOption extends StatelessWidget {
  const _RoomOption({required this.room, required this.subtitle, required this.selected, required this.onTap});

  final Room room;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.onTertiaryContainer : AppColors.onSurface;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: selected ? AppColors.tertiaryContainer : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
          side: BorderSide(color: selected ? AppColors.tertiary : AppColors.outlineVariant, width: selected ? 2 : 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.large),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                IconTile(
                  room.type.icon,
                  size: 40,
                  iconSize: 22,
                  background: selected ? AppColors.tertiary : AppColors.surfaceContainer,
                  foreground: selected ? Colors.white : AppColors.primary,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(room.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: fg)),
                    Text(subtitle, style: TextStyle(fontSize: 13, color: selected ? fg : AppColors.onSurfaceVariant)),
                  ]),
                ),
                RadioDot(selected: selected, color: AppColors.tertiary),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// S3 - what's wrong, plus up to three photos.
class ReportDetailsScreen extends ConsumerStatefulWidget {
  const ReportDetailsScreen({super.key});

  @override
  ConsumerState<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends ConsumerState<ReportDetailsScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _addPhoto(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(source: source, maxWidth: 1600, imageQuality: 80);
      if (file == null) return;
      ref.read(reportDraftProvider.notifier).addPhoto(await file.readAsBytes());
    } catch (_) {
      if (mounted) {
        showMessage(context, source == ImageSource.camera ? 'Couldn’t open the camera' : 'Couldn’t open your photos');
      }
    }
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    final draft = ref.read(reportDraftProvider);
    setState(() => _submitting = true);
    try {
      final issue = await ref.read(actionsProvider).reportIssue(NewIssue(
            roomId: draft.roomId!,
            title: _title.text.trim(),
            description: _description.text.trim(),
            photos: draft.photos,
          ));
      ref.read(reportDraftProvider.notifier).reset();
      if (mounted) context.go(Routes.reportDone(issue.id));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final draft = ref.watch(reportDraftProvider);
    final home = ref.watch(studentHomeProvider).value;
    final room = [if (home != null) home.room, ...?home?.sharedSpaces].where((r) => r.id == draft.roomId).firstOrNull;

    return Scaffold(
      appBar: _reportAppBar(context, step: 2, leading: const BackButton()),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          children: [
            Row(children: [
              Expanded(child: Text('What’s wrong?', style: t.headlineSmall)),
              if (room != null)
                SmallTag(
                  label: room.name,
                  icon: room.type.icon,
                  height: 32,
                  background: AppColors.tertiaryContainer,
                  foreground: AppColors.onTertiaryContainer,
                ),
            ]),
            const SizedBox(height: 16),
            TextFormField(
              controller: _title,
              maxLength: 120,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Short title', hintText: 'e.g. Bed frame slats snapped', counterText: ''),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Give it a short title' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _description,
              minLines: 5,
              maxLines: 8,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Describe the problem',
                alignLabelWithHint: true,
                helperText: 'Say what, where and since when',
              ),
              buildCounter: (context, {required currentLength, required isFocused, required maxLength}) =>
                  Text('$currentLength / $maxLength', style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
              validator: (v) => (v ?? '').trim().length < 10 ? 'Add a little more detail' : null,
            ),
            const SizedBox(height: 16),
            Text.rich(TextSpan(style: t.titleSmall, children: const [
              TextSpan(text: 'Photo '),
              TextSpan(text: '(optional, up to 3)', style: TextStyle(fontWeight: FontWeight.w400, color: AppColors.onSurfaceVariant)),
            ])),
            const SizedBox(height: 10),
            SizedBox(
              height: 104,
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                for (final (i, bytes) in draft.photos.indexed) ...[
                  _Thumb(bytes: bytes, onRemove: () => ref.read(reportDraftProvider.notifier).removePhoto(i)),
                  const SizedBox(width: 10),
                ],
                if (draft.photos.length < maxIssuePhotos) ...[
                  Expanded(child: _PickTile(icon: Symbols.photo_camera_rounded, label: 'Camera', onTap: () => _addPhoto(ImageSource.camera))),
                  const SizedBox(width: 10),
                  Expanded(child: _PickTile(icon: Symbols.photo_library_rounded, label: 'Gallery', onTap: () => _addPhoto(ImageSource.gallery))),
                ],
              ]),
            ),
            const SizedBox(height: 16),
            const InfoNote('Your landlord sets the priority. If it’s an emergency (gas, flooding, fire), call them directly.'),
            if (_error != null) ...[const SizedBox(height: 16), FormErrorBanner(_error!)],
          ],
        ),
      ),
      bottomNavigationBar: _bottomBar(BigButton(
        label: 'Submit report',
        icon: Symbols.send_rounded,
        variant: BigButtonVariant.nudge,
        loading: _submitting,
        onPressed: draft.roomId == null ? null : _submit,
      )),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.bytes, required this.onRemove});

  final Uint8List bytes;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 104,
        height: 104,
        child: Stack(children: [
          Positioned(
            left: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(bytes, width: 96, height: 96, fit: BoxFit.cover),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Semantics(
              label: 'Remove photo',
              button: true,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.onSurface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                  child: const Icon(Symbols.close_rounded, size: 16, color: Colors.white),
                ),
              ),
            ),
          ),
        ]),
      );
}

class _PickTile extends StatelessWidget {
  const _PickTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 96,
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.outline)),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 26, color: AppColors.primary),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.primary)),
            ]),
          ),
        ),
      );
}

/// S4 - submitted. The landlord has been notified.
class ReportDoneScreen extends ConsumerWidget {
  const ReportDoneScreen({super.key, required this.issueId});

  final int issueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issue = ref.watch(issueProvider(issueId)).value;
    final t = Theme.of(context).textTheme;
    final landlord = issue?.landlordName ?? 'Your landlord';
    final first = landlord.split(' ').first;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(Routes.student);
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(children: [
                Container(
                  width: 112,
                  height: 112,
                  decoration: const BoxDecoration(color: AppColors.tertiaryContainer, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: const BoxDecoration(color: AppColors.tertiary, shape: BoxShape.circle),
                    child: const Icon(Symbols.check_rounded, size: 44, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Issue reported', style: t.headlineMedium),
                const SizedBox(height: 16),
                Text(
                  '$landlord has been notified. You’ll get an alert each time the status changes.',
                  textAlign: TextAlign.center,
                  style: t.bodyLarge!.copyWith(color: AppColors.onSurfaceVariant),
                ),
                if (issue != null) ...[
                  const SizedBox(height: 24),
                  OutlinedCard(
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(issue.title, style: t.titleMedium),
                        const SizedBox(height: 10),
                        Row(children: [
                          StatusChip(issue.status),
                          const SizedBox(width: 8),
                          Text('${issue.roomName} · just now', style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
                        ]),
                      ]),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Symbols.notifications_active_rounded, size: 20, color: AppColors.tertiary, fill: 1),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text.rich(
                      TextSpan(children: [
                        const TextSpan(text: 'No progress? You can '),
                        TextSpan(text: 'nudge $first', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.onTertiaryContainer)),
                        const TextSpan(text: ' from the issue page once a day.'),
                      ]),
                      style: const TextStyle(fontSize: 13, height: 18 / 13, color: AppColors.onSurfaceVariant),
                    ),
                  ),
                ]),
              ]),
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              BigButton(
                label: 'View issue',
                onPressed: () {
                  context.go(Routes.student);
                  context.push(Routes.studentIssue(issueId));
                },
              ),
              const SizedBox(height: 4),
              BigButton(label: 'Back to home', variant: BigButtonVariant.text, onPressed: () => context.go(Routes.student)),
            ]),
          ),
        ),
      ),
    );
  }
}
