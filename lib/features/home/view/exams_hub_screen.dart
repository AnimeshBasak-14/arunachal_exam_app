import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'pyq_hub_screen.dart';
import 'mock_hub_screen.dart';

class ExamsHubScreen extends StatefulWidget {
  final int initialTabIndex;
  const ExamsHubScreen({super.key, this.initialTabIndex = 0});

  @override
  State<ExamsHubScreen> createState() => _ExamsHubScreenState();
}

class _ExamsHubScreenState extends State<ExamsHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
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
      appBar: AppBar(
        title: const Text(
          'Exams & Tests Hub',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
          tabs: const [
            Tab(
              text: 'PYQ Papers',
              icon: Icon(Icons.history_edu_rounded, size: 20),
            ),
            Tab(
              text: 'Mock Tests',
              icon: Icon(Icons.assignment_turned_in_rounded, size: 20),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          PyqHubScreen(isEmbedded: true),
          MockHubScreen(isEmbedded: true),
        ],
      ),
    );
  }
}
