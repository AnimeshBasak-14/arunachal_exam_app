import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arunachal_exam_app/core/services/question_repository.dart';
import 'package:arunachal_exam_app/core/widgets/primary_button.dart';
import 'package:arunachal_exam_app/widgets/comprehension_group_card.dart';
import 'package:arunachal_exam_app/features/home/widgets/single_question_widget.dart';

void main() {
  Question makeTestQuestion({
    required String id,
    required String text,
    int qNum = 1,
    String? passageId,
    String? direction,
    String subject = 'Elementary Mathematics',
  }) {
    return Question(
      id: id,
      examCode: 'APSSB-CGLE',
      year: 2024,
      subject: subject,
      questionNumber: qNum,
      passageId: passageId,
      passageOrDirection: direction,
      questionText: text,
      options: const [
        '(a) Rs. 50,000',
        '(b) Rs. 60,000',
        '(c) Rs. 62,000',
        '(d) Rs. 6,00,000',
      ],
      correctAnswer: 'b',
      officialAnswer: '(b) Rs. 60,000',
      solution: 'Explanation details here',
    );
  }

  group('Quiz UI/UX Automated Stability Tests', () {
    // ─── 1. VIEWPORT OVERFLOW TEST ──────────────────────────────────────
    testWidgets(
      'Viewport Overflow Test: ensures no RenderFlex overflow on small screen (360x640)',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final q = makeTestQuestion(
          id: 'q_overflow_1',
          text: 'In a business, A invests Rs. 50,000 and B invests Rs. 60,000. Find profit ratio.',
          subject: 'Elementary Mathematics',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(68),
                child: SafeArea(
                  bottom: false,
                  child: AppBar(
                    toolbarHeight: 68,
                    leading: const BackButton(),
                    title: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('APSSB-CGLE 2024 Mock Test', overflow: TextOverflow.ellipsis),
                              Text('100 Questions · +2 / -0.5 Marking', style: TextStyle(fontSize: 10)),
                            ],
                          ),
                        ),
                        Text('120:00'),
                      ],
                    ),
                  ),
                ),
              ),
              body: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, kBottomNavigationBarHeight + 80),
                children: [
                  SingleQuestionWidget(
                    question: q,
                    displayNum: 1,
                    selectedSubjectFilter: 'Elementary Mathematics', // tests duplicate suppression
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify that no layout overflow exceptions were thrown
        expect(tester.takeException(), isNull);
      },
    );

    // ─── 2. OCCLUSION TEST ──────────────────────────────────────────────
    testWidgets(
      'Occlusion Test: scrolling to end ensures candidate discussion is above submit button',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final questions = List.generate(
          2,
          (i) => makeTestQuestion(
            id: 'occlusion_q_$i',
            text: 'Question $i text with complete choices and options.',
            qNum: i + 1,
          ),
        );

        final scrollController = ScrollController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              extendBody: true,
              body: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, kBottomNavigationBarHeight + 80),
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  return Card(
                    key: ValueKey('card_$index'),
                    child: SingleQuestionWidget(
                      question: questions[index],
                      displayNum: index + 1,
                      discussionWidget: Container(
                        key: const Key('candidate_discussion'),
                        padding: const EdgeInsets.all(12),
                        child: const Text('Candidate Discussion Thread'),
                      ),
                    ),
                  );
                },
              ),
              bottomNavigationBar: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    child: PrimaryButton(
                      key: const Key('submit_mock_test_btn'),
                      text: 'SUBMIT MOCK TEST',
                      onPressed: () {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Programmatically scroll to the final question/candidate discussion card
        final discussionFinder = find.byKey(const Key('candidate_discussion')).last;
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
        await tester.pumpAndSettle();

        // Assert that the bottom of the candidate discussion card is strictly ABOVE the submit button
        final discussionBottomRight = tester.getBottomRight(discussionFinder);
        final submitButtonTopLeft = tester.getTopLeft(find.byKey(const Key('submit_mock_test_btn')));

        expect(
          discussionBottomRight.dy < submitButtonTopLeft.dy,
          isTrue,
          reason: 'Candidate discussion bottom (${discussionBottomRight.dy}) must be < submit button top (${submitButtonTopLeft.dy}) to prevent occlusion',
        );
      },
    );

    // ─── 3. COMPREHENSION BINDING TEST ──────────────────────────────────
    testWidgets(
      'Comprehension Binding Test: 3 grouped questions render exactly 1 passage header and 3 question cards',
      (WidgetTester tester) async {
        final q1 = makeTestQuestion(
          id: 'comp_q_85',
          text: 'Which country contains the largest portion of the Amazon?',
          qNum: 85,
          passageId: 'passage_amazon',
          direction: 'Read the following passage carefully.\nThe Amazon rainforest is the largest tropical rainforest.',
        );
        final q2 = makeTestQuestion(
          id: 'comp_q_86',
          text: 'What percentage of the world oxygen is estimated to be produced here?',
          qNum: 86,
          passageId: 'passage_amazon',
          direction: 'Read the following passage carefully.\nThe Amazon rainforest is the largest tropical rainforest.',
        );
        final q3 = makeTestQuestion(
          id: 'comp_q_87',
          text: 'Which river flows through this basin?',
          qNum: 87,
          passageId: 'passage_amazon',
          direction: 'Read the following passage carefully.\nThe Amazon rainforest is the largest tropical rainforest.',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView(
                children: [
                  ComprehensionGroupCard(
                    title: 'Direction (Q. 85 - 87)',
                    passage: 'Read the following passage carefully.\nThe Amazon rainforest is the largest tropical rainforest.',
                    startIndex: 85,
                    endIndex: 87,
                    children: [
                      SingleQuestionWidget(question: q1, displayNum: 85, isInsideGroup: true),
                      SingleQuestionWidget(question: q2, displayNum: 86, isInsideGroup: true),
                      SingleQuestionWidget(question: q3, displayNum: 87, isInsideGroup: true),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify exactly 1 passage header is rendered
        expect(find.textContaining('Direction (Q. 85 - 87)'), findsOneWidget);
        expect(find.textContaining('Amazon rainforest is the largest'), findsOneWidget);

        // Verify exactly 3 interactive question cards are rendered sequentially
        expect(find.byType(SingleQuestionWidget), findsNWidgets(3));
        expect(find.textContaining('Q85 •'), findsOneWidget);
        expect(find.textContaining('Q86 •'), findsOneWidget);
        expect(find.textContaining('Q87 •'), findsOneWidget);
      },
    );
  });
}
