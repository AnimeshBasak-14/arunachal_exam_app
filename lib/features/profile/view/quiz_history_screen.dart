import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/theme/aura.dart';
import '../../../core/widgets/aura/aura_widgets.dart';
import '../../analytics/view/analytics_screen.dart' show AttemptRow;
import '../../exam/data/attempt.dart';
import '../../learn/view/study_widgets.dart';

class QuizHistoryScreen extends ConsumerStatefulWidget {
  const QuizHistoryScreen({super.key});

  @override
  ConsumerState<QuizHistoryScreen> createState() => _QuizHistoryScreenState();
}

class _QuizHistoryScreenState extends ConsumerState<QuizHistoryScreen> {
  String _q = '';
  int _filter = 0; // 0 all · 1 exam · 2 study

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final all = loadAttempts(ref.watch(storageServiceProvider));
    final shown = all.where((t) {
      if (_filter == 1 && t.mode == 'study') return false;
      if (_filter == 2 && t.mode != 'study') return false;
      final q = _q.trim().toLowerCase();
      return q.isEmpty ||
          t.title.toLowerCase().contains(q) ||
          t.examCode.toLowerCase().contains(q);
    }).toList();

    final graded = all.where((t) => t.maxScore > 0).toList();
    final avg = graded.isEmpty
        ? 0.0
        : graded.map((t) => t.scoreRatio).reduce((x, y) => x + y) /
            graded.length;
    final best = graded.isEmpty
        ? 0.0
        : graded.map((t) => t.scoreRatio).reduce((x, y) => x > y ? x : y);

    return StudyPage(
      title: 'Test history',
      children: [
        if (all.isEmpty)
          AuraEmpty(
            icon: CupertinoIcons.clock,
            title: 'No tests yet',
            message:
                'Finish a previous-year paper or a mock test and your results will appear here.',
            actionLabel: 'Browse papers',
            onAction: () => context.go('/home?tab=1'),
          )
        else ...[
          Row(children: [
            _Stat('${all.length}', 'tests'),
            _Stat('${(avg * 100).round()}%', 'average'),
            _Stat('${(best * 100).round()}%', 'best'),
          ]),
          const SizedBox(height: 22),
          TextField(
            onChanged: (v) => setState(() => _q = v),
            decoration: const InputDecoration(
              hintText: 'Search by paper or exam',
              prefixIcon: Icon(CupertinoIcons.search, size: 18),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          SegmentedTabs(
            labels: const ['All', 'Exam mode', 'Study mode'],
            selected: _filter,
            onChanged: (i) => setState(() => _filter = i),
          ),
          const SizedBox(height: 12),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child:
                  Text('No tests match.', style: AuraType.sans(14, a.inkMuted)),
            ),
          for (final t in shown) ...[
            AttemptRow(attempt: t),
            const SizedBox(height: 10)
          ],
        ],
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String value, label;
  const _Stat(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: AuraType.serif(28, a.ink)),
        Text(label, style: AuraType.sans(12.5, a.inkFaint)),
      ]),
    );
  }
}
