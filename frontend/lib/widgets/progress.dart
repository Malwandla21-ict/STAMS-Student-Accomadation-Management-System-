import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../models/enums.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Thin segmented bar: [done] of [total] segments filled. Used by the setup
/// checklist and the student's issue tracker.
class SegmentedProgress extends StatelessWidget {
  const SegmentedProgress({super.key, required this.done, required this.total, this.color = AppColors.tertiary, this.height = 6});

  final int done;
  final int total;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => Semantics(
        label: '$done of $total done',
        child: Row(children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: i < done ? 1 : 0),
                duration: Duration(milliseconds: 350 + i * 80),
                curve: Curves.easeOutCubic,
                builder: (context, t, _) => Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: Color.lerp(AppColors.surfaceHighest, color, t),
                    borderRadius: BorderRadius.circular(height),
                  ),
                ),
              ),
            ),
          ],
        ]),
      );
}

/// Friendly, student-facing names for each stage of a repair.
extension FriendlyStatus on IssueStatus {
  String get friendly => switch (this) {
        IssueStatus.reported => 'Reported',
        IssueStatus.acknowledged => 'Seen',
        IssueStatus.inProgress => 'Fixing',
        IssueStatus.resolved => 'Fixed',
      };
}

/// "Reported → Seen → Fixing → Fixed" tracker for students.
/// [compact] is the one-line version on issue cards.
class IssueProgress extends StatelessWidget {
  const IssueProgress({super.key, required this.status, this.landlordFirstName, this.compact = false});

  final IssueStatus status;
  final String? landlordFirstName;
  final bool compact;

  String get _caption => switch (status) {
        IssueStatus.reported => '${landlordFirstName ?? 'Your landlord'} has been told',
        IssueStatus.acknowledged => '${landlordFirstName ?? 'Your landlord'} has seen it',
        IssueStatus.inProgress => 'Being fixed',
        IssueStatus.resolved => 'All fixed',
      };

  @override
  Widget build(BuildContext context) {
    final done = status.index + 1;
    final color = status == IssueStatus.resolved ? const Color(0xFF2E9E62) : AppColors.tertiary;
    final small = Theme.of(context).textTheme.bodySmall!.copyWith(color: AppColors.onSurfaceVariant);
    if (compact) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SegmentedProgress(done: done, total: 4, color: color, height: 4),
        const SizedBox(height: 6),
        Text('${status.friendly} · $_caption', style: small),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SegmentedProgress(done: done, total: 4, color: color),
      const SizedBox(height: 8),
      Row(children: [
        for (final s in IssueStatus.values)
          Expanded(
            child: Text(
              s.friendly,
              textAlign: switch (s.index) { 0 => TextAlign.left, 3 => TextAlign.right, _ => TextAlign.center },
              style: small.copyWith(
                fontWeight: s == status ? FontWeight.w700 : FontWeight.w500,
                color: s.index <= status.index ? AppColors.onSurface : AppColors.onSurfaceVariant,
              ),
            ),
          ),
      ]),
    ]);
  }
}

class ChecklistStep {
  const ChecklistStep({required this.label, required this.done, this.hint, this.actionLabel, this.onAction});

  final String label;
  final bool done;

  /// Shown under the label while this is the next step.
  final String? hint;
  final String? actionLabel;
  final VoidCallback? onAction;
}

/// "Set up your properties · 2 of 4" card with a progress bar, ticks for finished
/// steps and a button for the next one.
class ChecklistCard extends StatelessWidget {
  const ChecklistCard({super.key, required this.title, required this.steps, this.subtitle});

  final String title;
  final String? subtitle;
  final List<ChecklistStep> steps;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final done = steps.where((s) => s.done).length;
    final next = steps.indexWhere((s) => !s.done);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.softIris,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.tertiaryContainer),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text(title, style: t.titleMedium)),
          Text('$done of ${steps.length}', style: t.labelLarge!.copyWith(color: AppColors.onTertiaryContainer)),
        ]),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle!, style: t.bodySmall!.copyWith(color: AppColors.onSurfaceVariant)),
        ],
        const SizedBox(height: 12),
        SegmentedProgress(done: done, total: steps.length),
        const SizedBox(height: 8),
        for (final (i, step) in steps.indexed) _StepRow(step: step, isNext: i == next),
      ]),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.isNext});

  final ChecklistStep step;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final Widget marker = step.done
        ? const Icon(Symbols.check_circle_rounded, size: 22, color: Color(0xFF2E9E62), fill: 1)
        : Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: isNext ? AppColors.tertiary : AppColors.outlineVariant, width: 2),
            ),
          );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        marker,
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              step.label,
              style: t.bodyMedium!.copyWith(
                fontWeight: isNext ? FontWeight.w600 : FontWeight.w400,
                color: step.done ? AppColors.onSurfaceVariant : AppColors.onSurface,
                decoration: step.done ? TextDecoration.lineThrough : null,
                decorationColor: AppColors.onSurfaceVariant,
              ),
            ),
            if (isNext && step.hint != null)
              Text(step.hint!, style: t.bodySmall!.copyWith(color: AppColors.onSurfaceVariant)),
          ]),
        ),
        if (isNext && step.onAction != null)
          FilledButton.tonal(
            onPressed: step.onAction,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              backgroundColor: AppColors.tertiaryContainer,
              foregroundColor: AppColors.onTertiaryContainer,
              textStyle: t.labelLarge!.copyWith(fontSize: 13),
            ),
            child: Text(step.actionLabel ?? 'Start'),
          ),
      ]),
    );
  }
}
