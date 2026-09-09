import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/avatar_utils.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import '../../profile/view/profile_screen.dart';
import '../../../core/services/service_providers.dart';
import 'notifications_screen.dart';
import '../widgets/word_of_day_card.dart';
import '../../../core/services/current_affairs_service.dart';
import '../../../core/services/remote_config_service.dart';
import 'exams_hub_screen.dart';
import 'current_affairs_gk_screen.dart';
import '../../chatbot/view/chatbot_screen.dart';
import '../../../widgets/custom_practice_modal.dart';

final currentTabProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(currentTabProvider);

    final tabs = [
      const HomeTabBody(),
      const ExamsHubScreen(),
      const ChatbotScreen(isEmbedded: true),
      const CurrentAffairsGkScreen(isEmbedded: true),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: tabs[selectedTab],
      ),
      floatingActionButton: selectedTab == 0
          ? FloatingActionButton(
              onPressed: () {
                ref.read(currentTabProvider.notifier).state = 2; // Switch to AI Tutor tab
              },
              backgroundColor: AppColors.primary,
              elevation: 4,
              tooltip: 'AI Tutor',
              child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 28),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: selectedTab,
          onTap: (index) {
            ref.read(currentTabProvider.notifier).state = index;
          },
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textHint,
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          backgroundColor: AppColors.surface,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment_rounded),
              label: 'Exams',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.psychology_outlined),
              activeIcon: Icon(Icons.psychology_rounded),
              label: 'AI Tutor',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.newspaper_outlined),
              activeIcon: Icon(Icons.newspaper_rounded),
              label: 'CA & GK',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// Home Tab Body (Page 2 / Page 11 wireframes)
// -------------------------------------------------------------
class HomeTabBody extends ConsumerStatefulWidget {
  const HomeTabBody({super.key});

  @override
  ConsumerState<HomeTabBody> createState() => _HomeTabBodyState();
}

