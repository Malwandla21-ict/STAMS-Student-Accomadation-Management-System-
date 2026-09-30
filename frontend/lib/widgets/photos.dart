import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../models/issue.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Diagonal-striped placeholder, as in the design's photo slots.
class StripedBox extends StatelessWidget {
  const StripedBox({super.key, this.stripe = 8, this.child, this.radius = AppRadius.large});

  final double stripe;
  final Widget? child;
  final double radius;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CustomPaint(
          painter: _StripePainter(stripe),
          child: Center(child: child),
        ),
      );
}

class _StripePainter extends CustomPainter {
  _StripePainter(this.stripe);

  final double stripe;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.stripeB);
    final paint = Paint()
      ..color = AppColors.stripeA
      ..strokeWidth = stripe * math.sqrt1_2 * 1.0;
    final step = stripe * 2 * math.sqrt2;
    for (double x = -size.height; x < size.width + size.height; x += step) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), paint);
    }
  }

  @override
  bool shouldRepaint(_StripePainter old) => old.stripe != stripe;
}

/// Renders an [IssuePhoto] whether it's a URL, local bytes or a demo placeholder.
class IssuePhotoView extends StatelessWidget {
  const IssuePhotoView(this.photo, {super.key, this.radius = AppRadius.large, this.caption = true});

  final IssuePhoto photo;
  final double radius;
  final bool caption;

  @override
  Widget build(BuildContext context) {
    if (photo.bytes != null) {
      return ClipRRect(borderRadius: BorderRadius.circular(radius), child: Image.memory(photo.bytes!, fit: BoxFit.cover));
    }
    if (photo.url != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.network(
          photo.url!,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => StripedBox(radius: radius, child: const Icon(Symbols.broken_image_rounded, color: AppColors.outline)),
        ),
      );
    }
    return StripedBox(
      radius: radius,
      child: caption && photo.label != null
          ? Text(
              photo.label!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.4, color: AppColors.onSurfaceVariant),
            )
          : null,
    );
  }
}

/// Swipeable photo header with a "1 / 2" counter (L3, S6).
class PhotoCarousel extends StatefulWidget {
  const PhotoCarousel({super.key, required this.photos, this.height = 190});

  final List<IssuePhoto> photos;
  final double height;

  @override
  State<PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<PhotoCarousel> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;
    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: photos.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: SizedBox.expand(child: IssuePhotoView(photos[i])),
            ),
          ),
          if (photos.length > 1)
            Positioned(
              right: 10,
              bottom: 10,
              child: Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(color: const Color(0xB815202B), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Symbols.photo_library_rounded, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text('${_page + 1} / ${photos.length}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
