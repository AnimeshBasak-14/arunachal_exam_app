import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/avatar_utils.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import '../viewmodel/exam_viewmodel.dart';
import '../../profile/view/profile_screen.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/services/question_repository.dart';
import 'notifications_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/word_of_day_card.dart';
import '../../../core/services/current_affairs_service.dart';

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
      floatingActionButton: selectedTab == 0
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/chatbot'),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.psychology_rounded, color: Colors.white),
              label: const Text(
                'AI Tutor',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
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
          currentIndex: selectedTab,
          onTap: (index) {
            ref.read(currentTabProvider.notifier).state = index;
          },
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textHint,
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final userName = authState.user?.name ?? 'Student Name';
    final exams = ref.watch(examViewModelProvider);
    final searchQuery = ref.watch(searchFilterProvider);

    final filteredExams = exams
        .where((exam) =>
            exam.code.toLowerCase().contains(searchQuery.toLowerCase()) ||
            exam.name.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

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

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1040),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
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
                    // Profile & Notification Badge
                    Row(
                      children: [
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
                                  size: 28,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: AppSpacing.s),
                        GestureDetector(
                          onTap: () {
                            ref.read(currentTabProvider.notifier).state =
                                2; // Profile Tab
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
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: AppColors.textSecondary),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    ref
                                        .read(searchFilterProvider.notifier)
                                        .state = '';
                                  },
                                )
                              : null,
                          fillColor: AppColors.surface,
                          filled: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 0),
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
                          ref.read(searchFilterProvider.notifier).state =
                              searchQuery.isEmpty ? 'Exam' : '';
                          _searchController.text =
                              ref.read(searchFilterProvider);
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.filter_list_rounded,
                                color: AppColors.textWhite, size: 18),
                            SizedBox(width: 4),
                            Text(
                              AppStrings.filterText,
                              style: TextStyle(
                                  color: AppColors.textWhite,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.l),

                // Render dynamic search results if active
                if (searchQuery.isNotEmpty) ...[
                  Text(
                    'Search Results (${filteredExams.length})',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  if (filteredExams.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                      child: Center(
                        child: Text(
                          'No matching exams found.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredExams.length,
                      itemBuilder: (context, index) {
                        final exam = filteredExams[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.s),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusL),
                            border:
                                Border.all(color: AppColors.divider, width: 1),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primaryLight,
                              child: Icon(exam.icon,
                                  color: AppColors.primary, size: 22),
                            ),
                            title: Text(
                              exam.code,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary),
                            ),
                            subtitle: Text(
                              exam.name,
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 13),
                            ),
                            trailing: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 16,
                                color: AppColors.textHint),
                            onTap: () {
                              context.push('/exam-detail/${exam.id}');
                            },
                          ),
                        );
                      },
                    ),
                ] else ...[
                  // Word of the Day Card
                  const WordOfDayCard(),
                  const SizedBox(height: AppSpacing.m),

                  // 3. Current Affairs & GK
                  const _CurrentAffairsSection(),
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
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusL),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withValues(alpha: 0.25),
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
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusL),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.teal.withValues(alpha: 0.25),
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

// -------------------------------------------------------------
// Bookmarks Tab Body (Page 11 bookmarks tab)
// -------------------------------------------------------------
class BookmarksTabBody extends ConsumerStatefulWidget {
  const BookmarksTabBody({super.key});

  @override
  ConsumerState<BookmarksTabBody> createState() => _BookmarksTabBodyState();
}

