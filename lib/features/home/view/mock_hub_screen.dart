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
    } else if (title.toLowerCase().contains('english') || title.toLowerCase().contains('grammar')) {
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
  const MockHubScreen({super.key});

  @override
  ConsumerState<MockHubScreen> createState() => _MockHubScreenState();
}

class _MockHubScreenState extends ConsumerState<MockHubScreen> {
  String _selectedCategory = 'All';
  String _selectedLevel = 'All Levels';
  String _selectedMockType = 'All Types';
  String _searchQuery = '';
  bool _isLoading = false;
  List<MockTestItem> _mockTests = [];

  final List<String> _topics = [
    'All',
    'Maths',
    'GK',
    'GA',
    'English',
    'Technical',
    'Full Mock',
  ];

  final List<String> _levels = [
    'All Levels',
    'Easy',
    'Medium',
    'Hard',
  ];

  final List<String> _mockTypes = [
    'All Types',
    '5 Questions',
    '10 Questions',
    '20 Questions',
    'Full Mock',
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

    // General Knowledge (GK)
    MockTestItem(
      id: 'mock_gk_arunachal',
      title: 'Arunachal Pradesh State GK & Culture High-Yield Mock',
      category: 'GK',
      examCode: 'APSSB-CGLE',
      questionCount: 20,
      durationMinutes: 15,
      difficulty: 'Medium',
      description: 'Tribes, festivals, geography, rivers, state symbols, and historical milestones of Arunachal.',
    ),
    MockTestItem(
      id: 'mock_gk_polity',
      title: 'Indian Polity & Constitution Practice Test',
      category: 'GK',
      examCode: 'APPSC-CCE',
      questionCount: 25,
      durationMinutes: 20,
      difficulty: 'Medium',
      description: 'Fundamental rights, Parliament, Governor powers, and state constitutional provisions.',
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

  @override
  Widget build(BuildContext context) {
    final filteredMocks = _mockTests.where((test) {
      if (_selectedCategory != 'All' && test.category != _selectedCategory) {
        return false;
      }
      if (_selectedLevel != 'All Levels' && test.difficulty.toLowerCase() != _selectedLevel.toLowerCase()) {
        return false;
      }
      if (_selectedMockType == '5 Questions' && test.questionCount > 8) {
        return false;
      }
      if (_selectedMockType == '10 Questions' && (test.questionCount < 8 || test.questionCount > 15)) {
        return false;
      }
      if (_selectedMockType == '20 Questions' && (test.questionCount < 15 || test.questionCount > 35)) {
        return false;
      }
      if (_selectedMockType == 'Full Mock' && test.questionCount < 35 && test.category != 'Full Mock') {
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
      appBar: AppBar(
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
                    const SizedBox(height: AppSpacing.s),
                    // 3 Dropdown Filters: Level, Topic, Mock Type
                    Row(
                      children: [
                        // 1. Question Level Dropdown
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusM),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedLevel,
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary, size: 18),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                items: _levels.map((lvl) {
                                  return DropdownMenuItem(value: lvl, child: Text(lvl, overflow: TextOverflow.ellipsis));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedLevel = val);
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // 2. Topic Dropdown
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusM),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedCategory,
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary, size: 18),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                items: _topics.map((t) {
                                  return DropdownMenuItem(value: t, child: Text(t == 'All' ? 'All Topics' : t, overflow: TextOverflow.ellipsis));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedCategory = val);
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // 3. Mock Type Dropdown
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusM),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedMockType,
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary, size: 18),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                items: _mockTypes.map((mt) {
                                  return DropdownMenuItem(value: mt, child: Text(mt, overflow: TextOverflow.ellipsis));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedMockType = val);
                                },
                              ),
                            ),
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

            // Test Metrics Row
            Row(
              children: [
                const Icon(Icons.help_outline_rounded, size: 14, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(
                  '${test.questionCount} Qs',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.timer_outlined, size: 14, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(
                  '${test.durationMinutes} mins',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 12),
                const Text(
                  '+2 / -0.5 APSSB Marking',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textHint),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Start Mock Button - Full width, clean padding, no overflow
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final targetCount = _selectedMockType == '5 Questions'
                      ? '5'
                      : _selectedMockType == '10 Questions'
                          ? '10'
                          : _selectedMockType == '20 Questions'
                              ? '20'
                              : 'full';
                  context.push('/mock-test/${test.examCode}/$targetCount');
                },
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
