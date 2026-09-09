import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/custom_practice_modal.dart';
import 'pyq_hub_screen.dart';
import 'mock_hub_screen.dart';

class ExamsHubScreen extends StatefulWidget {
  final int initialTabIndex;
  const ExamsHubScreen({super.key, this.initialTabIndex = 0});

  @override
  State<ExamsHubScreen> createState() => _ExamsHubScreenState();
}

class _ExamsHubScreenState extends State<ExamsHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTabIndex.clamp(0, 2));
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant ExamsHubScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTabIndex != oldWidget.initialTabIndex &&
        widget.initialTabIndex >= 0 &&
        widget.initialTabIndex < 3) {
      _tabController.animateTo(widget.initialTabIndex);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // ─── Collapsible Floating SliverAppBar ────────────────────────
            SliverAppBar(
              floating: true,
              pinned: false,
              snap: true,
              elevation: 0.5,
              backgroundColor: Colors.white,
              foregroundColor: AppColors.textPrimary,
              titleSpacing: 16,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.school_rounded, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'Exam Prep Center',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        Text(
                          'Official PYQs, Targeted Mocks & Custom Practice',
                          style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary, fontWeight: FontWeight.normal),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ─── Pinned 3-Segment Tab Bar Switcher ─────────────────────────
            SliverPersistentHeader(
              pinned: true,
              delegate: _ExamsHubTabBarDelegate(
                tabController: _tabController,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        _buildTab(0, Icons.history_edu_rounded, 'PYQ Papers'),
                        _buildTab(1, Icons.assignment_turned_in_rounded, 'Mock Tests'),
                        _buildTab(2, Icons.tune_rounded, 'Custom Test'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: const [
            PyqHubScreen(isEmbedded: true),
            MockHubScreen(isEmbedded: true),
            CustomPracticeModal(isEmbedded: true),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int index, IconData icon, String label) {
    final isSelected = _tabController.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _tabController.animateTo(index);
          setState(() {});
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 4,
                      offset: const Offset(0, 1.5),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? AppColors.primary : const Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.primary : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExamsHubTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final Widget child;

  _ExamsHubTabBarDelegate({required this.tabController, required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 50.0;

  @override
  double get minExtent => 50.0;

  @override
  bool shouldRebuild(covariant _ExamsHubTabBarDelegate oldDelegate) {
    return oldDelegate.tabController != tabController || oldDelegate.child != child;
  }
}
