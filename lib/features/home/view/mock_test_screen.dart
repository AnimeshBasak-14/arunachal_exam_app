import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
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
import '../../../core/utils/math_utils.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';

class MockTestScreen extends ConsumerStatefulWidget {
  final String examCode;
  final String testType; // 'topic', 'full', '5', '10', '20'

  const MockTestScreen({
    super.key,
    required this.examCode,
    required this.testType,
  });

  @override
  ConsumerState<MockTestScreen> createState() => _MockTestScreenState();
}

class _MockTestScreenState extends ConsumerState<MockTestScreen> {
  late List<Question> _testQuestions;
  final Map<String, String> _selectedAnswers = {}; // questionId -> optionChar
  late Timer _timer;
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
    // 1. Initial quick load
    final all = QuestionRepository.allQuestions;
    final initialCount = RemoteConfigService.instance.dailyTestQuestionCount;
    _testQuestions = all.take(initialCount).toList();
    _initialSeconds = _secondsRemaining;

    // 2. Fetch live mock test questions from Firestore / Supabase
    _loadLiveMockQuestions();

    _startTimer();
  }

  Future<void> _loadLiveMockQuestions() async {
    setState(() => _isLoadingQuestions = true);
    try {
      // 1. Fetch questions strictly of paperType MOCK
      final examQs = await QuestionRepository.fetchLiveQuestions(
        examCode: widget.examCode,
        paperType: 'MOCK',
      );

      // 2. Fetch general mock pool questions (APSSB-MOCK)
      final generalMocks = await QuestionRepository.fetchLiveQuestions(
        examCode: 'APSSB-MOCK',
        paperType: 'MOCK',
      );

      var pool = <Question>[
        ...examQs.where((q) => q.paperType.toUpperCase() == 'MOCK'),
        ...generalMocks.where((q) => q.paperType.toUpperCase() == 'MOCK'),
      ];

      // Fallback if empty
      if (pool.isEmpty) {
        final fallback = await QuestionRepository.fetchLiveQuestions(
          examCode: widget.examCode,
        );
        pool = fallback;
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

        final shuffled = List<Question>.from(pool)..shuffle(math.Random());
        final selectedQs = shuffled.take(count).toList();

        // Dynamic timer: 1 min (60s) per question, minimum 5 mins (300s)
        final totalSeconds = math.max(300, selectedQs.length * 60);

        setState(() {
          _testQuestions = selectedQs;
          _isLoadingQuestions = false;
          _secondsRemaining = totalSeconds;
          _initialSeconds = totalSeconds;
        });
      } else {
        if (mounted) setState(() => _isLoadingQuestions = false);
      }
    } catch (e) {
      debugPrint('[MockTest] Error loading live questions: $e');
      if (mounted) setState(() => _isLoadingQuestions = false);
    }
  }

  String _extractOptionChar(String option, int fallbackIndex) {
    final trimmed = option.trim();
    final match = RegExp(r'^[\(\[]?([a-dA-D])[\)\]\.\s]').firstMatch(trimmed);
    if (match != null) return match.group(1)!.toLowerCase();
    return String.fromCharCode(97 + fallbackIndex);
  }

  @override
  void dispose() {
    _timer.cancel();
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
    _timer.cancel();

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
    // Formula: timeLeft ratio × 10, rounded. Faster completion = higher bonus.
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
      backgroundColor: AppColors.background,
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
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _testQuestions.length,
              itemBuilder: (context, index) {
                return _buildQuestionReviewCard(_testQuestions[index], index);
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
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
        side: const BorderSide(color: AppColors.divider),
      ),
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

  Widget _buildPassageWidget(String passage) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.menu_book_rounded,
                  size: 14, color: AppColors.primary),
              SizedBox(width: 6),
              Text(
                'Comprehension / Direction',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            passage,
            style: const TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionReviewCard(Question question, int index) {
    final selectedOption = _selectedAnswers[question.id];
    final isCorrect = selectedOption == question.correctAnswer;

    return Card(
      key: ValueKey(question.id),
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
            _buildReviewQuestionHeader(question, selectedOption, isCorrect),
            const SizedBox(height: AppSpacing.s),
            if (question.passageOrDirection != null &&
                question.passageOrDirection!.trim().isNotEmpty) ...[
              _buildPassageWidget(MathUtils.formatMath(question.passageOrDirection!.trim())),
              const SizedBox(height: AppSpacing.s),
            ],
            Text(
              'Q${index + 1}. ${MathUtils.cleanQuestionText(question.questionText)}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            if (question.questionImage != null &&
                question.questionImage!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  question.questionImage!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.m),
            ...List.generate(question.options.length, (optIdx) {
              return _buildReviewOptionTile(question, optIdx, selectedOption);
            }),
            const SizedBox(height: AppSpacing.s),
            _buildSolutionBox(question),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewQuestionHeader(Question question, String? selectedOption, bool isCorrect) {
    final isPyq = question.paperType.toUpperCase() == 'PYQ' && question.year > 2000;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    question.subject,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPyq ? Colors.amber.shade100 : Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isPyq ? 'PYQ ${question.year}' : 'MOCK QUESTION',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isPyq ? Colors.amber.shade800 : const Color(0xFF1E40AF),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        if (selectedOption == null)
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.remove_circle_outline_rounded, color: AppColors.textHint, size: 16),
              SizedBox(width: 4),
              Text('Not Answered', style: TextStyle(color: AppColors.textHint, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          )
        else if (isCorrect)
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
              SizedBox(width: 4),
              Text('Correct (+2.0)', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          )
        else
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cancel_rounded, color: AppColors.error, size: 16),
              SizedBox(width: 4),
              Text('Incorrect (-0.5)', style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
      ],
    );
  }

  Widget _buildReviewOptionTile(Question question, int optIdx, String? selectedOption) {
    final option = question.options[optIdx];
    final optionChar = _extractOptionChar(option, optIdx);
    final isUserSelected = selectedOption == optionChar;
    final isOptionCorrect = question.correctAnswer == optionChar;

    Color optionBorderColor = AppColors.divider;
    Color optionBgColor = Colors.transparent;

    if (isOptionCorrect) {
      optionBorderColor = AppColors.success;
      optionBgColor = AppColors.success.withValues(alpha: 0.06);
    } else if (isUserSelected) {
      optionBorderColor = AppColors.error;
      optionBgColor = AppColors.error.withValues(alpha: 0.06);
    }

    return Container(
      key: ValueKey('${question.id}_opt_$optIdx'),
      margin: const EdgeInsets.only(bottom: AppSpacing.s),
      decoration: BoxDecoration(
        color: optionBgColor,
        border: Border.all(color: optionBorderColor, width: isUserSelected || isOptionCorrect ? 2.0 : 1.0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              MathUtils.formatMath(option),
              style: TextStyle(
                fontSize: 14,
                color: isOptionCorrect
                    ? AppColors.primaryDark
                    : isUserSelected
                        ? AppColors.error
                        : AppColors.textPrimary,
                fontWeight: isUserSelected || isOptionCorrect ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (optIdx < question.optionImages.length &&
                question.optionImages[optIdx] != null &&
                question.optionImages[optIdx]!.isNotEmpty) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  question.optionImages[optIdx]!,
                  height: 70,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSolutionBox(Question question) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: AppColors.primary, size: 16),
              const SizedBox(width: 6),
              Text(
                'Correct Answer: Option ${question.correctAnswer.toUpperCase()}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Solution Explanation:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            MathUtils.formatMath(question.solution),
            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
          ),
          if (question.solutionImage != null &&
              question.solutionImage!.isNotEmpty) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                question.solutionImage!,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
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
        backgroundColor: AppColors.background,
        appBar: AppBar(
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
        title: Text('${widget.examCode} Mock Test'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpacing.m),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _secondsRemaining < 60
                      ? AppColors.error.withValues(alpha: 0.12)
                      : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      color: _secondsRemaining < 60
                          ? AppColors.error
                          : AppColors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(_secondsRemaining),
                      style: TextStyle(
                        color: _secondsRemaining < 60
                            ? AppColors.error
                            : AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(AppSpacing.m),
                        itemCount: _testQuestions.length,
                        itemBuilder: (context, index) {
                          final question = _testQuestions[index];
                          final selectedOption = _selectedAnswers[question.id];

                          return Card(
                            key: ValueKey(question.id),
                            margin: const EdgeInsets.only(bottom: AppSpacing.m),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusL),
                              side: const BorderSide(color: AppColors.divider),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.m),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryLight,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            question.subject,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ),
                                      (() {
                                        final isPyq =
                                            question.paperType.toUpperCase() ==
                                                    'PYQ' &&
                                                question.year > 2000;
                                        if (isPyq) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              'PYQ ${question.year}',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.amber.shade800,
                                              ),
                                            ),
                                          );
                                        } else {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Text(
                                              'MOCK QUESTION',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1E40AF),
                                              ),
                                            ),
                                          );
                                        }
                                      })(),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.s),
                                  if (question.passageOrDirection != null &&
                                      question.passageOrDirection!.trim().isNotEmpty) ...[
                                    _buildPassageWidget(MathUtils.formatMath(question.passageOrDirection!.trim())),
                                    const SizedBox(height: AppSpacing.s),
                                  ],
                                  Text(
                                    'Q${index + 1}. ${MathUtils.cleanQuestionText(question.questionText)}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  if (question.questionImage != null &&
                                      question.questionImage!.isNotEmpty) ...[
                                    const SizedBox(height: AppSpacing.s),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        question.questionImage!,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) =>
                                            const SizedBox.shrink(),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: AppSpacing.m),
                                  ...List.generate(question.options.length,
                                      (optIdx) {
                                    final option = question.options[optIdx];
                                    final optionChar =
                                        _extractOptionChar(option, optIdx);
                                    final isSelected =
                                        selectedOption == optionChar;

                                    return Container(
                                      key: ValueKey(
                                          '${question.id}_opt_$optIdx'),
                                      margin: const EdgeInsets.only(
                                          bottom: AppSpacing.s),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primary
                                                .withValues(alpha: 0.06)
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primary
                                              : AppColors.divider,
                                          width: isSelected ? 2.0 : 1.0,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: InkWell(
                                        onTap: _isSubmitted
                                            ? null
                                            : () {
                                                setState(() {
                                                  _selectedAnswers[
                                                      question.id] = optionChar;
                                                });
                                              },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.m,
                                              vertical: 14),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                MathUtils.formatMath(option),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: AppColors.textPrimary,
                                                  fontWeight: isSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                              if (optIdx <
                                                      question.optionImages
                                                          .length &&
                                                  question.optionImages[
                                                          optIdx] !=
                                                      null &&
                                                  question
                                                      .optionImages[optIdx]!
                                                      .isNotEmpty) ...[
                                                const SizedBox(height: 6),
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  child: Image.network(
                                                    question
                                                        .optionImages[optIdx]!,
                                                    height: 70,
                                                    fit: BoxFit.contain,
                                                    errorBuilder: (_, __,
                                                            ___) =>
                                                        const SizedBox
                                                            .shrink(),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Submit Button
                    if (!_isSubmitted)
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                              AppSpacing.m, 0, AppSpacing.m, AppSpacing.m),
                          child: PrimaryButton(
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
                  ],
                ),
    ),
    );
  }
}
