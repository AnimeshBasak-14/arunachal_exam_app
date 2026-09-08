import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/services/service_providers.dart';
import '../../../data/grammar_data.dart';
import '../../home/view/home_screen.dart';

class GrammarQuizScreen extends ConsumerStatefulWidget {
  const GrammarQuizScreen({super.key});

  @override
  ConsumerState<GrammarQuizScreen> createState() => _GrammarQuizScreenState();
}

class _GrammarQuizScreenState extends ConsumerState<GrammarQuizScreen> {
  late List<GrammarQuizQuestion> _questions;
  int _currentIndex = 0;
  final Map<int, String> _userAnswers = {}; // questionIndex -> 'a'/'b'/'c'/'d'
  bool _isAnswerRevealed = false;
  bool _isFinished = false;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _questions = List<GrammarQuizQuestion>.from(GrammarData.quizQuestions)..shuffle();
  }

  String _extractOptionChar(String option, int fallbackIndex) {
    final trimmed = option.trim();
    final match = RegExp(r'^[\(\[]?([a-dA-D])[\)\]\.\s]').firstMatch(trimmed);
    if (match != null) return match.group(1)!.toLowerCase();
    return String.fromCharCode(97 + fallbackIndex);
  }

  void _onOptionSelected(String optionChar) {
    if (_isAnswerRevealed) return;
    setState(() {
      _userAnswers[_currentIndex] = optionChar;
      _isAnswerRevealed = true;
      if (optionChar == _questions[_currentIndex].correctAnswer.toLowerCase()) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _isAnswerRevealed = _userAnswers.containsKey(_currentIndex);
      });
    } else {
      _finishQuiz();
    }
  }

  Future<void> _finishQuiz() async {
    setState(() {
      _isFinished = true;
    });

    // Save to storage quiz history
    try {
      final storage = ref.read(storageServiceProvider);
      final historyList = List<String>.from(storage.getQuizHistory());
      final maxScore = _questions.length;
      final pct = maxScore > 0 ? (_score / maxScore) * 100 : 0.0;
      final trophyChange = (_score * 2);

      final resultRecord = {
        'testTitle': 'English Grammar Practice Quiz',
        'examCode': 'APSSB-ENG',
        'score': _score,
        'maxScore': maxScore,
        'percentage': pct,
        'ratingChange': trophyChange,
        'speedBonus': 5,
        'correct': _score,
        'wrong': maxScore - _score,
        'timeTaken': 120,
        'date': DateTime.now().toIso8601String(),
        'completedAt': DateTime.now().toIso8601String(),
      };

      historyList.insert(0, jsonEncode(resultRecord));
      await storage.saveQuizHistory(historyList);
    } catch (e) {
      debugPrint('Error saving grammar quiz result: $e');
    }
  }

  void _restartQuiz() {
    setState(() {
      _questions.shuffle();
      _currentIndex = 0;
      _userAnswers.clear();
      _isAnswerRevealed = false;
      _isFinished = false;
      _score = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Grammar Practice Quiz',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        actions: [
          if (!_isFinished)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.m),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentIndex + 1}/${_questions.length}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isFinished ? _buildResultView() : _buildQuizView(),
    );
  }

  Widget _buildQuizView() {
    final question = _questions[_currentIndex];
    final selectedChar = _userAnswers[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return Column(
      children: [
        // Progress bar
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.shade200,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          minHeight: 4,
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    question.category,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.m),

                // Question Text
                Text(
                  question.questionText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.l),

                // Options
                ...List.generate(question.options.length, (index) {
                  final optionText = question.options[index];
                  final optionChar = _extractOptionChar(optionText, index);
                  final isSelected = selectedChar == optionChar;
                  final isCorrect = question.correctAnswer.toLowerCase() == optionChar;

                  Color borderColor = Colors.grey.shade200;
                  Color bgColor = Colors.white;
                  Color textColor = AppColors.textPrimary;
                  IconData? statusIcon;

                  if (_isAnswerRevealed) {
                    if (isCorrect) {
                      borderColor = AppColors.success;
                      bgColor = AppColors.success.withOpacity(0.08);
                      textColor = AppColors.success;
                      statusIcon = Icons.check_circle_rounded;
                    } else if (isSelected && !isCorrect) {
                      borderColor = AppColors.error;
                      bgColor = AppColors.error.withOpacity(0.08);
                      textColor = AppColors.error;
                      statusIcon = Icons.cancel_rounded;
                    }
                  } else if (isSelected) {
                    borderColor = AppColors.primary;
                    bgColor = AppColors.primaryLight;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.s),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusM),
                      border: Border.all(color: borderColor, width: isSelected || (_isAnswerRevealed && isCorrect) ? 1.5 : 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: InkWell(
                      onTap: () => _onOptionSelected(optionChar),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusM),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: isSelected || (_isAnswerRevealed && isCorrect)
                                    ? borderColor.withOpacity(0.2)
                                    : Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                optionChar.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: textColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                optionText,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: textColor,
                                ),
                              ),
                            ),
                            if (statusIcon != null)
                              Icon(statusIcon, color: borderColor, size: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                // Explanation Box (if revealed)
                if (_isAnswerRevealed) ...[
                  const SizedBox(height: AppSpacing.m),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusM),
                      border: Border.all(color: Colors.blue.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.lightbulb_rounded, color: Colors.amber, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Explanation (Correct: ${question.correctAnswer.toUpperCase()})',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          question.explanation,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Bottom Navigation Bar
        Container(
          padding: const EdgeInsets.all(AppSpacing.m),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              if (_currentIndex > 0)
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _currentIndex--;
                      _isAnswerRevealed = _userAnswers.containsKey(_currentIndex);
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusM)),
                  ),
                  child: const Text('Previous'),
                ),
              if (_currentIndex > 0) const SizedBox(width: AppSpacing.m),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isAnswerRevealed ? _nextQuestion : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusM)),
                  ),
                  child: Text(
                    _currentIndex == _questions.length - 1 ? 'Finish & See Score' : 'Next Question',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultView() {
    final total = _questions.length;
    final pct = total > 0 ? (_score / total) * 100 : 0.0;
    final isPassed = pct >= 50.0;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Score Trophy Avatar
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (isPassed ? AppColors.accent : AppColors.primary).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPassed ? Icons.emoji_events_rounded : Icons.psychology_rounded,
                size: 72,
                color: isPassed ? AppColors.accent : AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.l),

            Text(
              isPassed ? 'Outstanding Work!' : 'Keep Practicing!',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              isPassed
                  ? 'You demonstrated strong command over English grammar rules.'
                  : 'Review the rules in Grammar Hub and try once more.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Score Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.l),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildResultKpi('Score', '$_score / $total', AppColors.primary),
                      _buildResultKpi('Accuracy', '${pct.toStringAsFixed(0)}%', isPassed ? AppColors.success : Colors.orange),
                      _buildResultKpi('Trophies', '+${_score * 2 + 5}', AppColors.accent),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _restartQuiz,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                label: const Text('Retake Quiz', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusM)),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.menu_book_rounded),
                label: const Text('Review Grammar Hub Rules'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusM)),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            TextButton(
              onPressed: () {
                ref.read(currentTabProvider.notifier).state = 0;
                context.go('/home');
              },
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultKpi(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
