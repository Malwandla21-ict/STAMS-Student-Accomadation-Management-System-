import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../data/api_client.dart';
import '../../models/issue.dart';
import '../../providers/data.dart';
import '../../router.dart';
import '../../theme/semantic_colors.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cards.dart';
import '../../widgets/common.dart';
import '../../widgets/list_states.dart';

/// S5 / S5e / S5x - the student's issues, Open and Resolved tabs.
class MyIssuesScreen extends ConsumerWidget {
  const MyIssuesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(studentIssuesProvider);
    final issues = value.value ?? const <Issue>[];
    final open = issues.where((i) => i.isOpen).toList();
    final resolved = issues.where((i) => !i.isOpen).toList()
      ..sort((a, b) => (b.resolvedAt ?? b.createdAt).compareTo(a.resolvedAt ?? a.createdAt));
    final offline = value.hasError && ApiException.from(value.error!).isNetwork;

    return DefaultTabController(
      length: 2,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(title: 'My issues'),
            if (offline) ...[const OfflineBanner(), const SizedBox(height: 8)],
            if (!value.hasError || value.hasValue)
              TabBar(tabs: [
                Tab(text: value.hasValue ? 'Open · ${open.length}' : 'Open'),
                Tab(text: value.hasValue ? 'Resolved · ${resolved.length}' : 'Resolved'),
              ]),
            Expanded(
              child: AsyncBody(
                value: value,
                onRetry: () => ref.invalidate(studentIssuesProvider),
                errorTitle: 'Couldn’t load your issues',
                loading: const SkeletonList(padding: EdgeInsets.fromLTRB(20, 16, 20, 20)),
                data: (_) => TabBarView(children: [
                  _IssueList(
                    issues: open,
                    empty: StateMessage(
                      icon: Symbols.task_alt_rounded,
                      iconBackground: context.statusColors.resolved.container,
                      iconForeground: context.statusColors.resolved.onContainer,
                      title: 'No open issues',
                      message: 'Something broken in your room or a shared space? Report it and follow the fix here.',
                      action: ref.watch(studentHomeProvider).value == null
                          ? null
                          : BigButton(
                              label: 'Report something',
                              icon: Symbols.add_circle_rounded,
                              filledIcon: true,
                              variant: BigButtonVariant.soft,
                              expand: false,
                              fontSize: 15,
                              onPressed: () {
                                ref.read(reportDraftProvider.notifier).reset();
                                context.push(Routes.report);
                              },
                            ),
                    ),
                  ),
                  _IssueList(
                    issues: resolved,
                    empty: const StateMessage(
                      icon: Symbols.history_rounded,
                      title: 'Nothing resolved yet',
                      message: 'Issues your landlord fixes will move here.',
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IssueList extends ConsumerWidget {
  const _IssueList({required this.issues, required this.empty});

  final List<Issue> issues;
  final Widget empty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (issues.isEmpty) return empty;
    return RefreshIndicator(
      onRefresh: () => ref.refresh(studentIssuesProvider.future),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        itemCount: issues.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) => IssueCard(
          issue: issues[i],
          reporterIsMe: true,
          onTap: () => context.push(Routes.studentIssue(issues[i].id)),
        ),
      ),
    );
  }
}