class _BookmarksTabBodyState extends ConsumerState<BookmarksTabBody>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Question> _bookmarkedQs = [];
  bool _loadingQs = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _loadBookmarkedQuestions(List<String> ids) async {
    if (ids.isEmpty) {
      setState(() {
        _bookmarkedQs = [];
        _loadingQs = false;
      });
      return;
    }
    setState(() => _loadingQs = true);
    try {
      final firestore = FirebaseFirestore.instance;
      // Firestore whereIn supports up to 30 items
      final chunks = <List<String>>[];
      for (int i = 0; i < ids.length; i += 30) {
        chunks.add(ids.sublist(i, i + 30 > ids.length ? ids.length : i + 30));
      }
      final results = <Question>[];
      for (final chunk in chunks) {
        final snap = await firestore
            .collection('questions')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        results.addAll(snap.docs.map((d) => Question.fromFirestore(d)));
      }
      if (mounted) {
        setState(() {
          _bookmarkedQs = results;
          _loadingQs = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingQs = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookmarkedExams = ref.watch(bookmarkedExamsProvider);

    // Load question bookmarks
    final bookmarkedQuestionIds = ref.watch(bookmarkedQuestionsProvider);

    if (!_loadingQs &&
        _bookmarkedQs.isEmpty &&
        bookmarkedQuestionIds.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadBookmarkedQuestions(bookmarkedQuestionIds);
      });
    }

    final bookmarkedQuestions = _bookmarkedQs;

    // Group by Exam Code
    final Map<String, List<Question>> groupedByExam = {};
    for (final q in bookmarkedQuestions) {
      groupedByExam.putIfAbsent(q.examCode, () => []).add(q);
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Text(
            'Bookmarks',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.s),

          // Tab Selector
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3.0,
            tabs: const [
              Tab(text: 'SAVED EXAMS'),
              Tab(text: 'QUESTIONS'),
            ],
          ),
          const SizedBox(height: AppSpacing.m),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Saved Exams
                bookmarkedExams.isEmpty
                    ? _buildEmptyState(
                        icon: Icons.bookmark_outline_rounded,
                        title: 'No saved exams',
                        subtitle: 'Browse exams and tap the star to save them.',
                      )
                    : ListView.builder(
                        itemCount: bookmarkedExams.length,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          final exam = bookmarkedExams[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: AppSpacing.s),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primaryLight,
                                child:
                                    Icon(exam.icon, color: AppColors.primary),
                              ),
                              title: Text(
                                exam.code,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                exam.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.bookmark_rounded,
                                    color: AppColors.primary),
                                onPressed: () {
                                  ref
                                      .read(examViewModelProvider.notifier)
                                      .toggleBookmark(exam.id);
                                },
                              ),
                              onTap: () {
                                context.push('/exam-detail/${exam.id}');
                              },
                            ),
                          );
                        },
                      ),

                // Tab 2: Grouped Questions
                bookmarkedQuestions.isEmpty
                    ? _buildEmptyState(
                        icon: Icons.question_answer_outlined,
                        title: 'No bookmarked questions',
                        subtitle:
                            'Read through PYQs and tap bookmark to save questions here.',
                      )
                    : ListView.builder(
                        itemCount: groupedByExam.keys.length,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          final examCode = groupedByExam.keys.elementAt(index);
                          final questions = groupedByExam[examCode]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.s,
                                    horizontal: AppSpacing.xs),
                                child: Text(
                                  '$examCode QUESTIONS (${questions.length})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ),
                              ...questions.map((q) {
                                return Card(
                                  margin: const EdgeInsets.only(
                                      bottom: AppSpacing.s),
                                  child: ListTile(
                                    title: Text(
                                      q.questionText,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Text(
                                      '${q.subject} • ${q.year} Paper',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    trailing: const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 14),
                                    onTap: () {
                                      context.push(
                                          '/pyqs/${q.examCode}/${q.year}');
                                    },
                                  ),
                                );
                              }),
                              const SizedBox(height: AppSpacing.m),
                            ],
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
      {required IconData icon,
      required String title,
      required String subtitle}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 72, color: AppColors.textHint.withValues(alpha: 0.5)),
        const SizedBox(height: AppSpacing.m),
        Text(
          title,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              fontSize: 16),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textHint, fontSize: 13),
        ),
      ],
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
