import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

/// The Roofline mark: an iris roof over two navy bars (64x64 grid).
/// On navy backgrounds pass [barColor] = chalk for the reversed version.
class StamsMark extends StatelessWidget {
  const StamsMark({super.key, this.size = 48, this.roofColor = AppColors.brandIris, this.barColor = AppColors.navy});

  final double size;
  final Color roofColor;
  final Color barColor;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'STAMS',
        image: true,
        child: CustomPaint(size: Size.square(size), painter: _MarkPainter(roofColor, barColor)),
      );
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.roof, this.bars);

  final Color roof;
  final Color bars;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 64);
    final roofPath = Path()
      ..moveTo(4, 29)
      ..lineTo(32, 6)
      ..lineTo(60, 29)
      ..lineTo(54, 36)
      ..lineTo(32, 18)
      ..lineTo(10, 36)
      ..close();
    canvas.drawPath(roofPath, Paint()..color = roof);
    final barPaint = Paint()..color = bars;
    for (final y in [38.0, 51.0]) {
      canvas.drawRRect(RRect.fromLTRBR(14, y, 50, y + 8, const Radius.circular(4)), barPaint);
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.roof != roof || old.bars != bars;
}

/// Outlined "STAMS" wordmark (Archivo ExtraBold, 125% width) from the brand export.
class StamsWordmark extends StatelessWidget {
  const StamsWordmark({super.key, this.height = 38, this.color = AppColors.navy});

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
        'stams-1c-roofline/lockup/stams-wordmark.svg',
        height: height,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        semanticsLabel: 'STAMS',
      );
}
