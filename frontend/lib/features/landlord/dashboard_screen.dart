import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../models/enums.dart';
import '../../models/issue.dart';
import '../../models/property.dart';
import '../../providers/auth.dart';
import '../../providers/data.dart';
import '../../router.dart';
import '../../theme/app_colors.dart';
import '../../theme/semantic_colors.dart';
import '../../utils/format.dart';
import '../../widgets/cards.dart';
import '../../widgets/common.dart';
import '../../widgets/list_states.dart';
import '../../widgets/progress.dart';

/// L1 - a calm overview: setup checklist for new landlords, open issues by
/// status, what needs attention, recent reports.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final issues = ref.watch(landlordIssuesProvider);
    final properties = ref.watch(propertiesProvider);
    final unread = ref.watch(unreadAlertCountProvider);
    final t = Theme.of(context).textTheme;

    void openIssues({IssueStatus? status, IssueSort sort = IssueSort.mostNudged}) {
      ref.read(issueFilterProvider.notifier).set(IssueFilter(status: status, sort: sort));
      context.go(Routes.landlordIssues);
    }

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(notificationsProvider);
          ref.invalidate(propertiesProvider);
          return ref.refresh(landlordIssuesProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(Fmt.longToday(), style: t.bodyMedium!.copyWith(color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text('${Fmt.greeting()}, ${user?.firstName ?? ''} 👋', style: t.headlineMedium),
                  ]),
                ),
                IconButton(
                  tooltip: unread > 0 ? 'Alerts, $unread new' : 'Alerts',
                  onPressed: () => context.go(Routes.landlordAlerts),
                  icon: Badge(
                    isLabelVisible: unread > 0,
                    smallSize: 8,
                    backgroundColor: AppColors.tertiary,
                    child: const Icon(Symbols.notifications_rounded, color: AppColors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (properties.hasValue && issues.hasValue)
              _SetupChecklist(properties: properties.requireValue, issues: issues.requireValue),
            AsyncBody(
              value: issues,
              onRetry: () => ref.invalidate(landlordIssuesProvider),
              errorTitle: 'Couldn’t load issues',
              loading: const SizedBox(height: 480, child: SkeletonList(padding: EdgeInsets.zero)),
              data: (all) => _Overview(issues: all, onOpenIssues: openIssues),
            ),
          ],
        ),
      ),
    );
  }
}

/// New landlords: property → room → student → first report. Hidden once everything's done.
class _SetupChecklist extends StatelessWidget {
  const _SetupChecklist({required this.properties, required this.issues});

  final List<Property> properties;
  final List<Issue> issues;

  @override
  Widget build(BuildContext context) {
    final hasProperty = properties.isNotEmpty;
    final hasRoom = properties.any((p) => p.roomCount > 0);
    final hasStudent = properties.any((p) => p.bedsFilled > 0);
    final hasReport = issues.isNotEmpty;
    if (hasProperty && hasRoom && hasStudent && hasReport) return const SizedBox.shrink();

    final needsRoom = properties.where((p) => p.roomCount == 0).firstOrNull ?? properties.firstOrNull;
    final hasFreeBed = properties.where((p) => p.bedsTotal > p.bedsFilled).firstOrNull ?? properties.firstOrNull;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: ChecklistCard(
        title: 'Get set up',
        subtitle: 'A few quick steps and your students can start reporting.',
        steps: [
          ChecklistStep(
            label: 'Add your first property',
            done: hasProperty,
            hint: 'Just a name and address.',
            actionLabel: 'Add',
            onAction: () => context.push(Routes.newProperty),
          ),
          ChecklistStep(
            label: 'Add its rooms',
            done: hasRoom,
            hint: 'Bedrooms, plus shared spaces like the kitchen.',
            actionLabel: 'Add room',
            onAction: needsRoom == null ? null : () => context.push(Routes.newRoom(needsRoom.id)),
          ),
          ChecklistStep(
            label: 'Assign a student',
            done: hasStudent,
            hint: 'Open a room and search their email.',
            actionLabel: 'Open',
            onAction: hasFreeBed == null ? null : () => context.push(Routes.property(hasFreeBed.id)),
          ),
          ChecklistStep(
            label: 'Get your first report',
            done: hasReport,
            hint: 'Students report from their app once they’re in a room.',
          ),
        ],
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.issues, required this.onOpenIssues});

