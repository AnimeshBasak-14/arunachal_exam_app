import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/services/question_repository.dart';
import '../../../core/widgets/primary_button.dart';

class MockTestResultScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> resultData;

  const MockTestResultScreen({
    super.key,
    required this.resultData,
  });

  @override
  ConsumerState<MockTestResultScreen> createState() => _MockTestResultScreenState();
}

class _MockTestResultScreenState extends ConsumerState<MockTestResultScreen> {
  // Track which question cards are expanded
  final Set<String> _expandedIds = {};

  void _toggleExpanded(String id) {
    setState(() {
      if (_expandedIds.contains(id)) {
        _expandedIds.remove(id);
      } else {
        _expandedIds.add(id);
      }
    });
  }

  Widget _buildStatChip(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: color.withOpacity(0.8), fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? selectedOption, String correctAnswer) {
    if (selectedOption == null) return AppColors.textHint;
    if (selectedOption == correctAnswer) return AppColors.success;
    return AppColors.error;
  }

  IconData _getStatusIcon(String? selectedOption, String correctAnswer) {
    if (selectedOption == null) return Icons.remove_circle_outline_rounded;
    if (selectedOption == correctAnswer) return Icons.check_circle_rounded;
    return Icons.cancel_rounded;
  }

  String _getStatusLabel(String? selectedOption, String correctAnswer) {
    if (selectedOption == null) return 'Skipped';
    if (selectedOption == correctAnswer) return 'Correct +2.0';
    return 'Wrong −0.5';
  }

