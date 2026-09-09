import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../core/services/question_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/math_utils.dart';

class QuestionFlaggerScreen extends StatefulWidget {
  const QuestionFlaggerScreen({super.key});

  @override
  State<QuestionFlaggerScreen> createState() => _QuestionFlaggerScreenState();
}

class _QuestionFlaggerScreenState extends State<QuestionFlaggerScreen> {
  static const String _supabaseUrl = 'https://fllopztywwblbucvaths.supabase.co';
  static const String _supabaseKey = 'sb_publishable_y68QKKHxBTZxBP3Sf1X7tw_zfFnXX8M';

  // Filter state
  String _selectedType = 'All'; // 'All', 'PYQ', 'MOCK'
  String _selectedYear = 'All'; // 'All', '2024', '2023', '2022', '2021'
  String _selectedSubject = 'All';
  String _selectedStatus = 'all'; // 'all', 'flagged', 'needs_ocr_rerun', 'approved'
  String _searchQuery = '';

  final List<String> _types = ['All', 'PYQ', 'MOCK'];
  final List<String> _years = ['All', '2024', '2023', '2022', '2021'];
  final List<String> _subjects = [
    'All',
    'General Studies',
    'Elementary Mathematics',
    'General English',
    'Reasoning',
  ];
  final List<String> _statuses = ['all', 'flagged', 'needs_ocr_rerun', 'approved'];

  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  List<Question> _allQuestions = [];
  List<Question> _filteredQuestions = [];

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchQuestions() async {
    setState(() => _isLoading = true);
    try {
      var url =
          '$_supabaseUrl/rest/v1/questions?select=*,passages(*),question_groups(*),tests!inner(*)&order=question_number';

      if (_selectedStatus != 'all') {
        url += '&review_status=eq.$_selectedStatus';
      }
      if (_selectedType != 'All') {
        url += '&tests.paper_type=eq.${Uri.encodeComponent(_selectedType.toUpperCase())}';
      }
      if (_selectedYear != 'All') {
        url += '&tests.year=eq.$_selectedYear';
      }
      if (_selectedSubject != 'All') {
        url += '&subject=ilike.*${Uri.encodeComponent(_selectedSubject)}*';
      }

      final res = await http.get(
        Uri.parse(url),
        headers: {
          'apikey': _supabaseKey,
          'Authorization': 'Bearer $_supabaseKey',
          'Prefer': 'return=representation',
        },
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final List raw = jsonDecode(res.body);
        final parsed = raw.map((m) => Question.fromSupabase(m as Map<String, dynamic>)).toList();
        setState(() {
          _allQuestions = parsed;
          _isLoading = false;
        });
        _applyClientFilters();
      } else {
        _fallbackLocalQuestions();
      }
    } catch (e) {
      debugPrint('[QuestionFlagger] Error fetching questions: $e');
      _fallbackLocalQuestions();
    }
  }

  void _fallbackLocalQuestions() {
    final local = QuestionRepository.allQuestions;
    setState(() {
      _allQuestions = List.from(local);
      _isLoading = false;
    });
    _applyClientFilters();
  }

  void _applyClientFilters() {
    setState(() {
      _filteredQuestions = _allQuestions.where((q) {
        // Query search
        if (_searchQuery.trim().isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          final inText = q.questionText.toLowerCase().contains(query);
          final inSubject = q.subject.toLowerCase().contains(query);
          final inOptions = q.options.any((o) => o.toLowerCase().contains(query));
          final inId = q.id.toLowerCase().contains(query);
          if (!inText && !inSubject && !inOptions && !inId) return false;
        }

        // Status filter
        if (_selectedStatus != 'all' && q.reviewStatus.toLowerCase() != _selectedStatus.toLowerCase()) {
          return false;
        }

        // Type filter
        if (_selectedType != 'All' && q.paperType.toUpperCase() != _selectedType.toUpperCase()) {
          return false;
        }

        // Year filter
        if (_selectedYear != 'All' && q.year.toString() != _selectedYear) {
          return false;
        }

        // Subject filter
        if (_selectedSubject != 'All' && !q.subject.toLowerCase().contains(_selectedSubject.toLowerCase())) {
          return false;
        }

        return true;
      }).toList();
    });
  }

