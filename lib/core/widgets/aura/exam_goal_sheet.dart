import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/exam_goals.dart';
import '../../theme/aura.dart';
import 'aura_widgets.dart';

Future<void> showExamGoalSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _ExamGoalSheet(),
  );
}

class _ExamGoalSheet extends ConsumerWidget {
  const _ExamGoalSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = context.aura;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Your exam goal', style: AuraType.serif(25, a.ink)),
          const SizedBox(height: 6),
          Text('We put papers for this exam first.',
              style: AuraType.sans(14, a.inkMuted)),
          const SizedBox(height: 20),
          ExamGoalList(
            onSelected: (_) => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

/// Goals grouped by department; used in onboarding and the picker sheet.
class ExamGoalList extends ConsumerWidget {
  final ValueChanged<ExamGoal>? onSelected;
  const ExamGoalList({super.key, this.onSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = context.aura;
    final current = ref.watch(examGoalProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final dept in Department.primary) ...[
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 10),
            child: Eyebrow(dept.longName),
          ),
          GlassList(
            indent: 18,
            children: [
              for (final g in examGoals.where((g) => g.department == dept))
                InkWell(
                  onTap: () {
                    ref.read(examGoalProvider.notifier).select(g);
                    onSelected?.call(g);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 15),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            g.name,
                            style: AuraType.sans(15, a.ink,
                                weight: g.id == current.id
                                    ? FontWeight.w600
                                    : FontWeight.w400),
                          ),
                        ),
                        AnimatedOpacity(
                          opacity: g.id == current.id ? 1 : 0,
                          duration: const Duration(milliseconds: 180),
                          child: Icon(CupertinoIcons.checkmark_alt,
                              size: 18, color: a.accent),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}
