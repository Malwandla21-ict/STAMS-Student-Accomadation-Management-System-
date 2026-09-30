import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../models/enums.dart';
import '../models/issue.dart';
import '../theme/app_colors.dart';
import '../theme/semantic_colors.dart';
import '../utils/format.dart';

/// Issue timeline, newest first. Same status palette + icons as the chips;
/// nudges interleave as tertiary events; the current step gets a ring and the
/// next step (Resolved) sits on top, outlined.
///
/// [compact] is the student's version inside a white "Progress" card (28dp nodes);
/// the landlord's version sits on the page (32dp nodes).
class StatusTimeline extends StatelessWidget {
  const StatusTimeline({super.key, required this.issue, required this.viewer, this.compact = false});

  final Issue issue;
  final Role viewer;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final steps = _buildSteps(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < steps.length; i++) _StepRow(step: steps[i], last: i == steps.length - 1, compact: compact),
      ],
    );
  }

  bool get _landlordView => viewer == Role.landlord;
  String _first(String name) => name.split(' ').first;

  List<_Step> _buildSteps(BuildContext context) {
    final colors = context.statusColors;
    final steps = <_Step>[];

    if (issue.isOpen) {
      steps.add(_Step(
        kind: _Kind.pending,
        icon: colors.resolved.icon,
        title: IssueStatus.resolved.label,
        subtitle: _landlordView ? 'Next step' : 'Waiting',
      ));
    }

    final currentStatusEvent = issue.events.lastWhere(
      (e) => e.status != null && (e.type == IssueEventType.reported || e.type == IssueEventType.statusChanged),
      orElse: () => issue.events.first,
    );

    // Walk newest-first, folding runs of consecutive nudges into one row.
    final events = issue.events.reversed.toList();
    for (var i = 0; i < events.length; i++) {
      final e = events[i];
      switch (e.type) {
        case IssueEventType.nudged:
          var j = i;
          while (j + 1 < events.length && events[j + 1].type == IssueEventType.nudged) {
            j++;
          }
          final newest = e;
          final oldest = events[j];
          final numbers = oldest.nudgeNumber == newest.nudgeNumber
              ? '#${newest.nudgeNumber}'
              : '#${oldest.nudgeNumber}–${newest.nudgeNumber}';
          final plural = oldest != newest;
          steps.add(_Step(
            kind: _Kind.nudge,
            icon: Symbols.notifications_active_rounded,
            title: _landlordView
                ? '${plural ? 'Nudges' : 'Nudge'} $numbers from ${_first(e.actorName)}'
                : 'You nudged ${_first(issue.landlordName)} · $numbers',
            subtitle: plural ? Fmt.range(oldest.createdAt, newest.createdAt) : _stamp(e),
          ));
          i = j;
        case IssueEventType.reported:
        case IssueEventType.statusChanged:
          final status = e.status ?? IssueStatus.reported;
          final isCurrent = identical(e, currentStatusEvent);
          final byLandlord = e.type == IssueEventType.statusChanged;
          final title = !_landlordView && byLandlord && status != IssueStatus.inProgress
              ? '${status.label} by ${_first(e.actorName)}'
              : status.label;
          steps.add(_Step(
            kind: _Kind.status,
            style: colors.of(status),
            icon: colors.of(status).icon,
            title: title,
            current: isCurrent,
            currentLabel: isCurrent && status.isOpen ? 'Current' : null,
            subtitle: _stamp(e),
            note: e.note,
            noteBy: !_landlordView && isCurrent && status.isOpen ? _first(e.actorName) : null,
          ));
        case IssueEventType.priorityChanged:
          steps.add(_Step(
            kind: _Kind.neutral,
            icon: context.priorityColors.of(e.priority!).icon,
            title: 'Priority set to ${e.priority!.label}',
            subtitle: _stamp(e),
          ));
        case IssueEventType.noteAdded:
          steps.add(_Step(
            kind: _Kind.neutral,
            icon: Symbols.chat_rounded,
            title: _landlordView ? 'You added a note' : 'Note from ${_first(e.actorName)}',
            subtitle: _stamp(e),
            note: e.note,
          ));
      }
    }
    return steps;
  }

  String _stamp(IssueEvent e) {
    final when = Fmt.stamp(e.createdAt);
    if (!_landlordView) return when;
    final who = e.type == IssueEventType.reported || e.type == IssueEventType.nudged ? e.actorName : 'You';
    return '$when · $who';
  }
}

