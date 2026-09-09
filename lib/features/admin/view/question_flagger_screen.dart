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

  // Filters state - default Status is 'all' so admin immediately sees database records
  String _selectedStatus = 'all'; // 'all', 'unreviewed', 'flagged', 'approved'
  String _selectedType = 'All'; // 'All', 'PYQ', 'Mock Test'
  String _selectedYear = 'All'; // 'All', '2024', '2023', '2022', '2021'
  String _selectedSubject = 'All';
  String _searchQuery = '';

  final List<String> _statuses = ['all', 'unreviewed', 'flagged', 'approved'];
  final List<String> _types = ['All', 'PYQ', 'Mock Test'];
  final List<String> _years = [
    'All',
    '2026',
    '2025',
    '2024',
    '2023',
    '2022',
    '2021',
    '2019',
  ];
  final List<String> _subjects = [
    'All',
    'Elementary Maths',
    'General Studies',
    'General English',
    'Logical Reasoning',
    'Reading Comprehension',
    'Civil Engineering',
  ];

  // Defect issue categories catalog
  static const List<Map<String, String>> issueCatalog = [
    {'id': 'correct', 'label': '✅ Correct / Verified'},
    {'id': 'wrong_answer_key', 'label': '🎯 Wrong Correct Answer Key'},
    {'id': 'explanation_wrong', 'label': '❌ Explanation / Solution Wrong'},
    {'id': 'missing_solution', 'label': '⚠️ Missing Explanation / Solution'},
    {'id': 'question_text_wrong', 'label': '❌ Question Text Wrong / Mangled OCR'},
    {'id': 'options_wrong', 'label': '❌ Options Wrong / Merged Options'},
    {'id': 'dummy_placeholders', 'label': '⚠️ Dummy Placeholders (Option A, B...)'},
    {'id': 'next_question_bleed', 'label': '🩸 Next Question Bleed Inside Option'},
    {'id': 'wrong_passage_direction', 'label': '🔀 Wrong / Irrelevant Passage Direction'},
    {'id': 'missing_image', 'label': '🖼️ Missing Chart / Person Image'},
    {'id': 'other', 'label': '❓ Other Issue'},
  ];

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // State
  List<Question> _questions = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 0;
  static const int _pageSize = 25;
  bool _dbNeedsMigration = false;

  // Local admin notes & expanded state tracking
  final Map<String, String> _questionAdminNotes = {};
  final Set<String> _collapsedPassages = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchQuestions(reset: true);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 250) {
      if (!_isLoading && !_isLoadingMore && _hasMore) {
        _fetchQuestions(reset: false);
      }
    }
  }

  Future<void> _fetchQuestions({bool reset = false}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _currentPage = 0;
        _questions = [];
        _hasMore = true;
      });
    } else {
      if (_isLoadingMore || !_hasMore) return;
      setState(() => _isLoadingMore = true);
    }

    try {
      final offset = _currentPage * _pageSize;
      final bool needsInnerJoin = (_selectedType != 'All' || _selectedYear != 'All');
      final String testsJoin = needsInnerJoin ? 'tests!inner(*)' : 'tests(*)';
      var baseUrl = '$_supabaseUrl/rest/v1/questions?select=*,question_groups(*),$testsJoin';

      // 1. Type filter
      if (_selectedType == 'PYQ') {
        baseUrl += '&tests.paper_type=eq.PYQ';
      } else if (_selectedType == 'Mock Test') {
        baseUrl += '&tests.paper_type=eq.MOCK';
      }

      // 2. Year filter
      if (_selectedYear != 'All') {
        baseUrl += '&tests.year=eq.$_selectedYear';
      }

      // 3. Subject filter with smart multi-variant matching
      if (_selectedSubject != 'All') {
        if (_selectedSubject == 'Elementary Maths') {
          baseUrl +=
              '&or=(subject.ilike.*Math*,subject.ilike.*Quantitative*,subject.ilike.*Arithmetic*)';
        } else if (_selectedSubject == 'Logical Reasoning') {
          baseUrl += '&or=(subject.ilike.*Reasoning*,subject.ilike.*Logical*)';
        } else if (_selectedSubject == 'General English') {
          baseUrl +=
              '&or=(subject.ilike.*English*,subject.ilike.*Grammar*,subject.ilike.*Vocab*)';
        } else {
          baseUrl +=
              '&subject=ilike.*${Uri.encodeComponent(_selectedSubject)}*';
        }
      }

      // 4. Quick Search query
      if (_searchQuery.trim().isNotEmpty) {
        baseUrl += '&question_text=ilike.*${Uri.encodeComponent(_searchQuery.trim())}*';
      }

      // 5. Status filter query
      String statusQuery = '';
      if (!_dbNeedsMigration) {
        if (_selectedStatus == 'unreviewed') {
          statusQuery = '&or=(review_status.eq.unreviewed,review_status.is.null)';
        } else if (_selectedStatus != 'all') {
          statusQuery = '&review_status=eq.$_selectedStatus';
        }
      }

      final paginationAndOrder = '&order=created_at.desc.nullslast,id.asc&limit=$_pageSize&offset=$offset';
      var requestUrl = '$baseUrl$statusQuery$paginationAndOrder';

      debugPrint('[QuestionFlagger] Fetching: $requestUrl');
      var res = await http.get(
        Uri.parse(requestUrl),
        headers: {
          'apikey': _supabaseKey,
          'Authorization': 'Bearer $_supabaseKey',
          'Range': '$offset-${offset + _pageSize - 1}',
          'Range-Unit': 'items',
          'Prefer': 'return=representation',
        },
      ).timeout(const Duration(seconds: 10));

      // Resilient fallback: if Supabase returns 400 because review_status column does not exist yet
      if (res.statusCode == 400 && (res.body.contains('review_status') || statusQuery.isNotEmpty)) {
        debugPrint('[QuestionFlagger] review_status column not found on questions table. Retrying without status filter...');
        _dbNeedsMigration = true;
        requestUrl = '$baseUrl$paginationAndOrder';
        res = await http.get(
          Uri.parse(requestUrl),
          headers: {
            'apikey': _supabaseKey,
            'Authorization': 'Bearer $_supabaseKey',
            'Range': '$offset-${offset + _pageSize - 1}',
            'Range-Unit': 'items',
            'Prefer': 'return=representation',
          },
        ).timeout(const Duration(seconds: 10));
      }

      debugPrint('[QuestionFlagger] HTTP Status: ${res.statusCode}, Body Length: ${res.body.length}');
      if (res.statusCode >= 400) {
        debugPrint('[QuestionFlagger] Postgres/Supabase Error: ${res.body}');
      }

      if (res.statusCode == 200 || res.statusCode == 206) {
        final List raw = jsonDecode(res.body);
        List<Question> parsed = raw.map((m) {
          final q = Question.fromSupabase(m as Map<String, dynamic>);
          if (m['admin_notes'] != null && m['admin_notes'].toString().isNotEmpty) {
            _questionAdminNotes[q.id] = m['admin_notes'].toString();
          }
          return q;
        }).toList();

        // In-memory status filter if review_status column is absent in DB
        if (_dbNeedsMigration && _selectedStatus != 'all') {
          if (_selectedStatus == 'unreviewed') {
            // All rows are treated as unreviewed
          } else {
            // Flagged or approved questions cannot exist until column is present
            parsed = [];
          }
        }

        debugPrint('[QuestionFlagger] Successfully loaded ${parsed.length} questions from Supabase.');
        setState(() {
          if (reset) {
            _questions = parsed;
          } else {
            _questions.addAll(parsed);
          }
          _currentPage++;
          _hasMore = raw.length == _pageSize;
          _isLoading = false;
          _isLoadingMore = false;
        });
      } else {
        _fallbackLocalQuestions(reset: reset);
      }
    } catch (e, stack) {
      debugPrint('[QuestionFlagger] Error fetching questions: $e');
      debugPrint(stack.toString());
      _fallbackLocalQuestions(reset: reset);
    }
  }

  void _fallbackLocalQuestions({bool reset = false}) {
    final local = QuestionRepository.allQuestions.where((q) {
      if (_selectedStatus != 'all' && q.reviewStatus.toLowerCase() != _selectedStatus.toLowerCase()) {
        return false;
      }
      if (_selectedType == 'PYQ' && q.paperType.toUpperCase() != 'PYQ') return false;
      if (_selectedType == 'Mock Test' && q.paperType.toUpperCase() != 'MOCK') return false;
      if (_selectedYear != 'All' && q.year.toString() != _selectedYear) return false;
      if (_selectedSubject != 'All' && !q.subject.toLowerCase().contains(_selectedSubject.toLowerCase())) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return q.questionText.toLowerCase().contains(query) ||
            q.options.any((o) => o.toLowerCase().contains(query)) ||
            q.id.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    setState(() {
      _questions = local;
      _isLoading = false;
      _isLoadingMore = false;
      _hasMore = false;
    });
  }

  // ─── Direct Action 1: Mark Correct / Approved ─────────────────────────────
  Future<void> _markCorrect(Question q) async {
    // 1. Optimistic UI update immediately
    final updated = q.copyWith(
      reviewStatus: 'approved',
      flagReasons: const [],
    );

    setState(() {
      final idx = _questions.indexWhere((item) => item.id == q.id);
      if (idx != -1) {
        _questions[idx] = updated;
      }
    });

    try {
      final now = DateTime.now().toIso8601String();

      // Supabase: questions table update
      final patchUrl = '$_supabaseUrl/rest/v1/questions?id=eq.${q.id}';
      final patchRes = await http.patch(
        Uri.parse(patchUrl),
        headers: {
          'apikey': _supabaseKey,
          'Authorization': 'Bearer $_supabaseKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'review_status': 'approved',
          'flagged_issues': [],
          'flag_reasons': [],
          'last_reviewed_at': now,
        }),
      ).timeout(const Duration(seconds: 6));

      if (patchRes.statusCode >= 400 && patchRes.body.contains('review_status')) {
        setState(() => _dbNeedsMigration = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Marked in session. Run migrations/003_admin_flagger.sql in Supabase to persist!'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // Supabase: question_flags audit log
      final flagUrl = '$_supabaseUrl/rest/v1/question_flags';
      await http.post(
        Uri.parse(flagUrl),
        headers: {
          'apikey': _supabaseKey,
          'Authorization': 'Bearer $_supabaseKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'question_id': q.id,
          'issue_category': 'correct',
          'issue_type': 'correct',
          'notes': 'Manually verified valid by admin',
          'resolved': true,
          'created_at': now,
        }),
      ).timeout(const Duration(seconds: 6));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Question marked as Correct / Approved!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('[QuestionFlagger] Error marking correct: $e');
    }
  }

  // ─── Direct Action 2: Flag Issue with Category ────────────────────────────
  Future<void> _flagIssue(Question q, String issueCategory, {String? notes}) async {
    if (issueCategory == 'correct') {
      await _markCorrect(q);
      return;
    }

    // 1. Optimistic UI update immediately
    final existingReasons = List<String>.from(q.flagReasons);
    if (!existingReasons.contains(issueCategory)) {
      existingReasons.add(issueCategory);
    }

    final updated = q.copyWith(
      reviewStatus: 'flagged',
      flagReasons: existingReasons,
    );

    setState(() {
      final idx = _questions.indexWhere((item) => item.id == q.id);
      if (idx != -1) {
        _questions[idx] = updated;
      }
      if (notes != null && notes.isNotEmpty) {
        _questionAdminNotes[q.id] = notes;
      }
    });

    try {
      final now = DateTime.now().toIso8601String();

      // Supabase: questions table update
      final patchUrl = '$_supabaseUrl/rest/v1/questions?id=eq.${q.id}';
      final patchBody = {
        'review_status': 'flagged',
        'flagged_issues': existingReasons,
        'flag_reasons': existingReasons,
        'last_reviewed_at': now,
      };
      if (notes != null && notes.isNotEmpty) {
        patchBody['admin_notes'] = notes;
      }

      final patchRes = await http.patch(
        Uri.parse(patchUrl),
        headers: {
          'apikey': _supabaseKey,
          'Authorization': 'Bearer $_supabaseKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(patchBody),
      ).timeout(const Duration(seconds: 6));

      if (patchRes.statusCode >= 400 && patchRes.body.contains('review_status')) {
        setState(() => _dbNeedsMigration = true);
        if (mounted) {
          final label = issueCatalog.firstWhere((i) => i['id'] == issueCategory, orElse: () => {'label': issueCategory})['label'];
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ $label (Flagged in session. Run migrations/003_admin_flagger.sql to persist)'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // Supabase: question_flags audit insert
      final flagUrl = '$_supabaseUrl/rest/v1/question_flags';
      await http.post(
        Uri.parse(flagUrl),
        headers: {
          'apikey': _supabaseKey,
          'Authorization': 'Bearer $_supabaseKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'question_id': q.id,
          'issue_category': issueCategory,
          'issue_type': issueCategory,
          'notes': notes ?? 'Flagged via Admin Review Feed',
          'resolved': false,
          'created_at': now,
        }),
      ).timeout(const Duration(seconds: 6));

      if (mounted) {
        final label = issueCatalog.firstWhere((i) => i['id'] == issueCategory, orElse: () => {'label': issueCategory})['label'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Flagged: $label'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('[QuestionFlagger] Error flagging issue: $e');
    }
  }

  // Helper to strip leading option labels like (a), a., a), {A}, etc.
  String _stripOptionPrefix(String opt) {
    return opt
        .replaceFirst(
            RegExp(r'^\s*[\(\{\[\<\|]?[a-dA-D][\)\}\]\>\|\.\s]\s*'), '')
        .trim();
  }

  // ─── Direct Action 3: Quick Edit & Notes Dialog ───────────────────────────
  void _showQuickEditDialog(Question q) {
    final noteController =
        TextEditingController(text: _questionAdminNotes[q.id] ?? '');
    final questionTextController = TextEditingController(text: q.questionText);

    // Prepare 4 clean option controllers
    final optA =
        q.options.isNotEmpty ? _stripOptionPrefix(q.options[0]) : '';
    final optB =
        q.options.length > 1 ? _stripOptionPrefix(q.options[1]) : '';
    final optC =
        q.options.length > 2 ? _stripOptionPrefix(q.options[2]) : '';
    final optD =
        q.options.length > 3 ? _stripOptionPrefix(q.options[3]) : '';

    final optAController = TextEditingController(text: optA);
    final optBController = TextEditingController(text: optB);
    final optCController = TextEditingController(text: optC);
    final optDController = TextEditingController(text: optD);

    final solutionController = TextEditingController(
      text: (q.solution.isNotEmpty &&
              q.solution != 'Verified with official key.')
          ? q.solution
          : '',
    );

    String selectedCorrect = q.correctAnswer.toLowerCase();
    if (!['a', 'b', 'c', 'd'].contains(selectedCorrect)) {
      selectedCorrect = 'a';
    }

    String selectedStatus = 'approved';

    final directionController =
        TextEditingController(text: q.directionText ?? '');
    final passageController =
        TextEditingController(text: q.passageOrDirection ?? '');
    final imageUrlController =
        TextEditingController(text: q.imageUrl ?? q.questionImage ?? '');
    final topicController = TextEditingController(text: q.topic ?? '');
    String selectedFormat = q.contentFormat;
    if (!['text', 'latex', 'image_only'].contains(selectedFormat)) {
      selectedFormat = 'text';
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          title: Row(
            children: [
              const Icon(Icons.edit_note_rounded,
                  color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Edit & Fix Question • Q${q.questionNumber > 0 ? q.questionNumber : q.id.substring(0, 4)}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 580,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Direction / Instructions Field
                  const Text('Direction / Instructions (Optional):',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: directionController,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 12),
                    decoration: const InputDecoration(
                      hintText: 'e.g. Direction (Q. 1 to 5): Choose the correct antonym...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. Passage / Comprehension Field
                  const Text('Passage / Reading Context (Optional):',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: passageController,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 12),
                    decoration: const InputDecoration(
                      hintText: 'Enter full reading comprehension text...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. Question Prompt Field
                  const Text('Question Text / Prompt:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: questionTextController,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      hintText: 'Enter clean question text...',
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 4. Options A-D Fields
                  const Text('Options (a–d):',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 6),
                  _buildOptionEditField('A', optAController),
                  const SizedBox(height: 6),
                  _buildOptionEditField('B', optBController),
                  const SizedBox(height: 6),
                  _buildOptionEditField('C', optCController),
                  const SizedBox(height: 6),
                  _buildOptionEditField('D', optDController),
                  const SizedBox(height: 12),

                  // 5. Topic, Content Format & Image URL Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Topic (Optional):',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: topicController,
                              style: const TextStyle(fontSize: 12),
                              decoration: const InputDecoration(
                                hintText: 'e.g. Ancient History',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Format / Math:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 6),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: selectedFormat,
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'text',
                                        child: Text('Standard Text')),
                                    DropdownMenuItem(
                                        value: 'latex',
                                        child: Text('📐 LaTeX Math')),
                                    DropdownMenuItem(
                                        value: 'image_only',
                                        child: Text('🖼️ Image Only')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setDialogState(
                                          () => selectedFormat = val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 6. Image URL Field
                  const Text('Question Image URL (Optional):',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: imageUrlController,
                    style: const TextStyle(fontSize: 12),
                    decoration: const InputDecoration(
                      hintText: 'https://... or image filename',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 7. Correct Answer & Status Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Correct Option:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 6),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: selectedCorrect,
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'a',
                                        child: Text('Option (A)')),
                                    DropdownMenuItem(
                                        value: 'b',
                                        child: Text('Option (B)')),
                                    DropdownMenuItem(
                                        value: 'c',
                                        child: Text('Option (C)')),
                                    DropdownMenuItem(
                                        value: 'd',
                                        child: Text('Option (D)')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setDialogState(
                                          () => selectedCorrect = val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Review Status:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 6),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: selectedStatus,
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'approved',
                                        child: Text('✅ Approved')),
                                    DropdownMenuItem(
                                        value: 'flagged',
                                        child: Text('⚠️ Flagged')),
                                    DropdownMenuItem(
                                        value: 'unreviewed',
                                        child: Text('⚪ Unreviewed')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setDialogState(
                                          () => selectedStatus = val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 8. Explanation / Solution
                  const Text('Explanation / Solution:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: solutionController,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 12),
                    decoration: const InputDecoration(
                      hintText:
                          'Enter solution or explanation for candidates...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 9. Admin Notes
                  const Text('Admin Note (Stored in admin_notes):',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: noteController,
                    maxLines: 1,
                    style: const TextStyle(fontSize: 12),
                    decoration: const InputDecoration(
                      hintText:
                          'e.g. Cleaned option leak and verified answer key',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final newNotes = noteController.text.trim();
                final newQText = questionTextController.text.trim();
                final newDirection = directionController.text.trim();
                final newPassage = passageController.text.trim();
                final newImageUrl = imageUrlController.text.trim();
                final newTopic = topicController.text.trim();
                final cleanOptions = [
                  '(a) ${optAController.text.trim()}',
                  '(b) ${optBController.text.trim()}',
                  '(c) ${optCController.text.trim()}',
                  '(d) ${optDController.text.trim()}',
                ];
                final newSolution =
                    solutionController.text.trim().isNotEmpty
                        ? solutionController.text.trim()
                        : 'Verified with official key.';

                Navigator.pop(ctx);

                // Update in Supabase
                try {
                  final patchUrl =
                      '$_supabaseUrl/rest/v1/questions?id=eq.${q.id}';
                  final patchPayload = <String, dynamic>{
                    'question_text': newQText,
                    'options': cleanOptions,
                    'correct_answer': selectedCorrect,
                    'correct_option': selectedCorrect,
                    'explanation': newSolution,
                    'admin_notes': newNotes,
                    'review_status': selectedStatus,
                    'direction_text': newDirection.isNotEmpty ? newDirection : null,
                    'content_format': selectedFormat,
                    'topic': newTopic.isNotEmpty ? newTopic : null,
                    if (newImageUrl.isNotEmpty) 'question_image_url': newImageUrl,
                    'flagged_issues': selectedStatus == 'approved'
                        ? []
                        : q.flagReasons,
                    'last_reviewed_at': DateTime.now().toIso8601String(),
                  };

                  final patchRes = await http.patch(
                    Uri.parse(patchUrl),
                    headers: {
                      'apikey': _supabaseKey,
                      'Authorization': 'Bearer $_supabaseKey',
                      'Content-Type': 'application/json',
                    },
                    body: jsonEncode(patchPayload),
                  );

                  // Resilient fallback if schema update is still pending
                  if (patchRes.statusCode >= 400) {
                    await http.patch(
                      Uri.parse(patchUrl),
                      headers: {
                        'apikey': _supabaseKey,
                        'Authorization': 'Bearer $_supabaseKey',
                        'Content-Type': 'application/json',
                      },
                      body: jsonEncode({
                        'question_text': newQText,
                        'options': cleanOptions,
                        'correct_answer': selectedCorrect,
                        'explanation': newSolution,
                      }),
                    );
                  }

                  setState(() {
                    _questionAdminNotes[q.id] = newNotes;
                    final idx =
                        _questions.indexWhere((item) => item.id == q.id);
                    if (idx != -1) {
                      _questions[idx] = q.copyWith(
                        questionText: newQText,
                        options: cleanOptions,
                        correctAnswer: selectedCorrect,
                        solution: newSolution,
                        directionText: newDirection.isNotEmpty ? newDirection : null,
                        passageOrDirection: newPassage.isNotEmpty ? newPassage : null,
                        imageUrl: newImageUrl.isNotEmpty ? newImageUrl : null,
                        questionImage: newImageUrl.isNotEmpty ? newImageUrl : null,
                        contentFormat: selectedFormat,
                        topic: newTopic.isNotEmpty ? newTopic : null,
                        reviewStatus: selectedStatus,
                        flagReasons: selectedStatus == 'approved'
                            ? const []
                            : q.flagReasons,
                        adminNotes: newNotes,
                      );
                    }
                  });

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          selectedStatus == 'approved'
                              ? 'Saved to Supabase and marked Approved!'
                              : 'Question updated in Supabase successfully!',
                        ),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint('Quick edit error: $e');
                }
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              icon: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 16),
              label: const Text('Save to Database',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionEditField(
      String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 12.5),
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            '($label)',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 36, minHeight: 0),
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    );
  }

  void _showImageZoomDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Failed to load image from URL', style: TextStyle(color: AppColors.error)),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.black87),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
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
                  'Admin Question Review & Flagger',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            Text(
              'Audit raw DB questions, verify correctness, or flag OCR defects',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            tooltip: 'Refresh Feed',
            onPressed: () => _fetchQuestions(reset: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Top Filter Bar (Sticky Header) ─────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Column(
              children: [
                // Quick Search input
                TextField(
                  controller: _searchController,
                  onSubmitted: (val) {
                    _searchQuery = val;
                    _fetchQuestions(reset: true);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by question text or ID (Press Enter)...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textHint),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _searchQuery = '';
                              _fetchQuestions(reset: true);
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

                // Dropdown Filter Chips Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // 1. Status Filter
                      _buildDropdownFilter(
                        label: 'Status',
                        value: _selectedStatus,
                        items: _statuses,
                        formatDisplay: (val) => val == 'all' ? 'Status: All' : 'Status: ${val.toUpperCase()}',
                        onChanged: (v) {
                          setState(() => _selectedStatus = v!);
                          _fetchQuestions(reset: true);
                        },
                      ),
                      const SizedBox(width: 8),

                      // 2. Type Filter
                      _buildDropdownFilter(
                        label: 'Type',
                        value: _selectedType,
                        items: _types,
                        formatDisplay: (val) => val == 'All' ? 'Type: All' : 'Type: $val',
                        onChanged: (v) {
                          setState(() => _selectedType = v!);
                          _fetchQuestions(reset: true);
                        },
                      ),
                      const SizedBox(width: 8),

                      // 3. Subject Filter
                      _buildDropdownFilter(
                        label: 'Subject',
                        value: _selectedSubject,
                        items: _subjects,
                        formatDisplay: (val) => val == 'All' ? 'Subject: All' : val,
                        onChanged: (v) {
                          setState(() => _selectedSubject = v!);
                          _fetchQuestions(reset: true);
                        },
                      ),
                      const SizedBox(width: 8),

                      // 4. Year Filter
                      _buildDropdownFilter(
                        label: 'Year',
                        value: _selectedYear,
                        items: _years,
                        formatDisplay: (val) => val == 'All' ? 'Year: All' : 'Year: $val',
                        onChanged: (v) {
                          setState(() => _selectedYear = v!);
                          _fetchQuestions(reset: true);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
          const Divider(height: 1, color: AppColors.divider),
          if (_dbNeedsMigration) _buildMigrationBanner(),

          // ─── Status Summary Banner ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFF8FAFC),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_questions.length} questions loaded • Filter: ${_selectedStatus.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 11.5,
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
                    _hasMore ? 'Scroll for more' : 'All questions loaded',
                    style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                  ),
              ],
            ),
          ),

          // ─── Question List Feed with Infinite Scroll ────────────────────
          Expanded(
            child: _isLoading && _questions.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _questions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, size: 48, color: AppColors.success),
                            const SizedBox(height: 12),
                            Text(
                              'No questions matching "$_selectedStatus"',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Try selecting another status (e.g. All Questions) or clear search.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedStatus = 'all';
                                  _selectedType = 'All';
                                  _selectedYear = 'All';
                                  _selectedSubject = 'All';
                                  _searchQuery = '';
                                  _searchController.clear();
                                });
                                _fetchQuestions(reset: true);
                              },
                              child: const Text('Reset All Filters'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _fetchQuestions(reset: true),
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                          itemCount: _questions.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _questions.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            final q = _questions[index];
                            return Center(
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 960),
                                child: _buildQuestionCard(q, index),
                              ),
                            );
                          },
                        ),
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
    required String Function(String) formatDisplay,
    required ValueChanged<String?> onChanged,
  }) {
    final isSelected = value != 'all' && value != 'All' && value != 'unreviewed';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.divider,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
          ),
          icon: const Icon(Icons.arrow_drop_down_rounded, size: 18, color: AppColors.textHint),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(formatDisplay(item), style: const TextStyle(fontSize: 12)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ─── Question Card Builder ────────────────────────────────────────────────
  Widget _buildQuestionCard(Question q, int index) {
    final status = q.reviewStatus.toLowerCase();
    final isApproved = status == 'approved';
    final isFlagged = status == 'flagged';
    final isUnreviewed = status == 'unreviewed' || status.isEmpty;

    // Defect detection heuristics
    final textLower = q.questionText.toLowerCase();
    final mentionsMissingImage = (textLower.contains('figure') ||
            textLower.contains('chart') ||
            textLower.contains('diagram') ||
            textLower.contains('given below') ||
            textLower.contains('portrait') ||
            textLower.contains('graph') ||
            textLower.contains('table')) &&
        (q.imageUrl == null || q.imageUrl!.trim().isEmpty) &&
        (q.questionImage == null || q.questionImage!.trim().isEmpty);

    final isPassageCollapsed = _collapsedPassages.contains(q.id);

    return Card(
      key: ValueKey(q.id),
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isApproved
              ? AppColors.success.withValues(alpha: 0.5)
              : isFlagged
                  ? AppColors.error.withValues(alpha: 0.5)
                  : isUnreviewed
                      ? const Color(0xFFCBD5E1)
                      : AppColors.divider,
          width: isApproved || isFlagged ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header Row ───────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Q${q.questionNumber > 0 ? q.questionNumber : index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11.5,
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
                        '${q.examCode} ${q.year} • ${q.paperType}',
                        style: const TextStyle(fontSize: 10, color: AppColors.textHint),
                      ),
                      if (q.topic != null && q.topic!.trim().isNotEmpty) ...[
                        Text(
                          ' • ${q.topic}',
                          style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                      ],
                      if (q.contentFormat == 'latex') ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE9FE),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('📐 LaTeX',
                              style: TextStyle(fontSize: 9, color: Color(0xFF6D28D9), fontWeight: FontWeight.bold)),
                        ),
                      ] else if (q.contentFormat == 'image_only') ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('🖼️ Image',
                              style: TextStyle(fontSize: 9, color: Color(0xFF0369A1), fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
            const SizedBox(height: 10),

            // ─── Flagged Issues Badges ────────────────────────────────────
            if (q.flagReasons.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: q.flagReasons.map((r) {
                  final item = issueCatalog.firstWhere(
                    (i) => i['id'] == r,
                    orElse: () => {'label': r.replaceAll('_', ' ')},
                  );
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      item['label'] ?? r,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
            ],

            // ─── Linked Passage Box (Collapsible) ─────────────────────────
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
                    Row(
                      children: [
                        const Icon(Icons.menu_book_rounded, size: 13, color: AppColors.primary),
                        const SizedBox(width: 6),
                        const Text(
                          'Passage / Comprehension Box',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () {
                            setState(() {
                              if (isPassageCollapsed) {
                                _collapsedPassages.remove(q.id);
                              } else {
                                _collapsedPassages.add(q.id);
                              }
                            });
                          },
                          child: Text(
                            isPassageCollapsed ? 'Expand ▾' : 'Collapse ▴',
                            style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    if (!isPassageCollapsed) ...[
                      const SizedBox(height: 6),
                      Text(
                        q.passageOrDirection!,
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textPrimary, height: 1.35),
                      ),
                      if (q.passageImage != null && q.passageImage!.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            q.passageImage!,
                            height: 140,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Text('Passage figure failed to load',
                                style: TextStyle(fontSize: 10, color: AppColors.error)),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // ─── Direction / Instruction Banner ───────────────────────────
            if (q.directionText != null &&
                q.directionText!.trim().isNotEmpty &&
                q.directionText != q.passageOrDirection) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        q.directionText!,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E40AF),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ─── Image Container (Preview or Missing Alert) ────────────────
            if (q.imageUrl != null && q.imageUrl!.trim().isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.image_rounded, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        const Text(
                          'Extracted Figure (Tap to zoom):',
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () => _showImageZoomDialog(q.imageUrl!),
                          child: const Text('Full View ⛶',
                              style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => _showImageZoomDialog(q.imageUrl!),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Center(
                          child: Image.network(
                            q.imageUrl!,
                            height: 130,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Padding(
                              padding: EdgeInsets.all(8),
                              child: Text('Image failed to load from URL', style: TextStyle(color: AppColors.error, fontSize: 11)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (mentionsMissingImage) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 15, color: Color(0xFFD97706)),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '⚠️ Potential missing image: Question text references a figure or chart, but image_url is empty.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF92400E), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ─── Question Prompt ──────────────────────────────────────────
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

            // ─── Options List (a, b, c, d) with Defect Highlighting ───────
            Column(
              children: List.generate(q.options.length, (optIdx) {
                final opt = q.options[optIdx];
                final optChar = _extractOptionChar(opt, optIdx);
                final isCorrect = optChar.toLowerCase() == q.correctAnswer.toLowerCase();

                // Detect defects inside option
                final isEmpty = opt.trim().isEmpty;
                final isDummy = RegExp(r'^Option\s+[A-D]$', caseSensitive: false).hasMatch(opt.trim());
                final isMerged = RegExp(r'[\(\[]?[b-d][\)\]\.\s]').hasMatch(opt) && optIdx == 0;
                final isBleed = RegExp(r'(?:\b\d{1,3}\.\s|Q\d+|\bDirection\b|\bPassage\b)', caseSensitive: false).hasMatch(opt);

                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? AppColors.success.withValues(alpha: 0.08)
                        : (isEmpty || isDummy || isMerged || isBleed)
                            ? const Color(0xFFFEF2F2)
                            : const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCorrect
                          ? AppColors.success
                          : (isMerged || isBleed)
                              ? AppColors.error
                              : isDummy
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFFE5E7EB),
                      width: isCorrect || isMerged || isBleed ? 1.3 : 1,
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              opt,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isCorrect ? FontWeight.w600 : FontWeight.normal,
                                color: isCorrect ? AppColors.success : AppColors.textPrimary,
                              ),
                            ),
                            // Defect warning tags
                            if (isEmpty)
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Text('⚠️ Empty Option',
                                    style: TextStyle(fontSize: 9.5, color: AppColors.error, fontWeight: FontWeight.bold)),
                              ),
                            if (isDummy)
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Text('⚠️ Dummy Placeholder (e.g. Option A)',
                                    style: TextStyle(fontSize: 9.5, color: Color(0xFFD97706), fontWeight: FontWeight.bold)),
                              ),
                            if (isMerged)
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Text('⚠️ Merged Options Leak (Contains (b) or (c))',
                                    style: TextStyle(fontSize: 9.5, color: AppColors.error, fontWeight: FontWeight.bold)),
                              ),
                            if (isBleed)
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Text('⚠️ Next Question Bleed Inside Option',
                                    style: TextStyle(fontSize: 9.5, color: AppColors.error, fontWeight: FontWeight.bold)),
                              ),
                            if (optIdx < q.optionImages.length &&
                                q.optionImages[optIdx] != null &&
                                q.optionImages[optIdx]!.trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  q.optionImages[optIdx]!,
                                  height: 75,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Text(
                                    'Option image load failed',
                                    style: TextStyle(
                                        color: AppColors.error, fontSize: 9.5),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (isCorrect)
                        const Row(
                          children: [
                            Text('Correct: ', style: TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.bold)),
                            Icon(Icons.check_circle_rounded, size: 15, color: AppColors.success),
                          ],
                        ),
                    ],
                  ),
                );
              }),
            ),

            // Correct Option Display
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Correct Option: (${q.correctAnswer.toUpperCase()})',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success),
                  ),
                ),
                const SizedBox(width: 8),
                if (_questionAdminNotes[q.id] != null && _questionAdminNotes[q.id]!.isNotEmpty) ...[
                  Expanded(
                    child: Text(
                      'Note: ${_questionAdminNotes[q.id]}',
                      style: const TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),

            // Explanation / Solution Box
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (q.solution.isNotEmpty &&
                        q.solution != 'Verified with official key.')
                    ? const Color(0xFFF8FAFC)
                    : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (q.solution.isNotEmpty &&
                          q.solution != 'Verified with official key.')
                      ? const Color(0xFFE2E8F0)
                      : const Color(0xFFFDE68A),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        (q.solution.isNotEmpty &&
                                q.solution != 'Verified with official key.')
                            ? Icons.lightbulb_outline_rounded
                            : Icons.warning_amber_rounded,
                        size: 14,
                        color: (q.solution.isNotEmpty &&
                                q.solution != 'Verified with official key.')
                            ? AppColors.primary
                            : const Color(0xFFD97706),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Explanation / Solution:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: (q.solution.isNotEmpty &&
                                  q.solution != 'Verified with official key.')
                              ? AppColors.primary
                              : const Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (q.solution.isNotEmpty &&
                            q.solution != 'Verified with official key.')
                        ? q.solution
                        : '⚠️ No detailed explanation/solution provided.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: (q.solution.isNotEmpty &&
                              q.solution != 'Verified with official key.')
                          ? AppColors.textPrimary
                          : const Color(0xFFB45309),
                      fontStyle: (q.solution.isNotEmpty &&
                              q.solution != 'Verified with official key.')
                          ? FontStyle.normal
                          : FontStyle.italic,
                    ),
                  ),
                  if (q.solutionImage != null && q.solutionImage!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        q.solutionImage!,
                        height: 130,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Text('Solution diagram load failed',
                            style: TextStyle(color: AppColors.error, fontSize: 10)),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 8),

            // ─── Flagging & Action Toolbar (Responsive Wrap) ─────────────
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // 1. Mark Correct Button (Green Checkmark)
                ElevatedButton.icon(
                  onPressed: () => _markCorrect(q),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isApproved ? AppColors.success : const Color(0xFFDCFCE7),
                    foregroundColor: isApproved ? Colors.white : AppColors.success,
                    elevation: 0,
                    side: const BorderSide(color: AppColors.success),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 15),
                  label: Text(
                    isApproved ? 'Approved ✓' : 'Mark Correct',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                ),

                // 2. Flag Issue Dropdown Menu
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: isFlagged ? const Color(0xFFFEE2E2) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isDense: true,
                      hint: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.flag_rounded, size: 14, color: AppColors.error),
                          SizedBox(width: 4),
                          Text('Flag Issue ▾', style: TextStyle(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      items: issueCatalog.map((item) {
                        return DropdownMenuItem<String>(
                          value: item['id'],
                          child: Text(
                            item['label']!,
                            style: const TextStyle(fontSize: 11.5, color: AppColors.textPrimary),
                          ),
                        );
                      }).toList(),
                      onChanged: (selectedIssue) {
                        if (selectedIssue != null) {
                          _flagIssue(q, selectedIssue);
                        }
                      },
                    ),
                  ),
                ),

                // 3. Edit & Fix Question Button
                OutlinedButton.icon(
                  onPressed: () => _showQuickEditDialog(q),
                  icon: const Icon(Icons.edit_rounded, size: 14),
                  label: const Text('Edit / Fix Question',
                      style:
                          TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side:
                        const BorderSide(color: AppColors.primary, width: 1.2),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
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
      case 'approved':
        bg = const Color(0xFFDCFCE7);
        fg = AppColors.success;
        icon = Icons.check_circle_rounded;
        break;
      case 'unreviewed':
      default:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
        icon = Icons.radio_button_unchecked_rounded;
        label = 'UNREVIEWED';
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

  Widget _buildMigrationBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFFFFFBEB),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Supabase Schema Update Pending',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Questions are loading in compatibility mode. To enable persistent DB flagging and status filters, run "migrations/003_admin_flagger.sql" in your Supabase SQL Editor.',
                  style: TextStyle(fontSize: 11, color: Color(0xFFB45309), height: 1.3),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF92400E)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            onPressed: () => setState(() => _dbNeedsMigration = false),
          ),
        ],
      ),
    );
  }
}
