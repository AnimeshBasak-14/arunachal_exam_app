import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/services/question_repository.dart';
import '../../../core/services/service_providers.dart';

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
  final Map<String, String> _selectedAnswers = {}; // Map of questionId -> selectedOption ('a', 'b', 'c', 'd')
  final Map<String, bool> _showSolutions = {}; // Map of questionId -> bool
  final Map<String, List<String>> _questionComments = {}; // Map of questionId -> comments
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

  @override
  void initState() {
    super.initState();
    // Filter questions matching examCode and year
    _questions = QuestionRepository.allQuestions
        .where((q) => q.examCode == widget.examCode && q.year == widget.year)
        .toList();

    // Initialize comments, controllers, and likes
    final storage = ref.read(storageServiceProvider);
    final prefs = ref.read(sharedPreferencesProvider);

    for (final q in _questions) {
      final savedComments = storage.getQuestionComments(q.id);
      _questionComments[q.id] = [...q.initialComments, ...savedComments];
      _commentControllers[q.id] = TextEditingController();

      // Pseudo-random initial likes based on question content
      _questionLikes[q.id] = (q.questionText.length % 15) + 6;
      _likedQuestions[q.id] = false;
      _likedSolutions[q.id] = false;

      // Load replies & likes for each comment index
      final allComments = _questionComments[q.id]!;
      for (int i = 0; i < allComments.length; i++) {
        // Load replies from prefs
        final repliesList = prefs.getStringList('replies_${q.id}_$i') ?? [];
        _commentReplies.putIfAbsent(q.id, () => {})[i] = repliesList;

        // Load comment likes
        final likes = prefs.getInt('likes_${q.id}_$i') ?? (i * 3 + 2); // default mock likes
        _commentLikesCount.putIfAbsent(q.id, () => {})[i] = likes;
        _commentUserLiked.putIfAbsent(q.id, () => {})[i] = prefs.getBool('user_liked_${q.id}_$i') ?? false;

        // Load reply likes
        for (int j = 0; j < repliesList.length; j++) {
          final rLikes = prefs.getInt('reply_likes_${q.id}_${i}_$j') ?? 1;
          _replyLikesCount.putIfAbsent(q.id, () => {}).putIfAbsent(i, () => {})[j] = rLikes;
          _replyUserLiked.putIfAbsent(q.id, () => {}).putIfAbsent(i, () => {})[j] = prefs.getBool('user_reply_liked_${q.id}_${i}_$j') ?? false;
        }
      }
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
        content: Text('Question copied to clipboard! Share it with other candidates.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _addComment(String questionId) async {
    final controller = _commentControllers[questionId]!;
    final text = controller.text.trim();
    if (text.isEmpty) return;

    if (_replyingToCommentIndex != null && _activeReplyingQuestionId == questionId) {
      // Save as nested reply instead of flat comment
      final prefs = ref.read(sharedPreferencesProvider);
      final cIndex = _replyingToCommentIndex!;
      final currentReplies = _commentReplies[questionId]?[cIndex] ?? [];
      
      final replyText = 'Candidate: $text';
      currentReplies.add(replyText);

      setState(() {
        _commentReplies.putIfAbsent(questionId, () => {})[cIndex] = currentReplies;
        controller.clear();
        _replyingToCommentText = null;
        _replyingToCommentIndex = null;
        _activeReplyingQuestionId = null;

        // Initialize likes for the new reply
        final newReplyIndex = currentReplies.length - 1;
        _replyLikesCount.putIfAbsent(questionId, () => {}).putIfAbsent(cIndex, () => {})[newReplyIndex] = 0;
        _replyUserLiked.putIfAbsent(questionId, () => {}).putIfAbsent(cIndex, () => {})[newReplyIndex] = false;
      });

      await prefs.setStringList('replies_${questionId}_$cIndex', currentReplies);

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
        _commentLikesCount.putIfAbsent(questionId, () => {})[newCommentIndex] = 0;
        _commentUserLiked.putIfAbsent(questionId, () => {})[newCommentIndex] = false;
      });

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
    final currentLikesCount = _commentLikesCount[questionId]?[commentIndex] ?? 0;
    final newCount = isLiked ? currentLikesCount - 1 : currentLikesCount + 1;

    setState(() {
      _commentUserLiked.putIfAbsent(questionId, () => {})[commentIndex] = !isLiked;
      _commentLikesCount.putIfAbsent(questionId, () => {})[commentIndex] = newCount;
    });

    await prefs.setBool('user_liked_${questionId}_$commentIndex', !isLiked);
    await prefs.setInt('likes_${questionId}_$commentIndex', newCount);
  }

  Future<void> _toggleReplyLike(String questionId, int commentIndex, int replyIndex) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final isLiked = _replyUserLiked[questionId]?[commentIndex]?[replyIndex] ?? false;
    final currentLikesCount = _replyLikesCount[questionId]?[commentIndex]?[replyIndex] ?? 0;
    final newCount = isLiked ? currentLikesCount - 1 : currentLikesCount + 1;

    setState(() {
      _replyUserLiked.putIfAbsent(questionId, () => {}).putIfAbsent(commentIndex, () => {})[replyIndex] = !isLiked;
      _replyLikesCount.putIfAbsent(questionId, () => {}).putIfAbsent(commentIndex, () => {})[replyIndex] = newCount;
    });

    await prefs.setBool('user_reply_liked_${questionId}_${commentIndex}_$replyIndex', !isLiked);
    await prefs.setInt('reply_likes_${questionId}_${commentIndex}_$replyIndex', newCount);
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
            size: 20,
          ),
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
        title: Text('${widget.examCode} ${widget.year} PYQ'),
      ),
      body: _questions.isEmpty
          ? const Center(
              child: Text(
                'No questions found for this past paper.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.m),
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                final question = _questions[index];
                final isBookmarked = bookmarkedIds.contains(question.id);
                final selectedOption = _selectedAnswers[question.id];
                final showSolution = _showSolutions[question.id] ?? false;
                final comments = _questionComments[question.id] ?? [];

                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.m),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                    side: const BorderSide(color: AppColors.divider),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Question Header (Subject & Actions)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                question.subject,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                _buildLikeButton(question.id),
                                IconButton(
                                  icon: const Icon(Icons.share_outlined, color: AppColors.textHint, size: 20),
                                  onPressed: () => _shareQuestion(question),
                                  tooltip: 'Share Question',
                                ),
                                IconButton(
                                  icon: Icon(
                                    isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                    color: isBookmarked ? AppColors.accent : AppColors.textHint,
                                    size: 20,
                                  ),
                                  onPressed: () async {
                                    await ref.read(bookmarkedQuestionsProvider.notifier).toggleBookmark(question.id);
                                  },
                                  tooltip: 'Bookmark Question',
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s),

                        // Question Text
                        Text(
                          'Q${index + 1}. ${question.questionText}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.m),

                        // Options List
                        ...question.options.map((option) {
                          final optionChar = option.trim().substring(1, 2).toLowerCase(); // 'a', 'b', 'c', 'd'
                          final isSelected = selectedOption == optionChar;
                          final isCorrect = question.correctAnswer == optionChar;

                          Color optionBorderColor = AppColors.divider;
                          Color optionBgColor = Colors.transparent;

                          if (selectedOption != null) {
                            if (isCorrect) {
                              optionBorderColor = AppColors.success;
                              optionBgColor = AppColors.success.withOpacity(0.06);
                            } else if (isSelected) {
                              optionBorderColor = AppColors.error;
                              optionBgColor = AppColors.error.withOpacity(0.06);
                            }
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: AppSpacing.s),
                            decoration: BoxDecoration(
                              color: optionBgColor,
                              border: Border.all(color: optionBorderColor, width: isSelected || (selectedOption != null && isCorrect) ? 2.0 : 1.0),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: selectedOption != null
                                  ? null
                                  : () {
                                      setState(() {
                                        _selectedAnswers[question.id] = optionChar;
                                        _showSolutions[question.id] = true; // Auto reveal explanation
                                      });
                                    },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: 14),
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: selectedOption != null && isCorrect
                                        ? AppColors.primaryDark
                                        : AppColors.textPrimary,
                                    fontWeight: isSelected || (selectedOption != null && isCorrect)
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: AppSpacing.s),

                        // Show solution button
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _showSolutions[question.id] = !showSolution;
                              });
                            },
                            icon: Icon(
                              showSolution ? Icons.lightbulb_outline_rounded : Icons.lightbulb_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            label: Text(
                              showSolution ? 'Hide Solution' : 'Show Solution',
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),

                        // Solution Drawer (GoClasses style explanation)
                        if (showSolution) ...[
                          const SizedBox(height: AppSpacing.s),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.m),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          const Icon(Icons.check_circle_outline_rounded, color: AppColors.primary, size: 18),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              'Official Answer: ${question.officialAnswer}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 13),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Helpful / Solution Like toggle
                                    InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () {
                                        setState(() {
                                          _likedSolutions[question.id] = !(_likedSolutions[question.id] ?? false);
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              (_likedSolutions[question.id] ?? false)
                                                  ? Icons.thumb_up_rounded
                                                  : Icons.thumb_up_outlined,
                                              color: (_likedSolutions[question.id] ?? false)
                                                  ? AppColors.primary
                                                  : AppColors.textSecondary,
                                              size: 15,
                                            ),
                                            const SizedBox(width: 4),
                                            const Text(
                                              'Helpful',
                                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.s),
                                const Text(
                                  'Explanation:',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  question.solution,
                                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const Divider(height: AppSpacing.l),

                        // Comments Section
                        const Text(
                          'Candidate Discussion',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: AppSpacing.s),

                        // List of comments
                        if (comments.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.s),
                            child: Text(
                              'No comments posted yet. Be the first to start the discussion!',
                              style: TextStyle(color: AppColors.textHint, fontSize: 12, fontStyle: FontStyle.italic),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: comments.length,
                            itemBuilder: (context, cIndex) {
                              final comment = comments[cIndex];
                              
                              final isCommentLiked = _commentUserLiked[question.id]?[cIndex] ?? false;
                              final commentLikes = _commentLikesCount[question.id]?[cIndex] ?? 0;
                              final repliesList = _commentReplies[question.id]?[cIndex] ?? [];

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Parent Comment
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.only(top: 2.0),
                                          child: Icon(Icons.forum_outlined, size: 14, color: AppColors.textSecondary),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                comment,
                                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                              ),
                                              const SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  GestureDetector(
                                                    onTap: () {
                                                      setState(() {
                                                        _replyingToCommentText = comment;
                                                        _replyingToCommentIndex = cIndex;
                                                        _activeReplyingQuestionId = question.id;
                                                      });
                                                    },
                                                    child: const Text(
                                                      'Reply',
                                                      style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Text(
                                                    '$commentLikes likes',
                                                    style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        GestureDetector(
                                          onTap: () => _toggleCommentLike(question.id, cIndex),
                                          child: Icon(
                                            isCommentLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                            size: 16,
                                            color: isCommentLiked ? Colors.red : AppColors.textHint,
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    // Nested Replies (Instagram Style)
                                    if (repliesList.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 28.0, top: 6.0),
                                        child: Column(
                                          children: repliesList.asMap().entries.map((replyEntry) {
                                            final rIndex = replyEntry.key;
                                            final reply = replyEntry.value;

                                            final isReplyLiked = _replyUserLiked[question.id]?[cIndex]?[rIndex] ?? false;
                                            final replyLikes = _replyLikesCount[question.id]?[cIndex]?[rIndex] ?? 0;

                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 6.0),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Padding(
                                                    padding: EdgeInsets.only(top: 2.0, right: 6.0),
                                                    child: Icon(Icons.subdirectory_arrow_right_rounded, size: 12, color: AppColors.textHint),
                                                  ),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          reply,
                                                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          '$replyLikes likes',
                                                          style: const TextStyle(fontSize: 10, color: AppColors.textHint),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  GestureDetector(
                                                    onTap: () => _toggleReplyLike(question.id, cIndex, rIndex),
                                                    child: Icon(
                                                      isReplyLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                                      size: 14,
                                                      color: isReplyLiked ? Colors.red : AppColors.textHint,
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
                        if (_replyingToCommentText != null && _activeReplyingQuestionId == question.id)
                          Container(
                            color: AppColors.primaryLight.withOpacity(0.4),
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: 4),
                            margin: const EdgeInsets.only(bottom: AppSpacing.s),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Replying to: "$_replyingToCommentText"',
                                    style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.primaryDark),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 14, color: AppColors.error),
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
                                controller: _commentControllers[question.id],
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: _replyingToCommentText != null && _activeReplyingQuestionId == question.id
                                      ? 'Write a reply...'
                                      : 'Ask a question or comment...',
                                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: 8),
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
                              icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                              onPressed: () => _addComment(question.id),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
