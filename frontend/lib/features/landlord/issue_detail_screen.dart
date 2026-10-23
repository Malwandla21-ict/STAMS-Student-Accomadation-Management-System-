import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../config.dart';
import '../../data/api_client.dart';
import '../../models/enums.dart';
import '../../models/issue.dart';
import '../../models/user.dart';
import '../../providers/data.dart';
import '../../router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/semantic_colors.dart';
import '../../utils/format.dart';
import '../../widgets/buttons.dart';
import '../../widgets/celebration.dart';
import '../../widgets/common.dart';
import '../../widgets/issue_badges.dart';
import '../../widgets/list_states.dart';
import '../../widgets/photos.dart';
import '../../widgets/status_timeline.dart';

/// L3 / L3t - photo, student, room, nudges, timeline. Update + Mark resolved.
class IssueDetailScreen extends ConsumerStatefulWidget {
  const IssueDetailScreen({super.key, required this.issueId});

  final int issueId;

  @override
  ConsumerState<IssueDetailScreen> createState() => _IssueDetailScreenState();
}

class _IssueDetailScreenState extends ConsumerState<IssueDetailScreen> {
  final _scroll = ScrollController();
  bool _scrolled = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final scrolled = _scroll.offset > 180;
      if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _openUpdate(Issue issue, {IssueStatus? preselect}) async {
    final saved = await showUpdateIssueSheet(context, issue, preselect: preselect);
    if (saved == null || !mounted) return;
    final student = issue.reporterName.split(' ').first;
    if (saved.status == IssueStatus.resolved && issue.status != IssueStatus.resolved) {
      final now = DateTime.now();
      final all = await ref.read(landlordIssuesProvider.future);
      final fixed = all.where((i) => i.resolvedAt != null && i.resolvedAt!.year == now.year && i.resolvedAt!.month == now.month).length;
      if (!mounted) return;
      celebrate(
        context,
        emoji: '✅',
        title: 'Fixed!',
        message: '$student has been told it’s sorted.${fixed > 1 ? ' That’s $fixed issues fixed this month — nice work.' : ''}',
      );
      return;
    }
    showMessage(
      context,
      saved.status != issue.status ? '$student has been told' : 'Issue updated',
      icon: Symbols.check_circle_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(issueProvider(widget.issueId));
    final issue = value.value;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(
          _scrolled && issue != null ? issue.title.split(' — ').first : 'Issue',
          style: _scrolled ? t.titleMedium!.copyWith(fontSize: 18) : null,
          overflow: TextOverflow.ellipsis,
        ),
        shape: _scrolled ? const Border(bottom: BorderSide(color: AppColors.surfaceHighest)) : null,
        actions: [
          if (issue != null)
            PopupMenuButton<String>(
              tooltip: 'More',
              icon: const Icon(Symbols.more_vert_rounded),
              onSelected: (v) {
                if (v == 'room') context.push(Routes.room(issue.roomId));
                if (v == 'update') _openUpdate(issue);
              },
              itemBuilder: (_) => [
                if (issue.isOpen) const PopupMenuItem(value: 'update', child: Text('Update status or priority')),
                if (kDemoMode) const PopupMenuItem(value: 'room', child: Text('Open room')),
              ],
            ),
        ],
      ),
      body: AsyncBody(
        value: value,
        onRetry: () => ref.invalidate(issueProvider(widget.issueId)),
        errorTitle: 'Couldn’t load this issue',
        data: (issue) => ListView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            if (issue.photos.isNotEmpty) ...[PhotoCarousel(photos: issue.photos), const SizedBox(height: 18)],
            Text(issue.title, style: t.titleLarge),
            const SizedBox(height: 10),
            Row(children: [StatusChip(issue.status), const SizedBox(width: 8), PriorityBadge(issue.priority)]),
            if (issue.nudgeCount > 0) ...[
              const SizedBox(height: 18),
              _NudgeBanner(issue: issue),
            ],
            const SizedBox(height: 18),
            Text(issue.description, style: t.bodyLarge),
            const SizedBox(height: 18),
            _InfoCard(issue: issue),
            const SizedBox(height: 28),
            Text('Timeline', style: t.titleMedium!.copyWith(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            StatusTimeline(issue: issue, viewer: Role.landlord),
          ],
        ),
      ),
      bottomNavigationBar: issue == null || !issue.isOpen
          ? null
          : DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.surfaceHighest)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Row(children: [
                    BigButton(
                      label: 'Update',
                      icon: Symbols.tune_rounded,
                      variant: BigButtonVariant.outlined,
                      expand: false,
                      fontSize: 15,
                      onPressed: () => _openUpdate(issue),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: BigButton(
                        label: 'Mark resolved',
                        icon: Symbols.check_circle_rounded,
                        fontSize: 15,
                        onPressed: () => _openUpdate(issue, preselect: IssueStatus.resolved),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
    );
  }
}

class _NudgeBanner extends StatelessWidget {
  const _NudgeBanner({required this.issue});

  final Issue issue;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: AppColors.tertiaryContainer, borderRadius: BorderRadius.circular(AppRadius.large)),
        child: Row(children: [
          const IconCircle(Symbols.notifications_active_rounded, background: Colors.white, foreground: AppColors.tertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Nudged ${issue.nudgeCount == 1 ? 'once' : '${issue.nudgeCount} times'}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.onTertiaryContainer)),
              const SizedBox(height: 2),
              Text(
                'Last nudge ${Fmt.ago(issue.lastNudgedAt!)} · waiting ${Fmt.waited(issue.createdAt)}',
                style: const TextStyle(fontSize: 13, height: 18 / 13, color: AppColors.onTertiaryContainer),
              ),
            ]),
          ),
        ]),
      );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.issue});

  final Issue issue;

  @override
  Widget build(BuildContext context) {
    Widget row({required Widget leading, required String label, required String value, VoidCallback? onTap}) => InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
              child: Row(children: [
                SizedBox(width: 24, child: Center(child: leading)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(label, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                    Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ]),
                ),
                if (onTap != null) const Icon(Symbols.chevron_right_rounded, color: AppColors.onSurfaceVariant),
              ]),
            ),
          ),
        );

    return OutlinedCard(
      padding: EdgeInsets.zero,
      child: Column(children: [
        row(
          leading: Icon(issue.roomType.icon, size: 22, color: AppColors.onSurfaceVariant),
          label: 'Room',
          value: issue.location,
          // Rooms in the demo store only exist in demo mode.
          onTap: kDemoMode ? () => context.push(Routes.room(issue.roomId)) : null,
        ),
        const Divider(color: AppColors.surfaceContainer),
        row(
          leading: InitialsAvatar(initialsOf(issue.reporterName), size: 24),
          label: 'Reported by',
          value: '${issue.reporterName} · ${Fmt.stamp(issue.createdAt)}',
        ),
      ]),
    );
  }
}

