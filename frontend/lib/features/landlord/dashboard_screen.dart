import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../models/enums.dart';
import '../../models/issue.dart';
import '../../providers/auth.dart';
import '../../providers/data.dart';
import '../../router.dart';
import '../../theme/app_colors.dart';
import '../../theme/semantic_colors.dart';
import '../../utils/format.dart';
import '../../widgets/cards.dart';
import '../../widgets/common.dart';
import '../../widgets/list_states.dart';

/// L1 - open issues by status, most nudged, recent activity.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final issues = ref.watch(landlordIssuesProvider);
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
          return ref.refresh(landlordIssuesProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(Fmt.today(), style: t.bodyMedium!.copyWith(color: AppColors.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Text('${Fmt.greeting()}, ${user?.firstName ?? ''}', style: t.headlineMedium),
                    ],
                  ),
                ),
                Transform.translate(
                  offset: const Offset(4, 0),
                  child: IconButton(
                    tooltip: unread > 0 ? 'Alerts, $unread unread' : 'Alerts',
                    style: IconButton.styleFrom(backgroundColor: AppColors.surfaceContainer, fixedSize: const Size(48, 48)),
                    onPressed: () => context.go(Routes.landlordAlerts),
                    icon: Badge(
                      isLabelVisible: unread > 0,
                      label: Text('$unread'),
                      offset: const Offset(6, -6),
                      child: const Icon(Symbols.notifications_rounded),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            AsyncBody(
              value: issues,
              onRetry: () => ref.invalidate(landlordIssuesProvider),
              errorTitle: 'Couldn’t load issues',
              loading: const SizedBox(height: 480, child: SkeletonList(padding: EdgeInsets.zero)),
              data: (all) => _DashboardBody(issues: all, onOpenIssues: openIssues),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.issues, required this.onOpenIssues});

  final List<Issue> issues;
  final void Function({IssueStatus? status, IssueSort sort}) onOpenIssues;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final now = DateTime.now();
    final open = issues.where((i) => i.isOpen).toList();
    final resolvedThisMonth =
        issues.where((i) => i.resolvedAt != null && i.resolvedAt!.year == now.year && i.resolvedAt!.month == now.month).length;
    final mostNudged = const IssueFilter().apply(open.where((i) => i.nudgeCount > 0)).take(2).toList();
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
            Expanded(child: Text(Fmt.plural(open.length, 'open issue'), style: t.titleMedium)),
            Text('$resolvedThisMonth resolved this month', style: t.bodyMedium!.copyWith(fontSize: 13, color: AppColors.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: 12),
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
        if (mostNudged.isNotEmpty) ...[
          const SizedBox(height: 24),
          SectionHeader(
            title: 'Most nudged',
            icon: Symbols.notifications_active_rounded,
            trailing: InlineAction('See all', onPressed: () => onOpenIssues()),
          ),
          const SizedBox(height: 4),
          for (final issue in mostNudged) ...[
            IssueCard(issue: issue, onTap: () => context.push(Routes.landlordIssue(issue.id))),
            const SizedBox(height: 12),
          ],
        ],
        if (recent.isNotEmpty) ...[
          SizedBox(height: mostNudged.isEmpty ? 24 : 12),
          Text('Recent activity', style: t.titleMedium!.copyWith(fontSize: 20, fontWeight: FontWeight.w700)),
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
                      context.statusColors.reported.icon,
                      size: 36,
                      background: context.statusColors.reported.container,
                      foreground: context.statusColors.reported.onContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(children: [
                              TextSpan(text: r.issue.reporterName, style: const TextStyle(fontWeight: FontWeight.w700)),
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
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconCircle(s.icon, size: 32, background: s.container, foreground: s.onContainer),
            const SizedBox(height: 8),
            Text('$count', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 28, height: 32 / 28)),
            const SizedBox(height: 8),
            Text(status.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
