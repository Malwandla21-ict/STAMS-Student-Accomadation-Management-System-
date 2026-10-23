import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../data/api_client.dart';
import '../models/issue.dart';
import '../theme/app_colors.dart';
import '../utils/format.dart';
import 'buttons.dart';
import 'common.dart';

/// The student's nudge control (S6a-c). States:
///  1. available  - iris button
///  2. just sent  - tonal confirmation for 3s
///  3. cooling down - disabled, countdown refreshed every minute
///  (4. resolved - not rendered; the caller shows something else)
class NudgeButton extends StatefulWidget {
  const NudgeButton({super.key, required this.issue, required this.landlordFirstName, required this.onNudge});

  final Issue issue;
  final String landlordFirstName;
  final Future<void> Function() onNudge;

  @override
  State<NudgeButton> createState() => _NudgeButtonState();
}

class _NudgeButtonState extends State<NudgeButton> {
  bool _sending = false;
  bool _justSent = false;
  Timer? _sentTimer;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // Countdown text updates each minute.
    _tick = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sentTimer?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _nudge() async {
    setState(() => _sending = true);
    try {
      await widget.onNudge();
      if (!mounted) return;
      setState(() => _justSent = true);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Symbols.notifications_active_rounded, size: 20, color: AppColors.inversePrimary, fill: 1),
            const SizedBox(width: 12),
            Expanded(child: Text('${widget.landlordFirstName} has been nudged')),
          ]),
          action: SnackBarAction(label: 'OK', onPressed: () {}),
        ));
      _sentTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _justSent = false);
      });
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final issue = widget.issue;
    if (!issue.isOpen) return const SizedBox.shrink();
    final name = widget.landlordFirstName;
    final now = DateTime.now();
    final next = issue.nextNudgeAt(now);

    final (Widget button, String helper) = switch ((_justSent, next)) {
      (true, _) => (
          _Pill(
            background: AppColors.tertiaryContainer,
            foreground: AppColors.onTertiaryContainer,
            icon: Symbols.check_circle_rounded,
            filled: true,
            label: 'Nudge sent',
          ),
          '$name was notified just now. You can nudge again in 24 hours.',
        ),
      (false, final DateTime next?) => (
          Semantics(
            enabled: false,
            button: true,
            child: _Pill(
              background: AppColors.surfaceContainer,
              foreground: AppColors.onSurfaceVariant,
              border: AppColors.surfaceHighest,
              icon: Symbols.schedule_rounded,
              label: 'Nudge again in ${Fmt.countdown(next.difference(now))}',
            ),
          ),
          'Last nudged ${Fmt.ago(issue.lastNudgedAt!)} · ${Fmt.plural(issue.nudgeCount, 'nudge')} sent on this issue',
        ),
      _ => (
          BigButton(
            label: 'Nudge $name',
            icon: Symbols.notifications_active_rounded,
            filledIcon: true,
            variant: BigButtonVariant.soft,
            loading: _sending,
            onPressed: _nudge,
          ),
          'Sends $name a reminder about this issue. You can nudge once every 24 hours.',
        ),
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(duration: const Duration(milliseconds: 200), child: KeyedSubtree(key: ValueKey(helper), child: button)),
        const SizedBox(height: 8),
        Text(
          helper,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 13, height: 18 / 13, color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.background, required this.foreground, required this.icon, required this.label, this.border, this.filled = false});

  final Color background;
  final Color foreground;
  final Color? border;
  final IconData icon;
  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) => Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: border == null ? null : Border.all(color: border!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: foreground, fill: filled ? 1 : 0),
            const SizedBox(width: 10),
            Text(label, style: Theme.of(context).textTheme.labelLarge!.copyWith(fontSize: 16, color: foreground)),
          ],
        ),
      );
}
