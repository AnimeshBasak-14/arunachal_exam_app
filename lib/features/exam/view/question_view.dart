import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/question_repository.dart';
import '../../../core/theme/aura.dart';
import '../../../core/utils/math_utils.dart';
import '../../../core/widgets/aura/aura_widgets.dart';

/// Option text split into its letter and body: "(b) Rs. 60,000" -> b, "Rs. 60,000".
class ParsedOption {
  final String letter;
  final String text;
  const ParsedOption(this.letter, this.text);

  static final _prefix = RegExp(r'^\s*\(([a-dA-D])\)\s*');

  static List<ParsedOption> parse(List<String> options) => [
        for (int i = 0; i < options.length; i++)
          () {
            final m = _prefix.firstMatch(options[i]);
            return m == null
                ? ParsedOption(String.fromCharCode(97 + i), options[i].trim())
                : ParsedOption(m.group(1)!.toLowerCase(),
                    options[i].substring(m.end).trim());
          }(),
      ];
}

enum OptionState { idle, selected, correct, wrong, dimmed }

class QuestionView extends StatelessWidget {
  final Question question;
  final int number;
  final int total;
  final String? selected;
  final bool reveal; // study mode: show the key and explanation
  final bool bookmarked;
  final String? passageRange; // "Q 11–15"
  final ValueChanged<String>? onSelect;
  final VoidCallback? onBookmark;
  final VoidCallback? onExplain;

  const QuestionView({
    super.key,
    required this.question,
    required this.number,
    required this.total,
    this.selected,
    this.reveal = false,
    this.bookmarked = false,
    this.passageRange,
    this.onSelect,
    this.onBookmark,
    this.onExplain,
  });

  OptionState _stateFor(String letter) {
    if (!reveal || !question.hasAnswerKey) {
      return selected == letter ? OptionState.selected : OptionState.idle;
    }
    if (letter == question.correctAnswer) return OptionState.correct;
    if (letter == selected) return OptionState.wrong;
    return OptionState.dimmed;
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final q = question;
    final options = ParsedOption.parse(q.options);
    final image = (q.questionImage?.trim().isNotEmpty ?? false)
        ? q.questionImage
        : q.imageUrl;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(
                        text: 'Question $number',
                        style: AuraType.sans(13, a.ink, weight: FontWeight.w600)),
                    TextSpan(
                        text: '  of $total',
                        style: AuraType.digits(13, a.inkFaint, weight: FontWeight.w400)),
                  ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (q.subject.isNotEmpty && q.subject != 'General')
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Tag(q.subject),
                ),
              if (onBookmark != null)
                IconButton(
                  tooltip: bookmarked ? 'Remove bookmark' : 'Bookmark question',
                  visualDensity: VisualDensity.compact,
                  onPressed: onBookmark,
                  icon: Icon(
                    bookmarked ? CupertinoIcons.bookmark_fill : CupertinoIcons.bookmark,
                    size: 19,
                    color: bookmarked ? a.accent : a.inkFaint,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          if (q.passageOrDirection?.trim().isNotEmpty ?? false) ...[
            _Passage(
              key: ValueKey('passage_${q.groupId ?? q.passageId ?? number}'),
              text: MathUtils.formatMath(q.passageOrDirection!.trim()),
              image: q.passageImage,
              range: passageRange,
            ),
            const SizedBox(height: 20),
          ],
          if (q.directionText?.trim().isNotEmpty ?? false) ...[
            Text(MathUtils.formatMath(q.directionText!.trim()),
                style: AuraType.sans(14.5, a.inkMuted, height: 1.6)
                    .copyWith(fontStyle: FontStyle.italic)),
            const SizedBox(height: 14),
          ],
          Text(
            MathUtils.cleanQuestionText(q.questionText, number),
            style: AuraType.sans(17.5, a.ink, weight: FontWeight.w500, height: 1.6),
          ),
          if (image != null && image.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            _NetImage(url: image),
          ],
          const SizedBox(height: 26),
          for (int i = 0; i < options.length; i++) ...[
            OptionTile(
              letter: options[i].letter,
              text: MathUtils.formatMath(options[i].text),
              image: i < q.optionImages.length ? q.optionImages[i] : null,
              state: _stateFor(options[i].letter),
              onTap: onSelect == null ? null : () => onSelect!(options[i].letter),
            ),
            const SizedBox(height: 12),
          ],
          if (reveal) ...[
            const SizedBox(height: 10),
            _Explanation(question: q, onExplain: onExplain),
          ],
        ],
      ),
    );
  }
}

class OptionTile extends StatelessWidget {
  final String letter;
  final String text;
  final String? image;
  final OptionState state;
  final VoidCallback? onTap;

