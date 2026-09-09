import 'package:flutter/material.dart';
import '../../../core/services/question_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/math_utils.dart';

class QuestionDisplayGroup {
  final String? groupId;
  final String? passage;
  final String? passageImage;
  final List<Question> questions;
  final int startIndex;
  final int endIndex;

  QuestionDisplayGroup({
    this.groupId,
    this.passage,
    this.passageImage,
    required this.questions,
    required this.startIndex,
    required this.endIndex,
  });

  bool get isGroup =>
      questions.length > 1 || (passage != null && passage!.trim().isNotEmpty);
}

List<QuestionDisplayGroup> buildQuestionDisplayGroups(List<Question> questions) {
  final groups = <QuestionDisplayGroup>[];
  int currentQIndex = 1;

  int i = 0;
  while (i < questions.length) {
    final q = questions[i];
    final gId = (q.passageId != null && q.passageId!.isNotEmpty)
        ? q.passageId
        : ((q.groupId != null && q.groupId!.isNotEmpty) ? q.groupId : null);

    if (gId != null) {
      final siblingQuestions = <Question>[q];
      int j = i + 1;
      while (j < questions.length &&
          ((questions[j].passageId != null && questions[j].passageId == gId) ||
              (questions[j].groupId != null && questions[j].groupId == gId))) {
        siblingQuestions.add(questions[j]);
        j++;
      }

      String? groupPassage = q.passageOrDirection;
      String? groupImage = q.passageImage;
      for (final sq in siblingQuestions) {
        if (groupPassage == null || groupPassage.isEmpty) {
          if (sq.passageOrDirection != null && sq.passageOrDirection!.isNotEmpty) {
            groupPassage = sq.passageOrDirection;
          }
        }
        if (groupImage == null || groupImage.isEmpty) {
          if (sq.passageImage != null && sq.passageImage!.isNotEmpty) {
            groupImage = sq.passageImage;
          }
        }
      }

      groups.add(QuestionDisplayGroup(
        groupId: gId,
        passage: groupPassage,
        passageImage: groupImage,
        questions: siblingQuestions,
        startIndex: currentQIndex,
        endIndex: currentQIndex + siblingQuestions.length - 1,
      ));
      currentQIndex += siblingQuestions.length;
      i = j;
    } else if (q.passageOrDirection != null &&
        q.passageOrDirection!.trim().isNotEmpty) {
      final siblingQuestions = <Question>[q];
      int j = i + 1;
      while (j < questions.length &&
          questions[j].passageOrDirection != null &&
          questions[j].passageOrDirection!.trim() ==
              q.passageOrDirection!.trim()) {
        siblingQuestions.add(questions[j]);
        j++;
      }
      groups.add(QuestionDisplayGroup(
        groupId: null,
        passage: q.passageOrDirection,
        passageImage: q.passageImage,
        questions: siblingQuestions,
        startIndex: currentQIndex,
        endIndex: currentQIndex + siblingQuestions.length - 1,
      ));
      currentQIndex += siblingQuestions.length;
      i = j;
    } else {
      groups.add(QuestionDisplayGroup(
        groupId: null,
        passage: null,
        passageImage: null,
        questions: [q],
        startIndex: currentQIndex,
        endIndex: currentQIndex,
      ));
      currentQIndex++;
      i++;
    }
  }
  return groups;
}


class ComprehensionGroupWidget extends StatefulWidget {
  final String? passage;
  final String? passageImage;
  final int startIndex;
  final int endIndex;
  final List<Widget> children;
  final String? bannerTitle;

  const ComprehensionGroupWidget({
    super.key,
    this.passage,
    this.passageImage,
    required this.startIndex,
    required this.endIndex,
    required this.children,
    this.bannerTitle,
  });

  @override
  State<ComprehensionGroupWidget> createState() =>
      _ComprehensionGroupWidgetState();
}

class _ComprehensionGroupWidgetState extends State<ComprehensionGroupWidget> {
  bool _isPassageCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final hasPassage =
        (widget.passage != null && widget.passage!.trim().isNotEmpty) ||
            (widget.passageImage != null && widget.passageImage!.trim().isNotEmpty);

    final rangeText = widget.startIndex == widget.endIndex
        ? 'Q${widget.startIndex}'
        : 'Q${widget.startIndex} – Q${widget.endIndex}';

    return Card(
      key: widget.key,
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusL),
        side: const BorderSide(
          color: Color(0xFF1565C0),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen = constraints.maxWidth >= 720;

            if (isWideScreen && hasPassage) {
              // ─── Wide Screen: Side-by-side Two Pane Layout ────────────────
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildBanner(rangeText),
                  const SizedBox(height: AppSpacing.m),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Pane: Passage
                        Expanded(
                          flex: 5,
                          child: _buildPassageContainer(
                            rangeText: rangeText,
                            collapsible: false,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.m),
                        const VerticalDivider(
                          color: AppColors.divider,
                          thickness: 1.2,
                        ),
                        const SizedBox(width: AppSpacing.m),
                        // Right Pane: Sub-questions
                        Expanded(
                          flex: 7,
                          child: _buildQuestionsList(),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            // ─── Standard / Mobile Screen: Vertical Stack Layout ────────────
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBanner(rangeText),
                if (hasPassage) ...[
                  const SizedBox(height: AppSpacing.m),
                  _buildPassageContainer(
                    rangeText: rangeText,
                    collapsible: true,
                  ),
                ],
                const SizedBox(height: AppSpacing.m),
                _buildQuestionsList(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBanner(String rangeText) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF1565C0).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.layers_rounded,
            size: 16,
            color: Color(0xFF1565C0),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.bannerTitle ??
                  '📚 Comprehension / Group Questions ($rangeText)',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1565C0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassageContainer({
    required String rangeText,
    required bool collapsible,
  }) {
    final passageText = widget.passage?.trim() ?? '';
    final isLongPassage = passageText.length > 250;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.menu_book_rounded,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Directions ($rangeText)',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              if (collapsible && isLongPassage)
                InkWell(
                  onTap: () {
                    setState(() {
                      _isPassageCollapsed = !_isPassageCollapsed;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isPassageCollapsed ? 'Expand' : 'Collapse',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Icon(
                          _isPassageCollapsed
                              ? Icons.keyboard_arrow_down_rounded
                              : Icons.keyboard_arrow_up_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (!_isPassageCollapsed && passageText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              MathUtils.formatDirectionRange(
                passageText,
                widget.startIndex,
                widget.endIndex,
              ),
              style: const TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ] else if (_isPassageCollapsed && passageText.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              passageText.length > 100
                  ? '${passageText.substring(0, 100)}...'
                  : passageText,
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.textHint,
              ),
            ),
          ],
          if (widget.passageImage != null &&
              widget.passageImage!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                widget.passageImage!,
                fit: BoxFit.contain,
                loadingBuilder: (ctx, child, progress) => progress == null
                    ? child
                    : const SizedBox(
                        height: 60,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
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
                          color: AppColors.textHint, size: 20),
                      SizedBox(width: 6),
                      Text(
                        'Diagram could not be loaded',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestionsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < widget.children.length; i++) ...[
          if (i > 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.m),
              child: Divider(
                color: AppColors.divider,
                thickness: 1.2,
              ),
            ),
          widget.children[i],
        ],
      ],
    );
  }
}
