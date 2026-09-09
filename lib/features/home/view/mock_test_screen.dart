import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/services/question_repository.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/remote_config_service.dart';
import '../../../core/utils/rank_utils.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import '../widgets/single_question_widget.dart';
import '../widgets/comprehension_group_widget.dart';
import '../../../core/widgets/antigravity_timer_ring.dart';
import '../../../core/widgets/antigravity_glass_card.dart';

class MockTestScreen extends ConsumerStatefulWidget {
  final String examCode;
  final String testType; // 'topic', 'full', '5', '10', '20'
  final String? subject; // Optional subject/topic filter (e.g., 'English', 'Mathematics')
  final String? difficulty; // Optional difficulty filter (e.g., 'Easy', 'Medium', 'Hard')
  final String? paperType; // 'PYQ' or 'MOCK' — defaults to 'MOCK'
  final int? year; // Optional year filter for PYQ practice tests
  final int? durationMinutes; // Optional test duration in minutes
  final bool isStudyMode; // false = Timed Exam Mode, true = Study Mode (Instant Solutions)
  final List<Question>? initialQuestions; // Optional pre-fetched questions for custom practice

  const MockTestScreen({
    super.key,
    required this.examCode,
    required this.testType,
    this.subject,
    this.difficulty,
    this.paperType,
    this.year,
    this.durationMinutes,
    this.isStudyMode = false,
    this.initialQuestions,
  });

  @override
  ConsumerState<MockTestScreen> createState() => _MockTestScreenState();
}

class _MockTestScreenState extends ConsumerState<MockTestScreen> {
  late List<Question> _testQuestions;
  final Map<String, String> _selectedAnswers = {}; // questionId -> optionChar
  final Map<String, bool> _showSolutions = {}; // questionId -> showSolution boolean
  Timer? _timer; // nullable — timer starts only after questions are fetched
  int _secondsRemaining = 300; // Dynamic based on question count
  int _initialSeconds = 300;
  bool _isSubmitted = false;
  bool _isLoadingQuestions = true;

