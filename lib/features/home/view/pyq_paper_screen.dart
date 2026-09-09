import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/services/question_repository.dart';
import '../../../core/services/service_providers.dart';
import '../widgets/single_question_widget.dart';
import '../widgets/comprehension_group_widget.dart';

class PyqPaperScreen extends ConsumerStatefulWidget {
  final String examCode;
  final int year;

  const PyqPaperScreen({
    super.key,
    required this.examCode,
    required this.year,
  });

  @override
  ConsumerState<PyqPaperScreen> createState() => _PyqPaperScreenState();
}

class _PyqPaperScreenState extends ConsumerState<PyqPaperScreen> {
  late List<Question> _questions;
  final Map<String, String> _selectedAnswers =
      {}; // Map of questionId -> selectedOption ('a', 'b', 'c', 'd')
  final Map<String, bool> _showSolutions = {}; // Map of questionId -> bool
  final Map<String, List<String>> _questionComments =
      {}; // Map of questionId -> comments
  final Map<String, TextEditingController> _commentControllers = {};

  final Map<String, int> _questionLikes = {};
  final Map<String, bool> _likedQuestions = {};
  final Map<String, bool> _likedSolutions = {};

  // Structured comment replies (questionId -> commentIndex -> replies list)
  final Map<String, Map<int, List<String>>> _commentReplies = {};

  // Comment likes (questionId -> commentIndex -> likes count / liked status)
  final Map<String, Map<int, int>> _commentLikesCount = {};
  final Map<String, Map<int, bool>> _commentUserLiked = {};

  // Reply likes (questionId -> commentIndex -> replyIndex -> likes count / liked status)
  final Map<String, Map<int, Map<int, int>>> _replyLikesCount = {};
  final Map<String, Map<int, Map<int, bool>>> _replyUserLiked = {};

  String? _replyingToCommentText;
  int? _replyingToCommentIndex;
  String? _activeReplyingQuestionId;

  String _selectedSubject = 'All';
  List<String> _allSubjects = ['All'];
  List<Question> _filteredQuestions = [];

  List<QuestionDisplayGroup> _buildDisplayGroups() =>
      buildQuestionDisplayGroups(_filteredQuestions);

  @override
  void initState() {
    super.initState();
    // 1. Initial quick load from local bank (strictly matching year if specified)
    _questions = QuestionRepository.allQuestions
        .where((q) =>
            q.examCode == widget.examCode &&
            (widget.year <= 2000 || q.year == widget.year))
        .toList();
    _filteredQuestions = _questions;
    _initQuestionMetadata();

    // 2. Fetch all live synced questions from Cloud Firestore & Supabase
    _loadLiveQuestions();
  }

  Future<void> _loadLiveQuestions() async {
    try {
      final live = await QuestionRepository.fetchLiveQuestions(
        examCode: widget.examCode,
        year: widget.year > 2000 ? widget.year : null,
        paperType: 'PYQ',
      );
      // Strictly filter to PYQ only and match year if specified
      final pyqOnly = live.where((q) {
        final isPyq = q.paperType.toUpperCase() == 'PYQ';
        final matchesYear = widget.year <= 2000 || q.year == widget.year;
        return isPyq && matchesYear;
      }).toList();

      final result = pyqOnly.isNotEmpty
          ? pyqOnly
          : live.where((q) => q.paperType.toUpperCase() == 'PYQ').toList();

      if (result.isNotEmpty && mounted) {
        setState(() {
          _questions = result;
          _initQuestionMetadata();
          final subjects = [
            'All',
            ...{...result.map((q) => q.subject)}.where((s) => s.isNotEmpty)
          ];
          _allSubjects = subjects;
          _selectedSubject = 'All';
          _filteredQuestions = result;
        });
      }
    } catch (_) {}
  }

  void _applySubjectFilter(String subject) {
    setState(() {
      _selectedSubject = subject;
      _filteredQuestions = subject == 'All'
          ? _questions
          : _questions.where((q) => q.subject == subject).toList();
    });
  }

