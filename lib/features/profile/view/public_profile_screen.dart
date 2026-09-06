import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/rank_utils.dart';
import '../../../core/utils/avatar_utils.dart';

class PublicProfileScreen extends StatelessWidget {
  final Map<String, dynamic> user;

  const PublicProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final name = user['name'] as String? ?? 'Student';
    final rating = user['rating'] as int? ?? 0;
    final state = user['state'] as String? ?? 'Arunachal Pradesh';
    final profilePic = user['profilePic'] as String? ?? '';
    final tier = RankUtils.getTier(rating);

    Widget buildAvatar() {
      final imgProvider = AvatarUtils.getAvatarImageProvider(profilePic);
      return CircleAvatar(
        radius: 52,
        backgroundColor: AppColors.primary,
        backgroundImage: imgProvider,
        child: imgProvider != null
            ? null
            : Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'S',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Player Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.l),
            buildAvatar(),
            const SizedBox(height: AppSpacing.m),
            Text(
              name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              state,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.m),
            // Rank tier badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(tier.icon, size: 20, color: AppColors.primaryDark),
                  const SizedBox(width: 8),
                  Text(
                    tier.name,
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            // Stats card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.l),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  const Text(
                    'PUBLIC STATS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statItem('🏆', '$rating', 'Trophies'),
                      _statItem('📊', tier.name, 'Rank'),
                      _statItem('📍', state, 'Location'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            // Privacy note
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline_rounded,
                    size: 14, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(
                  'Personal info is private',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
