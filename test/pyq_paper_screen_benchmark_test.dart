import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arunachal_exam_app/core/services/storage_service.dart';
import 'package:arunachal_exam_app/core/services/question_repository.dart';

// Current unoptimized implementation for baseline measurement
void runInitQuestionMetadataBaseline({
  required List<Question> questions,
  required StorageService storage,
  required SharedPreferences prefs,
  required Map<String, List<String>> questionComments,
  required Map<String, int> questionLikes,
  required Map<String, bool> likedQuestions,
  required Map<String, bool> likedSolutions,
  required Map<String, Map<int, List<String>>> commentReplies,
  required Map<String, Map<int, int>> commentLikesCount,
  required Map<String, Map<int, bool>> commentUserLiked,
  required Map<String, Map<int, Map<int, int>>> replyLikesCount,
  required Map<String, Map<int, Map<int, bool>>> replyUserLiked,
}) {
  for (final q in questions) {
    final savedComments = storage.getQuestionComments(q.id);
    questionComments[q.id] = [...q.initialComments, ...savedComments];

    questionLikes[q.id] = (q.questionText.length % 15) + 6;
    likedQuestions[q.id] = false;
    likedSolutions[q.id] = false;

    final allComments = questionComments[q.id]!;
    for (int i = 0; i < allComments.length; i++) {
      final repliesList = prefs.getStringList('replies_${q.id}_$i') ?? [];
      commentReplies.putIfAbsent(q.id, () => {})[i] = repliesList;

      final likes = prefs.getInt('likes_${q.id}_$i') ?? (i * 3 + 2);
      commentLikesCount.putIfAbsent(q.id, () => {})[i] = likes;
      commentUserLiked.putIfAbsent(q.id, () => {})[i] = prefs.getBool('user_liked_${q.id}_$i') ?? false;

      for (int j = 0; j < repliesList.length; j++) {
        final rLikes = prefs.getInt('reply_likes_${q.id}_${i}_$j') ?? 1;
        replyLikesCount.putIfAbsent(q.id, () => {}).putIfAbsent(i, () => {})[j] = rLikes;
        replyUserLiked.putIfAbsent(q.id, () => {}).putIfAbsent(i, () => {})[j] = prefs.getBool('user_reply_liked_${q.id}_${i}_$j') ?? false;
      }
    }
  }
}

