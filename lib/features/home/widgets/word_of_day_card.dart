import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/word_of_the_day_data.dart';

class WordOfDayCard extends StatefulWidget {
  const WordOfDayCard({super.key});

  @override
  State<WordOfDayCard> createState() => _WordOfDayCardState();
}

class _WordOfDayCardState extends State<WordOfDayCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final word = WordOfTheDayData.getTodaysWord();
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1a237e), Color(0xFF283593)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusL),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1a237e).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '📚 WORD OF THE DAY',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: Colors.white54,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  word.word,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  word.partOfSpeech,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              word.meaning,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            if (_expanded) ...[
              const SizedBox(height: AppSpacing.s),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: AppSpacing.s),
              _buildPill('Example', word.exampleSentence, Icons.format_quote_rounded),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildTagRow('Synonyms', word.synonyms, const Color(0xFF4CAF50))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildTagRow('Antonyms', word.antonyms, const Color(0xFFE57373))),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPill(String label, String text, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white54, size: 14),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic, height: 1.3),
          ),
        ),
      ],
    );
  }

  Widget _buildTagRow(String label, List<String> words, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: words.map((w) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Text(w, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
          )).toList(),
        ),
      ],
    );
  }
}
