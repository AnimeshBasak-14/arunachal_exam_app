import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import '../../home/view/home_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);
    final user = authState.user;
    final userName = user?.name ?? 'Student Name';
    final userEmail = user?.email ?? 'student@arunachal.in';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.xl),
      child: Column(
        children: [
          // 1. Profile Avatar Hero
          Hero(
            tag: 'profile_avatar_hero',
            child: CircleAvatar(
              radius: 64,
              backgroundColor: AppColors.primary,
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'S',
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
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
          const SizedBox(height: AppSpacing.xl),

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
                  leading: const Icon(Icons.book_rounded, color: AppColors.primary),
                  title: const Text('MY COURSE', style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textHint),
                  onTap: () {
                    // Switch bottom tab index to Bookmarks
                    ref.read(currentTabProvider.notifier).state = 1;
                  },
                ),
                const Divider(height: 1, color: AppColors.divider),
                ListTile(
                  leading: const Icon(Icons.settings_outlined, color: AppColors.primary),
                  title: const Text('SETTING', style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textHint),
                  onTap: () {
                    context.push('/edit-profile');
                  },
                ),
                const Divider(height: 1, color: AppColors.divider),
                ListTile(
                  leading: const Icon(Icons.share_outlined, color: AppColors.primary),
                  title: const Text('SHARE', style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textHint),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mock Link Copied! Share this with other candidates.')),
                    );
                  },
                ),
                const Divider(height: 1, color: AppColors.divider),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                  title: const Text('SIGN OUT', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
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
        ],
      ),
    );
  }
}
