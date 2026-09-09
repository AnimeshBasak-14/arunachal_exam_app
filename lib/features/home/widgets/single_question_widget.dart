import 'package:flutter/material.dart';
import '../../../core/services/question_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/math_utils.dart';

class SingleQuestionWidget extends StatelessWidget {
  final Question question;
  final int displayNum;
  final String? selectedOption;
  final ValueChanged<String>? onSelectOption;
  final bool isSubmitted;
  final bool showSolution;
  final VoidCallback? onToggleSolution;
  final bool isBookmarked;
  final VoidCallback? onToggleBookmark;
  final VoidCallback? onShare;
  final String? selectedSubjectFilter;
  final bool isInsideGroup;
  final bool isHelpfulLiked;
  final VoidCallback? onToggleHelpful;
  final Widget? discussionWidget;
  final Widget? likeButton;
  final Widget? trailingHeader;

  const SingleQuestionWidget({
    super.key,
    required this.question,
    required this.displayNum,
    this.selectedOption,
    this.onSelectOption,
    this.isSubmitted = false,
    this.showSolution = false,
    this.onToggleSolution,
    this.isBookmarked = false,
    this.onToggleBookmark,
    this.onShare,
    this.selectedSubjectFilter,
    this.isInsideGroup = false,
    this.isHelpfulLiked = false,
    this.onToggleHelpful,
    this.discussionWidget,
    this.likeButton,
    this.trailingHeader,
  });

  String _extractOptionChar(String option, int fallbackIndex) {
    final trimmed = option.trim();
    final match = RegExp(r'^[\(\[]?([a-dA-D])[\)\]\.\s]').firstMatch(trimmed);
    if (match != null) return match.group(1)!.toLowerCase();
    return String.fromCharCode(97 + fallbackIndex);
  }

  @override
  Widget build(BuildContext context) {
    // Determine if subject chip is redundant (matches the currently selected filter)
    final isFilterActive = selectedSubjectFilter != null &&
        selectedSubjectFilter != 'All' &&
        selectedSubjectFilter!.trim().isNotEmpty;
    final isSameSubject = isFilterActive &&
        question.subject.trim().toLowerCase() ==
            selectedSubjectFilter!.trim().toLowerCase();
    final showSubjectChip = !isSameSubject;

    // Filter out dummy or empty options
    final validOptions = <MapEntry<int, String>>[];
    for (int i = 0; i < question.options.length; i++) {
      final opt = question.options[i].trim();
      if (opt.isNotEmpty && !RegExp(r'^Option\s+[A-D]$', caseSensitive: false).hasMatch(opt)) {
        validOptions.add(MapEntry(i, opt));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─── Question Header: Subject Badge & Actions ──────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (showSubjectChip)
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isInsideGroup
                        ? const Color(0xFF1565C0).withValues(alpha: 0.1)
                        : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isInsideGroup
                        ? 'Q$displayNum • ${question.subject}'
                        : question.subject,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isInsideGroup
                          ? const Color(0xFF1565C0)
                          : AppColors.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              )
            else if (isInsideGroup)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Q$displayNum',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                  ),
                ),
              )
            else
              const SizedBox.shrink(),
            const SizedBox(width: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (trailingHeader != null) trailingHeader!,
                if (likeButton != null) likeButton!,
                if (onShare != null)
                  IconButton(
                    icon: const Icon(Icons.share_outlined,
                        color: AppColors.textHint, size: 20),
                    onPressed: onShare,
                    tooltip: 'Share Question',
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                if (onToggleBookmark != null)
                  IconButton(
                    icon: Icon(
                      isBookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: isBookmarked ? AppColors.accent : AppColors.textHint,
                      size: 20,
                    ),
                    onPressed: onToggleBookmark,
                    tooltip: 'Bookmark Question',
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s),

        // ─── Question Text ─────────────────────────────────────────────
        Text(
          'Q$displayNum. ${MathUtils.cleanQuestionText(question.questionText, displayNum)}',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),

        // ─── Question Image (if any) ───────────────────────────────────
        if (question.questionImage != null &&
            question.questionImage!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              question.questionImage!,
              fit: BoxFit.contain,
              loadingBuilder: (ctx, child, progress) => progress == null
                  ? child
                  : const SizedBox(
                      height: 48,
                      child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
              errorBuilder: (_, __, ___) => Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.divider),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image_rounded,
                        size: 20, color: AppColors.textHint),
                    SizedBox(width: 8),
                    Text('Image unavailable',
                        style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                  ],
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.m),

        // ─── Options List ──────────────────────────────────────────────
        ...validOptions.map((entry) {
          final optIdx = entry.key;
          final option = entry.value;
          final optionChar = _extractOptionChar(option, optIdx);
          final isSelected = selectedOption == optionChar;
          final isCorrect = question.correctAnswer.toLowerCase() == optionChar;

          Color optionBorderColor = AppColors.divider;
          Color optionBgColor = Colors.transparent;

          if (selectedOption != null || isSubmitted) {
            if (isCorrect) {
              optionBorderColor = AppColors.success;
              optionBgColor = AppColors.success.withValues(alpha: 0.08);
            } else if (isSelected) {
              optionBorderColor = AppColors.error;
              optionBgColor = AppColors.error.withValues(alpha: 0.08);
            }
          }

          return Container(
            key: ValueKey('${question.id}_opt_$optIdx'),
            margin: const EdgeInsets.only(bottom: AppSpacing.s),
            decoration: BoxDecoration(
              color: optionBgColor,
              border: Border.all(
                color: optionBorderColor,
                width: isSelected || ((selectedOption != null || isSubmitted) && isCorrect)
                    ? 2.0
                    : 1.0,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: (isSubmitted || (selectedOption != null && onToggleSolution == null))
                  ? null
                  : () => onSelectOption?.call(optionChar),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.m, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      MathUtils.formatMath(option),
                      style: TextStyle(
                        fontSize: 14,
                        color: (selectedOption != null || isSubmitted) && isCorrect
                            ? AppColors.primaryDark
                            : AppColors.textPrimary,
                        fontWeight: isSelected ||
                                ((selectedOption != null || isSubmitted) && isCorrect)
                            ? FontWeight.bold
                            : FontWeight.normal,
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
            ),
          );
        }),

        // ─── Show Solution Button (Practice / PYQ mode) ────────────────
        if (onToggleSolution != null) ...[
          const SizedBox(height: AppSpacing.s),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onToggleSolution,
              icon: Icon(
                showSolution
                    ? Icons.lightbulb_outline_rounded
                    : Icons.lightbulb_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              label: Text(
                showSolution ? 'Hide Solution' : 'Show Solution',
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],

        // ─── Solution Drawer ───────────────────────────────────────────
        if (showSolution) ...[
          const SizedBox(height: AppSpacing.s),
          Container(
            padding: const EdgeInsets.all(AppSpacing.m),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline_rounded,
                              color: AppColors.primary, size: 18),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Official Answer: ${question.officialAnswer}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryDark,
                                  fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onToggleHelpful != null) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: onToggleHelpful,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isHelpfulLiked
                                    ? Icons.thumb_up_rounded
                                    : Icons.thumb_up_outlined,
                                color: isHelpfulLiked
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                size: 15,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Helpful',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.s),
                const Text(
                  'Explanation:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  MathUtils.formatMath(question.solution),
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4),
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
          ),
        ],

        // ─── Discussion Widget ─────────────────────────────────────────
        if (discussionWidget != null) ...[
          const Divider(height: AppSpacing.l),
          discussionWidget!,
        ],
      ],
    );
  }
}
