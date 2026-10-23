import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'buttons.dart';

/// A small "well done" moment: a confetti burst behind a card with what just
/// happened and, optionally, the next thing to do.
///
/// Pass a context that outlives the current screen (e.g. the root navigator's)
/// when the caller is about to close itself.
Future<void> celebrate(
  BuildContext context, {
  required String emoji,
  required String title,
  required String message,
  String? nextLabel,
  VoidCallback? onNext,
}) {
  HapticFeedback.lightImpact();
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: const Color(0x52102A43),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (context, _, _) => _Celebration(
      emoji: emoji,
      title: title,
      message: message,
      nextLabel: nextLabel,
      onNext: onNext,
    ),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn);
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: Tween(begin: .92, end: 1.0).animate(curved), child: child),
      );
    },
  );
}

class _Celebration extends StatelessWidget {
  const _Celebration({required this.emoji, required this.title, required this.message, this.nextLabel, this.onNext});

  final String emoji;
  final String title;
  final String message;
  final String? nextLabel;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Stack(children: [
      const Positioned.fill(child: ConfettiBurst()),
      Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.extraLarge),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: AppColors.softIris, shape: BoxShape.circle),
                  child: Text(emoji, style: const TextStyle(fontSize: 34)),
                ),
                const SizedBox(height: 16),
                Text(title, textAlign: TextAlign.center, style: t.titleLarge),
                const SizedBox(height: 8),
                Text(message,
                    textAlign: TextAlign.center, style: t.bodyMedium!.copyWith(color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 20),
                if (nextLabel != null && onNext != null) ...[
                  BigButton(
                    label: nextLabel!,
                    variant: BigButtonVariant.soft,
                    height: 48,
                    fontSize: 15,
                    onPressed: () {
                      Navigator.of(context).pop();
                      onNext!();
                    },
                  ),
                  const SizedBox(height: 4),
                  BigButton(label: 'Later', variant: BigButtonVariant.text, height: 44, fontSize: 14, onPressed: () => Navigator.of(context).pop()),
                ] else
                  BigButton(label: 'Nice!', variant: BigButtonVariant.soft, height: 48, fontSize: 15, onPressed: () => Navigator.of(context).pop()),
              ]),
            ),
          ),
        ),
      ),
    ]);
  }
}



/// One burst of confetti over whatever it's stacked on. Plays once when it
/// appears; does nothing when the system asks for reduced motion.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key, this.originY = .38});

  /// Where the burst starts, as a fraction of the height.
  final double originY;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
  late final List<_Piece> _pieces;

  @override
  void initState() {
    super.initState();
    final random = math.Random();
    const colors = [
      AppColors.brandIris,
      AppColors.tertiary,
      Color(0xFFFFD166),
      Color(0xFF7ED3A1),
      Color(0xFF8FB8EA),
      Color(0xFFF7A1B5),
    ];
    _pieces = List.generate(46, (_) {
      final angle = -math.pi / 2 + (random.nextDouble() - .5) * math.pi * .9;
      final speed = 380 + random.nextDouble() * 420;
      return _Piece(
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed,
        spin: (random.nextDouble() - .5) * 14,
        size: 5 + random.nextDouble() * 6,
        color: colors[random.nextInt(colors.length)],
        round: random.nextBool(),
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !MediaQuery.of(context).disableAnimations) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(painter: _ConfettiPainter(_pieces, _controller.value, widget.originY)),
        ),
      );
}

class _Piece {
  const _Piece({required this.vx, required this.vy, required this.spin, required this.size, required this.color, required this.round});

  final double vx;
  final double vy;
  final double spin;
  final double size;
  final Color color;
  final bool round;
}

/// Pieces burst up from just above the card, then fall with gravity and fade out.
class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t, this.originY);

  final List<_Piece> pieces;
  final double t;
  final double originY;

  @override
  void paint(Canvas canvas, Size size) {
    if (t == 0 || t == 1) return;
    final seconds = t * 1.8;
    final origin = Offset(size.width / 2, size.height * originY);
    final opacity = (1 - Curves.easeIn.transform(t)).clamp(0.0, 1.0);
    final paint = Paint();
    for (final p in pieces) {
      final dx = p.vx * seconds;
      final dy = p.vy * seconds + 900 * seconds * seconds / 2;
      paint.color = p.color.withValues(alpha: opacity);
      canvas.save();
      canvas.translate(origin.dx + dx, origin.dy + dy);
      canvas.rotate(p.spin * seconds);
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * .5), const Radius.circular(1.5)),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