  void _initQuestionMetadata() {
    final storage = ref.read(storageServiceProvider);
    final prefs = ref.read(sharedPreferencesProvider);

    for (final q in _questions) {
      final qId = q.id;
      final savedComments = storage.getQuestionComments(qId);
      final allComments = [...q.initialComments, ...savedComments];
      _questionComments[qId] = allComments;
      _commentControllers[qId] = TextEditingController();

      _questionLikes[qId] = (q.questionText.length % 15) + 6;
      _likedQuestions[qId] = false;
      _likedSolutions[qId] = false;

      final qCommentReplies = <int, List<String>>{};
      final qCommentLikesCount = <int, int>{};
      final qCommentUserLiked = <int, bool>{};
      final qReplyLikesCount = <int, Map<int, int>>{};
      final qReplyUserLiked = <int, Map<int, bool>>{};

      for (int i = 0; i < allComments.length; i++) {
        final keyPrefix = '${qId}_$i';
        final repliesList = prefs.getStringList('replies_$keyPrefix') ?? [];
        qCommentReplies[i] = repliesList;

        qCommentLikesCount[i] = prefs.getInt('likes_$keyPrefix') ?? (i * 3 + 2);
        qCommentUserLiked[i] = prefs.getBool('user_liked_$keyPrefix') ?? false;

        if (repliesList.isNotEmpty) {
          final iReplyLikes = <int, int>{};
          final iReplyUserLiked = <int, bool>{};

          for (int j = 0; j < repliesList.length; j++) {
            final replyKeyPrefix = '${keyPrefix}_$j';
            iReplyLikes[j] = prefs.getInt('reply_likes_$replyKeyPrefix') ?? 1;
            iReplyUserLiked[j] = prefs.getBool('user_reply_liked_$replyKeyPrefix') ?? false;
          }

          qReplyLikesCount[i] = iReplyLikes;
          qReplyUserLiked[i] = iReplyUserLiked;
        }
      }

      _commentReplies[qId] = qCommentReplies;
      _commentLikesCount[qId] = qCommentLikesCount;
      _commentUserLiked[qId] = qCommentUserLiked;
      _replyLikesCount[qId] = qReplyLikesCount;
      _replyUserLiked[qId] = qReplyUserLiked;
    }
  }

