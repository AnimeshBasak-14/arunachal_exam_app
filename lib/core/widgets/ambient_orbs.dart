import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../theme/app_colors.dart';

/// Three slow-drifting ambient light orbs on the atmosphere background.
///
/// On mobile (Android/iOS), the orbs also respond to device gyroscope/
/// accelerometer data for a true 3D depth effect (inverse translation).
/// On web and desktop, only mouse-parallax is used.
///
/// Place this as the bottom layer in any Scaffold body Stack.
class AmbientOrbs extends StatefulWidget {
  final Widget? child;
  const AmbientOrbs({super.key, this.child});

  @override
  State<AmbientOrbs> createState() => _AmbientOrbsState();
}

class _AmbientOrbsState extends State<AmbientOrbs>
    with SingleTickerProviderStateMixin {
  late AnimationController _drift;
  Offset _mouseOffset = Offset.zero;
  // Gyro offset (mobile only) — inverse of device tilt
  Offset _gyroOffset = Offset.zero;
  StreamSubscription<AccelerometerEvent>? _accelSub;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);

    // Subscribe to accelerometer on mobile only
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS)) {
      _accelSub = accelerometerEventStream(
        samplingPeriod: SensorInterval.uiInterval,
      ).listen((event) {
        if (!mounted) return;
        setState(() {
          // Inverse translation: tilt left → orbs shift right
          _gyroOffset = Offset(
            -event.y.clamp(-5.0, 5.0) * 3.5,
            event.x.clamp(-5.0, 5.0) * 3.5,
          );
        });
      });
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    _accelSub?.cancel();
    super.dispose();
  }

  void _onMouseMove(PointerEvent event) {
    if (!mounted) return;
    final size = MediaQuery.sizeOf(context);
    setState(() {
      _mouseOffset = Offset(
        (event.position.dx / size.width - 0.5) * 24,
        (event.position.dy / size.height - 0.5) * 24,
      );
    });
  }

  Offset get _combinedOffset => _mouseOffset + _gyroOffset;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerMove: _onMouseMove,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          // Atmosphere background
          Positioned.fill(
            child: Container(color: AppColors.atmosphere),
          ),
          // Orb 1 — Mint tint (top-left)
          _AnimatedOrb(
            drift: _drift,
            mouseOffset: _combinedOffset,
            color: AppColors.orbMint,
            width: 0.50,
            height: 0.50,
            alignment: const Alignment(-0.9, -0.9),
            phaseOffset: 0.0,
            parallaxFactor: 1.0,
          ),
          // Orb 2 — Sky tint (top-right)
          _AnimatedOrb(
            drift: _drift,
            mouseOffset: _combinedOffset,
            color: AppColors.orbSky,
            width: 0.40,
            height: 0.40,
            alignment: const Alignment(0.9, -0.8),
            phaseOffset: 0.33,
            parallaxFactor: 0.8,
          ),
          // Orb 3 — Amber tint (bottom-center)
          _AnimatedOrb(
            drift: _drift,
            mouseOffset: _combinedOffset,
            color: AppColors.orbAmber,
            width: 0.55,
            height: 0.45,
            alignment: const Alignment(0.1, 1.0),
            phaseOffset: 0.66,
            parallaxFactor: 0.6,
          ),
          // Child content on top
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }
}

class _AnimatedOrb extends AnimatedWidget {
  final Offset mouseOffset;
  final Color color;
  final double width;
  final double height;
  final Alignment alignment;
  final double phaseOffset;
  final double parallaxFactor;

  const _AnimatedOrb({
    required Animation<double> drift,
    required this.mouseOffset,
    required this.color,
    required this.width,
    required this.height,
    required this.alignment,
    required this.phaseOffset,
    required this.parallaxFactor,
  }) : super(listenable: drift);

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    final t = (animation.value + phaseOffset) % 1.0;
    // Sinusoidal drift path
    final dx = math.sin(t * 2 * math.pi) * 30;
    final dy = math.cos(t * 2 * math.pi) * 20;

    return Positioned.fill(
      child: Align(
        alignment: alignment,
        child: Transform.translate(
          offset: Offset(
            dx + mouseOffset.dx * parallaxFactor,
            dy + mouseOffset.dy * parallaxFactor,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.sizeOf(context).width;
              final screenHeight = MediaQuery.sizeOf(context).height;
              return ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 110, sigmaY: 110),
                child: Container(
                  width: screenWidth * width,
                  height: screenHeight * height,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        color.withValues(alpha: 0.60),
                        color.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
