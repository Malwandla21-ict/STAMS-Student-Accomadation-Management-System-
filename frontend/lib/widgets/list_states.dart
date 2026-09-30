import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../data/api_client.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'buttons.dart';

/// Skeleton shimmer - 1.2s sweep, keeps the real card height so nothing jumps.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final x = _controller.value * 3 - 1;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment(x - 1, 0),
            end: Alignment(x + 1, 0),
            colors: const [Color(0x00FFFFFF), Color(0x99FFFFFF), Color(0x00FFFFFF)],
          ).createShader(rect),
          child: child,
        );
      },
    );
  }
}

class _Bone extends StatelessWidget {
  const _Bone({required this.height, this.width, this.widthFactor, this.radius});

  final double height;
  final double? width;
  final double? widthFactor;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      height: height,
      width: width,
      decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(radius ?? height / 2)),
    );
    return widthFactor == null ? box : FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: widthFactor, child: box);
  }
}

/// Placeholder in the shape of an [IssueCard].
class IssueCardSkeleton extends StatelessWidget {
  const IssueCardSkeleton({super.key, this.titleFactor = 0.85, this.chipWidth = 104});

  final double titleFactor;
  final double chipWidth;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.surfaceHighest),
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const _Bone(height: 56, width: 56, radius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _Bone(height: 14, widthFactor: titleFactor),
                  const SizedBox(height: 8),
                  const _Bone(height: 12, widthFactor: 0.6),
                ]),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [_Bone(height: 28, width: chipWidth), const SizedBox(width: 8), const _Bone(height: 24, width: 60, radius: 4)]),
            const SizedBox(height: 12),
            const Divider(color: AppColors.surfaceContainer),
            const SizedBox(height: 10),
            const _Bone(height: 10, widthFactor: 0.4),
          ],
        ),
      );
}

/// Three fading skeleton cards.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.padding = const EdgeInsets.fromLTRB(20, 0, 20, 20)});

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Loading',
        child: Shimmer(
          child: ListView(
            padding: padding,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              IssueCardSkeleton(),
              SizedBox(height: 12),
              Opacity(opacity: .75, child: IssueCardSkeleton(titleFactor: .7, chipWidth: 120)),
              SizedBox(height: 12),
              Opacity(opacity: .5, child: IssueCardSkeleton(titleFactor: .8, chipWidth: 96)),
            ],
          ),
        ),
      );
}

/// Centered icon + title + message + optional action. Used for empty and error states.
class StateMessage extends StatelessWidget {
  const StateMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.iconBackground = AppColors.surfaceContainer,
    this.iconForeground = AppColors.onSurfaceVariant,
    this.action,
    this.size = 88,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color iconBackground;
  final Color iconForeground;
  final Widget? action;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(40, 0, 40, 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(color: iconBackground, shape: BoxShape.circle),
              child: Icon(icon, size: size / 2, color: iconForeground),
            ),
            const SizedBox(height: 20),
            Text(title, textAlign: TextAlign.center, style: t.titleLarge!.copyWith(fontSize: 20)),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: t.bodyLarge!.copyWith(fontSize: 15, height: 22 / 15, color: AppColors.onSurfaceVariant)),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

class ErrorMessage extends StatelessWidget {
  const ErrorMessage({super.key, required this.error, required this.title, required this.onRetry, this.message});

  final Object error;
  final String title;
  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final api = ApiException.from(error);
    return StateMessage(
      icon: Symbols.cloud_off_rounded,
      iconBackground: AppColors.errorContainer,
      iconForeground: AppColors.onErrorContainer,
      title: title,
      message: message ?? (api.isNetwork ? 'Check your connection and try again.' : api.message),
      action: BigButton(label: 'Try again', icon: Symbols.refresh_rounded, height: 48, fontSize: 14, expand: false, onPressed: onRetry),
    );
  }
}

/// Red "You're offline" strip (S5x).
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: AppColors.errorContainer, borderRadius: BorderRadius.circular(AppRadius.medium)),
        child: const Row(children: [
          Icon(Symbols.wifi_off_rounded, size: 18, color: AppColors.onErrorContainer),
          SizedBox(width: 10),
          Text("You're offline", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onErrorContainer)),
        ]),
      );
}

/// Small helper so every async screen handles loading / error / data the same way.
class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({super.key, required this.value, required this.data, required this.onRetry, this.errorTitle = 'Couldn’t load this', this.loading});

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback onRetry;
  final String errorTitle;
  final Widget? loading;

  @override
  Widget build(BuildContext context) {
    // Keep showing old data while refreshing so pull-to-refresh doesn't flash.
    if (value.hasValue) return data(value.requireValue);
    if (value.hasError) return ErrorMessage(error: value.error!, title: errorTitle, onRetry: onRetry);
    return loading ?? const Center(child: CircularProgressIndicator());
  }
}