class _HomeTabBodyState extends ConsumerState<HomeTabBody> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _claimPendingTrophies();
    });
  }

  Future<void> _claimPendingTrophies() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final pending = prefs.getInt('pending_streak_trophies') ?? 0;
    if (pending > 0) {
      await ref.read(authViewModelProvider.notifier).updateRating(pending);
      await prefs.setInt('pending_streak_trophies', 0);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔥 Streak Check-in! You earned $pending Trophies!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  void _openSearchModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: AppSpacing.m,
          right: AppSpacing.m,
          top: AppSpacing.m,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.m,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXL)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Search Exam Hub',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search exams, subjects, topics...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (val) {
                Navigator.pop(ctx);
                ref.read(currentTabProvider.notifier).state = 1; // Switch to Exams tab
              },
            ),
            const SizedBox(height: 16),
            const Text('Quick Access', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.history_edu_rounded, size: 16, color: AppColors.primary),
                  label: const Text('PYQ Papers'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ref.read(currentTabProvider.notifier).state = 1;
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.assignment_turned_in_rounded, size: 16, color: AppColors.primary),
                  label: const Text('Mock Tests'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ref.read(currentTabProvider.notifier).state = 1;
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.psychology_rounded, size: 16, color: AppColors.primary),
                  label: const Text('AI Tutor'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ref.read(currentTabProvider.notifier).state = 2;
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.menu_book_rounded, size: 16, color: AppColors.primary),
                  label: const Text('English Grammar'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/grammar-hub');
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.flag_rounded, size: 16, color: AppColors.primary),
                  label: const Text('Arunachal State GK'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/state-gk');
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final userName = authState.user?.name ?? 'Student Name';

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
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
          // 1. Header Card (Page 2 & 11)
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.l, vertical: AppSpacing.xl),
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(AppSpacing.radiusXL),
                bottomRight: Radius.circular(AppSpacing.radiusXL),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hi, $userName',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  color: AppColors.textWhite,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'What do you want to learn today?',
                            style: TextStyle(
                              color:
                                  AppColors.textWhite.withValues(alpha: 0.85),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.m),
                    // Header Action Buttons: Search, Notifications & Profile
                    Row(
                      children: [
                        if (kIsWeb) ...[
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.primary,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () =>
                                  context.push('/syllabus'),
                              icon: const Icon(Icons.auto_stories_rounded,
                                  size: 18, color: AppColors.primary),
                              label: const Text('Exam Syllabus',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF0F9D58),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () =>
                                  context.push('/state-gk'),
                              icon: const Icon(Icons.terrain_rounded,
                                  size: 18, color: Color(0xFF0F9D58)),
                              label: const Text('State GK',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                        IconButton(
                          onPressed: () => _openSearchModal(context),
                          icon: const Icon(
                            Icons.search_rounded,
                            color: AppColors.textWhite,
                            size: 26,
                          ),
                          tooltip: 'Search Exams & Topics',
                        ),
                        Consumer(
                          builder: (context, ref, _) {
                            final hasUnread = ref.watch(hasUnreadNotifProvider);
                            return IconButton(
                              onPressed: () {
                                context.push('/notifications');
                              },
                              icon: Badge(
                                isLabelVisible: hasUnread,
                                backgroundColor: AppColors.accent,
                                smallSize: 9,
                                child: const Icon(
                                  Icons.notifications_none_rounded,
                                  color: AppColors.textWhite,
                                  size: 26,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        GestureDetector(
                          onTap: () {
                            ref.read(currentTabProvider.notifier).state =
                                4; // Profile Tab
                          },
                          child: Hero(
                            tag: 'profile_avatar_hero',
                            child: Builder(
                              builder: (context) {
                                final pic = authState.user?.profilePic;
                                final imgProvider =
                                    AvatarUtils.getAvatarImageProvider(pic);
                                return CircleAvatar(
                                  radius: 22,
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
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s),
                Consumer(
                  builder: (context, ref, _) {
                    final prefs = ref.read(sharedPreferencesProvider);
                    final streak = prefs.getInt('streak_count') ?? 0;
                    if (streak == 0) return const SizedBox.shrink();
                    return Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.push('/streak-calendar'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🔥',
                                    style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 4),
                                Text(
                                  '$streak day streak!',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Remote Config Live Announcement Banner
                Consumer(
                  builder: (context, ref, _) {
                    final remoteConfig = ref.watch(remoteConfigServiceProvider);
                    if (!remoteConfig.showExamBanner) return const SizedBox.shrink();
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.m),
                      padding: const EdgeInsets.all(AppSpacing.m),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                        border: Border.all(
                            color: const Color(0xFFA5D6A7), width: 1.2),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.campaign_rounded,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: AppSpacing.s),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  remoteConfig.examBannerTitle,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFF1B5E20),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  remoteConfig.examBannerSubtitle,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Word of the Day Card
                const WordOfDayCard(),
                const SizedBox(height: AppSpacing.m),

                // Dynamic Daily Sprint / Weekend Mega Mock Card (Remote Config & A/B Testing)
                const _DailyChallengeCard(),
                const SizedBox(height: AppSpacing.m),


                  // English Grammar & Quiz Shortcut Card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3F51B5).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.menu_book_rounded,
                              color: Color(0xFF3F51B5), size: 24),
                        ),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'English Grammar & Quiz',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.5,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Rules of SV Agreement, Voice & Practice Quizzes',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/grammar-hub'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            backgroundColor: const Color(0xFF3F51B5).withValues(alpha: 0.12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text(
                            'STUDY',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3F51B5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  // Core Pillars: 4 Primary Action Cards (PYQ, Mock, Custom Test, Admin Flagger)
                  Row(
                    children: [
                      // 1. PYQ Bank Card
                      Expanded(
                        child: InkWell(
                          onTap: () => context.push('/exams-hub?tab=0'),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.m),
                            height: 125,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0D47A1).withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.history_edu_rounded, color: Colors.white, size: 20),
                                    ),
                                    const Icon(Icons.arrow_forward_rounded, color: Colors.white70, size: 16),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'PYQ Bank',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'APPSC & APSSB Papers\nExam & Study Mode',
                                      style: TextStyle(color: Colors.white70, fontSize: 10, height: 1.2),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.m),

                      // 2. Mock Tests Card
                      Expanded(
                        child: InkWell(
                          onTap: () => context.push('/exams-hub?tab=1'),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.m),
                            height: 125,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4A148C), Color(0xFF7B1FA2)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4A148C).withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.assignment_turned_in_rounded, color: Colors.white, size: 20),
                                    ),
                                    const Icon(Icons.arrow_forward_rounded, color: Colors.white70, size: 16),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'Mock Tests',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Maths, GK, English &\nTechnical Sectionals',
                                      style: TextStyle(color: Colors.white70, fontSize: 10, height: 1.2),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Row(
                    children: [
                      // 3. Custom Mock Test Card
                      Expanded(
                        child: InkWell(
                          onTap: () => showCustomPracticeModal(context),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.m),
                            height: 125,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF004D40), Color(0xFF00796B)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF004D40).withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                                    ),
                                    const Icon(Icons.arrow_forward_rounded, color: Colors.white70, size: 16),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'Custom Test',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Build Your Practice\nBy Subject & Time',
                                      style: TextStyle(color: Colors.white70, fontSize: 10, height: 1.2),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.m),

                      // 4. Official Exam Syllabus & Pattern Card
                      Expanded(
                        child: InkWell(
                          onTap: () => context.push('/syllabus'),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.m),
                            height: 125,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F766E).withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 20),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.25),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Official 2025-26',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'Exam Syllabus',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14.5,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'APSSB & APPSC Schemes,\nMarks & Negative Marking',
                                      style: TextStyle(color: Colors.white70, fontSize: 9.5, height: 1.2),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.m),

                  // 3. Current Affairs & GK
                  const _CurrentAffairsSection(),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

class _CurrentAffairsSection extends ConsumerWidget {
  const _CurrentAffairsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final affairsAsync = ref.watch(currentAffairsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '📰 Daily Current Affairs & GK',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: AppColors.primary),
              tooltip: 'View All Current Affairs & GK',
              onPressed: () => context.push('/current-affairs-gk'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s),
        affairsAsync.when(
          data: (items) {
            return SizedBox(
              height: 185,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: items.length + 2,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return InkWell(
                      onTap: () => context.push('/state-gk'),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusL),
                      child: Container(
                        width: 280,
                        margin: const EdgeInsets.only(right: AppSpacing.m),
                        padding: const EdgeInsets.all(AppSpacing.m),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F9D58), Color(0xFF0B8043)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusL),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F9D58)
                                  .withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '📚 STATE GK HANDBOOK',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Arunachal Pradesh Comprehensive Compendium',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Expanded(
                              child: Text(
                                '11 Modules: All 28 Districts, GI Tags, History, Rivers, Peaks, Governors & Demographics.',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                            const Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Explore All Chapters →',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Icon(Icons.arrow_forward_rounded,
                                    color: Colors.white, size: 16),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (index == items.length + 1) {
                    return InkWell(
                      onTap: () => context.push('/current-affairs-gk'),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusL),
                      child: Container(
                        width: 220,
                        margin: const EdgeInsets.only(right: AppSpacing.m),
                        padding: const EdgeInsets.all(AppSpacing.m),
                        decoration: BoxDecoration(
                          color:
                              AppColors.primaryLight.withValues(alpha: 0.5),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusL),
                          border: Border.all(
                              color: AppColors.primary
                                  .withValues(alpha: 0.4)),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.feed_outlined,
                                  color: AppColors.primary, size: 36),
                              SizedBox(height: 8),
                              Text(
                                'More Current Affairs & GK →',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'View All Articles & Notifications',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  final item = items[index - 1];
                  return Container(
                    width: 280,
                    margin: const EdgeInsets.only(right: AppSpacing.m),
                    padding: const EdgeInsets.all(AppSpacing.m),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.source,
                                style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary),
                              ),
                            ),
                            Text(
                              item.dateStr,
                              style: const TextStyle(
                                  fontSize: 10, color: AppColors.textHint),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Text(
                            item.summary,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () {
                                context.push('/news-details', extra: {
                                  'id': item.id,
                                  'title': item.title,
                                  'source': item.source,
                                  'date': item.dateStr,
                                  'description': item.summary,
                                  'link': item.link,
                                  'pdfUrl': item.pdfUrl ?? item.link,
                                  'keyPoints': [
                                    'Important for upcoming APSSB & APPSC exams.',
                                    'Focus on Arunachal state governance, history and geography.',
                                  ],
                                });
                              },
                              child: const Text(
                                'More Info →',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                context.push('/chatbot',
                                    extra:
                                        '${item.title}\n\n${item.summary}');
                              },
                              child: const Text(
                                'Ask AI Tutor →',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const SizedBox(
              height: 185,
              child: Center(child: CircularProgressIndicator())),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------
// Dynamic Daily Challenge / Weekly Mega Mock Card
// Driven by Firebase Remote Config & A/B Testing
// -------------------------------------------------------------
class _DailyChallengeCard extends ConsumerWidget {
  const _DailyChallengeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remoteConfig = ref.watch(remoteConfigServiceProvider);
    final isMegaMock = remoteConfig.weeklyMegaMockActive;
    final title = isMegaMock
        ? remoteConfig.weeklyMegaMockTitle
        : remoteConfig.dailyChallengeTheme;
    final questionCount = remoteConfig.dailyTestQuestionCount;
    final multiplier = remoteConfig.trophiesMultiplier;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isMegaMock
              ? const [Color(0xFF6A1B9A), Color(0xFF8E24AA)]
              : const [Color(0xFF004D40), Color(0xFF00796B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusL),
        boxShadow: [
          BoxShadow(
            color: (isMegaMock
                    ? const Color(0xFF6A1B9A)
                    : const Color(0xFF004D40))
                .withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusL),
          onTap: () {
            context.push('/mock-test/APSSB-MOCK/daily');
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isMegaMock
                        ? Icons.emoji_events_rounded
                        : Icons.bolt_rounded,
                    color: Colors.amberAccent,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (multiplier > 1.0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${multiplier}x XP',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$questionCount Questions • 5 Mins • Live Ranking',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Start',
                        style: TextStyle(
                          color: isMegaMock
                              ? const Color(0xFF6A1B9A)
                              : const Color(0xFF004D40),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: isMegaMock
                            ? const Color(0xFF6A1B9A)
                            : const Color(0xFF004D40),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
