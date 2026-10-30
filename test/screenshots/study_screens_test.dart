@Tags(['screenshots'])
library;

import 'package:arunachal_exam_app/core/services/auth_gateway.dart';
import 'package:arunachal_exam_app/core/services/current_affairs_service.dart';
import 'package:arunachal_exam_app/core/theme/app_theme.dart';
import 'package:arunachal_exam_app/features/account/view/account_screen.dart';
import 'package:arunachal_exam_app/features/auth/view/forgot_password_screen.dart';
import 'package:arunachal_exam_app/features/auth/view/login_screen.dart';
import 'package:arunachal_exam_app/features/auth/view/register_screen.dart';
import 'package:arunachal_exam_app/features/auth/view/welcome_screen.dart';
import 'package:arunachal_exam_app/features/chatbot/view/chatbot_screen.dart';
import 'package:arunachal_exam_app/features/home/view/bookmarks_screen.dart';
import 'package:arunachal_exam_app/features/home/view/current_affairs_gk_screen.dart';
import 'package:arunachal_exam_app/features/home/view/notifications_screen.dart';
import 'package:arunachal_exam_app/features/learn/data/learn_deck.dart';
import 'package:arunachal_exam_app/features/learn/view/learn_feed_screen.dart';
import 'package:arunachal_exam_app/features/profile/view/change_password_screen.dart';
import 'package:arunachal_exam_app/features/profile/view/edit_profile_screen.dart';
import 'package:arunachal_exam_app/features/profile/view/quiz_history_screen.dart';
import 'package:arunachal_exam_app/features/shell/view/app_shell.dart';
import 'package:arunachal_exam_app/features/study/view/grammar_hub_screen.dart';
import 'package:arunachal_exam_app/features/study/view/grammar_quiz_screen.dart';
import 'package:arunachal_exam_app/features/syllabus/view/syllabus_screen.dart';
import 'package:arunachal_exam_app/core/services/question_repository.dart';
import 'package:arunachal_exam_app/features/exam/data/attempt.dart';
import 'package:arunachal_exam_app/features/streak/data/day_key.dart';
import 'package:arunachal_exam_app/features/home/view/state_gk_screen.dart';
import 'package:arunachal_exam_app/features/streak/view/daily_question_screen.dart';
import 'package:arunachal_exam_app/features/streak/view/streak_screen.dart';
import 'dart:convert';
import 'package:arunachal_exam_app/features/plan/data/study_plan.dart';
import 'package:arunachal_exam_app/features/plan/view/study_plan_sheet.dart';
import 'package:arunachal_exam_app/data/state_gk_data.dart';
import 'package:arunachal_exam_app/data/national_gk_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import '../helpers/test_app.dart';

// Renders screens to PNG for visual review:
//   flutter test --tags screenshots --run-skipped --update-goldens test/screenshots
// Output: test/screenshots/goldens/*.png (not a regression gate).

Future<void> _loadFonts() async {
  GoogleFonts.config.allowRuntimeFetching = false;
  Future<void> load(String family, List<String> assets) async {
    final l = FontLoader(family);
    for (final a in assets) {
      l.addFont(rootBundle.load(a));
    }
    await l.load();
  }

  await load(
      'CupertinoIcons', ['packages/cupertino_icons/assets/CupertinoIcons.ttf']);
  await load('packages/cupertino_icons/CupertinoIcons',
      ['packages/cupertino_icons/assets/CupertinoIcons.ttf']);
  await load('MaterialIcons', ['fonts/MaterialIcons-Regular.otf']);
}

class _SignedIn implements AuthGateway {
  @override
  Future<String?> restoredEmail() async => 'tashi.bam@gmail.com';
  @override
  bool get hasPassword => true;
  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}

final _news = FeedResult([
  CurrentAffairsItem(
    id: '1',
    title: 'APSSB announces CGL 2026 written exam dates for 312 posts',
    summary:
        'The Arunachal Pradesh Staff Selection Board has released the schedule for the combined graduate level written test.',
    source: 'Arunachal Observer',
    published: DateTime.now().subtract(const Duration(minutes: 40)),
    link: 'https://example.org',
    examRelated: true,
  ),
  CurrentAffairsItem(
    id: '2',
    title: 'APPSC releases CCE prelims result; 1,204 qualify for mains',
    summary: '',
    source: 'The Arunachal Times',
    published: DateTime.now().subtract(const Duration(hours: 3)),
    link: 'https://example.org',
    examRelated: true,
  ),
  CurrentAffairsItem(
    id: '3',
    title: 'Tawang to host 14th International Tourism Mart',
    summary: 'Officials reviewed preparations.',
    source: 'Arunachal24',
    published: DateTime.now().subtract(const Duration(days: 1)),
    link: 'https://example.org',
  ),
], failed: const []);