  Future<void> _approveQuestion(Question q) async {
    try {
      final url = '$_supabaseUrl/rest/v1/questions?id=eq.${q.id}';
      final res = await http.patch(
        Uri.parse(url),
        headers: {
          'apikey': _supabaseKey,
          'Authorization': 'Bearer $_supabaseKey',
          'Content-Type': 'application/json',
          'Prefer': 'return=representation',
        },
        body: jsonEncode({
          'review_status': 'approved',
          'flag_reasons': [],
        }),
      ).timeout(const Duration(seconds: 6));

      if (mounted) {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Question marked as Approved!'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ),
          );
        }

        // Update local model
        setState(() {
          final idx = _allQuestions.indexWhere((item) => item.id == q.id);
          if (idx != -1) {
            _allQuestions[idx] = Question(
              id: q.id,
              examCode: q.examCode,
              year: q.year,
              paperType: q.paperType,
              testId: q.testId,
              testTitle: q.testTitle,
              subject: q.subject,
              difficulty: q.difficulty,
              groupId: q.groupId,
              passageId: q.passageId,
              passageOrDirection: q.passageOrDirection,
              passageImage: q.passageImage,
              questionText: q.questionText,
              questionImage: q.questionImage,
              imageUrl: q.imageUrl,
              hasImage: q.hasImage,
              reviewStatus: 'approved',
              flagReasons: const [],
              modeAvailability: q.modeAvailability,
              options: q.options,
              optionImages: q.optionImages,
              correctAnswer: q.correctAnswer,
              officialAnswer: q.officialAnswer,
              solution: q.solution,
            );
          }
        });
        _applyClientFilters();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error approving question: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showFlagIssueBottomSheet(BuildContext context, Question q) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FlagIssueBottomSheet(
        question: q,
        onFlagged: (updatedQuestion) {
          setState(() {
            final idx = _allQuestions.indexWhere((item) => item.id == q.id);
            if (idx != -1) {
              _allQuestions[idx] = updatedQuestion;
            }
          });
          _applyClientFilters();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag_circle_rounded, color: AppColors.error, size: 20),
                SizedBox(width: 8),
                Text(
                  'Question Quality Flagger',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            Text(
              'Audit OCR questions, mark defects & report flags',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppColors.primary),
            tooltip: 'Detailed Review Tool',
            onPressed: () => context.push('/admin/question-review'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            tooltip: 'Refresh',
            onPressed: _fetchQuestions,
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Search & Dropdown Filters Bar ──────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    _searchQuery = val;
                    _applyClientFilters();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by question, option, or ID...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textHint),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _searchQuery = '';
                              _applyClientFilters();
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Horizontal Dropdown Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildDropdownFilter(
                        label: 'Status',
                        value: _selectedStatus,
                        items: _statuses,
                        onChanged: (v) {
                          setState(() => _selectedStatus = v!);
                          _fetchQuestions();
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildDropdownFilter(
                        label: 'Type',
                        value: _selectedType,
                        items: _types,
                        onChanged: (v) {
                          setState(() => _selectedType = v!);
                          _fetchQuestions();
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildDropdownFilter(
                        label: 'Year',
                        value: _selectedYear,
                        items: _years,
                        onChanged: (v) {
                          setState(() => _selectedYear = v!);
                          _fetchQuestions();
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildDropdownFilter(
                        label: 'Subject',
                        value: _selectedSubject,
                        items: _subjects,
                        onChanged: (v) {
                          setState(() => _selectedSubject = v!);
                          _fetchQuestions();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // ─── Results Summary Bar ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFF8FAFC),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredQuestions.length} Questions Found',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Text(
                    'Status: ${_selectedStatus.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _selectedStatus == 'flagged' ? AppColors.error : AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),

          // ─── Question List ───────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredQuestions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.rule_rounded, size: 52, color: AppColors.textHint),
                            const SizedBox(height: 12),
                            const Text(
                              'No questions matching your filters',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Try changing your status, subject, or search term.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _selectedType = 'All';
                                  _selectedYear = 'All';
                                  _selectedSubject = 'All';
                                  _selectedStatus = 'all';
                                  _searchQuery = '';
                                  _searchController.clear();
                                });
                                _fetchQuestions();
                              },
                              icon: const Icon(Icons.restore_rounded, size: 16),
                              label: const Text('Reset All Filters'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                        itemCount: _filteredQuestions.length,
                        itemBuilder: (context, index) {
                          final q = _filteredQuestions[index];
                          return _buildQuestionCard(q, index);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: value != 'all' && value != 'All' ? AppColors.primary : AppColors.divider,
          width: value != 'all' && value != 'All' ? 1.5 : 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: value != 'all' && value != 'All' ? AppColors.primary : AppColors.textPrimary,
          ),
          icon: const Icon(Icons.arrow_drop_down_rounded, size: 18, color: AppColors.textHint),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item == 'all' || item == 'All' ? '$label: All' : item,
                style: const TextStyle(fontSize: 12),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildQuestionCard(Question q, int index) {
    final isFlagged = q.reviewStatus.toLowerCase() == 'flagged';
    final isNeedsRerun = q.reviewStatus.toLowerCase() == 'needs_ocr_rerun';

    return Card(
      key: ValueKey(q.id),
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isFlagged
              ? AppColors.error.withValues(alpha: 0.5)
              : isNeedsRerun
                  ? AppColors.warning.withValues(alpha: 0.5)
                  : AppColors.divider,
          width: isFlagged || isNeedsRerun ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Meta Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Q${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          q.subject,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Text(
                        '${q.examCode} • ${q.year}',
                        style: const TextStyle(fontSize: 10, color: AppColors.textHint),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(q.reviewStatus),
              ],
            ),
            const SizedBox(height: 10),

            // Flag reasons chips if flagged
            if (q.flagReasons.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: q.flagReasons.map((r) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.report_problem_rounded, size: 11, color: AppColors.error),
                        const SizedBox(width: 4),
                        Text(
                          r.replaceAll('_', ' '),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
            ],

            // Associated Passage / Direction Card (if any)
            if (q.passageOrDirection != null && q.passageOrDirection!.trim().isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.menu_book_rounded, size: 12, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text(
                          'Direction / Comprehension Passage',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      q.passageOrDirection!,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textPrimary, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Question Image preview (Interactive zoom)
            if (q.questionImage != null && q.questionImage!.trim().isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.divider),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 3.0,
                    child: Center(
                      child: Image.network(
                        q.questionImage!,
                        height: 140,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Image failed to load', style: TextStyle(color: AppColors.error, fontSize: 11)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],

            // Question Text
            Text(
              MathUtils.cleanQuestionText(q.questionText, index + 1),
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),

            // Options List
            Column(
              children: List.generate(q.options.length, (optIdx) {
                final opt = q.options[optIdx];
                final optChar = _extractOptionChar(opt, optIdx);
                final isCorrect = optChar.toLowerCase() == q.correctAnswer.toLowerCase();

                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCorrect ? AppColors.success.withValues(alpha: 0.08) : const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCorrect ? AppColors.success : const Color(0xFFE5E7EB),
                      width: isCorrect ? 1.2 : 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCorrect ? AppColors.success : const Color(0xFFE2E8F0),
                        ),
                        child: Text(
                          optChar.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isCorrect ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          opt,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isCorrect ? FontWeight.w600 : FontWeight.normal,
                            color: isCorrect ? AppColors.success : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (isCorrect)
                        const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
                    ],
                  ),
                );
              }),
            ),

            // Solution (if present)
            if (q.solution.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded, size: 14, color: Color(0xFF1D4ED8)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Explanation: ${q.solution}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF1E3A8A)),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 8),

            // Bottom Actions: Flag Issue, Quick Edit, Approve
            Row(
              children: [
                // Flag Issue Button
                ElevatedButton.icon(
                  onPressed: () => _showFlagIssueBottomSheet(context, q),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFlagged ? const Color(0xFFFEE2E2) : Colors.white,
                    foregroundColor: AppColors.error,
                    elevation: 0,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.flag_rounded, size: 14),
                  label: Text(
                    isFlagged ? 'Edit Flag' : 'Flag Issue',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),

                // Quick Edit Button
                OutlinedButton.icon(
                  onPressed: () => context.push('/admin/question-review'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.edit_rounded, size: 14),
                  label: const Text(
                    'Full Review',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),

                // Approve Button
                if (!isFlagged && q.reviewStatus == 'approved')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, size: 12, color: AppColors.success),
                        SizedBox(width: 4),
                        Text(
                          'Approved',
                          style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () => _approveQuestion(q),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 14),
                    label: const Text(
                      'Approve',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    IconData icon;
    String label = status.toUpperCase();

    switch (status.toLowerCase()) {
      case 'flagged':
        bg = const Color(0xFFFEE2E2);
        fg = AppColors.error;
        icon = Icons.flag_rounded;
        break;
      case 'needs_ocr_rerun':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        icon = Icons.warning_amber_rounded;
        label = 'NEEDS RERUN';
        break;
      case 'approved':
        bg = const Color(0xFFDCFCE7);
        fg = AppColors.success;
        icon = Icons.check_circle_rounded;
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        fg = AppColors.textSecondary;
        icon = Icons.help_outline_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: fg),
          ),
        ],
      ),
    );
  }

  String _extractOptionChar(String option, int fallbackIndex) {
    final trimmed = option.trim();
    final match = RegExp(r'^[\\(\\[]?([a-dA-D])[\\)\\]\\.\\s]').firstMatch(trimmed);
    if (match != null) return match.group(1)!.toLowerCase();
    return String.fromCharCode(97 + fallbackIndex);
  }
}

// ─── Inline Flag Issue Bottom Sheet Modal ───────────────────────────────────────
class _FlagIssueBottomSheet extends StatefulWidget {
  final Question question;
  final ValueChanged<Question> onFlagged;

  const _FlagIssueBottomSheet({
    required this.question,
    required this.onFlagged,
  });

  @override
  State<_FlagIssueBottomSheet> createState() => _FlagIssueBottomSheetState();
}

class _FlagIssueBottomSheetState extends State<_FlagIssueBottomSheet> {
  static const String _supabaseUrl = 'https://fllopztywwblbucvaths.supabase.co';
  static const String _supabaseKey = 'sb_publishable_y68QKKHxBTZxBP3Sf1X7tw_zfFnXX8M';

  final Map<String, String> _issueDescriptions = {
    'merged_options': 'Merged Options (Options compressed together into one)',
    'dummy_placeholders': 'Dummy Placeholders (Generic Option A/B text)',
    'bleed_through': 'Next Question Bleed (Contains subsequent question prompt)',
    'wrong_passage': 'Wrong Direction / Passage (Unrelated comprehension text)',
    'missing_image': 'Missing Image / Figure (Referenced diagram absent)',
    'formatting_noise': 'Scanning / OCR Noise (Stray tokens, bars, corrupted LaTeX)',
  };

  late Set<String> _selectedIssues;
  late TextEditingController _notesController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedIssues = Set.from(widget.question.flagReasons);
    if (_selectedIssues.isEmpty) {
      _selectedIssues.add('merged_options');
    }
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitFlag() async {
    if (_selectedIssues.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one issue type.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final reasonsList = _selectedIssues.toList();

    try {
      // 1. Update questions table review_status & flag_reasons
      final url = '$_supabaseUrl/rest/v1/questions?id=eq.${widget.question.id}';
      final res1 = await http.patch(
        Uri.parse(url),
        headers: {
          'apikey': _supabaseKey,
          'Authorization': 'Bearer $_supabaseKey',
          'Content-Type': 'application/json',
          'Prefer': 'return=representation',
        },
        body: jsonEncode({
          'review_status': 'flagged',
          'flag_reasons': reasonsList,
        }),
      ).timeout(const Duration(seconds: 6));

      // 2. Insert into question_flags audit table
      final flagUrl = '$_supabaseUrl/rest/v1/question_flags';
      await http.post(
        Uri.parse(flagUrl),
        headers: {
          'apikey': _supabaseKey,
          'Authorization': 'Bearer $_supabaseKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'question_id': widget.question.id,
          'issue_type': reasonsList.first,
          'notes': _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : 'Flagged via Admin Question Flagger',
        }),
      ).timeout(const Duration(seconds: 6));

      if (mounted) {
        final updatedQ = Question(
          id: widget.question.id,
          examCode: widget.question.examCode,
          year: widget.question.year,
          paperType: widget.question.paperType,
          testId: widget.question.testId,
          testTitle: widget.question.testTitle,
          subject: widget.question.subject,
          difficulty: widget.question.difficulty,
          groupId: widget.question.groupId,
          passageId: widget.question.passageId,
          passageOrDirection: widget.question.passageOrDirection,
          passageImage: widget.question.passageImage,
          questionText: widget.question.questionText,
          questionImage: widget.question.questionImage,
          imageUrl: widget.question.imageUrl,
          hasImage: widget.question.hasImage,
          reviewStatus: 'flagged',
          flagReasons: reasonsList,
          modeAvailability: widget.question.modeAvailability,
          options: widget.question.options,
          optionImages: widget.question.optionImages,
          correctAnswer: widget.question.correctAnswer,
          officialAnswer: widget.question.officialAnswer,
          solution: widget.question.solution,
        );

        widget.onFlagged(updatedQ);
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res1.statusCode < 300
                  ? 'Question flagged and saved to Supabase audit!'
                  : 'Question flagged locally (Supabase HTTP ${res1.statusCode})',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving flag: $e'), backgroundColor: AppColors.error),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                const Icon(Icons.flag_rounded, color: AppColors.error, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Flag Question Issue',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Select all data defects present in this question. This will tag the item for OCR repair.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),

            // Issue checkboxes
            ..._issueDescriptions.entries.map((entry) {
              final isChecked = _selectedIssues.contains(entry.key);
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: isChecked ? const Color(0xFFFEF2F2) : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isChecked ? AppColors.error.withValues(alpha: 0.4) : const Color(0xFFE5E7EB),
                  ),
                ),
                child: CheckboxListTile(
                  value: isChecked,
                  dense: true,
                  activeColor: AppColors.error,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    entry.value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
                      color: isChecked ? AppColors.error : AppColors.textPrimary,
                    ),
                  ),
                  onChanged: (bool? checked) {
                    setState(() {
                      if (checked == true) {
                        _selectedIssues.add(entry.key);
                      } else {
                        _selectedIssues.remove(entry.key);
                      }
                    });
                  },
                ),
              );
            }),

            const SizedBox(height: 12),
            const Text(
              'Admin Notes & Context (Optional):',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              maxLines: 2,
              style: const TextStyle(fontSize: 12.5),
              decoration: InputDecoration(
                hintText: 'e.g. Option B has (c) merged; original was 1947...',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitFlag,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded, size: 16),
                    label: const Text(
                      'Save & Submit Flag',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