  @override
  void dispose() {
    for (final controller in _commentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _shareQuestion(Question question) {
    final shareText = 'Check out this PYQ on Arunachal Exam App!\n\n'
        'Q. ${question.questionText}\n'
        'Subject: ${question.subject}\n'
        'Exam: ${question.examCode} ${question.year}\n\n'
        'Install Arunachal Exam App to view solutions, discussions, and mock tests!';

    Clipboard.setData(ClipboardData(text: shareText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Question copied to clipboard! Share it with other candidates.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _addComment(String questionId) async {
    final controller = _commentControllers[questionId]!;
    final text = controller.text.trim();
    if (text.isEmpty) return;

    if (_replyingToCommentIndex != null &&
        _activeReplyingQuestionId == questionId) {
      // Save as nested reply instead of flat comment
      final prefs = ref.read(sharedPreferencesProvider);
      final cIndex = _replyingToCommentIndex!;
      final currentReplies = _commentReplies[questionId]?[cIndex] ?? [];

      final replyText = 'Candidate: $text';
      currentReplies.add(replyText);

      setState(() {
        _commentReplies.putIfAbsent(questionId, () => {})[cIndex] =
            currentReplies;
        controller.clear();
        _replyingToCommentText = null;
        _replyingToCommentIndex = null;
        _activeReplyingQuestionId = null;

        // Initialize likes for the new reply
        final newReplyIndex = currentReplies.length - 1;
        _replyLikesCount
            .putIfAbsent(questionId, () => {})
            .putIfAbsent(cIndex, () => {})[newReplyIndex] = 0;
        _replyUserLiked
            .putIfAbsent(questionId, () => {})
            .putIfAbsent(cIndex, () => {})[newReplyIndex] = false;
      });

      await prefs.setStringList(
          'replies_${questionId}_$cIndex', currentReplies);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reply posted successfully!'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // Save as regular flat comment
      final storage = ref.read(storageServiceProvider);
      storage.addQuestionComment(questionId, text);

      setState(() {
        _questionComments[questionId]!.add(text);
        controller.clear();

        // Initialize likes and replies for the new comment
        final newCommentIndex = _questionComments[questionId]!.length - 1;
        _commentReplies.putIfAbsent(questionId, () => {})[newCommentIndex] = [];
        _commentLikesCount.putIfAbsent(questionId, () => {})[newCommentIndex] =
            0;
        _commentUserLiked.putIfAbsent(questionId, () => {})[newCommentIndex] =
            false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comment posted successfully!'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _toggleCommentLike(String questionId, int commentIndex) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final isLiked = _commentUserLiked[questionId]?[commentIndex] ?? false;
    final currentLikesCount =
        _commentLikesCount[questionId]?[commentIndex] ?? 0;
    final newCount = isLiked ? currentLikesCount - 1 : currentLikesCount + 1;

    setState(() {
      _commentUserLiked.putIfAbsent(questionId, () => {})[commentIndex] =
          !isLiked;
      _commentLikesCount.putIfAbsent(questionId, () => {})[commentIndex] =
          newCount;
    });

    await prefs.setBool('user_liked_${questionId}_$commentIndex', !isLiked);
    await prefs.setInt('likes_${questionId}_$commentIndex', newCount);
  }

  Future<void> _toggleReplyLike(
      String questionId, int commentIndex, int replyIndex) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final isLiked =
        _replyUserLiked[questionId]?[commentIndex]?[replyIndex] ?? false;
    final currentLikesCount =
        _replyLikesCount[questionId]?[commentIndex]?[replyIndex] ?? 0;
    final newCount = isLiked ? currentLikesCount - 1 : currentLikesCount + 1;

    setState(() {
      _replyUserLiked
          .putIfAbsent(questionId, () => {})
          .putIfAbsent(commentIndex, () => {})[replyIndex] = !isLiked;
      _replyLikesCount
          .putIfAbsent(questionId, () => {})
          .putIfAbsent(commentIndex, () => {})[replyIndex] = newCount;
    });

    await prefs.setBool(
        'user_reply_liked_${questionId}_${commentIndex}_$replyIndex', !isLiked);
    await prefs.setInt(
        'reply_likes_${questionId}_${commentIndex}_$replyIndex', newCount);
  }

  Widget _buildLikeButton(String questionId) {
    final isLiked = _likedQuestions[questionId] ?? false;
    final likesCount = _questionLikes[questionId] ?? 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            isLiked ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
            color: isLiked ? AppColors.primary : AppColors.textHint,
            size: 18,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          onPressed: () {
            setState(() {
              if (isLiked) {
                _likedQuestions[questionId] = false;
                _questionLikes[questionId] = likesCount - 1;
              } else {
                _likedQuestions[questionId] = true;
                _questionLikes[questionId] = likesCount + 1;
              }
            });
          },
        ),
        Text(
          '$likesCount',
          style: TextStyle(
            fontSize: 12,
            color: isLiked ? AppColors.primary : AppColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    final bookmarkedIds = ref.watch(bookmarkedQuestionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.examCode}${widget.year > 2000 ? ' ${widget.year}' : ''}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Text(
              'Study Mode — Tap an option to answer',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: _questions.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.folder_off_rounded, size: 54, color: AppColors.textHint),
                    const SizedBox(height: AppSpacing.m),
                    Text('No PYQ papers uploaded for ${widget.examCode} yet.', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: AppSpacing.s),
                    const Text('New papers are uploaded regularly via the CMS web portal.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: AppSpacing.m),
                    ElevatedButton.icon(
                      onPressed: _loadLiveQuestions,
                      icon: const Icon(Icons.refresh),
                      label: const Text('RETRY LOADING'),
                    ),
                  ],
                ),
              ),
            )
          : Column(

                  children: [
                    if (_allSubjects.length > 1)
                      SizedBox(
                        height: 48,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.m, vertical: 6),
                          itemCount: _allSubjects.length,
                          itemBuilder: (context, i) {
                            final subj = _allSubjects[i];
                            final isSelected = _selectedSubject == subj;
                            return GestureDetector(
                              onTap: () => _applySubjectFilter(subj),
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.divider,
                                  ),
                                ),
                                child: Text(
                                  subj,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final displayGroups = _buildDisplayGroups();
                          return ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(
                              AppSpacing.m,
                              AppSpacing.m,
                              AppSpacing.m,
                              MediaQuery.of(context).padding.bottom + 96,
                            ),
                            itemCount: displayGroups.length,
                            itemBuilder: (context, gIdx) {
                              final group = displayGroups[gIdx];
                              final isGroup = group.isGroup;

                              if (isGroup) {
                                return ComprehensionGroupWidget(
                                  key: ValueKey('group_${group.groupId ?? gIdx}'),
                                  passage: group.passage,
                                  passageImage: group.passageImage,
                                  startIndex: group.startIndex,
                                  endIndex: group.endIndex,
                                  children: [
                                    for (int qSubIdx = 0;
                                        qSubIdx < group.questions.length;
                                        qSubIdx++)
                                      _buildQuestionItem(
                                        question: group.questions[qSubIdx],
                                        displayNum: group.startIndex + qSubIdx,
                                        bookmarkedIds: bookmarkedIds,
                                        isInsideGroup: true,
                                      ),
                                  ],
                                );
                              }

                              // ─── Standalone Question ───────────────────────────
                              final question = group.questions.first;
                              final displayNum = group.startIndex;
                              return Card(
                                key: ValueKey(question.id),
                                margin: const EdgeInsets.only(bottom: AppSpacing.m),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                                  side: const BorderSide(color: AppColors.divider, width: 1.0),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.m),
                                  child: _buildQuestionItem(
                                    question: question,
                                    displayNum: displayNum,
                                    bookmarkedIds: bookmarkedIds,
                                    isInsideGroup: false,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildQuestionItem({
    required Question question,
    required int displayNum,
    required List<String> bookmarkedIds,
    required bool isInsideGroup,
  }) {
    final isBookmarked = bookmarkedIds.contains(question.id);
    final selectedOption = _selectedAnswers[question.id];
    final showSolution = _showSolutions[question.id] ?? false;

    return SingleQuestionWidget(
      key: ValueKey(question.id),
      question: question,
      displayNum: displayNum,
      isInsideGroup: isInsideGroup,
      selectedOption: selectedOption,
      onSelectOption: (val) {
        setState(() {
          _selectedAnswers[question.id] = val;
        });
      },
      showSolution: showSolution,
      onToggleSolution: () {
        setState(() {
          _showSolutions[question.id] = !showSolution;
        });
      },
      isBookmarked: isBookmarked,
      onToggleBookmark: () async {
        await ref
            .read(bookmarkedQuestionsProvider.notifier)
            .toggleBookmark(question.id);
      },
      onShare: () => _shareQuestion(question),
      selectedSubjectFilter: _selectedSubject,
      isHelpfulLiked: _likedSolutions[question.id] ?? false,
      onToggleHelpful: () {
        setState(() {
          final current = _likedSolutions[question.id] ?? false;
          _likedSolutions[question.id] = !current;
        });
      },
      likeButton: _buildLikeButton(question.id),
      discussionWidget: _buildDiscussionWidget(question),
    );
  }

  Widget _buildDiscussionWidget(Question question) {
    final comments = _questionComments[question.id] ?? [];
    final commentController = _commentControllers.putIfAbsent(
      question.id,
      () => TextEditingController(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Comments Section
        const Text(
          'Candidate Discussion',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.s),

        if (comments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.s),
            child: Text(
              'No comments posted yet. Be the first to start the discussion!',
              style: TextStyle(
                  color: AppColors.textHint,
                  fontSize: 12,
                  fontStyle: FontStyle.italic),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: comments.length,
            itemBuilder: (context, cIndex) {
              final comment = comments[cIndex];
              final isCommentLiked =
                  _commentUserLiked[question.id]?[cIndex] ?? false;
              final commentLikes =
                  _commentLikesCount[question.id]?[cIndex] ?? 0;
              final repliesList =
                  _commentReplies[question.id]?[cIndex] ?? [];

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2.0),
                          child: Icon(Icons.forum_outlined,
                              size: 14, color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                comment,
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _replyingToCommentText = comment;
                                        _replyingToCommentIndex = cIndex;
                                        _activeReplyingQuestionId =
                                            question.id;
                                      });
                                    },
                                    child: const Text(
                                      'Reply',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '$commentLikes likes',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textHint),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () =>
                              _toggleCommentLike(question.id, cIndex),
                          child: Icon(
                            isCommentLiked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 16,
                            color: isCommentLiked
                                ? Colors.red
                                : AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                    if (repliesList.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 28.0, top: 6.0),
                        child: Column(
                          children:
                              repliesList.asMap().entries.map((replyEntry) {
                            final rIndex = replyEntry.key;
                            final reply = replyEntry.value;
                            final isReplyLiked = _replyUserLiked[question.id]
                                    ?[cIndex]?[rIndex] ??
                                false;
                            final replyLikes = _replyLikesCount[question.id]
                                    ?[cIndex]?[rIndex] ??
                                0;

                            return Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 6.0),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(
                                        top: 2.0, right: 6.0),
                                    child: Icon(
                                        Icons
                                            .subdirectory_arrow_right_rounded,
                                        size: 12,
                                        color: AppColors.textHint),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          reply,
                                          style: const TextStyle(
                                              color: AppColors
                                                  .textSecondary,
                                              fontSize: 11.5),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$replyLikes likes',
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color: AppColors.textHint),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () => _toggleReplyLike(
                                        question.id, cIndex, rIndex),
                                    child: Icon(
                                      isReplyLiked
                                          ? Icons.favorite_rounded
                                          : Icons
                                              .favorite_border_rounded,
                                      size: 14,
                                      color: isReplyLiked
                                          ? Colors.red
                                          : AppColors.textHint,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        const SizedBox(height: AppSpacing.s),

        // Replying Header Banner
        if (_replyingToCommentText != null &&
            _activeReplyingQuestionId == question.id)
          Container(
            color: AppColors.primaryLight.withValues(alpha: 0.4),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.m, vertical: 4),
            margin: const EdgeInsets.only(bottom: AppSpacing.s),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Replying to: "$_replyingToCommentText"',
                    style: const TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: AppColors.primaryDark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 14, color: AppColors.error),
                  onPressed: () {
                    setState(() {
                      _replyingToCommentText = null;
                      _replyingToCommentIndex = null;
                      _activeReplyingQuestionId = null;
                    });
                  },
                ),
              ],
            ),
          ),

        // Write comment text field
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: commentController,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: _replyingToCommentText != null &&
                          _activeReplyingQuestionId == question.id
                      ? 'Write a reply...'
                      : 'Ask a question or comment...',
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.m, vertical: 8),
                  fillColor: AppColors.background,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            IconButton(
              icon: const Icon(Icons.send_rounded,
                  color: AppColors.primary),
              onPressed: () => _addComment(question.id),
            ),
          ],
        ),
      ],
    );
  }
}
