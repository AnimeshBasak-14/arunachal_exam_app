import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class PyqPaperItem {
  final String id;
  final String title;
  final String board; // 'APPSC' or 'APSSB'
  final String examCode;
  final int year;
  final String subject;
  final int questionCount;
  final int durationMinutes;
  final double marksPerCorrect;
  final double negativeMarks;

  const PyqPaperItem({
    required this.id,
    required this.title,
    required this.board,
    required this.examCode,
    required this.year,
    required this.subject,
    required this.questionCount,
    required this.durationMinutes,
    this.marksPerCorrect = 2.0,
    this.negativeMarks = 0.5,
  });

  factory PyqPaperItem.fromSupabase(Map<String, dynamic> data) {
    final examCode = (data['exam_code'] ?? 'APSSB-CGLE').toString().toUpperCase();
    final board = examCode.startsWith('APPSC') ? 'APPSC' : 'APSSB';

    int qCount = 50;
    if (data['questions'] is List && (data['questions'] as List).isNotEmpty) {
      final f = (data['questions'] as List).first;
      if (f is Map && f['count'] != null) {
        qCount = int.tryParse(f['count'].toString()) ?? 50;
      }
    } else if (data['total_questions'] != null) {
      qCount = int.tryParse(data['total_questions'].toString()) ?? 50;
    }

    final dur = int.tryParse(data['duration_minutes']?.toString() ?? '') ??
        (qCount > 0 ? (qCount <= 30 ? 30 : (qCount <= 60 ? 60 : 120)) : 120);

    return PyqPaperItem(
      id: data['id']?.toString() ?? '',
      title: data['title']?.toString() ?? 'Previous Year Paper',
      board: board,
      examCode: examCode,
      year: int.tryParse(data['year']?.toString() ?? '') ?? 2024,
      subject: data['subject']?.toString() ?? 'General Studies',
      questionCount: qCount,
      durationMinutes: dur,
      marksPerCorrect: (data['marks_per_correct'] as num?)?.toDouble() ?? 2.0,
      negativeMarks: (data['negative_marks'] as num?)?.toDouble() ?? 0.5,
    );
  }
}

class PyqHubScreen extends ConsumerStatefulWidget {
  final bool isEmbedded;
  const PyqHubScreen({super.key, this.isEmbedded = false});

  @override
  ConsumerState<PyqHubScreen> createState() => _PyqHubScreenState();
}

class _PyqHubScreenState extends ConsumerState<PyqHubScreen> with SingleTickerProviderStateMixin {
  late TabController _boardTabController;
  String _searchQuery = '';
  String _selectedExam = 'All Exams';
  String _selectedYear = 'All Years';
  String _selectedSubject = 'All Subjects';
  bool _isLoading = false;
  List<PyqPaperItem> _livePapers = [];

  final List<String> _exams = [
    'All Exams',
    'CGL',
    'CHSL',
    'CSLE',
    'UDC',
    'MTS',
    'CCE',
  ];

  final List<String> _years = [
    'All Years',
    '2025',
    '2024',
    '2023',
    '2022',
    '2021',
    '2020',
  ];

  final List<String> _subjects = [
    'All Subjects',
    'General Studies',
    'Elementary Maths',
    'General English',
    'Reading Comprehension',
    'Grammar',
    'Reasoning / CSAT',
    'Civil Engineering',
  ];