Map<String, Object> _streakData() {
  final now = DateTime.now();
  final days = [
    for (final i in [0, 1, 2, 3, 5, 6, 9, 10, 11])
      dayKey(now.subtract(Duration(days: i)))
  ];
  final q = Question(
    id: 'q1',
    examCode: 'APPSC-CCE',
    year: 2023,
    subject: 'Geography',
    questionText:
        'Which river is known as the Siang in Arunachal Pradesh before it joins the Brahmaputra?',
    options: const ['(a) Subansiri', '(b) Dihang', '(c) Lohit', '(d) Kameng'],
    correctAnswer: 'b',
    officialAnswer: 'b',
    solution:
        'The Siang, also called the Dihang, is the Brahmaputra as it flows through Arunachal Pradesh.',
  );
  final today = dayKey(now);
  return {
    'streak_count': 3,
    'streak_longest': 6,
    'streak_last_date': today,
    'streak_active_dates_history': days,
    'daily_q_$today': jsonEncode(Attempt.questionToMap(q)),
    'coins_balance_v1': 48,
    'coins_events_v1': jsonEncode([
      {'d': today, 'a': 2, 'r': 'Hidden coin'},
      {
        'd': dayKey(now.subtract(const Duration(days: 1))),
        'a': 10,
        'r': 'PYQ of the day'
      },
      {
        'd': dayKey(now.subtract(const Duration(days: 2))),
        'a': 5,
        'r': 'Daily card goal'
      },
    ]),
    'daily_log_v1': jsonEncode({
      dayKey(now.subtract(const Duration(days: 1))): {'p': 'b', 'c': true},
      dayKey(now.subtract(const Duration(days: 2))): {'p': 'a', 'c': false},
    }),
    'time_log_v1': jsonEncode({
      today: {
        'pyq': {'paper': 1500, 'daily': 240},
        'mock': {'paper': 900},
        'cards': {
          'grammar': 1260,
          'vocab': 600,
          'polity': 420,
          'arunachal': 300
        },
        'read': {'gk': 360, 'news': 120},
      }
    }),
  };
}

Map<String, Object> _plan(DateTime exam, {int answered = 4}) => {
      'study_plan_v1': jsonEncode(StudyPlan(
        examDate: exam,
        dailyQuestions: 10,
        completed: true,
      ).toJson()),
      'questions_today_count': answered,
      'questions_today_day': dayKey(DateTime.now()),
    };

