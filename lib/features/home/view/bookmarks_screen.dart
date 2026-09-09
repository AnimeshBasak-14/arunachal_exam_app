import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../core/services/question_repository.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../viewmodel/exam_viewmodel.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Saved Bookmarks',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: const BookmarksTabBody(showHeader: false),
          ),
        ),
      ),
    );
  }
}

class BookmarksTabBody extends ConsumerStatefulWidget {
  final bool showHeader;
  const BookmarksTabBody({super.key, this.showHeader = true});

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
      final results = <Question>[];
      final idParams = ids.map((id) => '"$id"').join(',');
      final url =
          'https://fllopztywwblbucvaths.supabase.co/rest/v1/questions?id=in.($idParams)&select=*,tests(*)';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'apikey': 'sb_publishable_y68QKKHxBTZxBP3Sf1X7tw_zfFnXX8M',
          'Authorization':
              'Bearer sb_publishable_y68QKKHxBTZxBP3Sf1X7tw_zfFnXX8M',
        },
      );
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        results.addAll(
          list.map(
            (item) => Question.fromSupabase(item as Map<String, dynamic>),
          ),
        );
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
          // Header (if showHeader is true)
          if (widget.showHeader) ...[
            Text(
              'Bookmarks',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.s),
          ],

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
