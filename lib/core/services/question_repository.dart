import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class Question {
  final String id;
  final String
      examCode; // 'APSSB-CGLE', 'APSSB-CHSL', 'APSSB-CSLE', 'APSSB-UDC', 'APSSB-MOCK', etc.
  final int year; // 2021, 2019, 2023, 2024
  final String paperType; // 'PYQ' or 'MOCK'
  final String testId;
  final String testTitle;
  final String subject; // 'English', 'Mathematics', 'General Knowledge'
  final String difficulty;
  final String? groupId;
  final String? passageId;
  final String? passageOrDirection;
  final String? passageImage;
  final String questionText;
  final String? questionImage;
  final String? imageUrl;
  final bool hasImage;
  final String reviewStatus; // 'approved', 'flagged', 'needs_ocr_rerun'
  final List<String> flagReasons;
  final List<String> modeAvailability; // ['timed', 'study']
  final List<String> options; // ['(a) ...', '(b) ...']
  final List<String?> optionImages;
  final String correctAnswer; // 'a', 'b', 'c', 'd'
  final String officialAnswer;
  final String solution;
  final String? solutionImage;
  final int timeLimitMins;
  final double marksPerCorrect;
  final double negativeMarks;
  final bool isScenarioTest;
  final String? scenarioTags;
  final List<String> initialComments;
  final String? pyqText;
  final int questionNumber;

  const Question({
    required this.id,
    required this.examCode,
    required this.year,
    this.paperType = 'PYQ',
    this.testId = '',
    this.testTitle = '',
    required this.subject,
    this.difficulty = 'Medium',
    this.groupId,
    this.passageId,
    this.passageOrDirection,
    this.passageImage,
    required this.questionText,
    this.questionImage,
    this.imageUrl,
    this.hasImage = false,
    this.reviewStatus = 'approved',
    this.flagReasons = const [],
    this.modeAvailability = const ['timed', 'study'],
    required this.options,
    this.optionImages = const [null, null, null, null],
    required this.correctAnswer,
    required this.officialAnswer,
    required this.solution,
    this.solutionImage,
    this.timeLimitMins = 120,
    this.marksPerCorrect = 2.0,
    this.negativeMarks = 0.5,
    this.isScenarioTest = false,
    this.scenarioTags,
    this.initialComments = const [],
    this.pyqText,
    this.questionNumber = 0,
  });

  Question copyWith({
    String? id,
    String? examCode,
    int? year,
    String? paperType,
    String? testId,
    String? testTitle,
    String? subject,
    String? difficulty,
    String? groupId,
    String? passageId,
    String? passageOrDirection,
    String? passageImage,
    String? questionText,
    String? questionImage,
    String? imageUrl,
    bool? hasImage,
    String? reviewStatus,
    List<String>? flagReasons,
    List<String>? modeAvailability,
    List<String>? options,
    List<String?>? optionImages,
    String? correctAnswer,
    String? officialAnswer,
    String? solution,
    String? solutionImage,
    int? timeLimitMins,
    double? marksPerCorrect,
    double? negativeMarks,
    bool? isScenarioTest,
    String? scenarioTags,
    List<String>? initialComments,
    String? pyqText,
    int? questionNumber,
  }) {
    return Question(
      id: id ?? this.id,
      examCode: examCode ?? this.examCode,
      year: year ?? this.year,
      paperType: paperType ?? this.paperType,
      testId: testId ?? this.testId,
      testTitle: testTitle ?? this.testTitle,
      subject: subject ?? this.subject,
      difficulty: difficulty ?? this.difficulty,
      groupId: groupId ?? this.groupId,
      passageId: passageId ?? this.passageId,
      passageOrDirection: passageOrDirection ?? this.passageOrDirection,
      passageImage: passageImage ?? this.passageImage,
      questionText: questionText ?? this.questionText,
      questionImage: questionImage ?? this.questionImage,
      imageUrl: imageUrl ?? this.imageUrl,
      hasImage: hasImage ?? this.hasImage,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      flagReasons: flagReasons ?? this.flagReasons,
      modeAvailability: modeAvailability ?? this.modeAvailability,
      options: options ?? this.options,
      optionImages: optionImages ?? this.optionImages,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      officialAnswer: officialAnswer ?? this.officialAnswer,
      solution: solution ?? this.solution,
      solutionImage: solutionImage ?? this.solutionImage,
      timeLimitMins: timeLimitMins ?? this.timeLimitMins,
      marksPerCorrect: marksPerCorrect ?? this.marksPerCorrect,
      negativeMarks: negativeMarks ?? this.negativeMarks,
      isScenarioTest: isScenarioTest ?? this.isScenarioTest,
      scenarioTags: scenarioTags ?? this.scenarioTags,
      initialComments: initialComments ?? this.initialComments,
      pyqText: pyqText ?? this.pyqText,
      questionNumber: questionNumber ?? this.questionNumber,
    );
  }

  factory Question.fromMap(String docId, Map<String, dynamic> data) {
    // Parse options list
    List<String> parsedOptions = [];
    List<String?> parsedOptionImages = [null, null, null, null];

    if (data['options'] is List) {
      final rawList = data['options'] as List;
      for (int i = 0; i < rawList.length; i++) {
        final item = rawList[i];
        if (item is Map) {
          final prefix = item['key'] != null
              ? '(${item['key']}) '
              : '(${String.fromCharCode(97 + i)}) ';
          final text = item['text'] != null ? item['text'].toString() : '';
          parsedOptions.add(text.startsWith('(') ? text : '$prefix$text');
          if (i < 4 && item['image'] != null) {
            parsedOptionImages[i] = item['image'].toString();
          }
        } else if (item is String) {
          parsedOptions.add(item);
        }
      }
    }

    if (parsedOptions.isEmpty) {
      parsedOptions = [
        '(a) Option A',
        '(b) Option B',
        '(c) Option C',
        '(d) Option D'
      ];
    }

    final rawCorrect = (data['correctAnswer'] ?? 'a')
        .toString()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-d]'), '');
    final cleanCorrect = rawCorrect.isNotEmpty ? rawCorrect[0] : 'a';

    // Find official answer string
    String official = '($cleanCorrect)';
    final correctIdx = cleanCorrect.codeUnitAt(0) - 97;
    if (correctIdx >= 0 && correctIdx < parsedOptions.length) {
      official = parsedOptions[correctIdx];
    }

    final rawExamCode = (data['examCode'] ?? 'APSSB-CGLE').toString();
    final parsedYear = int.tryParse(data['year']?.toString() ?? '') ?? 2024;
    final paperType = (data['paperType'] ?? 'PYQ').toString();
    final testId = (data['testId'] ?? '').toString();
    final testTitle = (data['testTitle'] ?? '').toString();

    return Question(
      id: docId,
      examCode: rawExamCode,
      year: parsedYear,
      paperType: paperType,
      testId: testId,
      testTitle: testTitle,
      subject: (data['subject'] ?? 'General').toString(),
      difficulty: (data['difficulty'] ?? 'Medium').toString(),
      groupId: data['groupId']?.toString() ?? data['group_id']?.toString(),
      passageId: data['passageId']?.toString() ?? data['passage_id']?.toString(),
      passageOrDirection: data['passageOrDirection']?.toString() ??
          data['passage_or_direction']?.toString(),
      passageImage: data['passageImage']?.toString() ?? data['passage_image']?.toString(),
      questionText: (data['questionText'] ?? data['question_text'] ?? '').toString(),
      questionImage: data['questionImage']?.toString() ??
          data['question_image_url']?.toString() ??
          data['image_url']?.toString(),
      imageUrl: data['imageUrl']?.toString() ??
          data['image_url']?.toString() ??
          data['question_image_url']?.toString(),
      hasImage: data['hasImage'] == true ||
          data['has_image'] == true ||
          (data['image_url'] != null && data['image_url'].toString().trim().isNotEmpty),
      reviewStatus: (data['reviewStatus'] ?? data['review_status'] ?? 'approved').toString(),
      flagReasons: (data['flagReasons'] is List)
          ? (data['flagReasons'] as List).map((e) => e.toString()).toList()
          : (data['flag_reasons'] is List)
              ? (data['flag_reasons'] as List).map((e) => e.toString()).toList()
              : const [],
      modeAvailability: (data['modeAvailability'] is List)
          ? (data['modeAvailability'] as List).map((e) => e.toString()).toList()
          : (data['mode_availability'] is List)
              ? (data['mode_availability'] as List).map((e) => e.toString()).toList()
              : const ['timed', 'study'],
      options: parsedOptions,
      optionImages: parsedOptionImages,
      correctAnswer: cleanCorrect,
      officialAnswer: official,
      solution: (data['solution'] ?? data['explanation'] ?? '').toString(),
      solutionImage: data['solutionImage']?.toString() ??
          data['explanation_image_url']?.toString(),
      timeLimitMins: int.tryParse(data['timeLimitMins']?.toString() ?? '') ?? 120,
      marksPerCorrect: (data['marksPerCorrect'] as num?)?.toDouble() ?? 2.0,
      negativeMarks: (data['negativeMarks'] as num?)?.toDouble() ?? 0.5,
      isScenarioTest: data['isScenarioTest'] == true ||
          data['isScenarioTest']?.toString().toLowerCase() == 'true',
      scenarioTags: data['scenarioTags']?.toString(),
      initialComments: const [],
      pyqText: '[$rawExamCode $parsedYear]',
      questionNumber: int.tryParse(data['questionNumber']?.toString() ?? '') ??
          int.tryParse(data['question_number']?.toString() ?? '') ?? 0,
    );
  }

  factory Question.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return Question.fromMap(doc.id, data);
  }

  factory Question.fromSupabase(Map<String, dynamic> data) {
    final tests = data['tests'] as Map<String, dynamic>?;
    final passages = data['passages'] as Map<String, dynamic>?;
    final groups = data['question_groups'] as Map<String, dynamic>?;

    final rawExamCode = tests?['exam_code']?.toString() ?? 'APPSC';
    final parsedYear = tests?['year'] as int? ?? 2024;
    final paperType = tests?['paper_type']?.toString() ?? 'PYQ';
    final testId = data['test_id']?.toString() ?? '';
    final testTitle = tests?['title']?.toString() ?? '';
    final qNum = (data['order_index'] as int?) ??
        (data['question_number'] as int?) ??
        int.tryParse(data['question_number']?.toString() ?? '') ?? 0;

    // Options parsing from JSONB array
    List<String> parsedOptions = [];
    List<String?> parsedOptionImages = [null, null, null, null];
    if (data['options'] is List) {
      final list = data['options'] as List;
      for (int i = 0; i < list.length; i++) {
        final item = list[i];
        if (item is Map) {
          final id = (item['key'] ?? item['id'] ?? String.fromCharCode(97 + i)).toString();
          final text = (item['text'] ?? item['value'] ?? '').toString().trim();
          if (text.isNotEmpty && !RegExp(r'^Option\s+[A-D]$', caseSensitive: false).hasMatch(text)) {
            parsedOptions.add(text.startsWith('(') ? text : '($id) $text');
            if (i < 4 && item['image'] != null) {
              parsedOptionImages[i] = item['image'].toString();
            }
          }
        } else if (item is String && item.trim().isNotEmpty) {
          final text = item.trim();
          if (!RegExp(r'^Option\s+[A-D]$', caseSensitive: false).hasMatch(text)) {
            parsedOptions.add(text);
          }
        }
      }
    }

    final rawCorrect = (data['correct_option'] ?? data['correct_answer'] ?? 'a')
        .toString()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-d]'), '');
    final cleanCorrect = rawCorrect.isNotEmpty ? rawCorrect[0] : 'a';

    String official = '($cleanCorrect)';
    final correctIdx = cleanCorrect.codeUnitAt(0) - 97;
    if (correctIdx >= 0 && correctIdx < parsedOptions.length) {
      official = parsedOptions[correctIdx];
    }

    // Passage / Direction handling
    String? passageText;
    String? passageImage;
    String? passageId = data['passage_id']?.toString();

    if (passages != null) {
      passageText = passages['content']?.toString();
      passageImage = passages['image_url']?.toString();
      passageId ??= passages['id']?.toString();
    } else if (groups != null) {
      final gTitle = groups['title']?.toString();
      final pText = groups['passage_text']?.toString();
      final gInst = groups['instructions']?.toString();
      final parts = [
        if (gTitle != null && gTitle.isNotEmpty) gTitle,
        if (gInst != null && gInst.isNotEmpty) gInst,
        if (pText != null && pText.isNotEmpty) pText,
      ];
      if (parts.isNotEmpty) {
        passageText = parts.join('\n\n');
      }
    }

    String rawQuestionText = (data['question_text'] ?? '').toString();
    if (passageText == null) {
      final passageMatch = RegExp(
        r'^(?:(?:Passage|Direction|Directions|Read the following)[\s\S]*?)(?=\n\n\d+[\.:\)]\s|\n\s*(?:Q\.?\s*)?\d+[\.:\)]\s|\n\nWhich|\n\nBased on|\n\nAccording to|\Z)',
        caseSensitive: false,
      ).firstMatch(rawQuestionText);
      if (passageMatch != null && passageMatch.group(0) != null) {
        final extractedPassage = passageMatch.group(0)!.trim();
        final remaining = rawQuestionText.substring(passageMatch.end).trim();
        if (remaining.isNotEmpty && extractedPassage.length > 20) {
          passageText = extractedPassage;
          rawQuestionText = remaining;
        }
      }
    }

    // Synthesize or resolve group ID so multi-question passages link together
    String? effectiveGroupId = passageId ?? data['group_id']?.toString();
    if (effectiveGroupId == null && passageText != null && passageText.isNotEmpty) {
      final rangeMatch = RegExp(
        r'(?:Q\.?\s*(?:No\.?|Nos\.?)?\s*)(\d+)\s*(?:to|and|&|-|–|—)\s*(\d+)',
        caseSensitive: false,
      ).firstMatch(passageText);
      if (rangeMatch != null) {
        final start = rangeMatch.group(1);
        final end = rangeMatch.group(2);
        effectiveGroupId = 'synth_group_${testId}_${start}_$end';
      } else {
        effectiveGroupId = 'passage_${testId}_${passageText.hashCode.abs()}';
      }
    }

    return Question(
      id: data['id']?.toString() ?? '',
      examCode: rawExamCode,
      year: parsedYear,
      paperType: paperType,
      testId: testId,
      testTitle: testTitle,
      subject: (data['subject'] ?? 'General').toString(),
      difficulty: (data['difficulty'] ?? 'Medium').toString(),
      groupId: effectiveGroupId,
      passageId: passageId,
      passageOrDirection: passageText,
      passageImage: passageImage,
      questionText: rawQuestionText,
      questionImage: data['image_url']?.toString() ??
          data['question_image_url']?.toString() ??
          data['question_image']?.toString(),
      imageUrl: data['image_url']?.toString() ??
          data['question_image_url']?.toString(),
      hasImage: data['has_image'] == true ||
          (data['image_url'] != null && data['image_url'].toString().trim().isNotEmpty) ||
          (data['question_image_url'] != null && data['question_image_url'].toString().trim().isNotEmpty),
      reviewStatus: (data['review_status'] ?? 'unreviewed').toString(),
      flagReasons: (data['flagged_issues'] is List)
          ? (data['flagged_issues'] as List).map((e) => e.toString()).toList()
          : (data['flag_reasons'] is List)
              ? (data['flag_reasons'] as List).map((e) => e.toString()).toList()
              : const [],
      modeAvailability: (data['mode_availability'] is List)
          ? (data['mode_availability'] as List).map((e) => e.toString()).toList()
          : const ['timed', 'study'],
      options: parsedOptions,
      optionImages: parsedOptionImages,
      correctAnswer: cleanCorrect,
      officialAnswer: official,
      solution:
          (data['explanation'] ?? 'Verified with official key.').toString(),
      solutionImage: data['explanation_image_url']?.toString(),
      timeLimitMins: tests?['duration_minutes'] as int? ?? 120,
      marksPerCorrect:
          (tests?['marks_per_correct'] as num?)?.toDouble() ?? 2.0,
      negativeMarks: (tests?['negative_marks'] as num?)?.toDouble() ?? 0.5,
      isScenarioTest: passages != null || groups != null,
      scenarioTags: null,
      initialComments: const [],
      pyqText: '[$rawExamCode $parsedYear]',
      questionNumber: qNum,
    );
  }
}