  // Calculated Results state
  double _scoreObtained = 0.0;
  double _maxScore = 0.0;
  int _correctCount = 0;
  int _incorrectCount = 0;
  int _unattemptedCount = 0;
  int _ratingChange = 0;
  int _newRating = 1200;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuestions != null && widget.initialQuestions!.isNotEmpty) {
      _testQuestions = List.from(widget.initialQuestions!);
      _isLoadingQuestions = false;
      final mins = widget.durationMinutes ??
          (_testQuestions.length <= 10
              ? 15
              : (_testQuestions.length <= 20 ? 30 : 60));
      _secondsRemaining = mins * 60;
      _initialSeconds = _secondsRemaining;
      if (!widget.isStudyMode) {
        _startTimer();
      }
    } else {
      // 1. Initial quick load
      final all = QuestionRepository.allQuestions;
      final initialCount = RemoteConfigService.instance.dailyTestQuestionCount;
      _testQuestions = all.take(initialCount).toList();
      _initialSeconds = _secondsRemaining;

      // 2. Fetch live mock test questions — timer starts AFTER fetch completes
      _loadLiveMockQuestions();
    }
  }

  Future<void> _loadLiveMockQuestions() async {
    setState(() => _isLoadingQuestions = true);
    try {
      final targetPaperType = widget.paperType?.toUpperCase() ?? 'MOCK';

      // 1. Fetch questions for the given examCode
      final examQs = await QuestionRepository.fetchLiveQuestions(
        examCode: widget.examCode,
        paperType: targetPaperType,
        year: widget.year,
      );

      // 2. Also fetch from general MOCK pool if not a PYQ test
      List<Question> pool = [...examQs.where((q) => q.paperType.toUpperCase() == targetPaperType)];

      if (targetPaperType == 'MOCK' && pool.isEmpty) {
        final generalMocks = await QuestionRepository.fetchLiveQuestions(
          examCode: 'APSSB-MOCK',
          paperType: 'MOCK',
        );
        pool = [...generalMocks.where((q) => q.paperType.toUpperCase() == 'MOCK')];
      }

      // 3. For broad subject-based tests (e.g., from PYQ bank subject filter),
      //    fetch across all exam codes when examCode is 'ALL'
      if (widget.examCode.toUpperCase() == 'ALL') {
        final broadPool = await QuestionRepository.fetchLiveQuestions(
          examCode: '',
          paperType: targetPaperType,
        );
        pool = [...broadPool.where((q) => q.paperType.toUpperCase() == targetPaperType)];
      }

      // Fallback if empty
      if (pool.isEmpty) {
        final fallback = await QuestionRepository.fetchLiveQuestions(
          examCode: widget.examCode,
        );
        pool = fallback;
      }

      // 4. Apply optional subject filter
      if (widget.subject != null && widget.subject!.isNotEmpty && widget.subject != 'All') {
        final subjectLower = widget.subject!.toLowerCase();
        final isEnglishSearch = subjectLower.contains('english') || subjectLower.contains('comprehension');
        final subjectFiltered = pool.where((q) {
          final qSub = q.subject.toLowerCase();
          if (isEnglishSearch) {
            return qSub.contains('english') ||
                   qSub.contains('comprehension') ||
                   qSub.contains('grammar') ||
                   qSub.contains('reading');
          }
          return qSub.contains(subjectLower) || subjectLower.contains(qSub);
        }).toList();
        if (subjectFiltered.isNotEmpty) pool = subjectFiltered;
      }

      // 5. Apply optional difficulty filter
      if (widget.difficulty != null && widget.difficulty!.isNotEmpty && widget.difficulty != 'All Levels') {
        final diffFiltered = pool.where((q) =>
          q.difficulty.toLowerCase() == widget.difficulty!.toLowerCase()
        ).toList();
        if (diffFiltered.isNotEmpty) pool = diffFiltered;
      }

      if (pool.isNotEmpty && mounted) {
        // Determine question count based on testType (e.g. '5', '10', '20', 'full')
        int count = 10;
        final parsed = int.tryParse(widget.testType);
        if (parsed != null && parsed > 0) {
          count = parsed;
        } else if (widget.testType.toLowerCase() == 'full') {
          count = pool.length;
        } else {
          count = RemoteConfigService.instance.dailyTestQuestionCount;
        }

        final List<Question> selectedQs;
        if (widget.testType.toLowerCase() == 'full') {
          selectedQs = List<Question>.from(pool);
        } else {
          final shuffled = List<Question>.from(pool)..shuffle(math.Random());
          selectedQs = shuffled.take(count).toList();
        }

        // Timer: Use explicit durationMinutes if provided, or paper timeLimitMins, or 1m per question
        final int totalSeconds;
        if (widget.durationMinutes != null && widget.durationMinutes! > 0) {
          totalSeconds = widget.durationMinutes! * 60;
        } else if (selectedQs.isNotEmpty &&
            selectedQs.first.timeLimitMins > 0 &&
            widget.testType.toLowerCase() == 'full') {
          totalSeconds = selectedQs.first.timeLimitMins * 60;
        } else {
          totalSeconds = math.max(300, selectedQs.length * 60);
        }

        setState(() {
          _testQuestions = selectedQs;
          _isLoadingQuestions = false;
          _secondsRemaining = totalSeconds;
          _initialSeconds = totalSeconds;
        });

        // Start timer AFTER questions and seconds are set — only for timed mode
        if (!widget.isStudyMode) {
          _startTimer();
        }
      } else {
        if (mounted) setState(() => _isLoadingQuestions = false);
        // Fallback: start timer with default duration if timed mode
        if (!widget.isStudyMode) {
          _startTimer();
        }
      }
    } catch (e) {
      debugPrint('[MockTest] Error loading live questions: $e');
      if (mounted) setState(() => _isLoadingQuestions = false);
    }
  }


  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
        _autoSubmit();
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _autoSubmit() {
    if (_isSubmitted) return;
    _submitTest(isAuto: true);
  }

  void _submitTest({bool isAuto = false}) {
    _timer?.cancel();

    // Score Calculations
    int correctCount = 0;
    int incorrectCount = 0;
    int unattemptedCount = 0;

    for (final q in _testQuestions) {
      final answer = _selectedAnswers[q.id];
      if (answer == null) {
        unattemptedCount++;
      } else if (answer == q.correctAnswer) {
        correctCount++;
      } else {
        incorrectCount++;
      }
    }

    // Standard APSSB marking scheme: +2 for correct, -0.5 for wrong
    double totalPoints = (correctCount * 2.0) - (incorrectCount * 0.5);
    if (totalPoints < 0) totalPoints = 0.0;
    double maxPoints = _testQuestions.length * 2.0;

    // ELO Rating calculation
    final user = ref.read(authViewModelProvider).user;
    final currentRating = user?.rating ?? 1200;

    // Expected score E (Assuming a Medium test with difficulty rating 1200)
    const double testDifficulty = 1200.0;
    final double exponent = (testDifficulty - currentRating) / 400.0;
    final double expectedScore = 1.0 / (1.0 + math.pow(10.0, exponent));

    // Actual score percentage S
    final double actualScore = totalPoints / maxPoints;

    // Rating adjustment (K-factor = 32)
    final int ratingChange = (32 * (actualScore - expectedScore)).round();

    final int timeTaken = _initialSeconds - _secondsRemaining;

    // Speed Bonus: awarded only if accuracy >= 40%; max 10 trophies
    // Formula: timeLeft ratio Ã— 10, rounded. Faster completion = higher bonus.
    int speedBonus = 0;
    if (actualScore >= 0.40 && timeTaken < _initialSeconds) {
      final double timeLeftRatio =
          (_secondsRemaining / _initialSeconds.toDouble());
      speedBonus = (timeLeftRatio * 10).round();
    }
    final double multiplier = RemoteConfigService.instance.trophiesMultiplier;
    final int rawChange = ratingChange + speedBonus;
    final int totalChange = (rawChange * multiplier).round();

    // Persist new rating (score + speed)
    if (user != null) {
      ref.read(authViewModelProvider.notifier).updateRating(totalChange);
    }

    final now = DateTime.now();
    final dateStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    // Save attempts history
    _saveHistoryToPrefs(
      score: totalPoints,
      maxScore: maxPoints,
      ratingChange: ratingChange,
      speedBonus: speedBonus,
      correct: correctCount,
      wrong: incorrectCount,
      left: unattemptedCount,
      timeTaken: timeTaken,
      dateStr: dateStr,
    );

    setState(() {
      _isSubmitted = true;
      _scoreObtained = totalPoints;
      _maxScore = maxPoints;
      _correctCount = correctCount;
      _incorrectCount = incorrectCount;
      _unattemptedCount = unattemptedCount;
      _ratingChange = ratingChange;
      _newRating = math.max(0, currentRating + totalChange);
    });

    final resultData = {
      'examCode': widget.examCode,
      'score': totalPoints,
      'maxScore': maxPoints,
      'ratingChange': ratingChange,
      'speedBonus': speedBonus,
      'correct': correctCount,
      'wrong': incorrectCount,
      'left': unattemptedCount,
      'timeTaken': timeTaken,
      'date': dateStr,
      'selectedAnswers': Map<String, String>.from(_selectedAnswers),
    };

    if (mounted) {
      context.pushReplacement('/mock-test-result', extra: resultData);
    }
  }

  Future<void> _saveHistoryToPrefs({
    required double score,
    required double maxScore,
    required int ratingChange,
    required int speedBonus,
    required int correct,
    required int wrong,
    required int left,
    required int timeTaken,
    required String dateStr,
  }) async {
    final storage = ref.read(storageServiceProvider);
    final historyList = List<String>.from(storage.getQuizHistory());
    
    final recordJson = jsonEncode({
      'examCode': widget.examCode,
      'score': score,
      'maxScore': maxScore,
      'ratingChange': ratingChange,
      'speedBonus': speedBonus,
      'correct': correct,
      'wrong': wrong,
      'left': left,
      'timeTaken': timeTaken,
      'date': dateStr,
      'selectedAnswers': _selectedAnswers,
      'questions': _testQuestions.map((q) => {
        'id': q.id,
        'questionText': q.questionText,
        'subject': q.subject,
        'examCode': q.examCode,
        'options': q.options,
        'correctAnswer': q.correctAnswer,
        'officialAnswer': q.officialAnswer,
        'solution': q.solution,
        'difficulty': q.difficulty,
        'year': q.year,
        'passageOrDirection': q.passageOrDirection,
        'passageImage': q.passageImage,
        'questionImage': q.questionImage,
      }).toList(),
    });
    historyList.insert(0, recordJson); // Add most recent first
    await storage.saveQuizHistory(historyList);

    // Sync with Firebase Analytics & Cloud Firestore
    try {
      final user = ref.read(authViewModelProvider).user;
      final firebase = ref.read(firebaseServiceProvider);
      final currentRating = user?.rating ?? 1200;

      // 1. Log event to Firebase Analytics
      await firebase.logQuizCompleted(
        examCode: widget.examCode,
        score: score,
        maxScore: maxScore,
        trophiesChange: ratingChange + speedBonus,
        timeTakenSeconds: timeTaken,
        rankTier: RankUtils.getTierName(currentRating),
      );

      // 2. Save document to Cloud Firestore
      if (user != null && user.email.isNotEmpty) {
        await firebase.saveQuizResultToFirestore(user.email, {
          'examCode': widget.examCode,
          'score': score,
          'maxScore': maxScore,
          'ratingChange': ratingChange,
          'speedBonus': speedBonus,
          'correct': correct,
          'wrong': wrong,
          'left': left,
          'timeTakenSeconds': timeTaken,
          'date': dateStr,
        });
      }
    } catch (_) {}
  }

  Widget _buildMetric(String label, int val, Color color) {
    return Column(
      children: [
        Text(
          '$val',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildResultView(BuildContext context) {
    final accuracy = _maxScore > 0 ? (_scoreObtained / _maxScore * 100) : 0.0;

    return Scaffold(
      backgroundColor: AppColors.void_,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text('${widget.examCode} Test Results'),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildResultHeaderCard(accuracy),
            const SizedBox(height: AppSpacing.l),
            const Text(
              'REVIEW ANSWERS & EXPLANATIONS',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            Builder(
              builder: (context) {
                final displayGroups = buildQuestionDisplayGroups(_testQuestions);
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayGroups.length,
                  itemBuilder: (context, gIdx) {
                    final group = displayGroups[gIdx];
                    if (group.isGroup) {
                      return ComprehensionGroupWidget(
                        key: ValueKey('review_group_${group.groupId ?? gIdx}'),
                        passage: group.passage,
                        passageImage: group.passageImage,
                        startIndex: group.startIndex,
                        endIndex: group.endIndex,
                        children: [
                          for (int qSubIdx = 0;
                              qSubIdx < group.questions.length;
                              qSubIdx++)
                            _buildReviewQuestionItem(
                              group.questions[qSubIdx],
                              group.startIndex + qSubIdx,
                              isInsideGroup: true,
                            ),
                        ],
                      );
                    }
                    final question = group.questions.first;
                    return Card(
                      key: ValueKey('review_${question.id}'),
                      margin: const EdgeInsets.only(bottom: AppSpacing.m),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                        side: const BorderSide(color: AppColors.divider),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.m),
                        child: _buildReviewQuestionItem(
                          question,
                          group.startIndex,
                          isInsideGroup: false,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: AppSpacing.m),
            PrimaryButton(
              text: 'CLOSE & GO HOME',
              onPressed: () => context.go('/home'),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildResultHeaderCard(double accuracy) {
    return AntigravityGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          children: [
            const Icon(Icons.emoji_events_rounded, color: AppColors.accent, size: 54),
            const SizedBox(height: AppSpacing.s),
            Text(
              'Score: ${_scoreObtained.toStringAsFixed(1)} / ${_maxScore.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Accuracy: ${accuracy.toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.m),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetric('Correct', _correctCount, AppColors.success),
                _buildMetric('Wrong', _incorrectCount, AppColors.error),
                _buildMetric('Left', _unattemptedCount, AppColors.textHint),
              ],
            ),
            const Divider(height: AppSpacing.l),
            const Text(
              'Global Trophies Rating Update',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _ratingChange >= 0 ? '+$_ratingChange Trophies' : '$_ratingChange Trophies',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _ratingChange >= 0 ? AppColors.success : AppColors.error,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                const Icon(Icons.emoji_events_rounded, color: AppColors.accent, size: 18),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'New Rating: $_newRating',
              style: const TextStyle(color: AppColors.textHint, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewQuestionItem(
    Question question,
    int displayNum, {
    required bool isInsideGroup,
  }) {
    final selectedOption = _selectedAnswers[question.id];
    final isCorrect = selectedOption == question.correctAnswer;

    Widget? statusBadge;
    if (selectedOption == null) {
      statusBadge = const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.remove_circle_outline_rounded,
              color: AppColors.textHint, size: 16),
          SizedBox(width: 4),
          Text('Not Answered',
              style: TextStyle(
                  color: AppColors.textHint,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ],
      );
    } else if (isCorrect) {
      statusBadge = const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
          SizedBox(width: 4),
          Text('Correct (+2.0)',
              style: TextStyle(
                  color: AppColors.success,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ],
      );
    } else {
      statusBadge = const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cancel_rounded, color: AppColors.error, size: 16),
          SizedBox(width: 4),
          Text('Incorrect (-0.5)',
              style: TextStyle(
                  color: AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ],
      );
    }

    return SingleQuestionWidget(
      key: ValueKey(question.id),
      question: question,
      displayNum: displayNum,
      isInsideGroup: isInsideGroup,
      selectedOption: selectedOption,
      isSubmitted: true,
      showSolution: true,
      selectedSubjectFilter: widget.subject,
      trailingHeader: statusBadge,
    );
  }

  Widget _buildActiveQuestionItem(
    Question question,
    int displayNum, {
    required bool isInsideGroup,
  }) {
    final selectedOption = _selectedAnswers[question.id];
    final isStudy = widget.isStudyMode;
    final showSolution = _showSolutions[question.id] ?? false;

    return SingleQuestionWidget(
      key: ValueKey(question.id),
      question: question,
      displayNum: displayNum,
      isInsideGroup: isInsideGroup,
      selectedOption: selectedOption,
      isStudyMode: isStudy,
      onSelectOption: _isSubmitted
          ? null
          : (val) {
              setState(() {
                _selectedAnswers[question.id] = val;
                if (isStudy) {
                  _showSolutions[question.id] = true;
                }
              });
            },
      isSubmitted: _isSubmitted,
      showSolution: isStudy ? (_isSubmitted || showSolution) : _isSubmitted,
      onToggleSolution: isStudy
          ? () {
              setState(() {
                _showSolutions[question.id] = !showSolution;
              });
            }
          : null,
      selectedSubjectFilter: widget.subject,
      discussionWidget: isStudy ? _buildActiveDiscussionWidget(question) : null,
    );
  }

  Widget _buildActiveDiscussionWidget(Question question) {
    return Container(
      key: const Key('candidate_discussion'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Row(
        children: [
          Icon(Icons.forum_outlined, size: 14, color: AppColors.primary),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              'Candidate Discussion & Doubt Forum',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isSubmitted) {
      return _buildResultView(context);
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_isSubmitted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Cannot Go Back'),
              content: const Text(
                  'You must submit the test before leaving. Tap SUBMIT MOCK TEST to finish.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      },
      child: Scaffold(
        extendBody: true,
        backgroundColor: AppColors.void_,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(68),
          child: SafeArea(
            bottom: false,
            child: AppBar(
              toolbarHeight: 68,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Quit Test?'),
                      content: const Text(
                          'Are you sure you want to exit? Your progress will not be saved.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('CANCEL'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            context.pop();
                          },
                          child: const Text('QUIT',
                              style: TextStyle(color: AppColors.error)),
                        ),
                      ],
                    ),
                  );
                },
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.subject != null && widget.subject!.isNotEmpty
                              ? '${widget.subject} ${widget.paperType == 'PYQ' ? 'PYQ Practice' : 'Mock Test'}'
                              : '${widget.examCode} Mock Test',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!_isLoadingQuestions) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (widget.difficulty != null && widget.difficulty!.isNotEmpty) ...[
                                Text(
                                  widget.difficulty!,
                                  style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.normal),
                                ),
                                const Text(' · ', style: TextStyle(fontSize: 10, color: Colors.white70)),
                              ],
                              Text(
                                '${_testQuestions.length} Questions',
                                style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.normal),
                              ),
                              const Text(' · ', style: TextStyle(fontSize: 10, color: Colors.white70)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '+2 / -0.5 Marking',
                                  style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (widget.isStudyMode)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_stories_rounded,
                            color: Color(0xFF2E7D32),
                            size: 15,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Study Mode',
                            style: TextStyle(
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    AntigravityTimerRing(
                      timeLeft: _secondsRemaining,
                      totalTime: _initialSeconds,
                      size: 64,
                    ),
                ],
              ),
            ),
          ),
        ),
      body: _isLoadingQuestions
          ? const Center(child: CircularProgressIndicator())
          : _testQuestions.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 54, color: AppColors.textHint),
                        const SizedBox(height: AppSpacing.m),
                        Text('No questions found for ${widget.examCode}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: AppSpacing.s),
                        const Text(
                            'Check your internet connection and tap retry.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: AppSpacing.m),
                        ElevatedButton.icon(
                          onPressed: _loadLiveMockQuestions,
                          icon: const Icon(Icons.refresh),
                          label: const Text('RETRY LOADING'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final displayGroups =
                              buildQuestionDisplayGroups(_testQuestions);
                          return ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(
                              16,
                              12,
                              16,
                              kBottomNavigationBarHeight + 80,
                            ),
                            itemCount: displayGroups.length,
                            itemBuilder: (context, gIdx) {
                              final group = displayGroups[gIdx];
                              final isGroup = group.isGroup;

                              if (isGroup) {
                                return ComprehensionGroupWidget(
                                  key: ValueKey('test_group_${group.groupId ?? gIdx}'),
                                  passage: group.passage,
                                  passageImage: group.passageImage,
                                  startIndex: group.startIndex,
                                  endIndex: group.endIndex,
                                  children: [
                                    for (int qSubIdx = 0;
                                        qSubIdx < group.questions.length;
                                        qSubIdx++)
                                      _buildActiveQuestionItem(
                                        group.questions[qSubIdx],
                                        group.startIndex + qSubIdx,
                                        isInsideGroup: true,
                                      ),
                                  ],
                                );
                              }

                              final question = group.questions.first;
                              final displayNum = group.startIndex;
                              return Card(
                                key: ValueKey(question.id),
                                margin: const EdgeInsets.only(
                                    bottom: AppSpacing.m),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppSpacing.radiusL),
                                  side: const BorderSide(
                                      color: AppColors.divider),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.m),
                                  child: _buildActiveQuestionItem(
                                    question,
                                    displayNum,
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
        bottomNavigationBar: !_isSubmitted
            ? ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.90),
                      border: const Border(
                        top: BorderSide(color: AppColors.divider, width: 1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                        child: PrimaryButton(
                          key: const Key('submit_mock_test_btn'),
                          text: 'SUBMIT MOCK TEST',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Submit Test?'),
                                content: Text(
                                    'You have answered ${_selectedAnswers.length} of ${_testQuestions.length} questions. Do you want to submit?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('CANCEL'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _submitTest();
                                    },
                                    child: const Text('SUBMIT',
                                        style: TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

