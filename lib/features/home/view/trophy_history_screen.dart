import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/service_providers.dart';
import '../../../core/services/streak_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';

class TrophyHistoryScreen extends ConsumerWidget {
  const TrophyHistoryScreen({super.key});

  String _parseJsonVal(String json, String key) {
    final pattern = '"$key":';
    final index = json.indexOf(pattern);
    if (index == -1) return '';
    final startIdx = index + pattern.length;
    var endIdx = json.indexOf(',', startIdx);
    if (endIdx == -1) endIdx = json.indexOf('}', startIdx);
    if (endIdx == -1) endIdx = json.length;
    final val = json.substring(startIdx, endIdx).trim();
    if (val.startsWith('"')) return val.replaceAll('"', '');
    return val;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(storageServiceProvider);
    final currentUser = ref.watch(authViewModelProvider).user;
    final prefs = ref.watch(sharedPreferencesProvider);
    final streakService = StreakService(prefs);

    final currentStreak = streakService.getCurrentStreak();
    final longestStreak = streakService.getLongestStreak();
    final historyJsonList = storage.getQuizHistory();
    final currentRating = currentUser?.rating ?? 1200;

    // Build trophy events from history (reverse-chronological already)
    final events = <Map<String, dynamic>>[];
    int runningRating = currentRating;

    for (int i = 0; i < historyJsonList.length; i++) {
      final jsonStr = historyJsonList[i];
      try {
        final examCode = _parseJsonVal(jsonStr, 'examCode');
        final ratingChange =
            int.tryParse(_parseJsonVal(jsonStr, 'ratingChange')) ?? 0;
        final speedBonus =
            int.tryParse(_parseJsonVal(jsonStr, 'speedBonus')) ?? 0;
        final totalChange = ratingChange + speedBonus;
        final score = _parseJsonVal(jsonStr, 'score');
        final maxScore = _parseJsonVal(jsonStr, 'maxScore');
        final date = _parseJsonVal(jsonStr, 'date');
        final timeTaken =
            int.tryParse(_parseJsonVal(jsonStr, 'timeTaken')) ?? 0;

        final ratingAfter = runningRating;
        final ratingBefore = runningRating - totalChange;
        runningRating = ratingBefore;

        events.add({
          'type': 'quiz',
          'examCode': examCode,
          'ratingChange': ratingChange,
          'speedBonus': speedBonus,
          'totalChange': totalChange,
          'score': score,
          'maxScore': maxScore,
          'date': date,
          'timeTaken': timeTaken,
          'ratingAfter': ratingAfter,
          'ratingBefore': ratingBefore,
        });
      } catch (e) {
        // skip malformed entries
      }
    }

    // Add account-creation baseline event at the bottom
    events.add({
      'type': 'account',
      'date': 'Account Created',
      'totalChange': 1200,
      'ratingAfter': 1200,
    });

    final hasOnlyAccount = events.length == 1 && events[0]['type'] == 'account';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Trophy History'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Icon(Icons.emoji_events_rounded,
                    color: AppColors.accent, size: 18),
                const SizedBox(width: 4),
                Text(
                  '$currentRating',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Streak Header Banner
                        _buildStreakBanner(
                            context, currentStreak, longestStreak),
                        const SizedBox(height: 16),
                        // LeetCode-style Streak Milestones
                        _buildStreakMilestones(longestStreak),
                        const SizedBox(height: 16),
                        // Quiz Achievements
                        _buildAchievementBadges(events, currentRating),
                        const SizedBox(height: 20),
                        // Timeline Header with Quick Action
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Rating & Trophy Timeline',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => context.push('/mock-hub'),
                              icon: const Icon(Icons.play_arrow_rounded,
                                  size: 16),
                              label: const Text(
                                'Take Mock Test',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                if (hasOnlyAccount)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 24),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.emoji_events_outlined,
                                size: 56, color: AppColors.textHint),
                            const SizedBox(height: 12),
                            const Text(
                              'No test history yet',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Complete your first mock test to gain trophies & boost your rating!',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.textHint),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => context.push('/mock-hub'),
                              icon: const Icon(Icons.play_circle_fill_rounded),
                              label: const Text('Start First Mock Test'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildAccountCreationTile(events[0]),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      MediaQuery.of(context).padding.bottom + 48,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final event = events[index];
                          final isAccount = event['type'] == 'account';

                          if (isAccount) {
                            return _buildAccountCreationTile(event);
                          }
                          return _buildTimelineTile(
                              event, index, events.length);
                        },
                        childCount: events.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStreakBanner(
      BuildContext context, int currentStreak, int longestStreak) {
    return InkWell(
      onTap: () => context.push('/streak-calendar'),
      borderRadius: BorderRadius.circular(AppSpacing.radiusL),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE65100), Color(0xFFFF9800)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusL),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF9800).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Text('🔥', style: TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '$currentStreak Day Streak',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Best: $longestStreak d',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Practice daily to maintain your study streak! Tap to view full calendar.',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakMilestones(int longestStreak) {
    final milestones = [
      {'days': 3, 'label': '3 Days', 'icon': '🥉', 'name': 'Bronze'},
      {'days': 7, 'label': '7 Days', 'icon': '🥈', 'name': 'Silver'},
      {'days': 14, 'label': '14 Days', 'icon': '🥇', 'name': 'Gold'},
      {'days': 30, 'label': '30 Days', 'icon': '👑', 'name': 'Diamond'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Streak Milestones',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Row(
          children: milestones.map((m) {
            final days = m['days'] as int;
            final isUnlocked = longestStreak >= days;
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                decoration: BoxDecoration(
                  color: isUnlocked ? Colors.amber.shade50 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isUnlocked
                        ? Colors.amber.shade400
                        : Colors.grey.shade300,
                    width: isUnlocked ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      m['icon'] as String,
                      style: TextStyle(
                        fontSize: 20,
                        color: isUnlocked ? null : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      m['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isUnlocked
                            ? Colors.amber.shade900
                            : AppColors.textHint,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isUnlocked ? 'Unlocked' : 'Locked',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color:
                            isUnlocked ? AppColors.success : AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAchievementBadges(
      List<Map<String, dynamic>> events, int currentRating) {
    final quizCount = events.where((e) => e['type'] == 'quiz').length;
    final hasSpeedster = events.any((e) =>
        e['type'] == 'quiz' &&
        (e['timeTaken'] as int) > 0 &&
        (e['timeTaken'] as int) <= 300);
    final hasSharpShooter = events.any((e) {
      if (e['type'] != 'quiz') return false;
      final sc = double.tryParse('${e['score']}') ?? 0;
      final mx = double.tryParse('${e['maxScore']}') ?? 1;
      return mx > 0 && (sc / mx) >= 0.8;
    });
    final isContender = currentRating >= 1300;
    final isGrandmaster = currentRating >= 1500;

    final badges = [
      {
        'name': 'First Test',
        'icon': Icons.bolt_rounded,
        'unlocked': quizCount >= 1,
        'desc': 'Finish 1 test'
      },
      {
        'name': 'Speedster',
        'icon': Icons.speed_rounded,
        'unlocked': hasSpeedster,
        'desc': 'Done in < 5m'
      },
      {
        'name': 'Sharp Mind',
        'icon': Icons.track_changes_rounded,
        'unlocked': hasSharpShooter,
        'desc': 'Score 80%+'
      },
      {
        'name': '1300+ ELO',
        'icon': Icons.trending_up_rounded,
        'unlocked': isContender,
        'desc': 'Reach 1300'
      },
      {
        'name': 'Grandmaster',
        'icon': Icons.military_tech_rounded,
        'unlocked': isGrandmaster,
        'desc': 'Reach 1500'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quiz Achievements',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: badges.map((b) {
              final isUnlocked = b['unlocked'] as bool;
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? AppColors.primaryLight
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isUnlocked
                        ? AppColors.primary.withOpacity(0.4)
                        : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      b['icon'] as IconData,
                      size: 16,
                      color: isUnlocked ? AppColors.primary : AppColors.textHint,
                    ),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b['name'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isUnlocked
                                ? AppColors.primaryDark
                                : AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          b['desc'] as String,
                          style: const TextStyle(
                              fontSize: 9, color: AppColors.textHint),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineTile(
      Map<String, dynamic> event, int index, int totalCount) {
    final totalChange = event['totalChange'] as int;
    final ratingChange = event['ratingChange'] as int;
    final speedBonus = event['speedBonus'] as int? ?? 0;
    final examCode = event['examCode'] as String;
    final date = event['date'] as String;
    final score = event['score'] as String;
    final maxScore = event['maxScore'] as String;
    final timeTaken = event['timeTaken'] as int;
    final ratingAfter = event['ratingAfter'] as int;
    final ratingBefore = event['ratingBefore'] as int;
    final isGain = totalChange >= 0;

    final mins = timeTaken ~/ 60;
    final secs = timeTaken % 60;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line + dot
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isGain
                      ? AppColors.success.withValues(alpha: 0.12)
                      : AppColors.error.withValues(alpha: 0.12),
                  border: Border.all(
                    color: isGain
                        ? AppColors.success.withValues(alpha: 0.4)
                        : AppColors.error.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    isGain ? '+$totalChange' : '$totalChange',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: isGain ? AppColors.success : AppColors.error,
                    ),
                  ),
                ),
              ),
              if (index < totalCount - 1)
                Container(
                  width: 2,
                  height: 50,
                  color: AppColors.divider,
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Event card
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.task_alt_rounded,
                          color: AppColors.primary, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        '$examCode Mock Test',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const Spacer(),
                      Text(
                        date,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textHint),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _infoChip(Icons.score_outlined, '$score/$maxScore',
                          AppColors.primary),
                      _infoChip(
                          Icons.timer_outlined,
                          '${mins}m ${secs}s',
                          AppColors.textSecondary),
                      _trophyTag('Performance', ratingChange,
                          ratingChange >= 0 ? AppColors.success : AppColors.error),
                      if (speedBonus > 0)
                        _trophyTag('Speed Bonus', speedBonus, AppColors.accent),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Rating: ',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textHint),
                      ),
                      Text(
                        '$ratingBefore',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2),
                        child: Icon(Icons.arrow_forward_rounded,
                            size: 11, color: AppColors.textHint),
                      ),
                      Text(
                        '$ratingAfter',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isGain ? AppColors.success : AppColors.error,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.emoji_events_rounded,
                          color: AppColors.accent, size: 12),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 11),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _trophyTag(String label, int val, Color color) {
    final str = val >= 0 ? '+$val' : '$val';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $str 🏆',
        style:
            TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildAccountCreationTile(Map<String, dynamic> event) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryLight,
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
          ),
          child: const Center(
            child: Icon(Icons.person_add_alt_1_rounded,
                color: AppColors.primary, size: 18),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppSpacing.radiusL),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.star_rounded, color: AppColors.accent, size: 16),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Account Created · Started with 1200 🏆',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