class QuestionRepository {
  static final List<Question> allQuestions = [];

  /// Fetches live questions from Supabase (PostgreSQL) first, with Cloud Firestore and local fallbacks
  static Future<List<Question>> fetchLiveQuestions({
    required String examCode,
    int? year,
    String? paperType,
  }) async {
    final cleanCode = examCode.trim().toUpperCase();

    // 1. Query Supabase (Relational PostgreSQL DB)
    try {
      var supaUrl =
          'https://fllopztywwblbucvaths.supabase.co/rest/v1/questions?select=*,question_groups(*),tests!inner(*)&order=question_number';

      // Only filter by exam_code if a specific code is provided (not empty or 'ALL')
      if (cleanCode.isNotEmpty && cleanCode != 'ALL') {
        final examFilter = Uri.encodeComponent(cleanCode);
        supaUrl += '&tests.exam_code=ilike.*$examFilter*';
      }

      if (year != null) {
        supaUrl += '&tests.year=eq.$year';
      }
      if (paperType != null && paperType.isNotEmpty) {
        supaUrl += '&tests.paper_type=eq.${Uri.encodeComponent(paperType.toUpperCase())}';
      }

      final response = await http.get(
        Uri.parse(supaUrl),
        headers: {
          'apikey': 'sb_publishable_y68QKKHxBTZxBP3Sf1X7tw_zfFnXX8M',
          'Authorization':
              'Bearer sb_publishable_y68QKKHxBTZxBP3Sf1X7tw_zfFnXX8M',
          'Prefer': 'return=representation',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        if (list.isNotEmpty) {
          debugPrint(
              '[QuestionRepository] Loaded ${list.length} live questions from Supabase for $cleanCode');
          return list
              .map((item) =>
                  Question.fromSupabase(item as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[QuestionRepository] Supabase fetch skipped or error: $e');
    }

    // 2. Fallback to local questions (Firestore / spreadsheet completely removed)
    return allQuestions.where((q) {
      final matchesExam =
          q.examCode.toUpperCase().contains(examCode.toUpperCase()) ||
              examCode.toUpperCase().contains(q.examCode.toUpperCase());
      final matchesYear = year == null || q.year == year;
      return matchesExam && matchesYear;
    }).toList();
  }
}
