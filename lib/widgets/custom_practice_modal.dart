import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/services/exam_repository.dart';
import '../core/theme/app_colors.dart';

void showCustomPracticeModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).cardTheme.color,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => const Padding(
      padding: EdgeInsets.only(top: 8),
      child: CustomPracticeModal(),
    ),
  );
}

class CustomPracticeModal extends StatefulWidget {
  final bool isEmbedded;
  const CustomPracticeModal({super.key, this.isEmbedded = false});

  @override
  State<CustomPracticeModal> createState() => _CustomPracticeModalState();
}

class _CustomPracticeModalState extends State<CustomPracticeModal> {
  // Available Subjects and their respective Topics
  static const Map<String, List<String>> _subjectTaxonomy = {
    'Elementary Mathematics': [
      'All Topics',
      'Arithmetic',
      'Algebra',
      'Percentages & Ratio',
      'Geometry',
    ],
    'General English': [
      'All Topics',
      'Grammar',
      'Vocabulary',
      'Comprehension',
      'Cloze Test',
    ],
    'General Studies': [
      'All Topics',
      'Indian Polity',
      'History',
      'Arunachal GK',
      'Geography',
      'Current Affairs',
    ],
    'Logical Reasoning': [
      'All Topics',
      'Series & Analogy',
      'Coding-Decoding',
      'Syllogisms',
    ],
    'All Subjects': [
      'All Topics',
    ],
  };

  String _selectedSubject = 'Elementary Mathematics';
  String _selectedTopic = 'All Topics';
  int _selectedCount = 10;
  bool _isTimedMode = true; // true = Timed CBT, false = Learn (instant solutions)
  String _selectedSource = 'BOTH'; // 'BOTH', 'PYQ', 'MOCK'
  bool _showMoreOptions = false;
  bool _isGenerating = false;
  int _availableCount = 50;

  @override
  void initState() {
    super.initState();
    _refreshAvailableCount();
  }

  Future<void> _refreshAvailableCount() async {
    final count = await ExamRepository.instance.countPracticeQuestions(
      subject: _selectedSubject == 'All Subjects' ? '' : _selectedSubject,
      topic: _selectedTopic == 'All Topics' ? null : _selectedTopic,
      paperType: _selectedSource,
    );
    if (mounted) {
      setState(() {
        _availableCount = count > 0 ? count : 30; // fallback count estimate
      });
    }
  }

  Future<void> _startPractice() async {
    setState(() => _isGenerating = true);

    try {
      final questions = await ExamRepository.instance.fetchPracticeQuestions(
        subject: _selectedSubject == 'All Subjects' ? '' : _selectedSubject,
        topic: _selectedTopic == 'All Topics' ? null : _selectedTopic,
        paperType: _selectedSource,
        count: _selectedCount,
      );

      if (!mounted) return;

      // Always reset _isGenerating to prevent stuck spinner (Fix B5)
      setState(() => _isGenerating = false);

      if (questions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No questions found matching your filter. Please choose another subject or source.',
            ),
          ),
        );
        return;
      }

      if (questions.length < _selectedCount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Only ${questions.length} questions available for this topic. Starting practice now.',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Close bottom sheet if not embedded
      if (!widget.isEmbedded && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Consistent GoRouter navigation with pre-fetched questions (Fix B5)
      final modeParam = _isTimedMode ? 'exam' : 'study';
      final dur = math.max(10, _selectedCount * 2);
      final examCode = _selectedSubject.split(' ').last.toUpperCase();

      context.push(
        '/mock-test/$examCode/custom?mode=$modeParam&duration=$dur',
        extra: questions,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load practice questions. Please check connection.'),
          ),
        );
      }
    }
  }

  String get _buttonText {
    final subjWord = _selectedSubject == 'All Subjects'
        ? 'Questions'
        : '${_selectedSubject.split(' ').last} Questions';
    return 'Start $_selectedCount $subjWord';
  }

  @override
  Widget build(BuildContext context) {
    final topics = _subjectTaxonomy[_selectedSubject] ?? ['All Topics'];

    final content = SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (only if not embedded)
          if (!widget.isEmbedded) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Custom Practice Test',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // ─── 1. What to Practise (Subject & Topic) ──────────────────────────
          const Text(
            'What to Practise',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),

          // Subject Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _subjectTaxonomy.keys.map((subj) {
              final isSel = _selectedSubject == subj;
              return ChoiceChip(
                label: Text(subj),
                selected: isSel,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedSubject = subj;
                      _selectedTopic = 'All Topics';
                    });
                    _refreshAvailableCount();
                  }
                },
              );
            }).toList(),
          ),

          // Sub-topic Chips (if more than All Topics exists)
          if (topics.length > 1) ...[
            const SizedBox(height: 12),
            const Text(
              'Select Topic (Optional)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: topics.map((top) {
                final isSel = _selectedTopic == top;
                return ChoiceChip(
                  label: Text(top),
                  selected: isSel,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedTopic = top);
                      _refreshAvailableCount();
                    }
                  },
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 18),

          // ─── 2. How Many Questions ─────────────────────────────────────────
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              const Text(
                'Number of Questions',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
              ),
              if (_availableCount < 50)
                Text(
                  'Only $_availableCount available',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [10, 20, 50].map((count) {
              final isSel = _selectedCount == count;
              final isEnabled = _availableCount >= count || count == 10;
              return ChoiceChip(
                label: Text('$count Qs'),
                selected: isSel,
                onSelected: isEnabled
                    ? (_) {
                        setState(() => _selectedCount = count);
                      }
                    : null,
              );
            }).toList(),
          ),

          const SizedBox(height: 18),

          // ─── 3. Mode (Timed vs Learn) ──────────────────────────────────────
          const Text(
            'Practice Mode',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildModeCard(
                  icon: Icons.timer_outlined,
                  title: 'Timed Exam',
                  subtitle: '${_selectedCount * 2} mins · CBT Mode',
                  isSelected: _isTimedMode,
                  onTap: () => setState(() => _isTimedMode = true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildModeCard(
                  icon: Icons.lightbulb_outline_rounded,
                  title: 'Learn Mode',
                  subtitle: 'Untimed · Instant Solutions',
                  isSelected: !_isTimedMode,
                  onTap: () => setState(() => _isTimedMode = false),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ─── 4. Optional Source Toggle ("More Options") ────────────────────
          GestureDetector(
            onTap: () => setState(() => _showMoreOptions = !_showMoreOptions),
            child: Text(
              _showMoreOptions ? 'Fewer options ▴' : 'More options (Source filter) ▾',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
            ),
          ),
          if (_showMoreOptions) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSourceChip('Both PYQ & Mocks', 'BOTH'),
                _buildSourceChip('PYQs Only', 'PYQ'),
                _buildSourceChip('Mocks Only', 'MOCK'),
              ],
            ),
          ],

          const SizedBox(height: 24),

          // ─── Start Button (Specific text, near-black on orange) ─────────────
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isGenerating ? null : _startPractice,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnOrange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textOnOrange,
                      ),
                    )
                  : Text(
                      _buttonText,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
            ),
          ),
        ],
      ),
    );

    if (widget.isEmbedded) {
      return content;
    }

    return SafeArea(child: content);
  }

  Widget _buildModeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final borderColor = isSelected ? AppColors.primary : Theme.of(context).colorScheme.outline;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: isSelected ? AppColors.primary : AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppColors.primary : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceChip(String label, String value) {
    final isSel = _selectedSource == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSel,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedSource = value);
          _refreshAvailableCount();
        }
      },
    );
  }
}
