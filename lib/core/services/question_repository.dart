import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class Question {
  final String id;
  final String examCode; // 'APSSB-CGLE', 'APSSB-CHSL', 'APSSB-CSLE', 'APSSB-UDC', 'APSSB-MOCK', etc.
  final int year; // 2021, 2019, 2023, 2024
  final String paperType; // 'PYQ' or 'MOCK'
  final String testId;
  final String testTitle;
  final String subject; // 'English', 'Mathematics', 'General Knowledge'
  final String difficulty;
  final String? groupId;
  final String? passageOrDirection;
  final String questionText;
  final String? questionImage;
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
    this.passageOrDirection,
    required this.questionText,
    this.questionImage,
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
  });

  factory Question.fromMap(String docId, Map<String, dynamic> data) {
    // Parse options list
    List<String> parsedOptions = [];
    List<String?> parsedOptionImages = [null, null, null, null];

    if (data['options'] is List) {
      final rawList = data['options'] as List;
      for (int i = 0; i < rawList.length; i++) {
        final item = rawList[i];
        if (item is Map) {
          final prefix = item['key'] != null ? '(${item['key']}) ' : '(${String.fromCharCode(97 + i)}) ';
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
      parsedOptions = ['(a) Option A', '(b) Option B', '(c) Option C', '(d) Option D'];
    }

    final rawCorrect = (data['correctAnswer'] ?? 'a').toString().toLowerCase().replaceAll(RegExp(r'[^a-d]'), '');
    final cleanCorrect = rawCorrect.isNotEmpty ? rawCorrect[0] : 'a';

    // Find official answer string
    String official = '($cleanCorrect)';
    final correctIdx = cleanCorrect.codeUnitAt(0) - 97;
    if (correctIdx >= 0 && correctIdx < parsedOptions.length) {
      official = parsedOptions[correctIdx];
    }

    final rawExamCode = (data['examCode'] ?? 'APSSB-CGLE').toString();
    final rawYear = int.tryParse(data['year']?.toString() ?? '') ?? 2021;
    final rawPaperType = (data['paperType'] ?? 'PYQ').toString().toUpperCase();

    return Question(
      id: docId,
      examCode: rawExamCode,
      year: rawYear,
      paperType: rawPaperType,
      testId: (data['testId'] ?? '').toString(),
      testTitle: (data['testTitle'] ?? '').toString(),
      subject: (data['subject'] ?? 'General').toString(),
      difficulty: (data['difficulty'] ?? 'Medium').toString(),
      groupId: data['groupId']?.toString(),
      passageOrDirection: data['passageOrDirection']?.toString(),
      questionText: (data['questionText'] ?? '').toString(),
      questionImage: data['questionImage']?.toString(),
      options: parsedOptions,
      optionImages: parsedOptionImages,
      correctAnswer: cleanCorrect,
      officialAnswer: official,
      solution: (data['solution'] ?? 'Verified with official key.').toString(),
      solutionImage: data['solutionImage']?.toString(),
      timeLimitMins: int.tryParse(data['timeLimitMins']?.toString() ?? '') ?? 120,
      marksPerCorrect: double.tryParse(data['marksPerCorrect']?.toString() ?? '') ?? 2.0,
      negativeMarks: double.tryParse(data['negativeMarks']?.toString() ?? '') ?? 0.5,
      isScenarioTest: data['isScenarioTest'] == true || data['isScenarioTest']?.toString().toLowerCase() == 'true',
      scenarioTags: data['scenarioTags']?.toString(),
      initialComments: const [],
      pyqText: '[$rawExamCode $rawYear]',
    );
  }

  factory Question.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return Question.fromMap(doc.id, data);
  }
}

class QuestionRepository {
  static final List<Question> allQuestions = [];

  /// Fetches live questions from Cloud Firestore with automatic offline caching and local fallback
  static Future<List<Question>> fetchLiveQuestions({
    required String examCode,
    int? year,
    String? paperType,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;
      Query query = firestore.collection('questions');

      final cleanCode = examCode.trim().toUpperCase();
      
      // Match APSSB variants - accept both short codes and full codes
      String queryCode = cleanCode;
      if (cleanCode == 'APSSB-CGLE' || cleanCode == 'CGL' || cleanCode == 'CGLE') queryCode = 'APSSB-CGLE';
      if (cleanCode == 'APSSB-CHSL' || cleanCode == 'CHSL') queryCode = 'APSSB-CHSL';
      if (cleanCode == 'APSSB-CSLE' || cleanCode == 'CSLE' || cleanCode == 'CSCE') queryCode = 'APSSB-CSLE';
      if (cleanCode == 'APSSB-UDC' || cleanCode == 'UDC') queryCode = 'APSSB-UDC';
      if (cleanCode == 'APSSB-MTS' || cleanCode == 'MTS') queryCode = 'APSSB-MTS';
      if (cleanCode == 'APSSB-MOCK' || cleanCode == 'MOCK') queryCode = 'APSSB-MOCK';
      if (cleanCode == 'APSSB-MOCK-MATHS' || cleanCode == 'MOCK-MATHS') queryCode = 'APSSB-MOCK-MATHS';
      if (cleanCode == 'APPSC-AE' || cleanCode == 'AE') queryCode = 'APPSC-AE';
      if (cleanCode == 'APPSC-JE' || cleanCode == 'JE') queryCode = 'APPSC-JE';
      if (cleanCode == 'APPSC-APCS' || cleanCode == 'APCS') queryCode = 'APPSC-APCS';
      if (cleanCode == 'APPSC-ADO' || cleanCode == 'ADO') queryCode = 'APPSC-ADO';
      if (cleanCode == 'APPSC-HDO' || cleanCode == 'HDO') queryCode = 'APPSC-HDO';
      if (cleanCode == 'APPSC-FAO' || cleanCode == 'FAO') queryCode = 'APPSC-FAO';
      if (cleanCode == 'APPSC-PGT' || cleanCode == 'PGT') queryCode = 'APPSC-PGT';
      if (cleanCode == 'APPSC-TGT' || cleanCode == 'TGT') queryCode = 'APPSC-TGT';
      if (cleanCode == 'APP' || cleanCode == 'PROSECUTOR') queryCode = 'APPSC-APP';

      query = query.where('examCode', isEqualTo: queryCode);

      if (year != null) {
        query = query.where('year', isEqualTo: year);
      }
      if (paperType != null) {
        query = query.where('paperType', isEqualTo: paperType.toUpperCase());
      }

      final snapshot = await query.get(const GetOptions(source: Source.serverAndCache));
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) => Question.fromFirestore(doc)).toList();
      }
    } catch (e) {
      debugPrint('[QuestionRepository] Error fetching live questions from Firestore: $e');
    }

    // Fallback to local questions
    return allQuestions.where((q) {
      final matchesExam = q.examCode.toUpperCase().contains(examCode.toUpperCase()) ||
          examCode.toUpperCase().contains(q.examCode.toUpperCase());
      final matchesYear = year == null || q.year == year;
      return matchesExam && matchesYear;
    }).toList();
  }
}
