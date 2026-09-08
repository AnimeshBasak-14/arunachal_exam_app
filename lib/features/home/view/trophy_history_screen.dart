import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/services/service_providers.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import 'home_screen.dart';

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
            child: events.isEmpty ||
                    (events.length == 1 && events[0]['type'] == 'account')
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.emoji_events_outlined,
                            size: 64, color: AppColors.textHint),
                        const SizedBox(height: 16),
                        const Text(
                          'No trophy history yet.',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Take a mock test to start earning trophies!',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.textHint),
                        ),
                        const SizedBox(height: 24),
                        TextButton(
                          onPressed: () {
                            ref.read(currentTabProvider.notifier).state = 0;
                            context.go('/home');
                          },
                          child: const Text('Take a Test'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      12,
                      16,
                      MediaQuery.of(context).padding.bottom + 48,
                    ),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                final isAccount = event['type'] == 'account';

                if (isAccount) {
                  return _buildAccountCreationTile(event);
                }

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
                                  color: isGain
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                              ),
                            ),
                          ),
                          if (index < events.length - 1)
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
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusL),
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
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13),
                                  ),
                                  const Spacer(),
                                  Text(
                                    date,
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textHint),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Score + time row
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  _infoChip(
                                      Icons.equalizer_rounded,
                                      'Score $score / $maxScore',
                                      AppColors.primary),
                                  _infoChip(Icons.timer_outlined,
                                      '${mins}m ${secs}s', AppColors.secondary),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Trophy breakdown row
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: [
                                        _trophyTag('Score', ratingChange,
                                            AppColors.textPrimary),
                                        if (speedBonus != 0)
                                          _trophyTag(
                                              'Speed',
                                              speedBonus,
                                              speedBonus > 0
                                                  ? AppColors.accent
                                                  : AppColors.error),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  // Before → After
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '$ratingBefore',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary),
                                      ),
                                      const Padding(
                                        padding:
                                            EdgeInsets.symmetric(horizontal: 2),
                                        child: Icon(Icons.arrow_forward_rounded,
                                            size: 11,
                                            color: AppColors.textHint),
                                      ),
                                      Text(
                                        '$ratingAfter',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isGain
                                              ? AppColors.success
                                              : AppColors.error,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      const Icon(Icons.emoji_events_rounded,
                                          color: AppColors.accent, size: 12),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    ),
    ),
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
