import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/exam_repository.dart';

/// Typed model for Previous Year Question Papers.
/// Nullable fields prevent fake defaulted values (Fix A2).
class PyqPaperItem {
  final String id;
  final String title;
  final String? board; // 'APPSC' or 'APSSB'
  final String examCode;
  final int? year;
  final String? subject;
  final int questionCount;
  final int? officialQuestionCount;
  final int? durationMinutes;
  final double? marksPerCorrect;
  final double? negativeMarks;

  const PyqPaperItem({
    required this.id,
    required this.title,
    this.board,
    required this.examCode,
    this.year,
    this.subject,
    required this.questionCount,
    this.officialQuestionCount,
    this.durationMinutes,
    this.marksPerCorrect,
    this.negativeMarks,
  });

  bool get isIncomplete =>
      officialQuestionCount != null &&
      officialQuestionCount! > 0 &&
      questionCount < officialQuestionCount!;

  String get displayTitle {
    final cleanCode = examCode
        .replaceAll('APSSB-', '')
        .replaceAll('APPSC-', '')
        .replaceAll('-2024', '')
        .replaceAll('-2023', '')
        .replaceAll('-2022', '')
        .replaceAll('-2021', '')
        .replaceAll('-2020', '');
    final yearStr = year != null ? ' $year' : '';
    final subjStr = subject != null && subject!.isNotEmpty ? ' · $subject' : '';
    return '$cleanCode$yearStr$subjStr';
  }

  factory PyqPaperItem.fromSupabase(Map<String, dynamic> data) {
    final rawCode = (data['exam_code'] ?? '').toString().trim();
    final examCode = rawCode.isNotEmpty ? rawCode.toUpperCase() : 'EXAM';
    final board = data['board']?.toString() ??
        (examCode.startsWith('APPSC')
            ? 'APPSC'
            : (examCode.startsWith('APSSB') ? 'APSSB' : null));

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

    final int? dur = data['duration_minutes'] != null
        ? int.tryParse(data['duration_minutes'].toString())
        : null;

    final int? yr = data['year'] != null
        ? int.tryParse(data['year'].toString())
        : null;

    final String? subj = data['subject']?.toString();

    final double? marks = data['marks_per_correct'] != null
        ? (data['marks_per_correct'] as num).toDouble()
        : null;

    final double? neg = data['negative_marks'] != null
        ? (data['negative_marks'] as num).toDouble()
        : null;

    return PyqPaperItem(
      id: data['id']?.toString() ?? '',
      title: data['title']?.toString() ?? '$examCode Paper',
      board: board,
      examCode: examCode,
      year: yr,
      subject: subj,
      questionCount: qCount,
      officialQuestionCount: officialCount,
      durationMinutes: dur,
      marksPerCorrect: marks,
      negativeMarks: neg,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'board': board,
        'exam_code': examCode,
        'year': year,
        'subject': subject,
        'question_count': questionCount,
        'total_questions': officialQuestionCount,
        'duration_minutes': durationMinutes,
        'marks_per_correct': marksPerCorrect,
        'negative_marks': negativeMarks,
      };

  factory PyqPaperItem.fromJson(Map<String, dynamic> json) => PyqPaperItem(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        board: json['board']?.toString(),
        examCode: json['exam_code']?.toString() ?? '',
        year: json['year'] as int?,
        subject: json['subject']?.toString(),
        questionCount: json['question_count'] as int? ?? 0,
        officialQuestionCount: json['total_questions'] as int?,
        durationMinutes: json['duration_minutes'] as int?,
        marksPerCorrect: (json['marks_per_correct'] as num?)?.toDouble(),
        negativeMarks: (json['negative_marks'] as num?)?.toDouble(),
      );
}

class PyqHubScreen extends ConsumerStatefulWidget {
  final bool isEmbedded;
  const PyqHubScreen({super.key, this.isEmbedded = false});

  @override
  ConsumerState<PyqHubScreen> createState() => _PyqHubScreenState();
}

class _PyqHubScreenState extends ConsumerState<PyqHubScreen> {
  static const String _prefExamKey = 'my_selected_exam';
  static const String _cacheKey = 'cached_pyq_papers_v2';

  bool _isLoading = true;
  bool _isOffline = false;
  List<PyqPaperItem> _allPapers = [];

  String _selectedExam = 'ALL'; // 'ALL', 'CGL', 'CHSL', etc.
  String _selectedSubject = 'All';
  String _searchQuery = '';
  bool _isSearchOpen = false;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedExamPreference();
    _loadPapers();
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

