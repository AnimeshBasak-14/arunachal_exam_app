import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class MockTestItem {
  final String id;
  final String title;
  final String category; // 'Maths', 'GK', 'GA', 'English', 'Technical', 'Full Mock'
  final String examCode;
  final int questionCount;
  final int durationMinutes;
  final String difficulty;
  final String description;

  const MockTestItem({
    required this.id,
    required this.title,
    required this.category,
    required this.examCode,
    required this.questionCount,
    required this.durationMinutes,
    required this.difficulty,
    required this.description,
  });

  factory MockTestItem.fromSupabase(Map<String, dynamic> data) {
    final title = (data['title'] ?? 'Mock Test').toString();
    final examCode = (data['exam_code'] ?? 'APSSB-MOCK').toString().toUpperCase();

    String category = 'Full Mock';
    if (examCode.contains('MATH') || title.toLowerCase().contains('math')) {
      category = 'Maths';
    } else if (examCode.contains('CIVIL') || examCode.contains('COMP') || examCode.contains('AGRI') || title.toLowerCase().contains('civil') || title.toLowerCase().contains('technical')) {
      category = 'Technical';
    } else if (title.toLowerCase().contains('grammar')) {
      category = 'Grammar';
    } else if (title.toLowerCase().contains('english') || title.toLowerCase().contains('vocab')) {
      category = 'English';
    } else if (title.toLowerCase().contains('awareness') || title.toLowerCase().contains('current')) {
      category = 'GA';
    } else if (title.toLowerCase().contains('gk') || title.toLowerCase().contains('knowledge')) {
      category = 'GK';
    }

    return MockTestItem(
      id: data['id']?.toString() ?? '',
      title: title,
      category: category,
      examCode: examCode,
      questionCount: int.tryParse(data['total_questions']?.toString() ?? '20') ?? 20,
      durationMinutes: int.tryParse(data['duration_minutes']?.toString() ?? '30') ?? 30,
      difficulty: (data['difficulty'] ?? 'Medium').toString(),
      description: data['description']?.toString() ?? 'High-yield practice test for APSSB and APPSC aspirants.',
    );
  }
}

class MockHubScreen extends ConsumerStatefulWidget {
  final bool isEmbedded;
  const MockHubScreen({super.key, this.isEmbedded = false});

  @override
  ConsumerState<MockHubScreen> createState() => _MockHubScreenState();
}

class _MockHubScreenState extends ConsumerState<MockHubScreen> {
  String _selectedCategory = 'All';
  String _selectedLevel = 'All Levels';
  String _searchQuery = '';
  bool _isLoading = false;
  List<MockTestItem> _mockTests = [];

  final List<String> _topics = [
    'All',
    'Maths',
    'GK',
    'GA',
    'English',
    'Comprehension',
    'Grammar',
    'Technical',
    'Full Mock',
  ];

  final List<String> _levels = [
    'All Levels',
    'Easy',
    'Medium',
    'Hard',
  ];