// Optimized implementation for verification
void runInitQuestionMetadataOptimized({
  required List<Question> questions,
  required StorageService storage,
  required SharedPreferences prefs,
  required Map<String, List<String>> questionComments,
  required Map<String, int> questionLikes,
  required Map<String, bool> likedQuestions,
  required Map<String, bool> likedSolutions,
  required Map<String, Map<int, List<String>>> commentReplies,
  required Map<String, Map<int, int>> commentLikesCount,
  required Map<String, Map<int, bool>> commentUserLiked,
  required Map<String, Map<int, Map<int, int>>> replyLikesCount,
  required Map<String, Map<int, Map<int, bool>>> replyUserLiked,
}) {
  for (final q in questions) {
    final qId = q.id;
    final savedComments = storage.getQuestionComments(qId);
    final allComments = [...q.initialComments, ...savedComments];
    questionComments[qId] = allComments;

    questionLikes[qId] = (q.questionText.length % 15) + 6;
    likedQuestions[qId] = false;
    likedSolutions[qId] = false;

    final qCommentReplies = <int, List<String>>{};
    final qCommentLikesCount = <int, int>{};
    final qCommentUserLiked = <int, bool>{};
    final qReplyLikesCount = <int, Map<int, int>>{};
    final qReplyUserLiked = <int, Map<int, bool>>{};

    for (int i = 0; i < allComments.length; i++) {
      final keyPrefix = '${qId}_$i';
      final repliesList = prefs.getStringList('replies_$keyPrefix') ?? [];
      qCommentReplies[i] = repliesList;

      qCommentLikesCount[i] = prefs.getInt('likes_$keyPrefix') ?? (i * 3 + 2);
      qCommentUserLiked[i] = prefs.getBool('user_liked_$keyPrefix') ?? false;

      if (repliesList.isNotEmpty) {
        final iReplyLikes = <int, int>{};
        final iReplyUserLiked = <int, bool>{};

        for (int j = 0; j < repliesList.length; j++) {
          final replyKeyPrefix = '${keyPrefix}_$j';
          iReplyLikes[j] = prefs.getInt('reply_likes_$replyKeyPrefix') ?? 1;
          iReplyUserLiked[j] = prefs.getBool('user_reply_liked_$replyKeyPrefix') ?? false;
        }

        qReplyLikesCount[i] = iReplyLikes;
        qReplyUserLiked[i] = iReplyUserLiked;
      }
    }

    commentReplies[qId] = qCommentReplies;
    commentLikesCount[qId] = qCommentLikesCount;
    commentUserLiked[qId] = qCommentUserLiked;
    replyLikesCount[qId] = qReplyLikesCount;
    replyUserLiked[qId] = qReplyUserLiked;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Benchmark _initQuestionMetadata performance', () async {
    const questionCount = 50;
    const commentsPerQuestion = 10;
    const repliesPerComment = 5;

    final Map<String, Object> values = {};
    final List<Question> questions = [];

    for (int qIdx = 0; qIdx < questionCount; qIdx++) {
      final qId = 'question_$qIdx';
      final initialComments = List.generate(commentsPerQuestion, (i) => 'Comment $i for $qId');
      questions.add(Question(
        id: qId,
        examCode: 'APSSB-CGLE',
        year: 2021,
        subject: 'General Knowledge',
        questionText: 'Sample question text for question number $qIdx',
        options: const ['Option A', 'Option B', 'Option C', 'Option D'],
        correctAnswer: 'a',
        officialAnswer: 'Option A',
        solution: 'Sample solution',
        initialComments: initialComments,
      ));

      for (int i = 0; i < commentsPerQuestion; i++) {
        final repliesList = List.generate(repliesPerComment, (j) => 'Reply $j to comment $i');
        values['replies_${qId}_$i'] = repliesList;
        values['likes_${qId}_$i'] = i * 3 + 2;
        values['user_liked_${qId}_$i'] = i % 2 == 0;

        for (int j = 0; j < repliesPerComment; j++) {
          values['reply_likes_${qId}_${i}_$j'] = j + 1;
          values['user_reply_liked_${qId}_${i}_$j'] = j % 2 == 0;
        }
      }
    }

    SharedPreferences.setMockInitialValues(values);
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs);

    // Verify both produce identical outputs
    final baselineData = _runAndCapture(runInitQuestionMetadataBaseline, questions, storage, prefs);
    final optimizedData = _runAndCapture(runInitQuestionMetadataOptimized, questions, storage, prefs);

    expect(optimizedData, equals(baselineData));

    // Warm up
    for (int run = 0; run < 10; run++) {
      _runAndCapture(runInitQuestionMetadataBaseline, questions, storage, prefs);
      _runAndCapture(runInitQuestionMetadataOptimized, questions, storage, prefs);
    }

    // Benchmark loop baseline
    const iterations = 100;
    final swBaseline = Stopwatch()..start();
    for (int run = 0; run < iterations; run++) {
      _runAndCapture(runInitQuestionMetadataBaseline, questions, storage, prefs);
    }
    swBaseline.stop();

    // Benchmark loop optimized
    final swOptimized = Stopwatch()..start();
    for (int run = 0; run < iterations; run++) {
      _runAndCapture(runInitQuestionMetadataOptimized, questions, storage, prefs);
    }
    swOptimized.stop();

    final baselineAvgUs = swBaseline.elapsedMicroseconds / iterations;
    final optimizedAvgUs = swOptimized.elapsedMicroseconds / iterations;
    final speedup = ((baselineAvgUs - optimizedAvgUs) / baselineAvgUs) * 100;

    debugPrint('BENCHMARK_BASELINE: ${swBaseline.elapsedMilliseconds}ms total (${baselineAvgUs.toStringAsFixed(2)} us/run)');
    debugPrint('BENCHMARK_OPTIMIZED: ${swOptimized.elapsedMilliseconds}ms total (${optimizedAvgUs.toStringAsFixed(2)} us/run)');
    debugPrint('BENCHMARK_SPEEDUP: ${speedup.toStringAsFixed(2)}% faster');
  });
}

Map<String, dynamic> _runAndCapture(
  Function fn,
  List<Question> questions,
  StorageService storage,
  SharedPreferences prefs,
) {
  final questionComments = <String, List<String>>{};
  final questionLikes = <String, int>{};
  final likedQuestions = <String, bool>{};
  final likedSolutions = <String, bool>{};
  final commentReplies = <String, Map<int, List<String>>>{};
  final commentLikesCount = <String, Map<int, int>>{};
  final commentUserLiked = <String, Map<int, bool>>{};
  final replyLikesCount = <String, Map<int, Map<int, int>>>{};
  final replyUserLiked = <String, Map<int, Map<int, bool>>>{};

  fn(
    questions: questions,
    storage: storage,
    prefs: prefs,
    questionComments: questionComments,
    questionLikes: questionLikes,
    likedQuestions: likedQuestions,
    likedSolutions: likedSolutions,
    commentReplies: commentReplies,
    commentLikesCount: commentLikesCount,
    commentUserLiked: commentUserLiked,
    replyLikesCount: replyLikesCount,
    replyUserLiked: replyUserLiked,
  );

  return {
    'questionComments': questionComments,
    'questionLikes': questionLikes,
    'likedQuestions': likedQuestions,
    'likedSolutions': likedSolutions,
    'commentReplies': commentReplies,
    'commentLikesCount': commentLikesCount,
    'commentUserLiked': commentUserLiked,
    'replyLikesCount': replyLikesCount,
    'replyUserLiked': replyUserLiked,
  };
}