  Future<void> _loadPapers({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);

    try {
      final rawPapers = await ExamRepository.instance.fetchPapers(
        paperType: 'PYQ',
        forceRefresh: forceRefresh,
      );

      if (rawPapers.isNotEmpty) {
        final papers = rawPapers
            .map((data) => PyqPaperItem.fromSupabase(data))
            .where((p) => p.questionCount > 0) // Fix A1: Hide 0 question papers
            .toList();

        if (mounted) {
          setState(() {
            _allPapers = papers;
            _isLoading = false;
            _isOffline = false;
          });
        }

        // Cache locally for offline resilience
        final prefs = await SharedPreferences.getInstance();
        final encoded = jsonEncode(papers.map((p) => p.toJson()).toList());
        await prefs.setString(_cacheKey, encoded);
        return;
      }
    } catch (e) {
      debugPrint('[PyqHub] Fetch error: $e');
    }

    // Offline cache fallback
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    if (cached != null && cached.isNotEmpty && mounted) {
      try {
        final List list = jsonDecode(cached);
        final cachedPapers = list
            .map((item) => PyqPaperItem.fromJson(item as Map<String, dynamic>))
            .where((p) => p.questionCount > 0)
            .toList();
        setState(() {
          _allPapers = cachedPapers;
          _isLoading = false;
          _isOffline = true;
        });
        return;
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _allPapers = [];
        _isLoading = false;
        _isOffline = true;
      });
    }
  }

