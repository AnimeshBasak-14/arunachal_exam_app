import 'package:flutter/material.dart';
import '../../theme/aura.dart';

/// App name beside the ZAP mark: a Z whose top stroke is a horizon with a
/// peak, and the sun beside it (see brand/README.md).
class Wordmark extends StatelessWidget {
  final double size;
  const Wordmark({super.key, this.size = 22});

  /// Single place to change the product name.
  static const appName = 'Dawnlit';

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return Semantics(
      label: appName,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ZapMark(size: size * 1.25, color: a.accent),
          SizedBox(width: size * 0.45),
          Text(appName, style: AuraType.serif(size, a.ink, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class ZapMark extends StatelessWidget {
  final double size;
  final Color color;
  const ZapMark({super.key, required this.size, required this.color});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _MarkPainter(color));
}

/// Same geometry as brand/zap_mark.svg, on a 64-unit grid.
class _MarkPainter extends CustomPainter {
  final Color color;
  _MarkPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 64;
    canvas.scale(k);
    canvas.drawCircle(const Offset(47, 12), 4.6, Paint()..color = color);
    final z = Path()
      ..moveTo(11, 27)
      ..lineTo(19, 27)
      ..lineTo(30, 14)
      ..lineTo(41, 27)
      ..lineTo(53, 27)
      ..lineTo(11, 53)
      ..lineTo(53, 53);
    canvas.drawPath(
      z,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _MarkPainter old) => old.color != color;
}
