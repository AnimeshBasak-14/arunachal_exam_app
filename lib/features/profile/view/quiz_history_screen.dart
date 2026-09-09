import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/services/service_providers.dart';
import '../../home/view/home_screen.dart';

class QuizHistoryScreen extends ConsumerStatefulWidget {
  const QuizHistoryScreen({super.key});

  @override
  ConsumerState<QuizHistoryScreen> createState() => _QuizHistoryScreenState();
}

class _QuizHistoryScreenState extends ConsumerState<QuizHistoryScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All'; // 'All', 'Passed', 'Needs Review'

  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(storageServiceProvider);
    final historyJsonList = storage.getQuizHistory();

    // Parse all items into typed maps
    final parsedHistory = <Map<String, dynamic>>[];
    double totalScore = 0;
    double totalMax = 0;
    double highestScore = 0;
    int netTrophies = 0;

    for (final jsonStr in historyJsonList) {
      try {
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        final score = double.tryParse(decoded['score']?.toString() ?? '0') ?? 0.0;
        final maxScore = double.tryParse(decoded['maxScore']?.toString() ?? '1') ?? 1.0;
        final ratingChange = int.tryParse(decoded['ratingChange']?.toString() ?? '0') ?? 0;
        final speedBonus = int.tryParse(decoded['speedBonus']?.toString() ?? '0') ?? 0;
        final totalDelta = ratingChange + speedBonus;
        final pct = maxScore > 0 ? (score / maxScore) * 100 : 0.0;

        totalScore += score;
        totalMax += maxScore;
        if (score > highestScore) highestScore = score;
        netTrophies += totalDelta;

        parsedHistory.add({
          'raw': decoded,
          'title': decoded['testTitle']?.toString() ?? decoded['examCode']?.toString() ?? 'Practice Test',
          'examCode': decoded['examCode']?.toString() ?? 'TEST',
          'score': score,
          'maxScore': maxScore,
          'percentage': pct,
          'ratingChange': totalDelta,
          'timeTaken': int.tryParse(decoded['timeTaken']?.toString() ?? '0') ?? 0,
          'date': decoded['completedAt']?.toString() ?? '',
        });
      } catch (e) {
        debugPrint('Error parsing history item: $e');
      }
    }

    final avgPercentage = totalMax > 0 ? (totalScore / totalMax) * 100 : 0.0;

    // Filter items
    final filteredList = parsedHistory.where((item) {
      final title = (item['title'] as String).toLowerCase();
      final code = (item['examCode'] as String).toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          title.contains(_searchQuery.toLowerCase()) ||
          code.contains(_searchQuery.toLowerCase());

      if (!matchesSearch) return false;

      final pct = item['percentage'] as double;
      if (_selectedFilter == 'Passed') return pct >= 50.0;
      if (_selectedFilter == 'Needs Review') return pct < 50.0;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Quiz & Test History',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        actions: [
          if (parsedHistory.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.info_outline_rounded, color: AppColors.textSecondary),
              tooltip: 'Stats Overview',
              onPressed: () => _showStatsDialog(context, parsedHistory.length, avgPercentage, highestScore, netTrophies),
            ),
        ],
      ),
      body: parsedHistory.isEmpty
          ? _buildEmptyState(context)
          : CustomScrollView(
              slivers: [
                // Top Performance KPI Summary
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildKpiGrid(parsedHistory.length, avgPercentage, highestScore, netTrophies),
                        const SizedBox(height: AppSpacing.m),
                        // Search and Filter Bar
                        _buildSearchAndFilters(),
                      ],
                    ),
                  ),
                ),
                // Results List
                if (filteredList.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off_rounded, size: 56, color: AppColors.textHint),
                            const SizedBox(height: AppSpacing.s),
                            Text(
                              'No tests match "$_searchQuery"',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.m, 0, AppSpacing.m, AppSpacing.l),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = filteredList[index];
                          return _buildHistoryCard(context, item);
                        },
                        childCount: filteredList.length,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildKpiGrid(int totalTests, double avgPct, double highest, int trophies) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overall Performance',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.m),
          Row(
            children: [
              _buildStatItem('Attempts', '$totalTests', Icons.assignment_turned_in_rounded, AppColors.primary),
              _buildStatItem('Avg Score', '${avgPct.toStringAsFixed(1)}%', Icons.pie_chart_rounded, Colors.orange),
              _buildStatItem('Highest', highest.toStringAsFixed(highest % 1 == 0 ? 0 : 1), Icons.star_rounded, Colors.amber[700]!),
              _buildStatItem('Trophies', trophies >= 0 ? '+$trophies' : '$trophies', Icons.emoji_events_rounded, AppColors.accent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        TextField(
          onChanged: (val) => setState(() => _searchQuery = val),
          decoration: InputDecoration(
            hintText: 'Search by exam or paper title...',
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint, size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusM),
              borderSide: BorderSide.none,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textHint),
                    onPressed: () => setState(() => _searchQuery = ''),
                  )
                : null,
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('All'),
              const SizedBox(width: 8),
              _buildFilterChip('Passed'),
              const SizedBox(width: 8),
              _buildFilterChip('Needs Review'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = label),
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isSelected ? Colors.white : AppColors.textSecondary,
      ),
      elevation: isSelected ? 1 : 0,
      pressElevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, Map<String, dynamic> item) {
    final double pct = item['percentage'] as double;
    final double score = item['score'] as double;
    final double maxScore = item['maxScore'] as double;
    final int ratingDelta = item['ratingChange'] as int;
    final int timeTaken = item['timeTaken'] as int;
    final String date = item['date'] as String;
    final String title = item['title'] as String;
    final String examCode = item['examCode'] as String;

    final color = pct >= 75
        ? AppColors.success
        : pct >= 50
            ? Colors.orange
            : AppColors.error;

    final mins = timeTaken ~/ 60;
    final secs = timeTaken % 60;
    final timeStr = mins > 0 ? '${mins}m ${secs}s' : '${secs}s';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusM),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        onTap: () {
          try {
            final raw = item['raw'] as Map<String, dynamic>;
            context.push('/mock-test-result', extra: raw);
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Unable to open result: $e')),
            );
          }
        },
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${pct.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: color,
                ),
              ),
              Text(
                pct >= 50 ? 'PASS' : 'FAIL',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 8,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    examCode,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                if (timeTaken > 0) ...[
                  const Icon(Icons.timer_outlined, size: 12, color: AppColors.textHint),
                  const SizedBox(width: 2),
                  Text(
                    timeStr,
                    style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                  ),
                  const SizedBox(width: 6),
                ],
                if (date.isNotEmpty)
                  Expanded(
                    child: Text(
                      date.length > 10 ? date.substring(0, 10) : date,
                      style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${score.toStringAsFixed(score % 1 == 0 ? 0 : 1)} / ${maxScore.toStringAsFixed(maxScore % 1 == 0 ? 0 : 1)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ratingDelta >= 0 ? '+$ratingDelta' : '$ratingDelta',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: ratingDelta >= 0 ? AppColors.success : AppColors.error,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.emoji_events_rounded, color: AppColors.accent, size: 13),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.assignment_outlined, size: 64, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.l),
            const Text(
              'No Test Attempts Yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.s),
            const Text(
              'Take mock tests and practice papers to build your performance history and unlock trophies!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(currentTabProvider.notifier).state = 0;
                context.go('/home');
              },
              icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
              label: const Text('Start a Mock Test', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusM)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatsDialog(BuildContext context, int count, double avg, double highest, int trophies) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Preparation Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Total Tests Attempted: $count'),
            const SizedBox(height: 6),
            Text('• Average Score: ${avg.toStringAsFixed(1)}%'),
            const SizedBox(height: 6),
            Text('• Best Single Score: ${highest.toStringAsFixed(1)}'),
            const SizedBox(height: 6),
            Text('• Net Trophies: ${trophies >= 0 ? "+$trophies" : "$trophies"}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
