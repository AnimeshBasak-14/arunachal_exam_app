import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/aura.dart';
import '../../../core/widgets/aura/aura_widgets.dart';
import '../data/paper.dart';

String _qs(Paper p) => '${p.questionCount} Qs';

/// Compact card for horizontal carousels.
class PaperCard extends StatelessWidget {
  final Paper paper;
  final double width;
  const PaperCard({super.key, required this.paper, this.width = 232});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return SizedBox(
      width: width,
      child: GlassCard(
        onTap: () => showPaperSheet(context, paper),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Eyebrow('${paper.department.label} · ${paper.shortCode}',
                color: a.accent),
            const SizedBox(height: 10),
            Expanded(
              child: Text(
                paper.title,
                style: AuraType.serif(17, a.ink, height: 1.28),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),
            Divider(color: a.hairline),
            const SizedBox(height: 10),
            MetaLine([paper.year?.toString(), paper.shiftLabel, _qs(paper)]),
          ],
        ),
      ),
    );
  }
}

/// Full-width row for library lists.
class PaperRow extends StatelessWidget {
  final Paper paper;
  const PaperRow({super.key, required this.paper});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final isMock = paper.kind == PaperKind.mock;
    return GlassCard(
      onTap: () => showPaperSheet(context, paper),
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Eyebrow('${paper.department.label} · ${paper.shortCode}'),
                const SizedBox(height: 6),
                Text(
                  paper.title,
                  style: AuraType.sans(15.5, a.ink,
                      weight: FontWeight.w600, height: 1.35),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                MetaLine([
                  if (!isMock) paper.year?.toString(),
                  paper.shiftLabel,
                  _qs(paper),
                  if (paper.durationMinutes != null)
                    '${paper.durationMinutes} min',
                  if (isMock) paper.difficulty,
                ]),
                if (paper.isIncomplete) ...[
                  const SizedBox(height: 8),
                  Tag(
                    'Incomplete · ${paper.questionCount} of ${paper.officialQuestionCount}',
                    color: a.review,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(CupertinoIcons.chevron_right, size: 16, color: a.inkFaint),
        ],
      ),
    );
  }
}

/// Paper details with the two ways to attempt it.
Future<void> showPaperSheet(BuildContext context, Paper paper) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _PaperSheet(paper: paper),
  );
}

class _PaperSheet extends StatelessWidget {
  final Paper paper;
  const _PaperSheet({required this.paper});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final marks = paper.marksPerCorrect ?? 2;
    final neg = paper.negativeMarks ?? 0.5;
    String fmt(double v) =>
        v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

    void go(bool study) {
      Navigator.of(context).pop();
      context.push(paper.examRoute(study: study));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(paper.department.longName, color: a.accent),
          const SizedBox(height: 10),
          Text(paper.title, style: AuraType.serif(25, a.ink, height: 1.25)),
          const SizedBox(height: 22),
          Row(
            children: [
              _Fact(label: 'Questions', value: '${paper.questionCount}'),
              _Fact(label: 'Duration', value: '${paper.effectiveDuration} min'),
              _Fact(label: 'Marking', value: '+${fmt(marks)} / −${fmt(neg)}'),
            ],
          ),
          if (paper.year != null || paper.shiftLabel.isNotEmpty) ...[
            const SizedBox(height: 14),
            MetaLine([
              if (paper.year != null) 'Year ${paper.year}',
              paper.shiftLabel,
              paper.subject,
            ]),
          ],
          if (paper.isIncomplete) ...[
            const SizedBox(height: 14),
            Text(
              'This paper is still being digitised: ${paper.questionCount} of ${paper.officialQuestionCount} questions are available.',
              style: AuraType.sans(13, a.review, height: 1.5),
            ),
          ],
          const SizedBox(height: 26),
          FilledButton(
            onPressed: () => go(false),
            style:
                FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
            child: const Text('Begin exam mode'),
          ),
          const SizedBox(height: 6),
          Text(
            'Timed, full screen, scored on submit. Just like the real exam.',
            textAlign: TextAlign.center,
            style: AuraType.sans(12.5, a.inkFaint),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => go(true),
            style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(54)),
            child: const Text('Study with answers'),
          ),
          const SizedBox(height: 6),
          Text(
            'No timer. See the answer and explanation after each question.',
            textAlign: TextAlign.center,
            style: AuraType.sans(12.5, a.inkFaint),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  final String label;
  final String value;
  const _Fact({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AuraType.digits(17, a.ink)),
          const SizedBox(height: 3),
          Text(label, style: AuraType.sans(12, a.inkFaint)),
        ],
      ),
    );
  }
}
