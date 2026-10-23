import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../models/app_notification.dart';
import '../../models/enums.dart';
import '../../providers/auth.dart';
import '../../providers/data.dart';
import '../../router.dart';
import '../../theme/app_colors.dart';
import '../../theme/semantic_colors.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/list_states.dart';
import '../../widgets/progress.dart';

/// A4 (landlord: nudges from students) / A5 (student: status changes).
class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  bool _unreadOnly = false;

  void _open(AppNotification n, bool landlord) {
    if (!n.read) ref.read(actionsProvider).markAlertRead(n.id);
    if (n.issueId != null) {
      context.push(landlord ? Routes.landlordIssue(n.issueId!) : Routes.studentIssue(n.issueId!));
    } else if (n.type == NotificationType.roomAssigned) {
      context.go(Routes.student);
    }
  }

  @override
  Widget build(BuildContext context) {
    final landlord = ref.watch(currentUserProvider)?.isLandlord ?? false;
    final value = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadAlertCountProvider);

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: 'Alerts',
            trailing: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: InlineAction('Mark all read', onPressed: unread == 0 ? null : () => ref.read(actionsProvider).markAllAlertsRead()),
            ),
          ),
          if (landlord)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(children: [
                ChoiceChip(label: const Text('All'), selected: !_unreadOnly, onSelected: (_) => setState(() => _unreadOnly = false)),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(unread > 0 ? 'Unread · $unread' : 'Unread'),
                  selected: _unreadOnly,
                  onSelected: (_) => setState(() => _unreadOnly = true),
                ),
              ]),
            ),
          Expanded(
            child: AsyncBody(
              value: value,
              onRetry: () => ref.invalidate(notificationsProvider),
              errorTitle: 'Couldn’t load alerts',
              data: (all) {
                final items = _unreadOnly ? all.where((n) => !n.read).toList() : all;
                if (items.isEmpty) {
                  return StateMessage(
                    icon: Symbols.notifications_off_rounded,
                    title: _unreadOnly ? 'No unread alerts' : 'You’re all caught up',
                    message: landlord ? 'When a student nudges you about an issue, it shows up here.' : 'Updates from your landlord show up here.',
                  );
                }
                final groups = _group(items, landlord);
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(notificationsProvider.future),
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      for (final (label, list) in groups) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
                          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.onSurfaceVariant)),
                        ),
                        for (final n in list) _AlertRow(n: n, landlord: landlord, onTap: () => _open(n, landlord)),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<(String, List<AppNotification>)> _group(List<AppNotification> items, bool landlord) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final buckets = <String, List<AppNotification>>{};
    for (final n in items) {
      final label = !n.createdAt.isBefore(today)
          ? 'Today'
          : landlord && !n.createdAt.isBefore(weekStart)
              ? 'Earlier this week'
              : 'Earlier';
      buckets.putIfAbsent(label, () => []).add(n);
    }
    return [for (final e in buckets.entries) (e.key, e.value)];
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.n, required this.landlord, required this.onTap});

  final AppNotification n;
  final bool landlord;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = !n.read;
    final actor = n.actorName ?? 'Someone';
    final first = actor.split(' ').first;
    final shortTitle = (n.issueTitle ?? '').split(' — ').first;
    final strong = TextStyle(fontWeight: unread ? FontWeight.w700 : FontWeight.w600);
    final statusColors = context.statusColors;

    final (IconData icon, Color bg, Color fg, InlineSpan title, String subtitle, Widget? footer) = switch (n.type) {
      NotificationType.newIssue => (
          statusColors.reported.icon,
          statusColors.reported.container,
          statusColors.reported.onContainer,
          TextSpan(children: [TextSpan(text: actor, style: strong), const TextSpan(text: ' reported something')]),
          '$shortTitle · ${n.roomName}, ${n.propertyName}',
          null,
        ),
      NotificationType.nudge => (
          Symbols.notifications_active_rounded,
          AppColors.tertiaryContainer,
          AppColors.onTertiaryContainer,
          TextSpan(children: [
            TextSpan(text: actor, style: strong),
            const TextSpan(text: ' nudged you'),
            if ((n.nudgeNumber ?? 1) >= 2)
              TextSpan(text: ' · ${Fmt.ordinal(n.nudgeNumber!)} time', style: const TextStyle(color: AppColors.nudgeText)),
          ]),
          '$shortTitle · ${n.roomName}, ${n.propertyName}',
          null,
        ),
      NotificationType.statusChange => (
          statusColors.of(n.status ?? IssueStatus.acknowledged).icon,
          statusColors.of(n.status ?? IssueStatus.acknowledged).container,
          statusColors.of(n.status ?? IssueStatus.acknowledged).onContainer,
          TextSpan(children: [
            TextSpan(text: first, style: strong),
            TextSpan(
              text: switch (n.status ?? IssueStatus.acknowledged) {
                IssueStatus.acknowledged => ' has seen your issue',
                IssueStatus.inProgress => ' is fixing your issue',
                IssueStatus.resolved => ' fixed your issue 🎉',
                IssueStatus.reported => ' reopened your issue',
              },
            ),
          ]),
          '$shortTitle · ${n.roomName}',
          IssueProgress(status: n.status ?? IssueStatus.acknowledged, compact: true),
        ),
      NotificationType.roomAssigned => (
          Symbols.bed_rounded,
          AppColors.primaryContainer,
          AppColors.onPrimaryContainer,
          TextSpan(children: [TextSpan(text: first, style: strong), TextSpan(text: ' added you to ${n.roomName ?? 'a room'} 🏠')]),
          n.propertyName ?? '',
          null,
        ),
    };

    final small = Theme.of(context).textTheme.bodySmall!.copyWith(color: AppColors.onSurfaceVariant);
    return Material(
      color: unread ? AppColors.softIris : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            IconCircle(icon, background: bg, foreground: fg, filled: unread),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text.rich(title, style: const TextStyle(fontSize: 15, height: 20 / 15, color: AppColors.onSurface)),
                const SizedBox(height: 3),
                Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: small.copyWith(fontSize: 13, height: 18 / 13)),
                if (footer != null) ...[const SizedBox(height: 8), SizedBox(width: 180, child: footer)],
                const SizedBox(height: 4),
                Text(Fmt.ago(n.createdAt), style: small),
              ]),
            ),
            if (unread)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 7, left: 8),
                decoration: const BoxDecoration(color: AppColors.tertiary, shape: BoxShape.circle),
              ),
          ]),
        ),
      ),
    );
  }
}
