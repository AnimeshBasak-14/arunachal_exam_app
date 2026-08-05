import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import '../viewmodel/exam_viewmodel.dart';
import '../../profile/view/profile_screen.dart';

final currentTabProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(currentTabProvider);

    final tabs = [
      const HomeTabBody(),
      const BookmarksTabBody(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: tabs[selectedTab],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: selectedTab,
          onTap: (index) {
            ref.read(currentTabProvider.notifier).state = index;
          },
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textHint,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          backgroundColor: AppColors.surface,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_outline_rounded),
              activeIcon: Icon(Icons.bookmark_rounded),
              label: 'Bookmarks',
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
  bool _showNotifications = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final userName = authState.user?.name ?? 'Student Name';
    final searchQuery = ref.watch(searchFilterProvider);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header Card (Page 2 & 11)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.xl),
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
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: AppColors.textWhite,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'What do you want to learn today?',
                            style: TextStyle(
                              color: AppColors.textWhite.withOpacity(0.85),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.m),
                    // Profile & Notification Badge
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _showNotifications = !_showNotifications;
                            });
                          },
                          icon: const Badge(
                            isLabelVisible: true,
                            backgroundColor: AppColors.accent,
                            child: Icon(
                              Icons.notifications_none_rounded,
                              color: AppColors.textWhite,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s),
                        GestureDetector(
                          onTap: () {
                            ref.read(currentTabProvider.notifier).state = 2; // Profile Tab
                          },
                          child: Hero(
                            tag: 'profile_avatar_hero',
                            child: CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColors.surface,
                              child: Text(
                                userName.isNotEmpty ? userName[0].toUpperCase() : 'S',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Notification overlay view (Page 11 overlay representation)
          if (_showNotifications)
            Container(
              margin: const EdgeInsets.all(AppSpacing.m),
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                border: Border.all(color: AppColors.divider),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '✓ Notification Panel',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                        onPressed: () {
                          setState(() {
                            _showNotifications = false;
                          });
                        },
                      )
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s),
                  const Text(
                    'Welcome to Arunachal Exam Prep! Prepare for APPSC & APSSB exams. Bookmark exams to save them.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 2. Search & Filter Bar (Page 2 & 11)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          ref.read(searchFilterProvider.notifier).state = val;
                        },
                        decoration: InputDecoration(
                          hintText: AppStrings.searchPlaceholder,
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    ref.read(searchFilterProvider.notifier).state = '';
                                  },
                                )
                              : null,
                          fillColor: AppColors.surface,
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Container(
                      height: 48,
                      width: 90,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () {
                          // Toggle simple filter helper
                          ref.read(searchFilterProvider.notifier).state = searchQuery.isEmpty ? 'Exam' : '';
                          _searchController.text = ref.read(searchFilterProvider);
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.filter_list_rounded, color: AppColors.textWhite, size: 18),
                            SizedBox(width: 4),
                            Text(
                              AppStrings.filterText,
                              style: TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.l),

                // 3. Promoted Banner (Video Section)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade400,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'APPSC/APSSB Prep',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'General Studies:\nIntro to Arunachal',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    height: 1.2,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s),
                      // Play Button UI representation
                      Container(
                        width: 54,
                        height: 54,
                        decoration: const BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: AppColors.primary,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.l),

                // 4. Categories header
                Text(
                  AppStrings.categories,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: AppSpacing.m),

                // Grid Buttons for Categories (Page 2 and 11)
                Row(
                  children: [
                    // APPSC Category Button
                    Expanded(
                      child: InkWell(
                        onTap: () => context.push('/appsc'),
                        child: Container(
                          height: 110,
                          decoration: BoxDecoration(
                            gradient: AppColors.appscGradient,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              AppStrings.appsc,
                              style: TextStyle(
                                color: AppColors.textWhite,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.m),
                    // APSSB Category Button
                    Expanded(
                      child: InkWell(
                        onTap: () => context.push('/apssb'),
                        child: Container(
                          height: 110,
                          decoration: BoxDecoration(
                            gradient: AppColors.apssbGradient,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.teal.withOpacity(0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              AppStrings.apssb,
                              style: TextStyle(
                                color: AppColors.textWhite,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// Bookmarks Tab Body (Page 11 bookmarks tab)
// -------------------------------------------------------------
class BookmarksTabBody extends ConsumerWidget {
  const BookmarksTabBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarked = ref.watch(bookmarkedExamsProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Saved Exams',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.s),
          const Text(
            'Access your pinned APPSC & APSSB examinations quickly.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.l),
          if (bookmarked.isEmpty)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_outline_rounded, size: 72, color: AppColors.textHint.withOpacity(0.5)),
                  const SizedBox(height: AppSpacing.m),
                  const Text(
                    'No bookmarks added yet',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 16),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    'Browse exams in categories and tap the star to pin them.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textHint, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: bookmarked.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final exam = bookmarked[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.s),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primaryLight,
                        child: Icon(exam.icon, color: AppColors.primary),
                      ),
                      title: Text(
                        exam.code,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        exam.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.bookmark_rounded, color: AppColors.primary),
                        onPressed: () {
                          ref.read(examViewModelProvider.notifier).toggleBookmark(exam.id);
                        },
                      ),
                      onTap: () {
                        context.push('/exam-detail/${exam.id}');
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
