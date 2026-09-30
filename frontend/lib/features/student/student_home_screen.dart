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
import '../../theme/semantic_colors.dart';
import '../../utils/format.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cards.dart';
import '../../widgets/common.dart';
import '../../widgets/list_states.dart';
import '../../widgets/stams_logo.dart';

/// S1 / S1u - my room, report button, open issues.
class StudentHomeScreen extends ConsumerWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final home = ref.watch(studentHomeProvider);
    final t = Theme.of(context).textTheme;
    final assigned = home.value != null;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(studentIssuesProvider);
          ref.invalidate(notificationsProvider);
          return ref.refresh(studentHomeProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text(Fmt.today(), style: t.bodyMedium!.copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text(
              home.hasValue && !assigned ? 'Welcome, ${user?.firstName ?? ''}' : 'Hi ${user?.firstName ?? ''}',
              style: t.headlineMedium,
            ),
            const SizedBox(height: 20),
            AsyncBody(
              value: home,
              onRetry: () => ref.invalidate(studentHomeProvider),
              errorTitle: 'Couldn’t load your room',
              loading: const SizedBox(height: 300, child: Center(child: CircularProgressIndicator())),
              data: (home) => home == null ? _Unassigned(email: user?.email ?? '') : _Assigned(home: home),
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
    final open = (issues.value ?? const []).where((i) => i.isOpen).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RoomHero(home: home),
        const SizedBox(height: 20),
        BigButton(
          label: 'Report an issue',
          icon: Symbols.add_circle_rounded,
          filledIcon: true,
          variant: BigButtonVariant.nudge,
          height: 64,
          fontSize: 17,
          onPressed: () {
            ref.read(reportDraftProvider.notifier).reset();
            context.push(Routes.report);
          },
        ),
        const SizedBox(height: 20),
        SectionHeader(
          title: 'My open issues',
          count: issues.hasValue ? open.length : null,
          trailing: InlineAction('See all', onPressed: () => context.go(Routes.studentIssues)),
        ),
        const SizedBox(height: 4),
        if (issues.isLoading && !issues.hasValue)
          const IssueCardSkeleton()
        else if (open.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('Nothing open. If something breaks, report it and follow the fix here.',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: AppColors.onSurfaceVariant)),
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

/// Navy "My room" card with the mark as a watermark.
class _RoomHero extends StatelessWidget {
  const _RoomHero({required this.home});

  final StudentHome home;

  @override
  Widget build(BuildContext context) {
    final room = home.room;
    Widget fact(String label, String value) => Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.onNavyMuted)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.chalk)),
          ]),
        );
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(20)),
      child: Stack(children: [
        const Positioned(
          right: -18,
          top: -14,
          child: Opacity(opacity: .14, child: StamsMark(size: 120, barColor: AppColors.chalk)),
        ),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('MY ROOM',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 11 * .12, color: AppColors.onNavyMuted)),
            const SizedBox(height: 4),
            Text('${room.name} · ${room.description[0].toUpperCase()}${room.description.substring(1)}',
                style: const TextStyle(fontSize: 24, height: 30 / 24, fontWeight: FontWeight.w700, color: AppColors.chalk)),
            const SizedBox(height: 4),
            Text(home.propertyName, style: const TextStyle(fontSize: 14, color: AppColors.onNavySoft)),
            const SizedBox(height: 16),
            Container(height: 1, color: const Color(0x2EF5F3EC)),
            const SizedBox(height: 14),
            Row(children: [
              fact(
                home.roommates.isEmpty ? 'Room' : 'Sharing with',
                home.roommates.isEmpty ? 'Just you' : home.roommates.map((s) => s.name).join(', '),
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

/// S1u - waiting for the landlord to add them to a room.
class _Unassigned extends StatelessWidget {
  const _Unassigned({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final pending = context.statusColors.acknowledged;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomPaint(
          painter: const _DashedBorder(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(children: [
              IconCircle(Symbols.hourglass_top_rounded, size: 72, background: pending.container, foreground: pending.onContainer, filled: false),
              const SizedBox(height: 12),
              Text('You’re not in a room yet', textAlign: TextAlign.center, style: t.titleLarge!.copyWith(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Text(
                'Your landlord adds you to a room using your email. We’ll notify you as soon as it’s done.',
                textAlign: TextAlign.center,
                style: t.bodyLarge!.copyWith(fontSize: 15, height: 22 / 15, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 12),
              const Text('Share this with your landlord if they ask.', style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
            ]),
          ),
        ),
        const SizedBox(height: 20),
        const BigButton(label: 'Report an issue', icon: Symbols.add_circle_rounded, height: 64, fontSize: 17, onPressed: null),
        const SizedBox(height: 8),
        const Text(
          'Available once you’re assigned to a room.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, height: 18 / 13, color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _DashedBorder extends CustomPainter {
  const _DashedBorder();

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(20)).deflate(0.75);
    canvas.drawRRect(rrect, Paint()..color = Colors.white);
    final paint = Paint()
      ..color = AppColors.hoverBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      for (double d = 0; d < metric.length; d += 10) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder oldDelegate) => false;
}
