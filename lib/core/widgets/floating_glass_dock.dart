import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Floating glass dock — replaces BottomNavigationBar.
///
/// Renders as a glass capsule pill centered at the bottom of the screen,
/// floating 24px above the safe area edge.
///
/// Active item: neon emerald background chip + glowing dot below icon.
/// Inactive items: icon + label in muted grey with spring hover lift.
class FloatingGlassDock extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onIndexChanged;

  const FloatingGlassDock({
    super.key,
    required this.selectedIndex,
    required this.onIndexChanged,
  });

  static const _items = [
    _DockItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, label: 'Home'),
    _DockItem(icon: Icons.assignment_outlined, activeIcon: Icons.assignment_rounded, label: 'Exams'),
    _DockItem(icon: Icons.psychology_outlined, activeIcon: Icons.psychology_rounded, label: 'AI Tutor'),
    _DockItem(icon: Icons.newspaper_outlined, activeIcon: Icons.newspaper_rounded, label: 'CA & GK'),
    _DockItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Positioned(
      bottom: 24 + bottomPadding,
      left: 0,
      right: 0,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.08),
                    Colors.white.withValues(alpha: 0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(40),
                border: Border(
                  top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2), width: 1),
                  left: BorderSide(
                      color: Colors.white.withValues(alpha: 0.12), width: 1),
                  right: BorderSide(
                      color: Colors.white.withValues(alpha: 0.06), width: 1),
                  bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.06), width: 1),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x80000000),
                    blurRadius: 40,
                    offset: Offset(0, 16),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_items.length, (i) {
                  // Insert a subtle separator dot between item 2 and 3
                  return _DockButton(
                    item: _items[i],
                    isSelected: selectedIndex == i,
                    onTap: () => onIndexChanged(i),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _DockItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _DockButton extends StatefulWidget {
  final _DockItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _DockButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_DockButton> createState() => _DockButtonState();
}

class _DockButtonState extends State<_DockButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _liftAnim;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _liftAnim = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _ctrl, curve: const _SpringCurve()),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _hovered = true);
        _ctrl.forward();
      },
      onExit: (_) {
        setState(() => _hovered = false);
        _ctrl.reverse();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _liftAnim,
          builder: (ctx, child) => Transform.translate(
            offset: Offset(0, _liftAnim.value),
            child: child,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: widget.isSelected
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : Colors.transparent,
              boxShadow: widget.isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Icon(
                  widget.isSelected ? widget.item.activeIcon : widget.item.icon,
                  size: 22,
                  color: widget.isSelected
                      ? AppColors.primaryLight
                      : (_hovered
                          ? AppColors.textPrimary
                          : AppColors.textSecondary),
                ),
                const SizedBox(height: 3),
                // Label
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: widget.isSelected
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: widget.isSelected
                        ? AppColors.primaryLight
                        : AppColors.textHint,
                    fontFamily: 'Poppins',
                  ),
                  child: Text(widget.item.label),
                ),
                const SizedBox(height: 4),
                // Active neon dot
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: widget.isSelected ? 5 : 0,
                  height: widget.isSelected ? 5 : 0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.neon,
                    boxShadow: widget.isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.neon.withValues(alpha: 0.8),
                              blurRadius: 6,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpringCurve extends Curve {
  const _SpringCurve();
  @override
  double transformInternal(double t) {
    final v = 1 - t;
    return 1 - (v * v * v) + 3 * 0.34 * t * v * v + 3 * 1.56 * t * t * v + 0.64 * t * t * t;
  }
}