enum _Kind { pending, status, nudge, neutral }

class _Step {
  const _Step({
    required this.kind,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.style,
    this.current = false,
    this.currentLabel,
    this.note,
    this.noteBy,
  });

  final _Kind kind;
  final IconData icon;
  final String title;
  final String subtitle;
  final SemanticStyle? style;
  final bool current;
  final String? currentLabel;
  final String? note;
  final String? noteBy;
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.last, required this.compact});

  final _Step step;
  final bool last;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final node = compact ? 28.0 : 32.0;
    final ringGap = compact ? Colors.white : AppColors.surface;
    final titleSize = compact ? 14.0 : 15.0;
    final subSize = compact ? 12.0 : 13.0;

    final (Color? bg, Color fg) = switch (step.kind) {
      _Kind.pending => (null, AppColors.outline),
      _Kind.status => (step.style!.container, step.style!.onContainer),
      _Kind.nudge => (AppColors.tertiaryContainer, AppColors.onTertiaryContainer),
      _Kind.neutral => (AppColors.surfaceContainer, AppColors.onSurfaceVariant),
    };

    final circle = Container(
      width: node,
      height: node,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: step.kind == _Kind.pending ? Border.all(color: AppColors.hoverBorder, width: 2) : null,
        boxShadow: step.current
            ? [BoxShadow(color: ringGap, spreadRadius: 3), BoxShadow(color: fg, spreadRadius: 5)]
            : null,
      ),
      child: Icon(step.icon, size: compact ? 16 : 18, color: fg, fill: step.kind == _Kind.pending ? 0 : 1),
    );

    final t = Theme.of(context).textTheme;
    final titleColor = switch (step.kind) {
      _Kind.pending => AppColors.onSurfaceVariant,
      _Kind.nudge => AppColors.onTertiaryContainer,
      _ => AppColors.onSurface,
    };

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              circle,
              if (!last)
                Expanded(
                  child: Container(
                    constraints: BoxConstraints(minHeight: compact ? 10 : 14),
                    width: 2,
                    child: step.kind == _Kind.pending
                        ? const CustomPaint(painter: _DashedLine())
                        : const ColoredBox(color: AppColors.outlineVariant),
                  ),
                ),
            ],
          ),
          SizedBox(width: compact ? 12 : 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: compact ? 4 : 5, bottom: last ? (compact ? 12 : 0) : (compact ? 12 : 18)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(TextSpan(
                    text: step.title,
                    style: t.titleSmall!.copyWith(fontSize: titleSize, height: 1.3, color: titleColor),
                    children: [
                      if (step.currentLabel != null)
                        TextSpan(
                          text: ' · ${step.currentLabel}',
                          style: TextStyle(fontSize: 12, color: step.style?.onContainer, fontWeight: FontWeight.w600),
                        ),
                    ],
                  )),
                  const SizedBox(height: 2),
                  Text(step.subtitle, style: t.bodySmall!.copyWith(fontSize: subSize, color: AppColors.onSurfaceVariant)),
                  if (step.note != null && step.note!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _NoteBubble(note: step.note!, by: step.noteBy, compact: compact),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteBubble extends StatelessWidget {
  const _NoteBubble({required this.note, required this.by, required this.compact});

  final String note;
  final String? by;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    if (compact) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: AppColors.surfaceLow, borderRadius: BorderRadius.circular(10)),
        child: Text('“$note”${by == null ? '' : ' — $by'}', style: t.bodyMedium!.copyWith(fontSize: 13, height: 18 / 13)),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.surfaceHighest),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(note, style: t.bodyMedium),
    );
  }
}

class _DashedLine extends CustomPainter {
  const _DashedLine();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.outlineVariant
      ..strokeWidth = size.width;
    for (double y = 0; y < size.height; y += 8) {
      canvas.drawLine(Offset(size.width / 2, y), Offset(size.width / 2, (y + 4).clamp(0, size.height)), paint);
    }
  }

  @override
  bool shouldRepaint(_DashedLine oldDelegate) => false;
}
