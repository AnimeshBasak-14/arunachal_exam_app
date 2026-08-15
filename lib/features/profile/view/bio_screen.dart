import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/utils/rank_utils.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';

class BioScreen extends ConsumerWidget {
  const BioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);
    final user = authState.user;
    final userName = user?.name ?? 'Student Name';
    final userEmail = user?.email ?? 'student@arunachal.in';
    final userPhone = (user?.phone != null && user!.phone.isNotEmpty) ? user.phone : '9876543210';
    final userDob = user?.dob ?? '2000-01-01';
    final userCity = (user?.city != null && user!.city.isNotEmpty) ? user.city : 'Itanagar, Arunachal Pradesh';
    final rating = user?.rating ?? 1200;

    final rankTier = RankUtils.getTier(rating);

    // Calculate real stats from quiz history in storage
    final storage = ref.watch(storageServiceProvider);
    final historyList = storage.getQuizHistory();

    int mocksTaken = historyList.length;
    double totalScore = 0;
    double totalMaxScore = 0;
    double bestScore = 0;

    for (final item in historyList) {
      try {
        final map = jsonDecode(item) as Map<String, dynamic>;
        final score = (map['score'] as num?)?.toDouble() ?? 0.0;
        final maxScore = (map['maxScore'] as num?)?.toDouble() ?? 10.0;
        totalScore += score;
        totalMaxScore += maxScore;
        if (score > bestScore) {
          bestScore = score;
        }
      } catch (_) {}
    }

    final double avgAccuracy = totalMaxScore > 0 ? (totalScore / totalMaxScore * 100) : 0.0;

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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('CANDIDATE PROFILE BIO'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Profile',
            onPressed: () => context.push('/edit-profile'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.m),
              
              // Bio Card Header
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
                  side: const BorderSide(color: AppColors.divider),
                ),
                color: AppColors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  child: Column(
                    children: [
                      (() {
                        final pic = user?.profilePic;
                        final isFile = pic != null && !pic.startsWith('avatar_');
                        return Hero(
                          tag: 'profile_avatar_hero',
                          child: CircleAvatar(
                            radius: 54,
                            backgroundColor: getAvatarColor(pic),
                            backgroundImage: isFile ? FileImage(File(pic)) : null,
                            child: isFile
                                ? null
                                : Text(
                                    userName.isNotEmpty ? userName[0].toUpperCase() : 'S',
                                    style: const TextStyle(
                                      color: AppColors.textWhite,
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        );
                      })(),
                      const SizedBox(height: AppSpacing.m),
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        userEmail.endsWith('candidate.google@gmail.com') || userEmail.endsWith('@gmail.com')
                            ? 'Connected via Google'
                            : 'Local Account',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.m),

              // Rating / Global Ranking Card (MLBB Style)
              GestureDetector(
                onTap: () => context.push('/scoreboard'),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                    side: BorderSide(color: rankTier.color.withOpacity(0.4), width: 1.5),
                  ),
                  color: rankTier.color.withOpacity(0.06),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.s),
                          decoration: BoxDecoration(
                            color: rankTier.color.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(rankTier.icon, color: rankTier.color, size: 36),
                        ),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    rankTier.title,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: rankTier.color,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: rankTier.color.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      rankTier.badgeText,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: rankTier.color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$rating Trophies · Tap to view Scoreboard',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textHint),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.m),

              // Info Details List
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    _buildBioItem(Icons.person_pin_rounded, 'Full Name', userName),
                    const Divider(height: 1, color: AppColors.divider),
                    _buildBioItem(Icons.location_city_rounded, 'City / District', userCity),
                    const Divider(height: 1, color: AppColors.divider),
                    _buildBioItem(Icons.calendar_month_rounded, 'Date of Birth (DOB)', userDob),
                    const Divider(height: 1, color: AppColors.divider),
                    _buildBioItem(Icons.email_outlined, 'Gmail Address', userEmail),
                    const Divider(height: 1, color: AppColors.divider),
                    _buildBioItem(Icons.phone_android_rounded, 'Phone Number', userPhone),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.m),

              // Live Exam Statistics Panel
              Container(
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Exam Statistics',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        if (mocksTaken > 0)
                          const Text(
                            'Live Updated',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatMetric('Mocks Taken', '$mocksTaken'),
                        _buildStatMetric('Avg Accuracy', mocksTaken > 0 ? '${avgAccuracy.toStringAsFixed(0)}%' : '--'),
                        _buildStatMetric('Best Score', mocksTaken > 0 ? '${bestScore.toStringAsFixed(1)}' : '--'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.l),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBioItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatMetric(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
