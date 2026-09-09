import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/services/question_repository.dart';
import '../core/theme/app_colors.dart';
import '../features/home/view/mock_test_screen.dart';

void showCustomPracticeModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const CustomPracticeModal(),
  );
}

class CustomPracticeModal extends StatefulWidget {
  final bool isEmbedded;
  const CustomPracticeModal({super.key, this.isEmbedded = false});

  @override
  State<CustomPracticeModal> createState() => _CustomPracticeModalState();
}

class _CustomPracticeModalState extends State<CustomPracticeModal> {
  static const String _supabaseUrl = 'https://fllopztywwblbucvaths.supabase.co';
  static const String _supabaseKey = 'sb_publishable_y68QKKHxBTZxBP3Sf1X7tw_zfFnXX8M';

  // Topic Options grouped by Subject
  final Map<String, List<String>> _topicGroups = {
    'Elementary Mathematics': [
      'Arithmetic',
      'Algebra',
      'Geometry',
      'Mensuration',
      'Percentages & Ratio',
    ],
    'General English': [
      'Tenses & Grammar',
      'Vocabulary & Idioms',
      'Reading Comprehension',
      'Sentence Correction',
    ],
    'General Studies': [
      'Indian Polity',
      'Modern History',
      'Geography',
      'Economy',
      'Arunachal Pradesh GK',
      'Current Affairs',
    ],
    'Logical Reasoning': [
      'Analogies & Series',
      'Coding-Decoding',
      'Syllogisms',
      'Direction & Ranking',
    ],
  };

  // State
  final Set<String> _selectedTopics = {'Arithmetic', 'Indian Polity'};
  bool _includePyq = true;
  bool _includeMock = true;
  int _questionCount = 10;
  bool _isStudyMode = true; // true = Study Mode (Instant Solutions), false = Timed Exam
  bool _isGenerating = false;

  final List<int> _countOptions = [10, 20, 50, 100];

