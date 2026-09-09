import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Glowing countdown ring for the quiz timer.
///
/// Renders as a CustomPaint circular arc that depletes clockwise.
/// Color transitions:
///   - Emerald (#2E8B57)  when timeLeft > totalSeconds * 0.5
///   - Amber  (#F59E0B)   when timeLeft <= totalSeconds * 0.5
///   - Red    (#EF4444)   when timeLeft <= 10s  (+ flashing animation)
///
/// Usage:
/// ```dart
/// AntigravityTimerRing(
///   timeLeft: _secondsRemaining,
///   totalTime: _initialSeconds,
///   size: 56,
/// )
/// ```
class AntigravityTimerRing extends StatefulWidget {
  final int timeLeft;
  final int totalTime;
  final double size;
  final double strokeWidth;

  const AntigravityTimerRing({
    super.key,
    required this.timeLeft,
    required this.totalTime,
    this.size = 56,
    this.strokeWidth = 4.0,
  });

  @override
  State<AntigravityTimerRing> createState() => _AntigravityTimerRingState();
}

class _AntigravityTimerRingState extends State<AntigravityTimerRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _flash;
  late Animation<double> _flashAnim;

  @override
  void initState() {
    super.initState();
    _flash = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _flashAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _flash, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(AntigravityTimerRing old) {
    super.didUpdateWidget(old);
    if (widget.timeLeft <= 10 && !_flash.isAnimating) {
      _flash.repeat(reverse: true);
    } else if (widget.timeLeft > 10 && _flash.isAnimating) {
      _flash.stop();
      _flash.value = 1.0;
    }
  }

  @override
  void dispose() {
    _flash.dispose();
    super.dispose();
  }

  Color get _ringColor {
    final ratio = widget.totalTime > 0
        ? widget.timeLeft / widget.totalTime
        : 0.0;
    if (widget.timeLeft <= 10) return AppColors.error;
    if (ratio <= 0.5) return AppColors.accent;
    return AppColors.primary;
  }

  List<BoxShadow> get _glowShadow {
    final c = _ringColor;
    return [
      BoxShadow(
        color: c.withValues(alpha: 0.5),
        blurRadius: 16,
        spreadRadius: 2,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.totalTime > 0
        ? widget.timeLeft / widget.totalTime
        : 0.0;
    final mins = widget.timeLeft ~/ 60;
    final secs = widget.timeLeft % 60;
    final timeStr = mins > 0
        ? '$mins:${secs.toString().padLeft(2, '0')}'
        : '${widget.timeLeft}';

    return AnimatedBuilder(
      animation: _flashAnim,
      builder: (context, _) {
        final opacity = widget.timeLeft <= 10 ? _flashAnim.value : 1.0;
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: _glowShadow,
          ),
          child: Opacity(
            opacity: opacity,
            child: CustomPaint(
              painter: _RingPainter(
                progress: progress,
                color: _ringColor,
                strokeWidth: widget.strokeWidth,
                trackColor: Colors.white.withValues(alpha: 0.08),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: widget.size * 0.22,
                        fontWeight: FontWeight.bold,
                        color: _ringColor,
                        fontFamily: 'Poppins',
                        height: 1.0,
                      ),
                    ),
                    if (mins > 0)
                      Text(
                        'min',
                        style: TextStyle(
                          fontSize: widget.size * 0.13,
                          color: AppColors.textSecondary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final Color trackColor;

  const _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    const startAngle = -math.pi / 2; // 12 o'clock

    // Track ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Progress arc — glowing
    if (progress > 0) {
      final sweepAngle = 2 * math.pi * progress;
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, strokeWidth * 0.6);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      // Second crisp pass on top for sharpness
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth * 0.6
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
