import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../models/student_home.dart';
import '../../providers/auth.dart';
import '../../providers/data.dart';
import '../../router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/format.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cards.dart';
import '../../widgets/common.dart';
import '../../widgets/issue_badges.dart';
import '../../widgets/list_states.dart';
import '../../widgets/progress.dart';
import '../../widgets/stams_logo.dart';

/// S1 / S1u - my room, report button, open issues.
class StudentHomeScreen extends ConsumerWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final home = ref.watch(studentHomeProvider);
    final t = Theme.of(context).textTheme;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(studentIssuesProvider);
          ref.invalidate(notificationsProvider);
          return ref.refresh(studentHomeProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text(Fmt.longToday(), style: t.bodyMedium!.copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text('Hi ${user?.firstName ?? 'there'} 👋', style: t.headlineMedium),
            const SizedBox(height: 20),
            AsyncBody(
              value: home,
              onRetry: () => ref.invalidate(studentHomeProvider),
              errorTitle: 'Couldn’t load your room',
              loading: const SizedBox(height: 300, child: Center(child: CircularProgressIndicator())),
              data: (home) => home == null ? _GettingSetUp(email: user?.email ?? '') : _Assigned(home: home),
            ),
          ],
        ),
      ),
    );
  }
}

class _Assigned extends ConsumerWidget {
  const _Assigned({required this.home});

  final StudentHome home;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issues = ref.watch(studentIssuesProvider);
    final all = issues.value ?? const [];
    final open = all.where((i) => i.isOpen).toList();
    final fixed = all.length - open.length;
    final t = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RoomCard(home: home),
        const SizedBox(height: 16),
        BigButton(
          label: 'Report something',
          icon: Symbols.add_rounded,
          variant: BigButtonVariant.soft,
          onPressed: () {
            ref.read(reportDraftProvider.notifier).reset();
            context.push(Routes.report);
          },
        ),
        const SizedBox(height: 28),
        SectionHeader(
          title: open.isEmpty ? 'Your issues' : 'Being looked at',
          count: issues.hasValue && open.isNotEmpty ? open.length : null,
          size: 18,
          trailing: all.isEmpty ? null : InlineAction('See all', onPressed: () => context.go(Routes.studentIssues)),
        ),
        const SizedBox(height: 8),
        if (issues.isLoading && !issues.hasValue)
          const IssueCardSkeleton()
        else if (open.isEmpty)
          OutlinedCard(
            child: Row(children: [
              Text(all.isEmpty ? '🏡' : '✨', style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  all.isEmpty
                      ? 'Nothing reported yet. If something breaks, tell ${home.landlordFirstName} here and follow the fix.'
                      : 'Everything you reported is fixed${fixed > 1 ? ' — $fixed issues sorted so far' : ''}.',
                  style: t.bodyMedium!.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ),
            ]),
          )
        else
          for (final issue in open.take(3)) ...[
            IssueCard(issue: issue, reporterIsMe: true, onTap: () => context.push(Routes.studentIssue(issue.id))),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

/// "My room" on a light tint, with the mark as a faint watermark.
class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.home});

  final StudentHome home;

  @override
  Widget build(BuildContext context) {
    final room = home.room;
    final t = Theme.of(context).textTheme;
    Widget fact(String label, String value) => Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: t.bodySmall!.copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 2),
            Text(value, style: t.titleSmall),
          ]),
        );
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: AppColors.softTint, borderRadius: BorderRadius.circular(AppRadius.large + 4)),
      child: Stack(children: [
        const Positioned(right: -18, bottom: -22, child: Opacity(opacity: .05, child: StamsMark(size: 120))),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              IconTile(room.type.icon, size: 40, background: Colors.white, iconSize: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${room.name} · ${room.description[0].toUpperCase()}${room.description.substring(1)}', style: t.titleMedium),
                  Text(home.propertyName, style: t.bodySmall!.copyWith(color: AppColors.onSurfaceVariant)),
                ]),
              ),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              fact(
                home.roommates.isEmpty ? 'Room' : 'Sharing with',
                home.roommates.isEmpty ? 'Just you' : home.roommates.map((s) => s.name.split(' ').first).join(', '),
              ),
              const SizedBox(width: 16),
              fact('Landlord', home.landlordName),
            ]),
          ]),
        ),
      ]),
    );
  }
}

/// S1u - not in a room yet. Shows how far along they are and what happens next.
class _GettingSetUp extends StatelessWidget {
  const _GettingSetUp({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ChecklistCard(
          title: 'Getting you set up',
          subtitle: 'Nearly there — one step is with your landlord.',
          steps: [
            ChecklistStep(label: 'Create your account', done: true),
            ChecklistStep(
              label: 'Your landlord adds you to a room',
              done: false,
              hint: 'They find you by your email. We’ll let you know the moment it’s done.',
            ),
            ChecklistStep(label: 'Report and track repairs', done: false),
          ],
        ),
        const SizedBox(height: 16),
        OutlinedCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Share this with your landlord', style: t.titleSmall),
            const SizedBox(height: 4),
            Text('If they ask how to find you, this is the email to search for.',
                style: t.bodySmall!.copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 12),
            Container(
              height: 48,
              padding: const EdgeInsets.fromLTRB(14, 0, 4, 0),
              decoration: BoxDecoration(color: AppColors.surfaceLow, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Symbols.mail_rounded, size: 20, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(child: Text(email, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: email));
                    if (context.mounted) showMessage(context, 'Email copied');
                  },
                  style: TextButton.styleFrom(minimumSize: const Size(0, 40), textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  icon: const Icon(Symbols.content_copy_rounded, size: 18),
                  label: const Text('Copy'),
                ),
              ]),
            ),
          ]),
        ),
      ],
    );
  }
}
