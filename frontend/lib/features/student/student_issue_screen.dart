import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../models/enums.dart';
import '../../models/issue.dart';
import '../../providers/data.dart';
import '../../router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/semantic_colors.dart';
import '../../utils/format.dart';
import '../../widgets/buttons.dart';
import '../../widgets/common.dart';
import '../../widgets/list_states.dart';
import '../../widgets/nudge_button.dart';
import '../../widgets/photos.dart';
import '../../widgets/progress.dart';
import '../../widgets/status_timeline.dart';

/// S6a-d - the student's view of one issue: progress timeline and the nudge button.
class StudentIssueScreen extends ConsumerWidget {
  const StudentIssueScreen({super.key, required this.issueId});

  final int issueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(issueProvider(issueId));
    final issue = value.value;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('My issue')),
      body: AsyncBody(
        value: value,
        onRetry: () => ref.invalidate(issueProvider(issueId)),
        errorTitle: 'Couldn’t load this issue',
        data: (issue) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            if (!issue.isOpen)
              _ResolvedBanner(issue: issue)
            else if (issue.photos.isNotEmpty)
              PhotoCarousel(photos: issue.photos, height: 128),
            if (!issue.isOpen || issue.photos.isNotEmpty) const SizedBox(height: 14),
            Text(issue.title, style: t.titleLarge),
            const SizedBox(height: 4),
            Text('${issue.roomName} · ${issue.propertyName}', style: t.bodySmall!.copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 16),
            IssueProgress(status: issue.status, landlordFirstName: issue.landlordName.split(' ').first),
            const SizedBox(height: 20),
            OutlinedCard(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('What’s happened', style: t.titleSmall),
                const SizedBox(height: 12),
                StatusTimeline(issue: issue, viewer: Role.student, compact: true),
              ]),
            ),
            const SizedBox(height: 14),
            _Description(text: issue.description),
            if (!issue.isOpen) ...[
              const SizedBox(height: 14),
              const InfoNote('This one’s closed, so nudging is off. If the problem comes back, just report it again.', background: null),
            ],
          ],
        ),
      ),
      bottomNavigationBar: issue == null
          ? null
          : DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.surfaceHighest)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                  child: issue.isOpen
                      ? NudgeButton(
                          issue: issue,
                          landlordFirstName: issue.landlordName.split(' ').first,
                          onNudge: () => ref.read(actionsProvider).nudge(issue.id),
                        )
                      : BigButton(
                          label: 'Report a new issue',
                          icon: Symbols.add_circle_rounded,
                          variant: BigButtonVariant.outlined,
                          onPressed: () {
                            ref.read(reportDraftProvider.notifier).reset();
                            context.push(Routes.report);
                          },
                        ),
                ),
              ),
            ),
    );
  }
}

/// S6d - green "Fixed" banner in place of the photo.
class _ResolvedBanner extends StatelessWidget {
  const _ResolvedBanner({required this.issue});

  final Issue issue;

  @override
  Widget build(BuildContext context) {
    final s = context.statusColors.resolved;
    final resolvedAt = issue.resolvedAt ?? DateTime.now();
    final when = Fmt.age(resolvedAt).toLowerCase();
    final took = Fmt.waited(issue.createdAt, now: resolvedAt);
    final nudges = issue.nudgeCount == 0
        ? ''
        : ' · you nudged ${issue.nudgeCount == 1 ? 'once' : '${issue.nudgeCount} times'}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: s.container, borderRadius: BorderRadius.circular(AppRadius.large)),
      child: Row(children: [
        Icon(s.icon, size: 28, color: s.onContainer, fill: 1),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              'Fixed — resolved $when',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: s.onContainer),
            ),
            const SizedBox(height: 2),
            Text('Took $took$nudges', style: TextStyle(fontSize: 13, height: 18 / 13, color: s.onContainer)),
          ]),
        ),
      ]),
    );
  }
}

/// The student's own description, collapsed to three lines.
class _Description extends StatefulWidget {
  const _Description({required this.text});

  final String text;

  @override
  State<_Description> createState() => _DescriptionState();
}

class _DescriptionState extends State<_Description> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('What you reported', style: t.titleSmall!.copyWith(color: AppColors.onSurfaceVariant)),
      const SizedBox(height: 4),
      GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Text(
          widget.text,
          maxLines: _expanded ? null : 3,
          overflow: _expanded ? null : TextOverflow.ellipsis,
          style: t.bodyMedium,
        ),
      ),
    ]);
  }
}