  List<PyqPaperItem> get _filteredPapers {
    return _allPapers.where((p) {
      // 1. Exam filter
      if (_selectedExam != 'ALL') {
        final examMatch = p.examCode.toUpperCase().contains(_selectedExam.toUpperCase());
        if (!examMatch) return false;
      }

      // 2. Subject filter
      if (_selectedSubject != 'All') {
        if (_selectedSubject == 'Full papers') {
          final isFull = p.questionCount >= 50 || (p.subject ?? '').toLowerCase().contains('full');
          if (!isFull) return false;
        } else {
          final s = (p.subject ?? '').toLowerCase();
          final target = _selectedSubject.toLowerCase();
          if (!s.contains(target)) return false;
        }
      }

      // 3. Search query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = p.title.toLowerCase().contains(q);
        final matchCode = p.examCode.toLowerCase().contains(q);
        final matchSubject = (p.subject ?? '').toLowerCase().contains(q);
        final matchYear = p.year?.toString().contains(q) ?? false;
        if (!matchTitle && !matchCode && !matchSubject && !matchYear) return false;
      }

      return true;
    }).toList();
  }

  Map<int?, List<PyqPaperItem>> get _groupedByYear {
    final Map<int?, List<PyqPaperItem>> map = {};
    for (final p in _filteredPapers) {
      map.putIfAbsent(p.year, () => []).add(p);
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
        title: const Text('Previous Year Papers'),
      ),
      body: content,
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_allPapers.isEmpty) {
      return _buildEmptyState(
        title: 'No Papers Found',
        message: 'Unable to connect to paper bank. Please check your network and retry.',
        canRetry: true,
      );
    }

    final filtered = _filteredPapers;
    final years = _groupedByYear.keys.toList()
      ..sort((a, b) {
        if (a == null) return 1;
        if (b == null) return -1;
        return b.compareTo(a);
      });

    return RefreshIndicator(
      onRefresh: () => _loadPapers(forceRefresh: true),
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
                        tooltip: 'Search papers',
                      ),
                    ],
                  ),

                  // Search Field (Expands on tap)
                  if (_isSearchOpen) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search by exam, year, subject...',
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

                  // Row 2: Quick Chips Row (Sized to text, works at 130% font scale)
                  _buildQuickChipsRow(),

                  // Row 3: Active Filter / Offline Indicator
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
                            '${filtered.length} papers',
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

          // ─── Paper Cards Grouped by Year ──────────────────────────────────
          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(
                title: 'No Matching Papers',
                message: 'No previous year papers match your current filters.',
                canRetry: false,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final year = years[index];
                    final yearPapers = _groupedByYear[year] ?? [];
                    final headerText = year != null ? '$year Papers' : 'Other Papers';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Year Sticky Header
                        Padding(
                          padding: const EdgeInsets.only(top: 14, bottom: 8),
                          child: Row(
                            children: [
                              Text(
                                headerText,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
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
                                  '${yearPapers.length}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Paper cards for this year
                        ...yearPapers.map((paper) => _buildPaperCard(context, paper)),
                      ],
                    );
                  },
                  childCount: years.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool get _hasActiveFilter =>
      _selectedExam != 'ALL' || _selectedSubject != 'All' || _searchQuery.isNotEmpty;

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
    // Derive exam codes and counts from live papers
    final Map<String, int> examCounts = {};
    for (final p in _allPapers) {
      final code = p.examCode
          .replaceAll('APSSB-', '')
          .replaceAll('APPSC-', '')
          .replaceAll('-2024', '')
          .replaceAll('-2023', '')
          .replaceAll('-2022', '')
          .replaceAll('-2021', '')
          .replaceAll('-2020', '');
      examCounts[code] = (examCounts[code] ?? 0) + 1;
    }

    final apssbExams = examCounts.keys.where((k) => !k.contains('CCE') && !k.contains('ESE')).toList();
    final appscExams = examCounts.keys.where((k) => k.contains('CCE') || k.contains('ESE')).toList();

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

              // APSSB Group
              if (apssbExams.isNotEmpty) ...[
                const Text(
                  'APSSB Examinations',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: apssbExams.map((exam) {
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
                const SizedBox(height: 14),
              ],

              // APPSC Group
              if (appscExams.isNotEmpty) ...[
                const Text(
                  'APPSC Examinations',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: appscExams.map((exam) {
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
                const SizedBox(height: 14),
              ],

              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.apps_rounded, color: AppColors.primary),
                title: const Text('All Exams', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${_allPapers.length} total papers available'),
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

  // ─── B2: Quick Chips Row ───────────────────────────────────────────────────
  Widget _buildQuickChipsRow() {
    // Derive subjects and counts dynamically from loaded papers
    final Map<String, int> subjCounts = {'All': _allPapers.length};
    for (final p in _allPapers) {
      final s = p.subject?.trim();
      if (s != null && s.isNotEmpty) {
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

  // ─── B3: Compact Paper Card ────────────────────────────────────────────────
  Widget _buildPaperCard(BuildContext context, PyqPaperItem paper) {
    final markingText = paper.marksPerCorrect != null
        ? '+${paper.marksPerCorrect!.toStringAsFixed(0)} / -${(paper.negativeMarks ?? 0.5).toStringAsFixed(1)}'
        : 'Standard Marking';
    final durText = paper.durationMinutes != null ? '${paper.durationMinutes} min' : '60 min';

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
                  paper.displayTitle,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ),
              if (paper.isIncomplete) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.darkWarning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.darkWarning.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'Incomplete · ${paper.questionCount}/${paper.officialQuestionCount}',
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

          // Single Wrapping Meta Line (Nothing repeated, Fix A8)
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${paper.questionCount} Qs',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const Text('·', style: TextStyle(color: AppColors.textSecondary)),
              Text(
                durText,
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
                  onPressed: () => _confirmAndStartTest(context, paper),
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
                  onPressed: () => _launchStudyMode(context, paper),
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

  // ─── 3-Bullet Confirmation Dialog (B3) ─────────────────────────────────────
  void _confirmAndStartTest(BuildContext context, PyqPaperItem paper) {
    final dur = paper.durationMinutes ?? 60;
    final marks = paper.marksPerCorrect ?? 2.0;
    final neg = paper.negativeMarks ?? 0.5;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Start ${paper.displayTitle}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• $dur mins CBT exam simulation with live countdown timer.'),
            const SizedBox(height: 6),
            Text('• Marking scheme: +${marks.toStringAsFixed(0)} correct, -${neg.toStringAsFixed(1)} negative marks.'),
            const SizedBox(height: 6),
            const Text('• Instant scorecard, percentile & solution key on submit.'),
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
              final yrParam = paper.year != null ? '&year=${paper.year}' : '';
              // Wire testId through route (Fix A3)
              context.push(
                '/mock-test/${paper.examCode}/full?paperType=PYQ$yrParam&testId=${paper.id}&duration=$dur',
              );
            },
            child: const Text('Start Now'),
          ),
        ],
      ),
    );
  }

  void _launchStudyMode(BuildContext context, PyqPaperItem paper) {
    final yrParam = paper.year != null ? '&year=${paper.year}' : '';
    // Wire testId through route (Fix A3)
    context.push(
      '/pyq-paper?code=${paper.examCode}$yrParam&testId=${paper.id}',
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
            const Icon(Icons.school_outlined, size: 48, color: AppColors.textHint),
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
                onPressed: () => _loadPapers(forceRefresh: true),
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