  Future<void> _generatePracticeTest() async {
    if (!_includePyq && !_includeMock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one source (PYQ or Mock).'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      // Build dynamic Supabase REST query
      var url = '$_supabaseUrl/rest/v1/questions?select=*,passages(*),question_groups(*),tests!inner(*)';
      // Only include approved questions
      url += '&review_status=neq.flagged';

      // Filter by paper type source
      if (_includePyq && !_includeMock) {
        url += '&tests.paper_type=eq.PYQ';
      } else if (!_includePyq && _includeMock) {
        url += '&tests.paper_type=eq.MOCK';
      }

      final res = await http.get(
        Uri.parse(url),
        headers: {
          'apikey': _supabaseKey,
          'Authorization': 'Bearer $_supabaseKey',
          'Prefer': 'return=representation',
        },
      ).timeout(const Duration(seconds: 8));

      List<Question> pool = [];
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        pool = list.map((m) => Question.fromSupabase(m as Map<String, dynamic>)).toList();
      }

      // If pool is empty, fall back to repository
      if (pool.isEmpty) {
        pool = List.from(QuestionRepository.allQuestions);
      }

      // Filter pool by selected topics/subjects
      List<Question> filtered = pool.where((q) {
        if (_selectedTopics.isEmpty) return true;
        final qSubject = q.subject.toLowerCase();
        final qText = q.questionText.toLowerCase();

        for (final topic in _selectedTopics) {
          final t = topic.toLowerCase();
          if (qSubject.contains(t) || qText.contains(t)) return true;
          // Check broad group mapping
          if (t.contains('arithmetic') && (qSubject.contains('math') || qSubject.contains('arithmetic'))) return true;
          if (t.contains('polity') && (qSubject.contains('gk') || qSubject.contains('polity') || qSubject.contains('studies'))) return true;
          if (t.contains('grammar') && (qSubject.contains('english') || qSubject.contains('grammar'))) return true;
        }
        return false;
      }).toList();

      if (filtered.isEmpty) {
        filtered = pool; // If filter is overly restrictive, use pool
      }

      // Shuffle and pick target count
      final shuffled = List<Question>.from(filtered)..shuffle(math.Random());
      final selectedQs = shuffled.take(_questionCount).toList();

      if (!mounted) return;
      if (!widget.isEmbedded) {
        Navigator.of(context).pop(); // Close bottom sheet if opened as modal
      }

      // Navigate to MockTestScreen with selected questions and mode
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => MockTestScreen(
            examCode: 'CUSTOM-PRACTICE',
            testType: '$_questionCount',
            subject: _selectedTopics.length == 1 ? _selectedTopics.first : 'Custom Practice',
            paperType: _includePyq && !_includeMock ? 'PYQ' : 'MOCK',
            isStudyMode: _isStudyMode,
            durationMinutes: _isStudyMode ? null : (_questionCount <= 10 ? 15 : (_questionCount <= 20 ? 30 : 60)),
            initialQuestions: selectedQs,
          ),
        ),
      );
    } catch (e) {
      debugPrint('[CustomPractice] Error generating test: $e');
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate test: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isEmbedded ? AppColors.background : Colors.white,
        borderRadius: widget.isEmbedded
            ? BorderRadius.zero
            : const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        widget.isEmbedded ? 16 : 20,
        widget.isEmbedded ? 14 : 14,
        widget.isEmbedded ? 16 : 20,
        widget.isEmbedded ? 100 : (MediaQuery.of(context).viewInsets.bottom + 24),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar (modal only)
            if (!widget.isEmbedded) ...[
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Header Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Build Custom Practice',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    Text(
                      'Tailor your target topics, sources, and exam mode',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ─── 1. SELECT SUBJECT & TOPICS ──────────────────────────────────
            const Text(
              '1. Select Topics (Multi-select)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            ..._topicGroups.entries.map((group) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.key,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: group.value.map((topic) {
                        final isSelected = _selectedTopics.contains(topic);
                        return FilterChip(
                          selected: isSelected,
                          label: Text(topic, style: TextStyle(fontSize: 11.5, color: isSelected ? Colors.white : AppColors.textPrimary)),
                          selectedColor: AppColors.primary,
                          backgroundColor: const Color(0xFFF1F5F9),
                          checkmarkColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0)),
                          ),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedTopics.add(topic);
                              } else {
                                if (_selectedTopics.length > 1) {
                                  _selectedTopics.remove(topic);
                                }
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            }),

            const Divider(color: AppColors.divider, height: 24),

            // ─── 2. SOURCE SELECTION ─────────────────────────────────────────
            const Text(
              '2. Question Source',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Previous Year (PYQ)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                    value: _includePyq,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.primary,
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (val) => setState(() => _includePyq = val ?? true),
                  ),
                ),
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Targeted Mocks', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                    value: _includeMock,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.primary,
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (val) => setState(() => _includeMock = val ?? true),
                  ),
                ),
              ],
            ),

            const Divider(color: AppColors.divider, height: 24),

            // ─── 3. QUESTION COUNT SELECTOR ──────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '3. Question Count',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                Text(
                  '$_questionCount Questions',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: _countOptions.map((count) {
                final isSelected = _questionCount == count;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () => setState(() => _questionCount = count),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Text(
                          '$count Qs',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const Divider(color: AppColors.divider, height: 24),

            // ─── 4. MODE SELECTION ───────────────────────────────────────────
            const Text(
              '4. Practice Mode',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isStudyMode = true),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isStudyMode ? const Color(0xFFE8F5E9) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isStudyMode ? const Color(0xFF2E7D32) : const Color(0xFFE2E8F0),
                          width: _isStudyMode ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.auto_stories_rounded,
                                size: 16,
                                color: _isStudyMode ? const Color(0xFF2E7D32) : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Study Mode',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                  color: _isStudyMode ? const Color(0xFF2E7D32) : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Instant solutions, discussions, no time pressure',
                            style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isStudyMode = false),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: !_isStudyMode ? AppColors.primaryLight.withValues(alpha: 0.3) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: !_isStudyMode ? AppColors.primary : const Color(0xFFE2E8F0),
                          width: !_isStudyMode ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.timer_rounded,
                                size: 16,
                                color: !_isStudyMode ? AppColors.primary : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Timed Exam',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                  color: !_isStudyMode ? AppColors.primary : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Real exam timer, strict isolation, no cheats',
                            style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ─── CTA BUTTON ──────────────────────────────────────────────────
            ElevatedButton(
              onPressed: _isGenerating ? null : _generatePracticeTest,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isGenerating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Generate Practice Test',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
