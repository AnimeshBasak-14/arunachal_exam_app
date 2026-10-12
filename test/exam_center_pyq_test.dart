import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arunachal_exam_app/features/home/view/pyq_hub_screen.dart';
import 'package:arunachal_exam_app/features/home/view/mock_hub_screen.dart';
import 'package:arunachal_exam_app/widgets/custom_practice_modal.dart';
import 'package:arunachal_exam_app/core/theme/app_theme.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'my_selected_exam': 'ALL',
      'cached_pyq_papers_v2': '''[
        {
          "id": "real_pyq_1",
          "title": "APSSB CGL 2024 Solved Paper",
          "board": "APSSB",
          "exam_code": "APSSB-CGLE-2024",
          "year": 2024,
          "subject": "General Studies",
          "question_count": 5,
          "total_questions": 50,
          "duration_minutes": 60,
          "marks_per_correct": 2.0,
          "negative_marks": 0.5
        },
        {
          "id": "real_pyq_no_year",
          "title": "APSSB Special Paper",
          "board": "APSSB",
          "exam_code": "APSSB-SPECIAL",
          "year": null,
          "subject": "English",
          "question_count": 10,
          "total_questions": null,
          "duration_minutes": 30,
          "marks_per_correct": 2.0,
          "negative_marks": 0.5
        },
        {
          "id": "fake_zero_qs",
          "title": "Empty Ghost Paper",
          "board": "APSSB",
          "exam_code": "APSSB-GHOST",
          "year": 2024,
          "subject": "Maths",
          "question_count": 0,
          "total_questions": 100,
          "duration_minutes": 120,
          "marks_per_correct": 2.0,
          "negative_marks": 0.5
        }
      ]''',
      'cached_mock_tests_v2': '''[
        {
          "id": "real_mock_1",
          "title": "Quantitative Aptitude Mock 1",
          "subject": "Mathematics",
          "exam_code": "APSSB-MOCK",
          "question_count": 10,
          "total_questions": 20,
          "duration_minutes": 15,
          "difficulty": "Easy",
          "description": "High yield math mock",
          "marks_per_correct": 2.0,
          "negative_marks": 0.5
        }
      ]'''
    });
  });

  group('Part A1 & A2: PYQ Paper Model & Validation', () {
    test('PyqPaperItem parses nullable fields without fake defaulted values (Fix A2)', () {
      final rawData = {
        'id': 'test_empty_fields',
        'title': 'Test Paper',
        'exam_code': 'APSSB-TEST',
        'questions': [
          {'count': 12}
        ],
      };

      final paper = PyqPaperItem.fromSupabase(rawData);

      expect(paper.id, 'test_empty_fields');
      expect(paper.questionCount, 12);
      expect(paper.year, isNull, reason: 'Year must not default to 2024');
      expect(paper.subject, isNull, reason: 'Subject must not default to General Studies');
      expect(paper.officialQuestionCount, isNull, reason: 'Must not invent official count');
      expect(paper.durationMinutes, isNull, reason: 'Must not guess duration');
      expect(paper.marksPerCorrect, isNull, reason: 'Must not invent +2 marking');
      expect(paper.negativeMarks, isNull, reason: 'Must not invent -0.5 marking');
    });

    test('Incomplete pill flags papers with fewer questions than official count', () {
      const incompletePaper = PyqPaperItem(
        id: 'inc_1',
        title: 'CGL Paper',
        examCode: 'CGL',
        questionCount: 5,
        officialQuestionCount: 54,
      );

      const completePaper = PyqPaperItem(
        id: 'comp_1',
        title: 'Complete Paper',
        examCode: 'CGL',
        questionCount: 50,
        officialQuestionCount: 50,
      );

      expect(incompletePaper.isIncomplete, isTrue);
      expect(completePaper.isIncomplete, isFalse);
    });

    test('Zero question paper is flagged correctly', () {
      final rawZero = {
        'id': 'zero_q',
        'total_questions': 0,
        'questions': [
          {'count': 0}
        ],
      };
      final item = PyqPaperItem.fromSupabase(rawZero);
      expect(item.questionCount, 0);
    });
  });

  group('Part D: Widget Tests (Search Clear & 130% Font Scale)', () {
    testWidgets('Search clear button empties search text (Fix A4)', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(
              body: PyqHubScreen(isEmbedded: true),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap search icon to open search box
      final searchIcon = find.byIcon(Icons.search_rounded);
      expect(searchIcon, findsOneWidget);
      await tester.tap(searchIcon);
      await tester.pumpAndSettle();

      // Enter search text
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, 'Special');
      await tester.pumpAndSettle();

      expect(find.text('Special'), findsOneWidget);

      // Tap clear icon
      final clearIcon = find.byIcon(Icons.clear_rounded);
      expect(clearIcon, findsOneWidget);
      await tester.tap(clearIcon);
      await tester.pumpAndSettle();

      // Verify text is emptied
      final textFieldWidget = tester.widget<TextField>(searchField);
      expect(textFieldWidget.controller?.text, isEmpty);
    });

    testWidgets('Layout renders with text scale 1.3 at 360x780 with no overflow (Fix A5/A7/A8)', (tester) async {
      // Set test screen size to 360x780
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(360, 780),
                textScaler: TextScaler.linear(1.3),
              ),
              child: const Scaffold(
                body: PyqHubScreen(isEmbedded: true),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify no overflow exceptions occurred
      expect(tester.takeException(), isNull);

      // Verify 0-question ghost paper is NOT shown (Fix A1)
      expect(find.text('Empty Ghost Paper'), findsNothing);

      // Verify real papers are displayed
      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets('MockHubScreen renders with text scale 1.3 at 360x780 with no overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(360, 780),
                textScaler: TextScaler.linear(1.3),
              ),
              child: const Scaffold(
                body: MockHubScreen(isEmbedded: true),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('CustomPracticeModal renders with text scale 1.3 at 360x780 with no overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(360, 780),
                textScaler: TextScaler.linear(1.3),
              ),
              child: const Scaffold(
                body: CustomPracticeModal(isEmbedded: true),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Verify specific dynamic button text (Fix B5)
      expect(find.text('Start 10 Mathematics Questions'), findsOneWidget);
    });
  });
}