  final List<Issue> issues;
  final void Function({IssueStatus? status, IssueSort sort}) onOpenIssues;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final now = DateTime.now();
    final open = issues.where((i) => i.isOpen).toList();
    final resolvedThisMonth =
        issues.where((i) => i.resolvedAt != null && i.resolvedAt!.year == now.year && i.resolvedAt!.month == now.month).length;
    final attention = const IssueFilter().apply(open.where((i) => i.nudgeCount > 0)).take(2).toList();
    final recent = [
      for (final i in issues)
        for (final e in i.events)
          if (e.type == IssueEventType.reported) (issue: i, at: e.createdAt),
    ]..sort((a, b) => b.at.compareTo(a.at));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(child: Text(open.isEmpty ? 'No open issues' : Fmt.plural(open.length, 'open issue'), style: t.titleMedium)),
            if (resolvedThisMonth > 0)
              Text('✓ $resolvedThisMonth fixed this month',
                  style: t.bodyMedium!.copyWith(fontSize: 13, color: AppColors.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: 12),
        if (open.isEmpty)
          OutlinedCard(
            child: Row(children: [
              const Text('✨', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  issues.isEmpty ? 'Nothing reported yet. When students report something, it lands here.' : 'All caught up — nothing needs fixing right now.',
                  style: t.bodyMedium!.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ),
            ]),
          )
        else
          Row(
            children: [
              for (final status in IssueStatus.open) ...[
                if (status != IssueStatus.reported) const SizedBox(width: 10),
                Expanded(
                  child: _StatusTile(
                    status: status,
                    count: open.where((i) => i.status == status).length,
                    onTap: () => onOpenIssues(status: status),
                  ),
                ),
              ],
            ],
          ),
        if (attention.isNotEmpty) ...[
          const SizedBox(height: 28),
          SectionHeader(
            title: 'Needs attention',
            size: 18,
            trailing: InlineAction('See all', onPressed: () => onOpenIssues()),
          ),
          Text('Students have nudged you about these.', style: t.bodySmall!.copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 12),
          for (final issue in attention) ...[
            IssueCard(issue: issue, onTap: () => context.push(Routes.landlordIssue(issue.id))),
            const SizedBox(height: 12),
          ],
        ],
        if (recent.isNotEmpty) ...[
          SizedBox(height: attention.isEmpty ? 28 : 16),
          Text('Recently reported', style: t.titleMedium!.copyWith(fontSize: 18)),
          const SizedBox(height: 8),
          for (final r in recent.take(4))
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => context.push(Routes.landlordIssue(r.issue.id)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconCircle(
                      context.statusColors.of(r.issue.status).icon,
                      size: 36,
                      background: context.statusColors.of(r.issue.status).container,
                      foreground: context.statusColors.of(r.issue.status).onContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(children: [
                              TextSpan(text: r.issue.reporterName, style: const TextStyle(fontWeight: FontWeight.w600)),
                              TextSpan(text: ' reported “${r.issue.title}”'),
                            ]),
                            style: t.bodyMedium,
                          ),
                          const SizedBox(height: 2),
                          Text('${r.issue.propertyName} · ${Fmt.age(r.at).toLowerCase()}',
                              style: t.bodySmall!.copyWith(color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({required this.status, required this.count, required this.onTap});

  final IssueStatus status;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.statusColors.of(status);
    return Semantics(
      label: '$count ${status.label}',
      button: true,
      excludeSemantics: true,
      child: OutlinedCard(
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(s.icon, size: 18, color: s.onContainer, fill: 1),
              const Spacer(),
              Text('$count', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 22, height: 1)),
            ]),
            const SizedBox(height: 10),
            Text(status.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
