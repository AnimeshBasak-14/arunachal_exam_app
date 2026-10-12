import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/exam_repository.dart';

/// Typed model for Mock Tests.
/// Nullable/safe fields prevent fake data and phantom tests (Fix A1/A2/B4).
class MockTestItem {
  final String id;
  final String title;
  final String subject;
  final String examCode;
  final int questionCount;
  final int? officialQuestionCount;
  final int durationMinutes;
  final String difficulty; // 'Easy', 'Medium', 'Hard'
  final String description;
  final double? marksPerCorrect;
  final double? negativeMarks;

  const MockTestItem({
    required this.id,
    required this.title,
    required this.subject,
    required this.examCode,
    required this.questionCount,
    this.officialQuestionCount,
    required this.durationMinutes,
    required this.difficulty,
    required this.description,
    this.marksPerCorrect,
    this.negativeMarks,
  });

  bool get isIncomplete =>
      officialQuestionCount != null &&
      officialQuestionCount! > 0 &&
      questionCount < officialQuestionCount!;

  factory MockTestItem.fromSupabase(Map<String, dynamic> data) {
    final title = (data['title'] ?? 'Mock Test').toString();
    final rawCode = (data['exam_code'] ?? '').toString().trim();
    final examCode = rawCode.isNotEmpty ? rawCode.toUpperCase() : 'APSSB-MOCK';

    int qCount = 0;
    if (data['questions'] is List && (data['questions'] as List).isNotEmpty) {
      final f = (data['questions'] as List).first;
      if (f is Map && f['count'] != null) {
        qCount = int.tryParse(f['count'].toString()) ?? 0;
      }
    } else if (data['total_questions'] != null) {
      qCount = int.tryParse(data['total_questions'].toString()) ?? 0;
    }

    final int? officialCount = data['total_questions'] != null
        ? int.tryParse(data['total_questions'].toString())
        : null;

    final dur = int.tryParse(data['duration_minutes']?.toString() ?? '') ?? 30;

    String diff = (data['difficulty'] ?? '').toString().trim();
    if (diff.isEmpty) {
      final lowerTitle = title.toLowerCase();
      if (lowerTitle.contains('hard') || lowerTitle.contains('advanced')) {
        diff = 'Hard';
      } else if (lowerTitle.contains('easy') || lowerTitle.contains('basic')) {
        diff = 'Easy';
      } else {
        diff = 'Medium';
      }
    } else {
      diff = diff[0].toUpperCase() + diff.substring(1).toLowerCase();
    }

    String subj = (data['subject'] ?? '').toString().trim();
    if (subj.isEmpty) {
      final lowerTitle = title.toLowerCase();
      if (lowerTitle.contains('math')) {
        subj = 'Mathematics';
      } else if (lowerTitle.contains('english') || lowerTitle.contains('grammar')) {
        subj = 'English';
      } else if (lowerTitle.contains('gk') || lowerTitle.contains('knowledge') || lowerTitle.contains('studies')) {
        subj = 'General Knowledge';
      } else if (lowerTitle.contains('civil') || lowerTitle.contains('technical')) {
        subj = 'Technical';
      } else {
        subj = 'Full Mock';
      }
    }

    return MockTestItem(
      id: data['id']?.toString() ?? '',
      title: title,
      subject: subj,
      examCode: examCode,
      questionCount: qCount,
      officialQuestionCount: officialCount,
      durationMinutes: dur,
      difficulty: diff,
      description: data['description']?.toString() ?? 'High-yield practice test.',
      marksPerCorrect: (data['marks_per_correct'] as num?)?.toDouble(),
      negativeMarks: (data['negative_marks'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subject': subject,
        'exam_code': examCode,
        'question_count': questionCount,
        'total_questions': officialQuestionCount,
        'duration_minutes': durationMinutes,
        'difficulty': difficulty,
        'description': description,
        'marks_per_correct': marksPerCorrect,
        'negative_marks': negativeMarks,
      };

  factory MockTestItem.fromJson(Map<String, dynamic> json) => MockTestItem(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        subject: json['subject']?.toString() ?? 'General',
        examCode: json['exam_code']?.toString() ?? '',
        questionCount: json['question_count'] as int? ?? 0,
        officialQuestionCount: json['total_questions'] as int?,
        durationMinutes: json['duration_minutes'] as int? ?? 30,
        difficulty: json['difficulty']?.toString() ?? 'Medium',
        description: json['description']?.toString() ?? '',
        marksPerCorrect: (json['marks_per_correct'] as num?)?.toDouble(),
        negativeMarks: (json['negative_marks'] as num?)?.toDouble(),
      );
}

class MockHubScreen extends ConsumerStatefulWidget {
  final bool isEmbedded;
  const MockHubScreen({super.key, this.isEmbedded = false});

  @override
  ConsumerState<MockHubScreen> createState() => _MockHubScreenState();
}

class _MockHubScreenState extends ConsumerState<MockHubScreen> {
  static const String _prefExamKey = 'my_selected_exam';
  static const String _cacheKey = 'cached_mock_tests_v2';

  bool _isLoading = true;
  bool _isOffline = false;
  List<MockTestItem> _allMocks = [];

  String _selectedExam = 'ALL';
  String _selectedSubject = 'All';
  String _searchQuery = '';
  bool _isSearchOpen = false;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedExamPreference();
    _loadMockTests();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedExamPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefExamKey);
    if (saved != null && saved.isNotEmpty && mounted) {
      setState(() => _selectedExam = saved);
    }
  }

  Future<void> _saveExamPreference(String exam) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefExamKey, exam);
    if (mounted) {
      setState(() => _selectedExam = exam);
    }
  }

  Future<void> _loadMockTests({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);

    try {
      final rawPapers = await ExamRepository.instance.fetchPapers(
        paperType: 'MOCK',
        forceRefresh: forceRefresh,
      );

      if (rawPapers.isNotEmpty) {
        final mocks = rawPapers
            .map((data) => MockTestItem.fromSupabase(data))
            .where((m) => m.questionCount > 0) // Hide 0 question mock tests
            .toList();

        if (mounted) {
          setState(() {
            _allMocks = mocks;
            _isLoading = false;
            _isOffline = false;
          });
        }

        final prefs = await SharedPreferences.getInstance();
        final encoded = jsonEncode(mocks.map((m) => m.toJson()).toList());
        await prefs.setString(_cacheKey, encoded);
        return;
      }
    } catch (e) {
      debugPrint('[MockHub] Fetch error: $e');
    }

    // Offline cache fallback
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    if (cached != null && cached.isNotEmpty && mounted) {
      try {
        final List list = jsonDecode(cached);
        final cachedMocks = list
            .map((item) => MockTestItem.fromJson(item as Map<String, dynamic>))
            .where((m) => m.questionCount > 0)
            .toList();
        setState(() {
          _allMocks = cachedMocks;
          _isLoading = false;
          _isOffline = true;
        });
        return;
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _allMocks = [];
        _isLoading = false;
        _isOffline = true;
      });
    }
  }

  List<MockTestItem> get _filteredMocks {
    return _allMocks.where((m) {
      // 1. Exam filter
      if (_selectedExam != 'ALL') {
        final examMatch = m.examCode.toUpperCase().contains(_selectedExam.toUpperCase()) ||
            m.title.toUpperCase().contains(_selectedExam.toUpperCase());
        if (!examMatch) return false;
      }

      // 2. Subject filter
      if (_selectedSubject != 'All') {
        final s = m.subject.toLowerCase();
        final target = _selectedSubject.toLowerCase();
        if (!s.contains(target)) return false;
      }

      // 3. Search query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = m.title.toLowerCase().contains(q);
        final matchSubject = m.subject.toLowerCase().contains(q);
        final matchCode = m.examCode.toLowerCase().contains(q);
        if (!matchTitle && !matchSubject && !matchCode) return false;
      }

      return true;
    }).toList();
  }

  Map<String, List<MockTestItem>> get _groupedByLevel {
    final Map<String, List<MockTestItem>> map = {
      'Easy': [],
      'Medium': [],
      'Hard': [],
    };
    for (final m in _filteredMocks) {
      final lvl = (m.difficulty == 'Easy' || m.difficulty == 'Hard') ? m.difficulty : 'Medium';
      map[lvl]?.add(m);
    }
    return map;
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _selectedSubject = 'All';
      _searchQuery = '';
      _isSearchOpen = false;
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);
    if (widget.isEmbedded) {
      return content;
    }
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Targeted Mock Tests'),
      ),
      body: content,
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_allMocks.isEmpty) {
      return _buildEmptyState(
        title: 'No Mock Tests Found',
        message: 'Unable to connect to mock bank. Please check your network and retry.',
        canRetry: true,
      );
    }

    final filtered = _filteredMocks;
    final levels = ['Easy', 'Medium', 'Hard'].where((l) => (_groupedByLevel[l]?.isNotEmpty ?? false)).toList();

    return RefreshIndicator(
      onRefresh: () => _loadMockTests(forceRefresh: true),
      color: AppColors.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          // ─── Controls: My Exam Picker + Search + Quick Chips ────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: "My Exam" Picker Pill + Search Toggle
                  Row(
                    children: [
                      _buildMyExamPill(context),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          _isSearchOpen ? Icons.search_off_rounded : Icons.search_rounded,
                          color: _isSearchOpen ? AppColors.primary : AppColors.textSecondary,
                        ),
                        onPressed: () {
                          setState(() {
                            _isSearchOpen = !_isSearchOpen;
                            if (!_isSearchOpen) {
                              _searchController.clear();
                              _searchQuery = '';
                              FocusScope.of(context).unfocus();
                            }
                          });
                        },
                        tooltip: 'Search mock tests',
                      ),
                    ],
                  ),

                  // Search Field
                  if (_isSearchOpen) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search mock title, topic, subject...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                  FocusScope.of(context).unfocus();
                                },
                              )
                            : null,
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Row 2: Quick Chips Row
                  _buildQuickChipsRow(),

                  // Row 3: Filter & Offline Info
                  if (_isOffline || _hasActiveFilter) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (_isOffline)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.darkWarning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 4,
                              children: [
                                Icon(Icons.wifi_off_rounded, size: 12, color: AppColors.darkWarning),
                                Text(
                                  'Offline · showing saved list',
                                  style: TextStyle(fontSize: 11, color: AppColors.darkWarning, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        if (_hasActiveFilter) ...[
                          Text(
                            '${filtered.length} mock tests',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                          ),
                          GestureDetector(
                            onTap: _clearFilters,
                            child: const Text(
                              '· Clear',
                              style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ─── Mock Test Cards Grouped by Difficulty Level (Part B4) ──────────
          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(
                title: 'No Matching Mock Tests',
                message: 'No mock tests match your current filters.',
                canRetry: false,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final level = levels[index];
                    final levelMocks = _groupedByLevel[level] ?? [];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Difficulty Level Header
                        Padding(
                          padding: const EdgeInsets.only(top: 14, bottom: 8),
                          child: Row(
                            children: [
                              _buildLevelBadge(level),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '$level Level Mocks',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${levelMocks.length}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Mock cards for this level
                        ...levelMocks.map((mock) => _buildMockCard(context, mock)),
                      ],
                    );
                  },
                  childCount: levels.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool get _hasActiveFilter =>
      _selectedExam != 'ALL' || _selectedSubject != 'All' || _searchQuery.isNotEmpty;

  Widget _buildLevelBadge(String level) {
    Color badgeColor = AppColors.darkGreen;
    if (level == 'Hard') badgeColor = AppColors.darkRed;
    if (level == 'Medium') badgeColor = AppColors.primary;

    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: badgeColor,
        shape: BoxShape.circle,
      ),
    );
  }

  // ─── B1: "My Exam" Picker Pill ─────────────────────────────────────────────
  Widget _buildMyExamPill(BuildContext context) {
    final label = _selectedExam == 'ALL' ? 'All Exams' : _selectedExam;
    return GestureDetector(
      onTap: () => _showExamPickerSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _selectedExam != 'ALL' ? AppColors.primary : Theme.of(context).colorScheme.outline,
            width: _selectedExam != 'ALL' ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎯 ', style: TextStyle(fontSize: 13)),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _selectedExam != 'ALL' ? AppColors.primary : null,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down_rounded, size: 18),
          ],
        ),
      ),
    );
  }

  void _showExamPickerSheet(BuildContext context) {
    final Map<String, int> examCounts = {};
    for (final m in _allMocks) {
      final code = m.examCode
          .replaceAll('APSSB-', '')
          .replaceAll('APPSC-', '')
          .replaceAll('MOCK-', '')
          .replaceAll('MOCK', 'General');
      examCounts[code] = (examCounts[code] ?? 0) + 1;
    }

    final exams = examCounts.keys.toList()..sort();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Exam Target',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: exams.map((exam) {
                  final isSel = _selectedExam == exam;
                  final count = examCounts[exam] ?? 0;
                  return ChoiceChip(
                    label: Text('$exam ($count)'),
                    selected: isSel,
                    onSelected: (_) {
                      _saveExamPreference(exam);
                      Navigator.pop(ctx);
                    },
                  );
                }).toList(),
              ),
              const Divider(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.apps_rounded, color: AppColors.primary),
                title: const Text('All Exams', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${_allMocks.length} total mock tests available'),
                trailing: _selectedExam == 'ALL'
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () {
                  _saveExamPreference('ALL');
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Quick Chips Row ───────────────────────────────────────────────────────
  Widget _buildQuickChipsRow() {
    final Map<String, int> subjCounts = {'All': _allMocks.length};
    for (final m in _allMocks) {
      final s = m.subject.trim();
      if (s.isNotEmpty) {
        subjCounts[s] = (subjCounts[s] ?? 0) + 1;
      }
    }

    final chips = ['All', ...subjCounts.keys.where((k) => k != 'All')];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: chips.map((chip) {
          final isSelected = _selectedSubject == chip;
          final count = subjCounts[chip] ?? 0;
          if (count == 0 && chip != 'All') return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text('$chip ($count)'),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _selectedSubject = chip);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Compact Mock Test Card (Part B3/B4) ──────────────────────────────────
  Widget _buildMockCard(BuildContext context, MockTestItem mock) {
    final markingText = mock.marksPerCorrect != null
        ? '+${mock.marksPerCorrect!.toStringAsFixed(0)} / -${(mock.negativeMarks ?? 0.5).toStringAsFixed(1)}'
        : 'Standard Marking';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + Incomplete Pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${mock.title} · ${mock.subject}',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ),
              if (mock.isIncomplete) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.darkWarning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.darkWarning.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'Incomplete · ${mock.questionCount}/${mock.officialQuestionCount}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkWarning,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 6),

          // Meta Line (Single wrapping row, no duplication)
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${mock.questionCount} Qs',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const Text('·', style: TextStyle(color: AppColors.textSecondary)),
              Text(
                '${mock.durationMinutes} min',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const Text('·', style: TextStyle(color: AppColors.textSecondary)),
              Text(
                markingText,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => _confirmAndStartTest(context, mock),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnOrange,
                    minimumSize: const Size(100, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    'Start test',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                TextButton(
                  onPressed: () => _launchStudyMode(context, mock),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(60, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Study', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right_rounded, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmAndStartTest(BuildContext context, MockTestItem mock) {
    final marks = mock.marksPerCorrect ?? 2.0;
    final neg = mock.negativeMarks ?? 0.5;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Start ${mock.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• ${mock.durationMinutes} mins CBT simulation with live timer.'),
            const SizedBox(height: 6),
            Text('• Marking scheme: +${marks.toStringAsFixed(0)} correct, -${neg.toStringAsFixed(1)} negative marks.'),
            const SizedBox(height: 6),
            const Text('• Instant rank scorecard and performance analysis on submit.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Wire testId through route (Fix A3)
              context.push(
                '/mock-test/${mock.examCode}/full?paperType=MOCK&testId=${mock.id}&duration=${mock.durationMinutes}',
              );
            },
            child: const Text('Start Now'),
          ),
        ],
      ),
    );
  }

  void _launchStudyMode(BuildContext context, MockTestItem mock) {
    // Wire testId through route in study mode (Fix A3)
    context.push(
      '/mock-test/${mock.examCode}/full?paperType=MOCK&testId=${mock.id}&study=true',
    );
  }

  Widget _buildEmptyState({
    required String title,
    required String message,
    required bool canRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment_outlined, size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (canRetry) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _loadMockTests(forceRefresh: true),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
