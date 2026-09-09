import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/utils/rank_utils.dart';
import '../../../core/utils/avatar_utils.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);
    final user = authState.user;
    final userName = user?.name ?? 'Student Name';
    final userEmail = user?.email ?? 'student@arunachal.in';

    Color getAvatarColor(String? avatarName) {
      switch (avatarName) {
        case 'avatar_teal':
          return AppColors.secondary;
        case 'avatar_gold':
          return AppColors.accent;
        case 'avatar_blue':
          return const Color(0xff3b82f6);
        case 'avatar_orange':
          return const Color(0xffe07a5f);
        case 'avatar_green':
        default:
          return AppColors.primary;
      }
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l, vertical: AppSpacing.xl),
      child: Column(
        children: [
          // Clickable profile section leading to Bio
          GestureDetector(
            onTap: () => context.push('/bio'),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Column(
                children: [
                  (() {
                    final pic = user?.profilePic;
                    final imgProvider = AvatarUtils.getAvatarImageProvider(pic);
                    return Hero(
                      tag: 'profile_avatar_hero',
                      child: CircleAvatar(
                        radius: 64,
                        backgroundColor: getAvatarColor(pic),
                        backgroundImage: imgProvider,
                        child: imgProvider != null
                            ? null
                            : Text(
                                userName.isNotEmpty
                                    ? userName[0].toUpperCase()
                                    : 'S',
                                style: const TextStyle(
                                  color: AppColors.textWhite,
                                  fontSize: 54,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    );
                  })(),
                  const SizedBox(height: AppSpacing.m),
                  // Name and Subtitle
                  Text(
                    userName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    userEmail,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  // Trophies badge — taps to global scoreboard
                  Builder(
                    builder: (context) {
                      final rating = user?.rating ?? 1200;
                      final tier = RankUtils.getTier(rating);
                      return GestureDetector(
                        onTap: () => context.push('/scoreboard'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.m, vertical: 6),
                          decoration: BoxDecoration(
                            color: tier.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: tier.color.withValues(alpha: 0.5),
                                width: 1.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(tier.icon, color: tier.color, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                '$rating Trophies · ${tier.name}',
                                style: TextStyle(
                                  color: tier.color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.leaderboard_rounded,
                                  color: tier.color, size: 14),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Streak Stats Card
          Builder(builder: (context) {
            // Read from SharedPreferences via StorageService
            final prefs = ref.read(sharedPreferencesProvider);
            final streak = prefs.getInt('streak_count') ?? 0;
            final longest = prefs.getInt('streak_longest') ?? 0;
            final lastDate = prefs.getString('streak_last_date') ?? 'Never';
            if (streak == 0) return const SizedBox.shrink();
            return GestureDetector(
              onTap: () => context.push('/streak-calendar'),
              child: Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.m),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusL)),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Text('🔥', style: TextStyle(fontSize: 18)),
                          SizedBox(width: 6),
                          Text('Study Streak',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.m),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStreakStat(
                              'Current', '$streak days', AppColors.primary),
                          _buildStreakStat(
                              'Best', '$longest days', AppColors.accent),
                          _buildStreakStat(
                              'Last Active',
                              lastDate.length > 10
                                  ? lastDate.substring(5)
                                  : lastDate,
                              AppColors.textSecondary),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          // 2. Menu Options Container (Page 3 & 12 & 14)
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusL),
              border: Border.all(color: AppColors.divider, width: 1),
            ),
            child: Column(
              children: [
                ListTile(
                  leading:
                      const Icon(Icons.book_rounded, color: AppColors.primary),
                  title: const Text('MY COURSE',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded,
                      size: 16, color: AppColors.textHint),
                  onTap: () {
                    context.push('/my-courses');
                  },
                ),
                const Divider(height: 1, color: AppColors.divider),
                ListTile(
                  leading: const Icon(Icons.settings_outlined,
                      color: AppColors.primary),
                  title: const Text('SETTING',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded,
                      size: 16, color: AppColors.textHint),
                  onTap: () {
                    context.push('/edit-profile');
                  },
                ),
                const Divider(height: 1, color: AppColors.divider),
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings_outlined,
                      color: AppColors.primary),
                  title: const Text('ADMIN QUESTION REVIEW',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Quality triage, OCR fixes & flag reports',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded,
                      size: 16, color: AppColors.textHint),
                  onTap: () {
                    context.push('/admin/question-flagger');
                  },
                ),
                const Divider(height: 1, color: AppColors.divider),
                ListTile(
                  leading:
                      const Icon(Icons.logout_rounded, color: AppColors.error),
                  title: const Text('SIGN OUT',
                      style: TextStyle(
                          color: AppColors.error, fontWeight: FontWeight.bold)),
                  onTap: () async {
                    await ref.read(authViewModelProvider.notifier).logout();
                    if (context.mounted) {
                      context.go('/welcome');
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Quiz History Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'QUIZ ATTEMPTS HISTORY',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => context.push('/trophy-history'),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.emoji_events_rounded,
                            color: AppColors.accent, size: 14),
                        SizedBox(width: 4),
                        Text('Trophies',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => context.push('/quiz-history'),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_rounded,
                            color: AppColors.primary, size: 14),
                        SizedBox(width: 4),
                        Text('See All',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary)),
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 10, color: AppColors.primary),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          _buildQuizHistory(context, ref),
          const SizedBox(height: AppSpacing.l),
          const Center(
            child: Text(
              'Arunachal Exam Prep v1.2.0 (Build 99)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textHint,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildStreakStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildQuizHistory(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(storageServiceProvider);
    final historyJsonList = storage.getQuizHistory();

    if (historyJsonList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusL),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Center(
          child: Text(
            'No quiz history found. Take a mock test to see your score history!',
            style: TextStyle(
                color: AppColors.textHint,
                fontSize: 13,
                fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final displayList = historyJsonList.take(5).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusL),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayList.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final jsonStr = displayList[index];
              try {
                final examCode = _parseJsonVal(jsonStr, 'examCode');
                final score = _parseJsonVal(jsonStr, 'score');
                final maxScore = _parseJsonVal(jsonStr, 'maxScore');
                final ratingChange =
                    int.tryParse(_parseJsonVal(jsonStr, 'ratingChange')) ?? 0;
                final date = _parseJsonVal(jsonStr, 'date');

                return ListTile(
                  title: Text('$examCode Mock Test',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(date,
                      style:
                          const TextStyle(fontSize: 12, color: AppColors.textHint)),
                  onTap: () {
                    try {
                      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
                      context.push('/mock-test-result', extra: decoded);
                    } catch (e) {
                      debugPrint("Error loading result history: $e");
                    }
                  },
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Score: $score / $maxScore',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            ratingChange >= 0 ? '+$ratingChange' : '$ratingChange',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: ratingChange >= 0
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.emoji_events_rounded,
                              color: AppColors.accent, size: 14),
                        ],
                      ),
                    ],
                  ),
                );
              } catch (e) {
                return const SizedBox.shrink();
              }
            },
          ),
          if (historyJsonList.length > 5) ...[
            const Divider(height: 1),
            InkWell(
              onTap: () => context.push('/quiz-history'),
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppSpacing.radiusL)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'View All History (${historyJsonList.length} attempts)',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded,
                        size: 15, color: AppColors.primary),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _parseJsonVal(String json, String key) {
    final pattern = '"$key":';
    final index = json.indexOf(pattern);
    if (index == -1) return '';
    final startIdx = index + pattern.length;
    var endIdx = json.indexOf(',', startIdx);
    if (endIdx == -1) endIdx = json.indexOf('}', startIdx);
    final val = json.substring(startIdx, endIdx).trim();
    if (val.startsWith('"')) {
      return val.substring(1, val.length - 1);
    }
    return val;
  }
}
