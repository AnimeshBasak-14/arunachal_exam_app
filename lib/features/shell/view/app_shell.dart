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
        child: StatusBarScrim(
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
      ),
      bottomNavigationBar: _AuraTabBar(
        index: tab,
        onTap: (i) => ref.read(currentTabProvider.notifier).state = i,
      ),
    );
  }
}

/// Floating black pill, like the toolbar in the design reference. The
/// selected tab becomes a lighter pill with its label.
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
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          height: 66,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: a.chrome,
            borderRadius: BorderRadius.circular(33),
            border: Border.all(color: a.onChrome.withValues(alpha: 0.08)),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 24,
                  offset: Offset(0, 8)),
            ],
          ),
          child: Row(
            children: [
              for (int i = 0; i < _items.length; i++)
                Expanded(
                  flex: i == index ? 7 : 3,
                  child: _TabItem(
                    icon: _items[i].$1,
                    label: _items[i].$2,
                    selected: i == index,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
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
  final VoidCallback onTap;
  const _TabItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final color = selected ? a.onChrome : a.onChrome.withValues(alpha: 0.55);
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? a.onChrome.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22, color: color),
                if (selected) ...[
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style:
                            AuraType.sans(13, color, weight: FontWeight.w600)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
