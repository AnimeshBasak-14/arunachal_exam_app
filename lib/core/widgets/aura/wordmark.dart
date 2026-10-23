import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/aura.dart';

/// App name with a thin-line sun ("Donyi" is the Sun in the Donyi-Polo
/// tradition of Arunachal Pradesh).
class Wordmark extends StatelessWidget {
  final double size;
  const Wordmark({super.key, this.size = 22});

  static const appName = 'Donyi Prep';

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return Semantics(
      label: appName,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(size: Size.square(size * 1.15), painter: _SunPainter(a.accent)),
          SizedBox(width: size * 0.45),
          Text(appName, style: AuraType.serif(size, a.ink, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SunPainter extends CustomPainter {
  final Color color;
  _SunPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width * 0.22;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r, p);
    for (int i = 0; i < 8; i++) {
      final t = i * math.pi / 4;
      final d = Offset(math.cos(t), math.sin(t));
      canvas.drawLine(c + d * (r + size.width * 0.1), c + d * (size.width * 0.48), p);
    }
  }

  @override
  bool shouldRepaint(covariant _SunPainter old) => old.color != color;
}
