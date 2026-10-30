import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/supabase_config.dart';
import 'question_repository.dart';

/// Single typed repository for papers and questions.
/// Handles caching, error handling, and offline fallbacks in one place.
class ExamRepository {
  ExamRepository._();
  static final ExamRepository instance = ExamRepository._();

  final Map<String, List<Map<String, dynamic>>> _papersCache = {};

  /// Fetches test papers from Supabase with question counts.
  Future<List<Map<String, dynamic>>> fetchPapers({
    required String paperType,
    bool forceRefresh = false,
  }) async {
    final cacheKey = paperType.toUpperCase();
    if (!forceRefresh && _papersCache.containsKey(cacheKey)) {
      return _papersCache[cacheKey]!;
    }

    try {
      final uri = Uri.parse(
        '${SupabaseConfig.url}/rest/v1/tests?select=*,questions(count)&paper_type=eq.${Uri.encodeComponent(paperType.toUpperCase())}&order=year.desc,created_at.desc',
      );
      final response = await http
          .get(uri, headers: SupabaseConfig.authHeaders)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        final results = list.cast<Map<String, dynamic>>();
        _papersCache[cacheKey] = results;
        return results;
      }
    } catch (e) {
      debugPrint('[ExamRepository] fetchPapers error: $e');
      if (_papersCache.containsKey(cacheKey)) {
        return _papersCache[cacheKey]!;
      }
    }
    return [];
  }

  /// Fetches questions for a specific paper by test_id.
  Future<List<Question>> fetchQuestionsForTest(String testId) async {
    if (testId.trim().isEmpty) return [];

    try {
      final uri = Uri.parse(
        '${SupabaseConfig.url}/rest/v1/questions?select=*,question_groups(*),tests!inner(*)&test_id=eq.${Uri.encodeComponent(testId)}&order=question_number',
      );
      final response = await http.get(
        uri,
        headers: {
          ...SupabaseConfig.authHeaders,
          'Prefer': 'return=representation',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list
            .map((item) => Question.fromSupabase(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('[ExamRepository] fetchQuestionsForTest error: $e');
    }
    return [];
  }

  /// Server-side practice question fetch with subject, topic, and count limits.
  Future<List<Question>> fetchPracticeQuestions({
    required String subject,
    String? topic,
    String? paperType,
    required int count,
  }) async {
    try {
      var url =
          '${SupabaseConfig.url}/rest/v1/questions?select=*,question_groups(*),tests!inner(*)&limit=$count';

      if (subject.isNotEmpty && subject.toLowerCase() != 'all') {
        url += '&subject=ilike.*${Uri.encodeComponent(subject)}*';
      }
      if (topic != null && topic.isNotEmpty && topic.toLowerCase() != 'all') {
        url += '&topic=ilike.*${Uri.encodeComponent(topic)}*';
      }
      if (paperType != null && paperType.isNotEmpty && paperType != 'BOTH') {
        url +=
            '&tests.paper_type=eq.${Uri.encodeComponent(paperType.toUpperCase())}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          ...SupabaseConfig.authHeaders,
          'Prefer': 'return=representation',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list
            .map((item) => Question.fromSupabase(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('[ExamRepository] fetchPracticeQuestions error: $e');
    }
    return [];
  }

  /// Fast server-side count of practice questions using Content-Range header.
  Future<int> countPracticeQuestions({
    required String subject,
    String? topic,
    String? paperType,
  }) async {
    try {
      var url =
          '${SupabaseConfig.url}/rest/v1/questions?select=id,tests!inner(*)&limit=1';
      if (subject.isNotEmpty && subject.toLowerCase() != 'all') {
        url += '&subject=ilike.*${Uri.encodeComponent(subject)}*';
      }
      if (topic != null && topic.isNotEmpty && topic.toLowerCase() != 'all') {
        url += '&topic=ilike.*${Uri.encodeComponent(topic)}*';
      }
      if (paperType != null && paperType.isNotEmpty && paperType != 'BOTH') {
        url +=
            '&tests.paper_type=eq.${Uri.encodeComponent(paperType.toUpperCase())}';
      }

      final response = await http.head(
        Uri.parse(url),
        headers: {
          ...SupabaseConfig.authHeaders,
          'Prefer': 'count=exact',
        },
      ).timeout(const Duration(seconds: 4));

      final contentRange = response.headers['content-range'];
      if (contentRange != null && contentRange.contains('/')) {
        final totalStr = contentRange.split('/').last.trim();
        final total = int.tryParse(totalStr);
        if (total != null) return total;
      }
    } catch (e) {
      debugPrint('[ExamRepository] countPracticeQuestions error: $e');
    }
    return 0;
  }
}
