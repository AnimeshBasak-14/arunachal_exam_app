import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/supabase_config.dart';
import '../../../core/services/question_repository.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/theme/aura.dart';
import '../../../core/widgets/aura/aura_widgets.dart';
import '../../learn/view/study_widgets.dart';

final _bookmarkedQuestionsProvider = FutureProvider.autoDispose
    .family<List<Question>, String>((ref, joinedIds) async {
  if (joinedIds.isEmpty) return const [];
  final ids = joinedIds.split(',').map((id) => '"$id"').join(',');
  final res = await http
      .get(
        Uri.parse(
            '${SupabaseConfig.url}/rest/v1/questions?id=in.($ids)&select=*,tests(*)'),
        headers: SupabaseConfig.authHeaders,
      )
      .timeout(const Duration(seconds: 12));
  if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
  return [
    for (final item in jsonDecode(res.body) as List)
      Question.fromSupabase(item as Map<String, dynamic>)
  ];
});

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(bookmarkedQuestionsProvider);
    final async = ref.watch(_bookmarkedQuestionsProvider(ids.join(',')));

    return StudyPage(
      title: 'Bookmarked questions',
      children: [
        if (ids.isEmpty)
          const AuraEmpty(
            icon: CupertinoIcons.bookmark,
            title: 'No bookmarks yet',
            message:
                'Tap the bookmark on any question while practising a paper to keep it here for revision.',
          )
        else
          ...async.when(
            loading: () => [
              for (int i = 0; i < 4; i++)
                const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: SkeletonBox(height: 96)),
            ],
            error: (_, __) => [
              AuraEmpty(
                icon: CupertinoIcons.wifi_slash,
                title: 'Couldn\'t load bookmarks',
                message: 'Check your connection and try again.',
                actionLabel: 'Retry',
                onAction: () => ref.invalidate(_bookmarkedQuestionsProvider),
              ),
            ],
            data: (qs) => [
              Text('${qs.length} saved',
                  style: AuraType.sans(13, context.aura.inkFaint)),
              const SizedBox(height: 12),
              for (final q in qs) ...[
                _QuestionCard(q: q),
                const SizedBox(height: 12)
              ],
            ],
          ),
      ],
    );
  }
}

class _QuestionCard extends ConsumerStatefulWidget {
  final Question q;
  const _QuestionCard({required this.q});

  @override
  ConsumerState<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends ConsumerState<_QuestionCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final q = widget.q;
    final good = a.success;
    final answerIdx = 'abcd'.indexOf(q.correctAnswer.toLowerCase());

    return GlassCard(
      onTap: () => setState(() => _open = !_open),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
                child: MetaLine(
                    [q.examCode, q.year > 0 ? '${q.year}' : null, q.subject])),
            IconButton(
              tooltip: 'Remove bookmark',
              visualDensity: VisualDensity.compact,
              icon:
                  Icon(CupertinoIcons.bookmark_fill, size: 19, color: a.accent),
              onPressed: () => ref
                  .read(bookmarkedQuestionsProvider.notifier)
                  .toggleBookmark(q.id),
            ),
          ]),
          const SizedBox(height: 6),
          Text(q.questionText,
              maxLines: _open ? null : 3,
              overflow: _open ? null : TextOverflow.ellipsis,
              style: AuraType.sans(15, a.ink, height: 1.5)),
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            child: !_open
                ? const SizedBox(width: double.infinity)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      for (int i = 0; i < q.options.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                    i == answerIdx
                                        ? CupertinoIcons.checkmark_circle_fill
                                        : CupertinoIcons.circle,
                                    size: 17,
                                    color: i == answerIdx ? good : a.inkFaint),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(q.options[i],
                                      style: AuraType.sans(14,
                                          i == answerIdx ? a.ink : a.inkMuted,
                                          weight: i == answerIdx
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          height: 1.45)),
                                ),
                              ]),
                        ),
                      if (answerIdx < 0)
                        Text('Answer key not verified for this question.',
                            style: AuraType.sans(13, a.review)),
                      if (q.solution.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Divider(color: a.hairline),
                        const SizedBox(height: 8),
                        Text(q.solution,
                            style: AuraType.sans(14, a.inkMuted, height: 1.55)),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: 8),
          Text(_open ? 'Tap to hide' : 'Tap to see answer',
              style: AuraType.sans(12, a.inkFaint)),
        ],
      ),
    );
  }
}