  static const List<MockTestItem> _defaultCatalog = [
    // Elementary Mathematics
    MockTestItem(
      id: 'mock_math_3',
      title: 'APSSB Elementary Maths Mock Test 3 (Formulas & Arithmetic)',
      category: 'Maths',
      examCode: 'APSSB-MOCK-MATHS',
      questionCount: 12,
      durationMinutes: 20,
      difficulty: 'Medium',
      description: 'Covers ratios, percentages, time & work, and algebra with step-by-step LaTeX solutions.',
    ),
    MockTestItem(
      id: 'mock_math_4',
      title: 'APSSB Elementary Maths Mock Test 4 (Geometry & Mensuration)',
      category: 'Maths',
      examCode: 'APSSB-MOCK-MATHS',
      questionCount: 15,
      durationMinutes: 25,
      difficulty: 'Hard',
      description: 'Advanced numerical questions on areas, volumes, coordinate geometry and speed-distance.',
    ),

    // General Knowledge (GK) - 3 Tiers (Easy, Medium, Hard)
    MockTestItem(
      id: 'mock_gk_easy',
      title: 'Arunachal GK (Easy - State Symbols, Geography & Basics)',
      category: 'GK',
      examCode: 'APSSB-CGLE',
      questionCount: 15,
      durationMinutes: 15,
      difficulty: 'Easy',
      description: 'Foundational state facts: state bird, flower, rivers, districts, and major state symbols.',
    ),
    MockTestItem(
      id: 'mock_gk_medium',
      title: 'Arunachal Pradesh GK (Medium - Tribes, Festivals & Heritage)',
      category: 'GK',
      examCode: 'APSSB-CGLE',
      questionCount: 20,
      durationMinutes: 20,
      difficulty: 'Medium',
      description: 'Tribes, festivals (Losar, Nyokum, Mopin, Solung), crafts, historical evolution and folklore.',
    ),
    MockTestItem(
      id: 'mock_gk_hard',
      title: 'State & National GK (Hard - Indian Polity, History & Economy)',
      category: 'GK',
      examCode: 'APPSC-CCE',
      questionCount: 25,
      durationMinutes: 25,
      difficulty: 'Hard',
      description: 'Advanced questions on constitutional provisions, NEFA reorganization, budget, and judicial system.',
    ),

    // General Awareness (GA & Current Affairs)
    MockTestItem(
      id: 'mock_ga_monthly',
      title: 'Arunachal & National Current Affairs Sprint (Latest Schemes)',
      category: 'GA',
      examCode: 'APSSB-CHSL',
      questionCount: 15,
      durationMinutes: 15,
      difficulty: 'Easy',
      description: 'State government budget highlights, sports achievements, awards, and national summits.',
    ),

    // General English
    MockTestItem(
      id: 'mock_eng_grammar',
      title: 'APSSB General English (Subject-Verb & Error Spotting)',
      category: 'English',
      examCode: 'APSSB-CSLE',
      questionCount: 20,
      durationMinutes: 15,
      difficulty: 'Medium',
      description: 'Spotting errors, prepositions, voice, narration, and sentence rearrangement.',
    ),
    MockTestItem(
      id: 'mock_eng_vocab',
      title: 'English Vocabulary & Idioms Sprint Test',
      category: 'English',
      examCode: 'APSSB-CGLE',
      questionCount: 15,
      durationMinutes: 12,
      difficulty: 'Easy',
      description: 'High-frequency synonyms, antonyms, and idioms tested in Arunachal state examinations.',
    ),

    // Grammar (separate from English vocabulary)
    MockTestItem(
      id: 'mock_grammar_1',
      title: 'APSSB English Grammar Mock (Tenses, Voice & Narration)',
      category: 'Grammar',
      examCode: 'APSSB-CSLE',
      questionCount: 20,
      durationMinutes: 15,
      difficulty: 'Medium',
      description: 'Subject-verb agreement, active/passive voice, direct/indirect speech with explanations.',
    ),
    MockTestItem(
      id: 'mock_grammar_2',
      title: 'APPSC Grammar Sprint — Articles, Prepositions & Conjunctions',
      category: 'Grammar',
      examCode: 'APPSC-CCE',
      questionCount: 15,
      durationMinutes: 12,
      difficulty: 'Easy',
      description: 'Beginner to intermediate grammar rules covering articles, prepositions, and sentence connectors.',
    ),

    // Technical Subjects
    MockTestItem(
      id: 'mock_tech_civil_1',
      title: 'APPSC Civil Engineering Paper II Mock (Structures & Concrete)',
      category: 'Technical',
      examCode: 'APPSC-CIVIL',
      questionCount: 25,
      durationMinutes: 30,
      difficulty: 'Hard',
      description: 'Structural analysis, RCC, steel structures, soil mechanics, and environmental engineering.',
    ),
    MockTestItem(
      id: 'mock_tech_computer_1',
      title: 'Computer Science & IT Sectional Mock Test',
      category: 'Technical',
      examCode: 'APSSB-UDC',
      questionCount: 20,
      durationMinutes: 20,
      difficulty: 'Medium',
      description: 'Database systems, operating systems, MS Office shortcuts, networking, and cyber security.',
    ),
    MockTestItem(
      id: 'mock_tech_agriculture_1',
      title: 'Arunachal Agriculture & Horticulture Special Mock',
      category: 'Technical',
      examCode: 'APPSC-CCE',
      questionCount: 20,
      durationMinutes: 20,
      difficulty: 'Medium',
      description: 'Horticulture, organic farming policies in Arunachal, soil types, and crop diseases.',
    ),

    // Full Mocks
    MockTestItem(
      id: 'mock_full_1',
      title: 'APSSB Full-Length Mock Exam 1 (Complete Pattern)',
      category: 'Full Mock',
      examCode: 'APSSB-MOCK',
      questionCount: 39,
      durationMinutes: 45,
      difficulty: 'Medium',
      description: 'Full exam simulation covering English (25%), GK (25%), Maths (25%), and Reasoning (25%).',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fetchLiveMocksFromSupabase();
  }

  Future<void> _fetchLiveMocksFromSupabase() async {
    setState(() => _isLoading = true);
    try {
      const url =
          'https://fllopztywwblbucvaths.supabase.co/rest/v1/tests?paper_type=eq.MOCK&order=created_at.desc';
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
              .map((data) => MockTestItem.fromSupabase(data as Map<String, dynamic>))
              .toList();

          final existingIds = fetched.map((p) => p.id).toSet();
          for (final d in _defaultCatalog) {
            if (!existingIds.contains(d.id)) {
              fetched.add(d);
            }
          }
          if (mounted) {
            setState(() {
              _mockTests = fetched;
              _isLoading = false;
            });
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('[MockHub] Supabase fetch fallback: $e');
    }

    if (mounted) {
      setState(() {
        _mockTests = List.from(_defaultCatalog);
        _isLoading = false;
      });
    }
  }

  void _showModeSelectionModal(BuildContext context, MockTestItem test) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.speed_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Test Mode',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      Text(
                        test.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Mode 1: Timed Exam Mode
            InkWell(
              onTap: () {
                Navigator.pop(ctx);
                context.push('/mock-test/${test.examCode}/${test.questionCount}?duration=${test.durationMinutes}&mode=timed');
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF0F172A).withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.timer_rounded, color: Color(0xFF1E3A8A), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Row(
                            children: [
                              Text(
                                'Timed Exam Mode',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                              ),
                              SizedBox(width: 6),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.all(Radius.circular(4)),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  child: Text(
                                    'REAL EXAM',
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Live countdown timer · Choices recorded neutrally without revealing answers until final submission',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Mode 2: Study Mode
            InkWell(
              onTap: () {
                Navigator.pop(ctx);
                context.push('/mock-test/${test.examCode}/${test.questionCount}?duration=${test.durationMinutes}&mode=study');
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF0F172A).withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF047857).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.menu_book_rounded, color: Color(0xFF047857), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Row(
                            children: [
                              Text(
                                'Study & Practice Mode',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                              ),
                              SizedBox(width: 6),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.all(Radius.circular(4)),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  child: Text(
                                    'PRACTICE',
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Immediate right/wrong feedback on tap · Step-by-step explanations · Candidate doubt discussion',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                  ],
                ),
              ),
            ),
          ],
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
            final itemLabel = (item == 'All' && allLabel == 'All') ? 'All Topics' : item;
            return DropdownMenuItem(
              value: item,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      itemLabel,
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
    final filteredMocks = _mockTests.where((test) {
      if (_selectedCategory != 'All' && test.category != _selectedCategory) {
        return false;
      }
      if (_selectedLevel != 'All Levels' && test.difficulty.toLowerCase() != _selectedLevel.toLowerCase()) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!test.title.toLowerCase().contains(q) &&
            !test.category.toLowerCase().contains(q) &&
            !test.description.toLowerCase().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: const Text(
                'Mock Test Center',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              elevation: 0,
              backgroundColor: Colors.white,
              foregroundColor: AppColors.textPrimary,
              actions: [
                IconButton(
                  icon: const Icon(Icons.history_rounded, color: AppColors.primary),
                  tooltip: 'View Quiz History',
                  onPressed: () => context.push('/quiz-history'),
                ),
              ],
            ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            children: [
              // Search & 3 Dropdown Filters Header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Column(
                  children: [
                    TextField(
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                      decoration: InputDecoration(
                        hintText: 'Search Maths, GK, English, Technical mocks...',
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
                    // 2 Dropdown Filters: Topic & Level
                    Row(
                      children: [
                        // 1. Topic Dropdown
                        Expanded(
                          child: _buildFilterDropdown(
                            value: _selectedCategory,
                            items: _topics,
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedCategory = val);
                            },
                            icon: Icons.menu_book_rounded,
                            allLabel: 'All',
                          ),
                        ),
                        const SizedBox(width: 8),

                        // 2. Question Level Dropdown
                        Expanded(
                          child: _buildFilterDropdown(
                            value: _selectedLevel,
                            items: _levels,
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedLevel = val);
                            },
                            icon: Icons.tune_rounded,
                            allLabel: 'All Levels',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Mock Test List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredMocks.isEmpty
                        ? _buildEmptyView()
                        : RefreshIndicator(
                            onRefresh: _fetchLiveMocksFromSupabase,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(AppSpacing.m),
                              itemCount: filteredMocks.length,
                              itemBuilder: (context, index) {
                                final test = filteredMocks[index];
                                return _buildMockCard(context, test);
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

  Widget _buildMockCard(BuildContext context, MockTestItem test) {
    Color categoryColor;
    IconData categoryIcon;

    switch (test.category) {
      case 'Maths':
        categoryColor = Colors.purple;
        categoryIcon = Icons.calculate_rounded;
        break;
      case 'GK':
        categoryColor = Colors.teal;
        categoryIcon = Icons.public_rounded;
        break;
      case 'GA':
        categoryColor = Colors.amber.shade800;
        categoryIcon = Icons.newspaper_rounded;
        break;
      case 'English':
        categoryColor = Colors.indigo;
        categoryIcon = Icons.spellcheck_rounded;
        break;
      case 'Grammar':
        categoryColor = Colors.deepPurple;
        categoryIcon = Icons.menu_book_rounded;
        break;
      case 'Technical':
        categoryColor = Colors.deepOrange;
        categoryIcon = Icons.engineering_rounded;
        break;
      default:
        categoryColor = AppColors.primary;
        categoryIcon = Icons.assignment_turned_in_rounded;
    }

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
            // Top Tags
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(categoryIcon, size: 13, color: categoryColor),
                      const SizedBox(width: 4),
                      Text(
                        test.category,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: categoryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    test.examCode,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: test.difficulty == 'Hard'
                        ? AppColors.error.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    test.difficulty,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: test.difficulty == 'Hard' ? AppColors.error : Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Title
            Text(
              test.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),

            // Description
            Text(
              test.description,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),

            // Test Metrics Row (Count, Time, Marking - Compact & Mobile Safe)
            Builder(builder: (context) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.help_outline_rounded, size: 14, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(
                        '${test.questionCount} Questions',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.timer_outlined, size: 14, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(
                        '${test.durationMinutes} mins',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '+2 / -0.5',
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.textHint),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Start Mock Button with Mode Selection
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showModeSelectionModal(context, test),
                      icon: const Icon(Icons.play_arrow_rounded, size: 18, color: Colors.white),
                      label: const Text(
                        'Start Mock Test',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusM)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 54, color: AppColors.textHint),
            const SizedBox(height: AppSpacing.m),
            const Text(
              'No mock tests found in this category',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try selecting "All Mocks" or check back shortly as new papers are added.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.l),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _selectedCategory = 'All';
                  _searchQuery = '';
                });
              },
              child: const Text('View All Mocks'),
            ),
          ],
        ),
      ),
    );
  }
}
