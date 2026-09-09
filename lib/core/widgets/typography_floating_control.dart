import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/text_scale_provider.dart';
import '../theme/app_colors.dart';

/// Floating "Aa" button that spawns a frosted-glass typography control pill.
/// Drop this into any reading-heavy screen as a FloatingActionButton replacement.
class TypographyFloatingControl extends ConsumerStatefulWidget {
  const TypographyFloatingControl({super.key});

  @override
  ConsumerState<TypographyFloatingControl> createState() => _TypographyFloatingControlState();
}

class _TypographyFloatingControlState extends ConsumerState<TypographyFloatingControl>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _ctrl;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _expandAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _ctrl.forward() : _ctrl.reverse();
  }

  static const List<double> _steps = [0.85, 0.92, 1.0, 1.10, 1.20, 1.35];

  @override
  Widget build(BuildContext context) {
    final scale = ref.watch(textScaleProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Expanded pill panel
        SizeTransition(
          sizeFactor: _expandAnim,
          axis: Axis.vertical,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Decrease text
                      _ScaleStepButton(
                        icon: Icons.text_decrease_rounded,
                        onTap: () {
                          final idx = _steps.indexOf(scale);
                          if (idx > 0) {
                            ref.read(textScaleProvider.notifier).set(_steps[idx - 1]);
                          }
                        },
                        enabled: scale > _steps.first,
                      ),
                      const SizedBox(width: 8),
                      // Scale indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${(scale * 100).round()}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Increase text
                      _ScaleStepButton(
                        icon: Icons.text_increase_rounded,
                        onTap: () {
                          final idx = _steps.indexOf(scale);
                          if (idx < _steps.length - 1) {
                            ref.read(textScaleProvider.notifier).set(_steps[idx + 1]);
                          }
                        },
                        enabled: scale < _steps.last,
                      ),
                      const SizedBox(width: 8),
                      // Reset
                      GestureDetector(
                        onTap: () => ref.read(textScaleProvider.notifier).set(1.0),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.textHint.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.refresh_rounded, size: 14, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // "Aa" trigger button
        GestureDetector(
          onTap: _toggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _expanded ? AppColors.primary : Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _expanded ? AppColors.primary : Colors.white,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: _expanded ? 0.25 : 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              'Aa',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: _expanded ? Colors.white : AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScaleStepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _ScaleStepButton({required this.icon, required this.onTap, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.primary.withValues(alpha: 0.10)
              : AppColors.textHint.withValues(alpha: 0.06),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? AppColors.primary : AppColors.textHint,
        ),
      ),
    );
  }
}