  const OptionTile({
    super.key,
    required this.letter,
    required this.text,
    required this.state,
    this.image,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final (Color border, Color fill, double width) = switch (state) {
      OptionState.selected => (a.accent, a.accentSoft, 1.5),
      OptionState.correct => (a.accent, a.accentSoft, 1.5),
      OptionState.wrong => (a.danger, a.danger.withValues(alpha: 0.07), 1.5),
      _ => (a.hairline, a.surface, 0.8),
    };
    final dim = state == OptionState.dimmed;
    final radius = BorderRadius.circular(16);

    return Semantics(
      button: onTap != null,
      selected: state == OptionState.selected,
      label: 'Option ${letter.toUpperCase()}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: radius,
          border: Border.all(color: border, width: width),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap == null
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    onTap!();
                  },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LetterRadio(letter: letter, state: state),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(text,
                              style: AuraType.sans(16, dim ? a.inkFaint : a.ink,
                                  height: 1.5)),
                          if (image != null && image!.trim().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            _NetImage(url: image!),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (state == OptionState.correct || state == OptionState.wrong)
                    Padding(
                      padding: const EdgeInsets.only(left: 8, top: 4),
                      child: Icon(
                        state == OptionState.correct
                            ? CupertinoIcons.checkmark_alt
                            : CupertinoIcons.xmark,
                        size: 17,
                        color: state == OptionState.correct ? a.accent : a.danger,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LetterRadio extends StatelessWidget {
  final String letter;
  final OptionState state;
  const _LetterRadio({required this.letter, required this.state});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final filled = state == OptionState.selected || state == OptionState.correct;
    final wrong = state == OptionState.wrong;
    final color = wrong ? a.danger : a.accent;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled || wrong ? color : Colors.transparent,
        border: Border.all(
          color: filled || wrong ? color : a.inkFaint.withValues(alpha: 0.6),
          width: 1.3,
        ),
      ),
      child: Text(
        letter.toUpperCase(),
        style: AuraType.sans(13, filled || wrong ? a.onAccent : a.inkMuted,
            weight: FontWeight.w600, height: 1),
      ),
    );
  }
}

class _Passage extends StatefulWidget {
  final String text;
  final String? image;
  final String? range;
  const _Passage({super.key, required this.text, this.image, this.range});

  @override
  State<_Passage> createState() => _PassageState();
}

class _PassageState extends State<_Passage> {
  bool _open = true;

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(18, 6, 8, 6),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Row(
              children: [
                Expanded(
                  child: Eyebrow(widget.range == null
                      ? 'Read the passage'
                      : 'Passage · ${widget.range}'),
                ),
                IconButton(
                  tooltip: _open ? 'Hide passage' : 'Show passage',
                  onPressed: () => setState(() => _open = !_open),
                  icon: AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(CupertinoIcons.chevron_down, size: 16, color: a.inkFaint),
                  ),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _open
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 10, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.text,
                            style: AuraType.sans(15, a.ink, height: 1.7)),
                        if (widget.image?.trim().isNotEmpty ?? false) ...[
                          const SizedBox(height: 12),
                          _NetImage(url: widget.image!),
                        ],
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _Explanation extends StatelessWidget {
  final Question question;
  final VoidCallback? onExplain;
  const _Explanation({required this.question, this.onExplain});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final q = question;
    final solution = q.solution.trim();
    return GlassCard(
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(q.hasAnswerKey ? 'Answer · ${q.correctAnswer.toUpperCase()}' : 'Answer key pending',
              color: q.hasAnswerKey ? a.accent : a.review),
          const SizedBox(height: 10),
          Text(
            q.hasAnswerKey
                ? (solution.isEmpty ? 'No written explanation for this question yet.' : MathUtils.formatMath(solution))
                : 'The official key for this question has not been verified, so it is not scored.',
            style: AuraType.sans(15, a.inkMuted, height: 1.65),
          ),
          if (onExplain != null) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onExplain,
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                icon: const Icon(CupertinoIcons.sparkles, size: 16),
                label: const Text('Explain with AI'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NetImage extends StatelessWidget {
  final String url;
  const _NetImage({required this.url});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        fit: BoxFit.contain,
        loadingBuilder: (ctx, child, progress) => progress == null
            ? child
            : const SkeletonBox(height: 160),
        errorBuilder: (_, __, ___) => Container(
          height: 64,
          alignment: Alignment.center,
          color: a.hairline.withValues(alpha: 0.4),
          child: Text('Image unavailable offline', style: AuraType.sans(12.5, a.inkFaint)),
        ),
      ),
    );
  }
}