  @override
  Widget build(BuildContext context) {
    final resultData = widget.resultData;
    final examCode = resultData['examCode'] as String? ?? 'CGL';
    final score = (resultData['score'] as num?)?.toDouble() ?? 0.0;
    final maxScore = (resultData['maxScore'] as num?)?.toDouble() ?? 10.0;
    final ratingChange = (resultData['ratingChange'] as num?)?.toInt() ?? 0;
    final speedBonus = (resultData['speedBonus'] as num?)?.toInt() ?? 0;
    final correct = (resultData['correct'] as num?)?.toInt() ?? 0;
    final wrong = (resultData['wrong'] as num?)?.toInt() ?? 0;
    final left = (resultData['left'] as num?)?.toInt() ?? 0;
    final timeTaken = (resultData['timeTaken'] as num?)?.toInt() ?? 0;
    final date = resultData['date'] as String? ?? '';

    // Parse selectedAnswers map safely
    final selectedAnswersRaw = resultData['selectedAnswers'];
    Map<String, String> selectedAnswers = {};
    if (selectedAnswersRaw is Map) {
      selectedAnswers = selectedAnswersRaw.map((k, v) => MapEntry(k.toString(), v.toString()));
    }

    final accuracy = maxScore > 0 ? (score / maxScore * 100) : 0.0;
    final mins = timeTaken ~/ 60;
    final secs = timeTaken % 60;

    // Load questions for review (fall back to first 5 if no exam-specific match)
    final allQuestions = QuestionRepository.allQuestions;
    var testQuestions = allQuestions.where((q) => q.examCode == examCode).take(5).toList();
    if (testQuestions.isEmpty) testQuestions = allQuestions.take(5).toList();

    // Grade label based on accuracy
    String gradeLabel;
    if (accuracy >= 90) { gradeLabel = 'S'; }
    else if (accuracy >= 75) { gradeLabel = 'A'; }
    else if (accuracy >= 55) { gradeLabel = 'B'; }
    else if (accuracy >= 35) { gradeLabel = 'C'; }
    else { gradeLabel = 'D'; }

    final totalRatingChange = ratingChange + speedBonus;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text('$examCode · Results'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.leaderboard_rounded, size: 18),
            label: const Text('Scoreboard'),
            onPressed: () => context.push('/scoreboard'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── HERO SUMMARY CARD ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppSpacing.l),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1F6F4A), Color(0xFF14B8A6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${score.toStringAsFixed(1)} / ${maxScore.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            'Accuracy ${accuracy.toStringAsFixed(1)}%',
                            style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.timer_outlined, color: Colors.white70, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${mins}m ${secs}s',
                                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.75)),
                              ),
                              const SizedBox(width: 12),
                              const Icon(Icons.calendar_today_outlined, color: Colors.white70, size: 13),
                              const SizedBox(width: 4),
                              Text(
                                date,
                                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.75)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Grade badge
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                        ),
                        child: Center(
                          child: Text(
                            gradeLabel,
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.m),
                  // Stats Row
                  Row(
                    children: [
                      _buildStatChip('Correct', '$correct', Colors.greenAccent, Icons.check_circle_rounded),
                      _buildStatChip('Wrong', '$wrong', Colors.redAccent, Icons.cancel_rounded),
                      _buildStatChip('Skipped', '$left', Colors.white60, Icons.remove_circle_outline_rounded),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.m),
                  // Trophies Row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              ratingChange >= 0 ? '+$ratingChange' : '$ratingChange',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: ratingChange >= 0 ? Colors.greenAccent : Colors.redAccent,
                              ),
                            ),
                            const Text('Score Pts', style: TextStyle(fontSize: 10, color: Colors.white70)),
                          ],
                        ),
                        Container(width: 1, height: 32, color: Colors.white24),
                        Column(
                          children: [
                            Text(
                              speedBonus >= 0 ? '+$speedBonus' : '$speedBonus',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: speedBonus > 0 ? Colors.amber : Colors.white70,
                              ),
                            ),
                            const Text('Speed Bonus', style: TextStyle(fontSize: 10, color: Colors.white70)),
                          ],
                        ),
                        Container(width: 1, height: 32, color: Colors.white24),
                        Column(
                          children: [
                            Row(
                              children: [
                                Text(
                                  totalRatingChange >= 0 ? '+$totalRatingChange' : '$totalRatingChange',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: totalRatingChange >= 0 ? Colors.greenAccent : Colors.redAccent,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.emoji_events_rounded, color: Color(0xFFF59E0B), size: 18),
                              ],
                            ),
                            const Text('Total Trophies', style: TextStyle(fontSize: 10, color: Colors.white70)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.l),

            // ── SECTION HEADER ─────────────────────────────────────────────
            Row(
              children: [
                const Text(
                  'QUESTION REVIEW',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.1),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_expandedIds.length == testQuestions.length) {
                        _expandedIds.clear();
                      } else {
                        _expandedIds.addAll(testQuestions.map((q) => q.id));
                      }
                    });
                  },
                  child: Text(
                    _expandedIds.length == testQuestions.length ? 'Collapse All' : 'Expand All',
                    style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),

            // ── QUESTION CARDS ─────────────────────────────────────────────
            ...testQuestions.asMap().entries.map((entry) {
              final index = entry.key;
              final question = entry.value;
              final selectedOption = selectedAnswers[question.id];
              final isCorrect = selectedOption != null && selectedOption == question.correctAnswer;
              final isSkipped = selectedOption == null;
              final isExpanded = _expandedIds.contains(question.id);

              final statusColor = _getStatusColor(selectedOption, question.correctAnswer);
              final statusIcon = _getStatusIcon(selectedOption, question.correctAnswer);
              final statusLabel = _getStatusLabel(selectedOption, question.correctAnswer);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                  border: Border.all(
                    color: isExpanded ? statusColor.withOpacity(0.35) : AppColors.divider,
                    width: isExpanded ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    // ── COLLAPSED HEADER (always visible) ──
                    InkWell(
                      onTap: () => _toggleExpanded(question.id),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            // Status indicator dot
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Q number
                            Text(
                              'Q${index + 1}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                            ),
                            const SizedBox(width: 8),
                            // Question preview (truncated)
                            Expanded(
                              child: Text(
                                question.questionText,
                                maxLines: isExpanded ? 10 : 1,
                                overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Status badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(statusIcon, color: statusColor, size: 12),
                                  const SizedBox(width: 3),
                                  Text(
                                    statusLabel,
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            AnimatedRotation(
                              turns: isExpanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textHint, size: 20),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── EXPANDED DETAILS ───────────────────────────────────
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: isExpanded
                          ? Padding(
                              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Divider(height: 1),
                                  const SizedBox(height: 10),
                                  // Subject tag
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryLight,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          question.subject,
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Full question text
                                  Text(
                                    question.questionText,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.4),
                                  ),
                                  const SizedBox(height: 12),

                                  // Options — only show if wrong or skipped (to show correct vs selected)
                                  // For correct: show concise "You answered correctly" message
                                  if (isCorrect)
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.success.withOpacity(0.07),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: AppColors.success.withOpacity(0.3)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              'You selected the correct answer — Option ${question.correctAnswer.toUpperCase()}',
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else ...[
                                    // Show all options with highlights
                                    ...question.options.map((option) {
                                      final optionChar = option.trim().substring(1, 2).toLowerCase();
                                      final isUserPick = selectedOption == optionChar;
                                      final isRightAnswer = question.correctAnswer == optionChar;

                                      Color borderColor = AppColors.divider;
                                      Color bgColor = Colors.transparent;
                                      Color textColor = AppColors.textPrimary;

                                      if (isRightAnswer) {
                                        borderColor = AppColors.success;
                                        bgColor = AppColors.success.withOpacity(0.06);
                                        textColor = AppColors.primaryDark;
                                      } else if (isUserPick) {
                                        borderColor = AppColors.error;
                                        bgColor = AppColors.error.withOpacity(0.06);
                                        textColor = AppColors.error;
                                      }

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 6),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: bgColor,
                                          border: Border.all(color: borderColor, width: isRightAnswer || isUserPick ? 1.5 : 1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                option,
                                                style: TextStyle(fontSize: 13, color: textColor, fontWeight: isRightAnswer || isUserPick ? FontWeight.bold : FontWeight.normal),
                                              ),
                                            ),
                                            if (isRightAnswer)
                                              const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16)
                                            else if (isUserPick)
                                              const Icon(Icons.cancel_rounded, color: AppColors.error, size: 16),
                                          ],
                                        ),
                                      );
                                    }),
                                    const SizedBox(height: 8),
                                    // Explanation box (for wrong/skipped)
                                    Container(
                                      padding: const EdgeInsets.all(AppSpacing.m),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight.withOpacity(0.25),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isSkipped
                                                ? 'You did not attempt this question.'
                                            : 'You selected Option ${selectedOption.toUpperCase()} — that was incorrect.',
                                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                                          ),
                                          const SizedBox(height: 6),
                                          const Text(
                                            'Explanation:',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            question.solution,
                                            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.5),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: AppSpacing.m),
            PrimaryButton(
              text: 'View Global Scoreboard',
              onPressed: () => context.push('/scoreboard'),
            ),
            const SizedBox(height: AppSpacing.s),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusL)),
                side: const BorderSide(color: AppColors.divider),
              ),
              onPressed: () => context.go('/home'),
              child: const Text('Close & Go Home', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
