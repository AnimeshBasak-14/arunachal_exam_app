import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/ai_service.dart';
import '../theme/aura.dart';
import 'aura/aura_widgets.dart';

/// Bottom sheet that explains a question or passage with the AI tutor.
void showAiExplainSheet(BuildContext context,
    {required String highlightedText}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => AiExplainSheet(text: highlightedText),
  );
}

class AiExplainSheet extends StatefulWidget {
  final String text;
  const AiExplainSheet({super.key, required this.text});

  @override
  State<AiExplainSheet> createState() => _AiExplainSheetState();
}

class _AiExplainSheetState extends State<AiExplainSheet> {
  late Future<String> _answer = _ask();

  Future<String> _ask() => AiService.generate([
        AiTurn.user(
            'Explain this for an exam aspirant in under 150 words. Use bullet points where '
            'helpful and end with one memory tip.\n\n"${widget.text}"'),
      ]);

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        children: [
          Row(children: [
            Icon(CupertinoIcons.sparkles, size: 18, color: a.accent),
            const SizedBox(width: 8),
            Text('Explained', style: AuraType.serif(21, a.ink)),
          ]),
          const SizedBox(height: 16),
          FutureBuilder<String>(
            future: _answer,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Column(children: [
                  SkeletonBox(height: 16),
                  SizedBox(height: 10),
                  SkeletonBox(height: 16),
                  SizedBox(height: 10),
                  SkeletonBox(height: 16, width: 200),
                ]);
              }
              if (snap.hasError) {
                return AuraEmpty(
                  icon: CupertinoIcons.exclamationmark_circle,
                  title: 'No explanation',
                  message: snap.error.toString(),
                  actionLabel: 'Try again',
                  onAction: () => setState(() => _answer = _ask()),
                );
              }
              final body = AuraType.sans(15, a.ink, height: 1.55);
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MarkdownBody(
                      data: snap.data!,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: body,
                        listBullet: body,
                        strong: body.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('AI explanations can be wrong. Check important facts.',
                        style: AuraType.sans(12, a.inkFaint)),
                  ]);
            },
          ),
        ],
      ),
    );
  }
}