void main() {
  setUpAll(_loadFonts);

  Future<void> shoot(WidgetTester tester, String name, Widget screen,
      {bool dark = false,
      double text = 1.3,
      bool signedIn = true,
      Size size = const Size(412, 860),
      Map<String, Object> extra = const {}}) async {
    phoneViewport(tester, size: size);
    final prefs = await testPrefs({
      if (signedIn) ...{
        'is_logged_in': true,
        'user_email': 'tashi.bam@gmail.com',
        'user_name': 'Tashi Bam',
        'user_city': 'Itanagar',
      },
      ...extra,
    });
    await tester.pumpWidget(ProviderScope(
      overrides: [
        ...testOverrides(prefs),
        authGatewayProvider.overrideWithValue(_SignedIn()),
        currentAffairsProvider.overrideWith((_) async => _news),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        home: scaled(screen, scale: text),
      ),
    ));
    await settle(tester, 20);
    await tester.runAsync(() => GoogleFonts.pendingFonts());
    await settle(tester, 6);
    await expectLater(
        find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
  }

  testWidgets('streak',
      (t) => shoot(t, 'streak', const StreakScreen(), extra: _streakData()));
  testWidgets(
      'streak tall',
      (t) => shoot(t, 'streak_tall', const StreakScreen(),
          size: const Size(412, 2000), extra: _streakData()));
  testWidgets(
      'streak tall dark',
      (t) => shoot(t, 'streak_tall_dark', const StreakScreen(),
          dark: true, size: const Size(412, 2000), extra: _streakData()));
  testWidgets(
      'streak dark',
      (t) => shoot(t, 'streak_dark', const StreakScreen(),
          dark: true, extra: _streakData()));
  testWidgets(
      'daily question',
      (t) => shoot(
          t, 'daily', DailyQuestionScreen(date: dayKey(DateTime.now())),
          extra: _streakData()));
  testWidgets(
      'dashboard coins',
      (t) =>
          shoot(t, 'dashboard_coins', const AppShell(), extra: _streakData()));
  testWidgets(
      'timer months',
      (t) => shoot(t, 'timer_months', const AppShell(),
          extra: _plan(DateTime.now().add(const Duration(days: 75)))));
  testWidgets(
      'timer months dark',
      (t) => shoot(t, 'timer_months_dark', const AppShell(),
          dark: true,
          extra: _plan(DateTime.now().add(const Duration(days: 75)),
              answered: 10)));
  testWidgets(
      'timer days',
      (t) => shoot(t, 'timer_days', const AppShell(),
          extra: _plan(DateTime.now().add(const Duration(days: 4, hours: 3)))));
  testWidgets(
      'timer seconds',
      (t) => shoot(t, 'timer_seconds', const AppShell(),
          extra: _plan(DateTime.now().add(const Duration(days: 1, hours: 5)))));
  testWidgets(
      'timer none',
      (t) => shoot(t, 'timer_none', const AppShell(), extra: {
            'study_plan_v1':
                jsonEncode(const StudyPlan(completed: true).toJson())
          }));
  testWidgets(
      'chapter tribes',
      (t) => shoot(
          t,
          'chapter_tribes',
          ChapterScreen(
              chapter: StateGkData.chapters.firstWhere((c) => c.id == 'ch9'))));
  testWidgets(
      'chapter tribes dark',
      (t) => shoot(
          t,
          'chapter_tribes_dark',
          ChapterScreen(
              chapter: StateGkData.chapters.firstWhere((c) => c.id == 'ch9')),
          dark: true));
  testWidgets(
      'chapter gs',
      (t) => shoot(
          t,
          'chapter_gs',
          ChapterScreen(
              chapter:
                  NationalGkData.chapters.firstWhere((c) => c.id == 'his1'))));
  testWidgets(
      'plan sheet step 2',
      (t) => shoot(t, 'plan_step2', Builder(builder: (context) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) => showStudyPlanSheet(context));
            return const SizedBox();
          }), extra: {
            'study_plan_v1':
                jsonEncode(const StudyPlan(completed: true).toJson())
          }));
  testWidgets('dashboard', (t) => shoot(t, 'dashboard', const AppShell()));
  testWidgets('dashboard dark',
      (t) => shoot(t, 'dashboard_dark', const AppShell(), dark: true));
  testWidgets(
      'library', (t) => shoot(t, 'library', const AppShell(initialTab: 1)));
  testWidgets(
      'library dark',
      (t) =>
          shoot(t, 'library_dark', const AppShell(initialTab: 1), dark: true));
  testWidgets('mocks', (t) => shoot(t, 'mocks', const AppShell(initialTab: 2)));
  testWidgets('performance',
      (t) => shoot(t, 'performance', const AppShell(initialTab: 3)));
  testWidgets('gk hub dark',
      (t) => shoot(t, 'gk_hub_dark', const StateGkScreen(), dark: true));
  testWidgets('chatbot dark',
      (t) => shoot(t, 'chatbot_dark', const ChatbotScreen(), dark: true));
  testWidgets(
      'login dark',
      (t) => shoot(t, 'login_dark', const LoginScreen(),
          dark: true, signedIn: false));
  testWidgets('welcome',
      (t) => shoot(t, 'welcome', const WelcomeScreen(), signedIn: false));
  testWidgets(
      'login', (t) => shoot(t, 'login', const LoginScreen(), signedIn: false));
  testWidgets('register',
      (t) => shoot(t, 'register', const RegisterScreen(), signedIn: false));
  testWidgets('forgot',
      (t) => shoot(t, 'forgot', const ForgotPasswordScreen(), signedIn: false));
  testWidgets('account', (t) => shoot(t, 'account', const AccountScreen()));
  testWidgets('account dark',
      (t) => shoot(t, 'account_dark', const AccountScreen(), dark: true));
  testWidgets('edit profile',
      (t) => shoot(t, 'edit_profile', const EditProfileScreen()));
  testWidgets('change password',
      (t) => shoot(t, 'change_password', const ChangePasswordScreen()));
  testWidgets('notifications',
      (t) => shoot(t, 'notifications', const NotificationsScreen()));
  testWidgets(
      'bookmarks', (t) => shoot(t, 'bookmarks', const BookmarksScreen()));
  testWidgets('history', (t) => shoot(t, 'history', const QuizHistoryScreen()));
  testWidgets('chatbot', (t) => shoot(t, 'chatbot', const ChatbotScreen()));
  testWidgets('grammar quiz',
      (t) => shoot(t, 'grammar_quiz', const GrammarQuizScreen()));
  testWidgets('gk hub', (t) => shoot(t, 'gk_hub', const StateGkScreen()));
  testWidgets(
      'grammar hub', (t) => shoot(t, 'grammar_hub', const GrammarHubScreen()));
  testWidgets(
      'learn feed', (t) => shoot(t, 'learn_feed', const LearnFeedScreen()));
  testWidgets(
      'learn dark',
      (t) => shoot(
          t, 'learn_dark', const LearnFeedScreen(topics: {LearnTopic.polity}),
          dark: true));
  testWidgets('syllabus',
      (t) => shoot(t, 'syllabus', const SyllabusScreen(initialTabIndex: 2)));
  testWidgets('current affairs',
      (t) => shoot(t, 'current_affairs', const CurrentAffairsGkScreen()));
}