  // Default rich catalog fallback
  static const List<PyqPaperItem> _defaultCatalog = [
    // APPSC Papers
    PyqPaperItem(
      id: 'appsc_cce_2024_gs',
      title: 'APPSC CCE 2024 Prelims Paper I (General Studies)',
      board: 'APPSC',
      examCode: 'APPSC-CCE',
      year: 2024,
      subject: 'General Studies',
      questionCount: 100,
      durationMinutes: 120,
    ),
    PyqPaperItem(
      id: 'appsc_cce_2024_csat',
      title: 'APPSC CCE 2024 Prelims Paper II (CSAT)',
      board: 'APPSC',
      examCode: 'APPSC-CCE',
      year: 2024,
      subject: 'Reasoning / CSAT',
      questionCount: 80,
      durationMinutes: 120,
    ),
    PyqPaperItem(
      id: 'appsc_ese_2025_civil',
      title: 'APPSC ESE 2025 Civil Engineering (Paper II)',
      board: 'APPSC',
      examCode: 'APPSC-CIVIL',
      year: 2025,
      subject: 'Civil Engineering',
      questionCount: 100,
      durationMinutes: 120,
    ),
    PyqPaperItem(
      id: 'appsc_ese_2025_ga',
      title: 'APPSC ESE 2025 General Awareness & Reasoning (Paper A)',
      board: 'APPSC',
      examCode: 'APPSC-ESE',
      year: 2025,
      subject: 'General Studies',
      questionCount: 100,
      durationMinutes: 120,
    ),
    PyqPaperItem(
      id: 'appsc_cce_2023_gs',
      title: 'APPSC CCE 2023 Prelims General Studies Paper I',
      board: 'APPSC',
      examCode: 'APPSC-CCE',
      year: 2023,
      subject: 'General Studies',
      questionCount: 100,
      durationMinutes: 120,
    ),

    // APSSB Papers
    PyqPaperItem(
      id: 'apssb_cgl_2024_full',
      title: 'APSSB CGL 2024 Combined Graduate Level Examination',
      board: 'APSSB',
      examCode: 'APSSB-CGLE',
      year: 2024,
      subject: 'General Studies',
      questionCount: 54, // Calibrated to live DB count
      durationMinutes: 60,
      marksPerCorrect: 2.0,
      negativeMarks: 0.5,
    ),
    PyqPaperItem(
      id: 'apssb_cgl_2023_full',
      title: 'APSSB CGL 2023 Combined Graduate Level (Full Paper)',
      board: 'APSSB',
      examCode: 'APSSB-CGLE',
      year: 2023,
      subject: 'General Studies',
      questionCount: 50,
      durationMinutes: 60,
      marksPerCorrect: 2.0,
      negativeMarks: 0.5,
    ),
    PyqPaperItem(
      id: 'apssb_chsl_2024_full',
      title: 'APSSB CHSL 2024 Higher Secondary Level Exam',
      board: 'APSSB',
      examCode: 'APSSB-CHSL',
      year: 2024,
      subject: 'General Studies',
      questionCount: 50,
      durationMinutes: 60,
      marksPerCorrect: 2.0,
      negativeMarks: 0.5,
    ),
    PyqPaperItem(
      id: 'apssb_csle_2024_full',
      title: 'APSSB CSLE 2024 Combined Secondary Level Examination',
      board: 'APSSB',
      examCode: 'APSSB-CSLE',
      year: 2024,
      subject: 'General Studies',
      questionCount: 50,
      durationMinutes: 60,
      marksPerCorrect: 2.0,
      negativeMarks: 0.5,
    ),
    PyqPaperItem(
      id: 'apssb_udc_2023_full',
      title: 'APSSB UDC 2023 Upper Division Clerk Official Paper',
      board: 'APSSB',
      examCode: 'APSSB-UDC',
      year: 2023,
      subject: 'General Studies',
      questionCount: 50,
      durationMinutes: 60,
      marksPerCorrect: 2.0,
      negativeMarks: 0.5,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _boardTabController = TabController(length: 2, vsync: this);
    _boardTabController.addListener(() {
      if (mounted) setState(() {});
    });
    _fetchLivePapersFromSupabase();
  }

  @override
  void dispose() {
    _boardTabController.dispose();
    super.dispose();
  }

  Future<void> _fetchLivePapersFromSupabase() async {
    setState(() => _isLoading = true);
    try {
      const url =
          'https://fllopztywwblbucvaths.supabase.co/rest/v1/tests?select=*,questions(count)&paper_type=eq.PYQ&order=year.desc,created_at.desc';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'apikey': 'sb_publishable_y68QKKHxBTZxBP3Sf1X7tw_zfFnXX8M',
          'Authorization':
              'Bearer sb_publishable_y68QKKHxBTZxBP3Sf1X7tw_zfFnXX8M',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        if (list.isNotEmpty) {
          final fetched = list
              .map((data) => PyqPaperItem.fromSupabase(data as Map<String, dynamic>))
              .toList();

          // Merge with default catalog ensuring no duplicate IDs
          final existingIds = fetched.map((p) => p.id).toSet();
          for (final d in _defaultCatalog) {
            if (!existingIds.contains(d.id)) {
              fetched.add(d);
            }
          }
          if (mounted) {
            setState(() {
              _livePapers = fetched;
              _isLoading = false;
            });
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('[PyqHub] Supabase fetch fallback: $e');
    }

    if (mounted) {
      setState(() {
        _livePapers = List.from(_defaultCatalog);
        _isLoading = false;
      });
    }
  }
  Widget _buildBoardPill(int index, IconData icon, String label) {
    final isSelected = _boardTabController.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _boardTabController.animateTo(index);
          setState(() {});
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isSelected ? Colors.white : AppColors.textSecondary),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
    required String allLabel,
  }) {
    final isFiltered = value != allLabel;
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isFiltered ? AppColors.primary.withValues(alpha: 0.08) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isFiltered ? AppColors.primary.withValues(alpha: 0.4) : const Color(0xFFE2E8F0),
          width: isFiltered ? 1.4 : 1.0,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: isFiltered ? AppColors.primary : const Color(0xFF94A3B8),
            size: 16,
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(14),
          elevation: 4,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isFiltered ? FontWeight.bold : FontWeight.w600,
            color: isFiltered ? AppColors.primary : AppColors.textPrimary,
          ),
          items: items.map((item) {
            final isItemSel = item == value;
            return DropdownMenuItem(
              value: item,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isItemSel ? FontWeight.bold : FontWeight.normal,
                        color: isItemSel ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (isItemSel)
                    const Icon(Icons.check_rounded, size: 14, color: AppColors.primary),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeBoard = _boardTabController.index == 0 ? 'APSSB' : 'APPSC';

    final filteredPapers = _livePapers.where((paper) {
      if (paper.board != activeBoard) return false;
      if (_selectedYear != 'All Years' && paper.year.toString() != _selectedYear) {
        return false;
      }
      if (_selectedExam != 'All Exams') {
        if (!paper.examCode.toUpperCase().contains(_selectedExam.toUpperCase())) {
          return false;
        }
      }
      if (_selectedSubject != 'All Subjects' && paper.subject != _selectedSubject) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!paper.title.toLowerCase().contains(q) &&
            !paper.examCode.toLowerCase().contains(q) &&
            !paper.subject.toLowerCase().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();

    // Compact pill segmented selector for APSSB / APPSC
    final boardSelector = Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            _buildBoardPill(0, Icons.school_rounded, 'APSSB'),
            _buildBoardPill(1, Icons.account_balance_rounded, 'APPSC'),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: const Text(
                'Previous Year Papers (PYQ)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              elevation: 0,
              backgroundColor: Colors.white,
              foregroundColor: AppColors.textPrimary,
            ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            children: [
              boardSelector,

              // Search & Filter Header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(AppSpacing.m, AppSpacing.m, AppSpacing.m, AppSpacing.s),
                child: Column(
                  children: [
                    // Search Field
                    TextField(
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                      decoration: InputDecoration(
                        hintText: 'Search $activeBoard exams, years, or topics...',
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint, size: 20),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusM),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textHint),
                                onPressed: () => setState(() => _searchQuery = ''),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s),

                    // Filter Chips Row (Exam, Year & Subject dropdowns)
                    Row(
                      children: [
                        // 1. Exam Dropdown
                        Expanded(
                          child: _buildFilterDropdown(
                            value: _selectedExam,
                            items: _exams,
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedExam = val);
                            },
                            icon: Icons.school_rounded,
                            allLabel: 'All Exams',
                          ),
                        ),
                        const SizedBox(width: 6),

                        // 2. Year Dropdown
                        Expanded(
                          child: _buildFilterDropdown(
                            value: _selectedYear,
                            items: _years,
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedYear = val);
                            },
                            icon: Icons.calendar_today_rounded,
                            allLabel: 'All Years',
                          ),
                        ),
                        const SizedBox(width: 6),

                        // 3. Subject Dropdown
                        Expanded(
                          child: _buildFilterDropdown(
                            value: _selectedSubject,
                            items: _subjects,
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedSubject = val);
                            },
                            icon: Icons.menu_book_rounded,
                            allLabel: 'All Subjects',
                          ),
                        ),
                      ],
                    ),

                    // ─── Smart Practice CTA (PYQ Topic Filter) ───────────────────
                    if (_selectedSubject != 'All Subjects') ...[
                      const SizedBox(height: AppSpacing.s),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Choose exam code: use specific exam filter or 'ALL' for cross-exam practice
                            final examCode = _selectedExam != 'All Exams'
                                ? '$activeBoard-$_selectedExam'
                                : 'ALL';

                            // Build URI — use PYQ paper type, with subject filter
                            final year = _selectedYear != 'All Years' ? _selectedYear : '';
                            var uri = '/mock-test/$examCode/10?subject=${Uri.encodeComponent(_selectedSubject)}&paperType=PYQ';
                            if (year.isNotEmpty) uri += '&year=$year';

                            context.push(uri);
                          },
                          icon: const Icon(Icons.quiz_rounded, size: 18, color: Colors.white),
                          label: Text(
                            'Practice $_selectedSubject Questions'
                                '${_selectedExam != 'All Exams' ? ' · $_selectedExam' : ' (All Exams)'}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusM)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const Divider(height: 1),

              // Papers List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredPapers.isEmpty
                        ? _buildEmptyView(activeBoard)
                        : RefreshIndicator(
                            onRefresh: _fetchLivePapersFromSupabase,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(AppSpacing.m),
                              itemCount: filteredPapers.length,
                              itemBuilder: (context, index) {
                                final paper = filteredPapers[index];
                                return _buildPaperCard(context, paper);
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaperCard(BuildContext context, PyqPaperItem paper) {
    final isAppsc = paper.board == 'APPSC';
    final badgeColor = isAppsc ? const Color(0xFF0D47A1) : const Color(0xFF1B5E20);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusL),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Badges & Year
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    paper.examCode,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Year ${paper.year}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Marking Scheme Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '+${paper.marksPerCorrect.toStringAsFixed(0)} / -${paper.negativeMarks.toStringAsFixed(1)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF059669),
                    ),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 14, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text(
                      '${paper.durationMinutes}m',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Paper Title
            Text(
              paper.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),

            // Metadata row — question count, duration & marking
            Row(
              children: [
                const Icon(Icons.help_outline_rounded, size: 14, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(
                  '${paper.questionCount} Questions',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.timer_outlined, size: 14, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(
                  '${paper.durationMinutes} mins',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.verified_outlined, size: 14, color: Color(0xFF059669)),
                const SizedBox(width: 4),
                Text(
                  '+${paper.marksPerCorrect.toStringAsFixed(0)} / -${paper.negativeMarks.toStringAsFixed(1)} Marking',
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF059669), fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),

            // Mode Selection Action Buttons
            Row(
              children: [
                // 1. Exam Mode (Timed CBT)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _launchExamMode(context, paper);
                    },
                    icon: const Icon(Icons.alarm_on_rounded, size: 16, color: Colors.white),
                    label: const Text(
                      'Exam Mode',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusM),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // 2. Study / Practice Mode (Instant answers)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _launchStudyMode(context, paper);
                    },
                    icon: const Icon(Icons.menu_book_rounded, size: 16, color: AppColors.primary),
                    label: const Text(
                      'Study Mode',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary, width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusM),
                      ),
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

  void _launchExamMode(BuildContext context, PyqPaperItem paper) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusL)),
        title: Row(
          children: [
            const Icon(Icons.alarm_on_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Start Exam Simulation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You are about to start "${paper.title}" in Exam Mode.', style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            Text('• ${paper.questionCount} Questions (${paper.durationMinutes} mins CBT simulation).', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text('• APPSC/APSSB marking (+${paper.marksPerCorrect.toStringAsFixed(0)} per correct, -${paper.negativeMarks.toStringAsFixed(1)} negative marks).', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            const Text('• Instant rank scorecard and performance analysis at the end.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
              final yearParam = paper.year > 2000 ? '&year=${paper.year}' : '';
              context.push('/mock-test/${paper.examCode}/full?paperType=PYQ$yearParam&duration=${paper.durationMinutes}');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusM)),
            ),
            child: const Text('Start Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _launchStudyMode(BuildContext context, PyqPaperItem paper) {
    context.push('/pyq-paper?code=${paper.examCode}&year=${paper.year}');
  }

  Widget _buildEmptyView(String board) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 54, color: AppColors.textHint),
            const SizedBox(height: AppSpacing.m),
            Text(
              'No $board papers match your filter',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try changing the selected year, subject or clear your search keyword.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.l),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _selectedYear = 'All Years';
                  _selectedSubject = 'All Subjects';
                });
              },
              child: const Text('Reset All Filters'),
            ),
          ],
        ),
      ),
    );
  }
}
