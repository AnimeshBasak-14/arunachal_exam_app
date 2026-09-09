import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A reusable glass morphism card that implements the Antigravity design system.
///
/// Features:
/// - Blurred glass background (BackdropFilter, sigmaX/Y: 24)
/// - Top/left highlight border to catch simulated ambient light
/// - Deep shadow (0 20px 40px rgba(0,0,0,0.4))
/// - Spring-physics scale animation on hover/press
/// - Optional colored glow shadow (emerald, amber, red)
class AntigravityGlassCard extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final List<BoxShadow>? glowShadow;
  final Gradient? backgroundGradient;
  final double backgroundOpacity;
  final double blurSigma;
  final VoidCallback? onTap;
  final bool enableHover;
  final double hoverScale;

  const AntigravityGlassCard({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.glowShadow,
    this.backgroundGradient,
    this.backgroundOpacity = 0.75,
    this.blurSigma = 24.0,
    this.onTap,
    this.enableHover = true,
    this.hoverScale = 1.02,
  });

  @override
  State<AntigravityGlassCard> createState() => _AntigravityGlassCardState();
}

class _AntigravityGlassCardState extends State<AntigravityGlassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _translateAnimation;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.hoverScale).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const _SpringCurve(),
      ),
    );
    _translateAnimation = Tween<double>(begin: 0.0, end: -4.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const _SpringCurve(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHoverChange(bool hovering) {
    if (!widget.enableHover) return;
    setState(() => _isHovered = hovering);
    if (hovering) {
      _controller.forward();
    } else if (!_isPressed) {
      _controller.reverse();
    }
  }

  void _onTapDown(TapDownDetails _) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _isPressed = false);
    if (!_isHovered) _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    if (!_isHovered) _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.borderRadius);
    final isInteractive = widget.onTap != null;

    final currentShadow = (_isHovered || _isPressed)
        ? AppColors.glassHoverShadow
        : AppColors.glassShadow;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _translateAnimation.value),
        child: Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
      ),
      child: MouseRegion(
        cursor: isInteractive ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: (_) => _onHoverChange(true),
        onExit: (_) => _onHoverChange(false),
        child: GestureDetector(
          onTapDown: isInteractive ? _onTapDown : null,
          onTapUp: isInteractive ? _onTapUp : null,
          onTapCancel: isInteractive ? _onTapCancel : null,
          child: Container(
            margin: widget.margin,
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: widget.glowShadow ?? currentShadow,
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: widget.blurSigma,
                  sigmaY: widget.blurSigma,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: widget.padding,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                        alpha: (_isHovered || _isPressed)
                            ? 0.90
                            : widget.backgroundOpacity),
                    borderRadius: radius,
                    border: Border.all(
                      color: Colors.white,
                      width: 1.0,
                    ),
                  ),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom spring-physics curve that overshoots then settles.
class _SpringCurve extends Curve {
  const _SpringCurve();

  @override
  double transformInternal(double t) {
    // Approximation of cubic-bezier(0.34, 1.56, 0.64, 1)
    const c1 = 0.34;
    const c2 = 1.56;
    const c3 = 0.64;
    final v = (1 - t);
    return 1 -
        (v * v * v) +
        3 * c1 * t * v * v +
        3 * c2 * t * t * v +
        c3 * t * t * t;
  }
}

/// Convenience constructor for a glass card with emerald glow (correct answer state)
class EmeraldGlowCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  const EmeraldGlowCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return AntigravityGlassCard(
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      glowShadow: AppColors.emeraldGlowShadow(intensity: 1.2),
      backgroundOpacity: 0.12,
      child: child,
    );
  }
}

/// Convenience constructor for a glass card with red glow (wrong answer state)
class RedGlowCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  const RedGlowCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return AntigravityGlassCard(
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      glowShadow: AppColors.redGlowShadow(intensity: 1.2),
      backgroundOpacity: 0.10,
      child: child,
    );
  }
}
