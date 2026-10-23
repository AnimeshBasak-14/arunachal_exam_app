import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/data/exam_goals.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/theme/aura.dart';
import '../../../core/widgets/aura/aura_widgets.dart';
import '../../analytics/view/analytics_screen.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import '../../dashboard/view/dashboard_screen.dart';
import '../../library/view/pyq_library_screen.dart';
import '../../mocks/view/mock_tests_screen.dart';

/// 0 Dashboard · 1 PYQ Library · 2 Mock Tests · 3 Performance
final currentTabProvider = StateProvider<int>((ref) => 0);

/// Department preselected when the library is opened from the dashboard.
final libraryDepartmentProvider = StateProvider<Department?>((ref) => null);

class AppShell extends ConsumerStatefulWidget {
  final int? initialTab;
  const AppShell({super.key, this.initialTab});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tab = widget.initialTab;
      if (tab != null && tab >= 0 && tab <= 3) {
        ref.read(currentTabProvider.notifier).state = tab;
      }
      _claimStreakTrophies();
    });
  }

  Future<void> _claimStreakTrophies() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final pending = prefs.getInt('pending_streak_trophies') ?? 0;
    if (pending <= 0) return;
    await ref.read(authViewModelProvider.notifier).updateRating(pending);
    await prefs.setInt('pending_streak_trophies', 0);
  }

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(currentTabProvider);
    return Scaffold(
      extendBody: true,
      body: AuraBackground(
        child: IndexedStack(
          index: tab,
          children: const [
            DashboardScreen(),
            PyqLibraryScreen(),
            MockTestsScreen(),
            AnalyticsScreen(),
          ],
        ),
      ),
      bottomNavigationBar: _AuraTabBar(
        index: tab,
        onTap: (i) => ref.read(currentTabProvider.notifier).state = i,
      ),
    );
  }
}

class _AuraTabBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _AuraTabBar({required this.index, required this.onTap});

  static const _items = [
    (CupertinoIcons.house, 'Dashboard'),
    (CupertinoIcons.book, 'PYQ Library'),
    (CupertinoIcons.stopwatch, 'Mock Tests'),
    (CupertinoIcons.chart_bar, 'Performance'),
  ];

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: a.bg.withValues(alpha: 0.82),
            border: Border(top: BorderSide(color: a.hairline, width: 0.8)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Row(
                children: [
                  for (int i = 0; i < _items.length; i++)
                    Expanded(
                      child: InkResponse(
                        onTap: () => onTap(i),
                        radius: 36,
                        child: _TabItem(
                          icon: _items[i].$1,
                          label: _items[i].$2,
                          selected: i == index,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  const _TabItem({required this.icon, required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final color = selected ? a.accent : a.inkFaint;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            scale: selected ? 1.08 : 1,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(height: 4),
          MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.1,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AuraType.sans(10.5, color,
                  weight: selected ? FontWeight.w600 : FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