/// L4 - move the status forward, set priority, leave a note for the student.
/// Returns the updated issue, or null if cancelled.
Future<Issue?> showUpdateIssueSheet(BuildContext context, Issue issue, {IssueStatus? preselect}) =>
    showModalBottomSheet<Issue>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _UpdateSheet(issue: issue, preselect: preselect),
    );

class _UpdateSheet extends ConsumerStatefulWidget {
  const _UpdateSheet({required this.issue, this.preselect});

  final Issue issue;
  final IssueStatus? preselect;

  @override
  ConsumerState<_UpdateSheet> createState() => _UpdateSheetState();
}

class _UpdateSheetState extends ConsumerState<_UpdateSheet> {
  late IssueStatus _status = widget.preselect ?? widget.issue.status;
  late IssuePriority _priority = widget.issue.priority;
  final _note = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _note.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  bool get _changed => _status != widget.issue.status || _priority != widget.issue.priority || _note.text.trim().isNotEmpty;
  bool get _notifies => _status != widget.issue.status;

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await ref.read(actionsProvider).updateIssue(
            widget.issue.id,
            IssueUpdate(status: _status, priority: _priority, note: _note.text.trim().isEmpty ? null : _note.text.trim()),
          );
      if (mounted) Navigator.pop(context, updated);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  DateTime? _reachedAt(IssueStatus s) =>
      widget.issue.events.where((e) => e.status == s).map((e) => e.createdAt).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final issue = widget.issue;
    final student = issue.reporterName.split(' ').first;
    Widget label(String text, {double top = 0}) => Padding(
          padding: EdgeInsets.fromLTRB(24, top, 24, 8),
          child: Text(text, style: t.labelLarge!.copyWith(fontSize: 13, color: AppColors.onSurfaceVariant)),
        );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(padding: const EdgeInsets.fromLTRB(24, 0, 24, 12), child: Text('Update issue', style: t.titleLarge)),
            label('Status'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(children: [
                for (final s in IssueStatus.values)
                  _StatusOption(
                    status: s,
                    stage: s.index < issue.status.index
                        ? _Stage.past
                        : s == issue.status
                            ? _Stage.current
                            : _Stage.future,
                    selected: _status == s,
                    reachedAt: _reachedAt(s),
                    onTap: s.index >= issue.status.index ? () => setState(() => _status = s) : null,
                  ),
              ]),
            ),
            label('Priority', top: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SegmentedButton<IssuePriority>(
                segments: [
                  for (final p in IssuePriority.values)
                    ButtonSegment(value: p, label: Text(p.label), icon: Icon(context.priorityColors.of(p).icon, size: 18)),
                ],
                selected: {_priority},
                showSelectedIcon: true,
                onSelectionChanged: (s) => setState(() => _priority = s.first),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: TextField(
                controller: _note,
                maxLength: 500,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: 'Note to $student (optional)', counterText: ''),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(children: [
                Expanded(child: BigButton(label: 'Cancel', variant: BigButtonVariant.text, fontSize: 15, onPressed: () => Navigator.pop(context))),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: BigButton(
                    label: _notifies ? 'Save & notify $student' : 'Save',
                    fontSize: 15,
                    loading: _saving,
                    onPressed: _changed ? _save : null,
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

enum _Stage { past, current, future }

class _StatusOption extends StatelessWidget {
  const _StatusOption({required this.status, required this.stage, required this.selected, required this.reachedAt, required this.onTap});

  final IssueStatus status;
  final _Stage stage;
  final bool selected;
  final DateTime? reachedAt;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.statusColors.of(status);
    final moving = selected && stage == _Stage.future;
    final isCurrentRow = stage == _Stage.current;

    final Widget trailing = switch (stage) {
      _Stage.past => Row(mainAxisSize: MainAxisSize.min, children: [
          if (reachedAt != null) Text(Fmt.day(reachedAt!), style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
          const SizedBox(width: 14),
          const Icon(Symbols.check_rounded, size: 20, color: AppColors.onSurfaceVariant),
        ]),
      _Stage.current => Text('Current', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: s.onContainer)),
      _Stage.future => RadioDot(selected: selected, color: s.onContainer),
    };

    final decoration = moving
        ? BoxDecoration(color: s.container, borderRadius: BorderRadius.circular(12), border: Border.all(color: s.onContainer, width: 2))
        : isCurrentRow
            ? BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.surfaceHighest))
            : null;

    return Semantics(
      selected: selected,
      button: onTap != null,
      child: Padding(
        padding: EdgeInsets.only(top: stage == _Stage.future ? 6 : 0),
        child: Opacity(
          opacity: stage == _Stage.past ? 0.6 : 1,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: moving ? 56 : 52,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: decoration,
                child: Row(children: [
                  Icon(s.icon, size: 20, color: s.onContainer, fill: 1),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      status.label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        color: moving ? s.onContainer : AppColors.onSurface,
                      ),
                    ),
                  ),
                  trailing,
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
