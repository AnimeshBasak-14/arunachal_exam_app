import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/daily_dose_data.dart';

class WordOfDayCard extends StatefulWidget {
  const WordOfDayCard({super.key});

  @override
  State<WordOfDayCard> createState() => _WordOfDayCardState();
}

class _WordOfDayCardState extends State<WordOfDayCard> {
  DailyItemType _selectedType = DailyItemType.word;
  int _offset = 0;
  bool _expanded = false;

  void _shuffle() {
    setState(() {
      _offset += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = DailyDoseData.getTodayItem(_selectedType, _offset);

    List<Color> gradientColors;
    String badgeEmoji;
    switch (_selectedType) {
      case DailyItemType.word:
        gradientColors = [const Color(0xFF1a237e), const Color(0xFF283593)];
        badgeEmoji = '📚 VOCABULARY';
        break;
      case DailyItemType.idiom:
        gradientColors = [const Color(0xFF4A148C), const Color(0xFF6A1B9A)];
        badgeEmoji = '💡 IDIOM & PHRASE';
        break;
      case DailyItemType.quote:
        gradientColors = [const Color(0xFF004D40), const Color(0xFF00695C)];
        badgeEmoji = '✨ DAILY INSPIRATION';
        break;
    }

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusL),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withValues(alpha: 0.35),
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
                  child: Text(
                    badgeEmoji,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: _shuffle,
                  borderRadius: BorderRadius.circular(16),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Icon(Icons.shuffle_rounded, color: Colors.white70, size: 16),
                        SizedBox(width: 3),
                        Text(
                          'Next',
                          style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: Colors.white54,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),

            Row(
              children: [
                _buildTypeChip('Word', DailyItemType.word),
                const SizedBox(width: 6),
                _buildTypeChip('Idiom', DailyItemType.idiom),
                const SizedBox(width: 6),
                _buildTypeChip('Quote', DailyItemType.quote),
              ],
            ),
            const SizedBox(height: AppSpacing.s),

            Text(
              item.title,
              style: TextStyle(
                color: Colors.white,
                fontSize: _selectedType == DailyItemType.quote ? 15 : 20,
                fontWeight: FontWeight.bold,
                height: 1.3,
                fontStyle: _selectedType == DailyItemType.quote ? FontStyle.italic : FontStyle.normal,
              ),
            ),
            const SizedBox(height: 4),

            Text(
              _selectedType == DailyItemType.quote
                  ? item.exampleOrAuthor
                  : ' · ',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12.5,
                height: 1.35,
              ),
            ),

            if (_expanded) ...[
              const SizedBox(height: AppSpacing.s),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: AppSpacing.s),
              if (_selectedType == DailyItemType.quote) ...[
                _buildPill('Insight', item.meaning, Icons.lightbulb_outline_rounded),
              ] else ...[
                _buildPill('Exam Sentence', item.exampleOrAuthor, Icons.format_quote_rounded),
                if (item.synonyms.isNotEmpty || item.antonyms.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.synonyms.isNotEmpty)
                        Expanded(
                          child: _buildTagRow('Synonyms', item.synonyms, const Color(0xFF81C784)),
                        ),
                      if (item.synonyms.isNotEmpty && item.antonyms.isNotEmpty)
                        const SizedBox(width: 8),
                      if (item.antonyms.isNotEmpty)
                        Expanded(
                          child: _buildTagRow('Antonyms', item.antonyms, const Color(0xFFE57373)),
                        ),
                    ],
                  ),
                ],
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(String label, DailyItemType type) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        if (_selectedType != type) {
          setState(() {
            _selectedType = type;
            _offset = 0;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black87 : Colors.white70,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
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
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontStyle: FontStyle.italic,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagRow(String label, List<String> words, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: words
              .map((w) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: color.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      w,
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}
