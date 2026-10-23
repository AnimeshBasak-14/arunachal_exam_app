import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'core/services/firebase_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'core/services/service_providers.dart';
import 'features/onboarding/view/onboarding_screen.dart';
import 'features/onboarding/viewmodel/onboarding_viewmodel.dart';
import 'features/auth/view/welcome_screen.dart';
import 'features/auth/view/login_screen.dart';
import 'features/auth/view/register_screen.dart';
import 'features/auth/view/forgot_password_screen.dart';
import 'features/auth/viewmodel/auth_viewmodel.dart';
import 'features/home/view/appsc_categories.dart';
import 'features/home/view/apssb_categories.dart';
import 'features/home/view/exam_detail_screen.dart';
import 'features/profile/view/edit_profile_screen.dart';
import 'features/home/view/my_courses_screen.dart';
import 'features/profile/view/bio_screen.dart';
import 'features/profile/view/change_email_screen.dart';
import 'features/profile/view/change_phone_screen.dart';
import 'features/profile/view/change_password_screen.dart';
import 'features/home/view/scoreboard_screen.dart';
import 'features/home/view/trophy_history_screen.dart';
import 'features/profile/view/quiz_history_screen.dart';
import 'features/home/view/notifications_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/services/streak_service.dart';
import 'core/services/notification_service.dart';
import 'features/chatbot/view/chatbot_screen.dart';
import 'features/home/view/streak_calendar_screen.dart';
import 'features/home/view/news_details_screen.dart';
import 'features/profile/view/public_profile_screen.dart';
import 'features/home/view/state_gk_screen.dart';
import 'features/home/view/current_affairs_gk_screen.dart';
import 'features/study/view/grammar_hub_screen.dart';
import 'features/study/view/grammar_quiz_screen.dart';
import 'features/admin/view/question_review_screen.dart';
import 'features/admin/view/question_flagger_screen.dart';
import 'features/admin/view/admin_gate.dart';
import 'features/syllabus/view/syllabus_screen.dart';
import 'features/home/view/bookmarks_screen.dart';
import 'core/services/question_repository.dart';
import 'core/services/current_affairs_service.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'core/services/remote_config_service.dart';
import 'core/services/fcm_service.dart';
import 'features/account/view/account_screen.dart';
import 'features/exam/data/attempt.dart';
import 'features/exam/view/exam_screen.dart';
import 'features/exam/view/result_screen.dart';
import 'features/shell/view/app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyC8KsvkrcI1RkelPfPxqeHzzC8H-PBENPk',
          appId: '1:646900488202:web:2d474107c037f4d34e67f3',
          messagingSenderId: '646900488202',
          projectId: 'arunachal-exam-app',
          authDomain: 'arunachal-exam-app.firebaseapp.com',
          storageBucket: 'arunachal-exam-app.firebasestorage.app',
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint("Firebase initialization skipped or failed: $e");
  }

  // Enable Firestore offline persistence
  try {
    if (!kIsWeb && Firebase.apps.isNotEmpty) {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    }
  } catch (_) {}

  // ─── CRASHLYTICS OBSERVABILITY ──────────────────────────────────────────
  if (!kIsWeb && Firebase.apps.isNotEmpty) {
    try {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      // Handshake log so Firebase Console immediately verifies the SDK installation
      await FirebaseCrashlytics.instance
          .log("Donyi Prep started");
    } catch (_) {}

    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  // ─── PERFORMANCE MONITORING ─────────────────────────────────────────────
  try {
    if (!kIsWeb && Firebase.apps.isNotEmpty) {
      await FirebasePerformance.instance.setPerformanceCollectionEnabled(true);
      debugPrint("[Performance] Firebase Performance Monitoring active");
    }
  } catch (e) {
    debugPrint("Performance monitoring initialization skipped: $e");
  }

  // ─── REMOTE CONFIG & CLOUD MESSAGING ───────────────────────────────────
  try {
    if (Firebase.apps.isNotEmpty) {
      await RemoteConfigService.instance.initialize();
      await FcmService.instance.initialize();
    }
  } catch (e) {
    debugPrint("DevOps services initialization skipped or error: $e");
  }

  // Initialize notifications (skip on web where native notifications plugin is unsupported)
  if (!kIsWeb) {
    await NotificationService.initialize();
  }

  final prefs = await SharedPreferences.getInstance();

  // Update streak
  final streakService = StreakService(prefs);
  await streakService.checkAndUpdateStreak();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MyApp(),
    ),
  );
}

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authViewModelProvider).isLoggedIn;
});

final routerProvider = Provider<GoRouter>((ref) {
  final onboardingCompleted = ref.watch(onboardingViewModelProvider);
  final isLoggedIn = ref.watch(isLoggedInProvider);

  final analytics = ref.watch(firebaseServiceProvider).analytics;

  return GoRouter(
    initialLocation: '/',
    observers: [
      if (analytics != null)
        FirebaseAnalyticsObserver(analytics: analytics),
    ],
    redirect: (context, state) {
      final isGoingToOnboarding = state.matchedLocation == '/onboarding';
      final isGoingToWelcome = state.matchedLocation == '/welcome';
      final isGoingToLogin = state.matchedLocation == '/login';
      final isGoingToRegister = state.matchedLocation == '/register';
      final isGoingToForgotPassword =
          state.matchedLocation == '/forgot-password';

      final isAuthRoute = isGoingToWelcome ||
          isGoingToLogin ||
          isGoingToRegister ||
          isGoingToForgotPassword;

      // Allow direct access to news articles and admin screens via web URL / deep-link.
      // Admin screens are wrapped in AdminGate (Supabase admin sign-in), and RLS
      // rejects writes from anyone who is not in public.admin_users.
      final isPublicRoute = state.matchedLocation.startsWith('/news-details') ||
          state.matchedLocation.startsWith('/admin');

      // 1. If logged in, go to /home from any auth, onboarding, or root route
      if (isLoggedIn) {
        if (isAuthRoute ||
            isGoingToOnboarding ||
            state.matchedLocation == '/') {
          return '/home';
        }
        return null;
      }

      // 2. On Web, allow direct access to admin portal, home, and public info pages without requiring login
      if (kIsWeb) {
        if (isPublicRoute) {
          return null;
        }
        if (state.matchedLocation == '/') {
          return '/home';
        }
        if (state.matchedLocation == '/home' ||
            state.matchedLocation == '/syllabus' ||
            state.matchedLocation == '/state-gk' ||
            state.matchedLocation == '/current-affairs-gk' ||
            state.matchedLocation == '/exams-hub' ||
            state.matchedLocation == '/pyq-hub' ||
            state.matchedLocation == '/mock-hub' ||
            state.matchedLocation == '/grammar-hub' ||
            state.matchedLocation == '/bookmarks') {
          return null;
        }
        if (!isAuthRoute && !isLoggedIn) {
          return '/welcome';
        }
        return null;
      }

      // 3. If onboarding is not completed on mobile, force onboarding screen
      if (!onboardingCompleted && !isPublicRoute) {
        return isGoingToOnboarding ? null : '/onboarding';
      }

      // 4. If not logged in and not on auth routes or public news route, redirect to welcome page
      if (!isLoggedIn && !isAuthRoute && !isPublicRoute) {
        return '/welcome';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(
          body: Center(child: CircularProgressIndicator(strokeWidth: 1.6)),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) {
          final extra = state.extra;
          return _legacy(extra is Map<String, dynamic>
              ? RegisterScreen(
                  initialEmail: extra['email'] as String?,
                  initialName: extra['name'] as String?,
                )
              : const RegisterScreen());
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => _legacy(const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => AppShell(
          initialTab: int.tryParse(state.uri.queryParameters['tab'] ?? ''),
        ),
      ),
      // Older entry points now open the matching tab.
      GoRoute(path: '/pyq-hub', redirect: (_, __) => '/home?tab=1'),
      GoRoute(path: '/mock-hub', redirect: (_, __) => '/home?tab=2'),
      GoRoute(
        path: '/exams-hub',
        redirect: (_, state) =>
            state.uri.queryParameters['tab'] == '1' ? '/home?tab=2' : '/home?tab=1',
      ),
      GoRoute(
        path: '/account',
        builder: (context, state) => const AccountScreen(),
      ),
      GoRoute(
        path: '/appsc',
        builder: (context, state) => _legacy(const AppscCategoriesScreen()),
      ),
      GoRoute(
        path: '/apssb',
        builder: (context, state) => _legacy(const ApssbCategoriesScreen()),
      ),
      GoRoute(
        path: '/exam-detail/:id',
        builder: (context, state) =>
            _legacy(ExamDetailScreen(examId: state.pathParameters['id'] ?? '')),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => _legacy(const EditProfileScreen()),
      ),
      GoRoute(
        path: '/my-courses',
        builder: (context, state) => _legacy(const MyCoursesScreen()),
      ),
      GoRoute(
        path: '/bio',
        builder: (context, state) => _legacy(const BioScreen()),
      ),
      GoRoute(
        path: '/change-email',
        builder: (context, state) => _legacy(const ChangeEmailScreen()),
      ),
      GoRoute(
        path: '/change-phone',
        builder: (context, state) => _legacy(const ChangePhoneScreen()),
      ),
      GoRoute(
        path: '/change-password',
        builder: (context, state) => _legacy(const ChangePasswordScreen()),
      ),
      // Study a whole paper (older links): same engine, study mode.
      GoRoute(
        path: '/pyqs/:examCode/:year',
        builder: (context, state) => ExamScreen(
          examCode: state.pathParameters['examCode'] ?? '',
          testType: 'full',
          paperType: 'PYQ',
          year: int.tryParse(state.pathParameters['year'] ?? ''),
          isStudyMode: true,
        ),
      ),
      GoRoute(
        path: '/pyq-paper',
        builder: (context, state) {
          final q = state.uri.queryParameters;
          return ExamScreen(
            examCode: q['code'] ?? q['examCode'] ?? 'ALL',
            testType: 'full',
            paperType: 'PYQ',
            year: int.tryParse(q['year'] ?? ''),
            testId: q['testId'] ?? q['id'] ?? q['test_id'],
            title: q['title'],
            isStudyMode: true,
          );
        },
      ),
      GoRoute(
        path: '/mock-test/:examCode/:type',
        builder: (context, state) {
          // Optional query: testId, title, subject, difficulty, paperType,
          // year, duration, study=true
          final q = state.uri.queryParameters;
          final extra = state.extra;
          return ExamScreen(
            examCode: state.pathParameters['examCode'] ?? '',
            testType: state.pathParameters['type'] ?? '',
            testId: q['testId'] ?? q['id'] ?? q['test_id'],
            title: q['title'],
            subject: q['subject'],
            difficulty: q['difficulty'],
            paperType: q['paperType'],
            year: int.tryParse(q['year'] ?? ''),
            durationMinutes: int.tryParse(q['duration'] ?? ''),
            isStudyMode: q['study'] == 'true' || q['mode'] == 'study',
            initialQuestions: extra is List<Question> ? extra : null,
          );
        },
      ),
      GoRoute(
        path: '/mock-test-result',
        builder: (context, state) {
          final extra = state.extra;
          final data = extra is Map
              ? Map<String, dynamic>.from(extra)
              : <String, dynamic>{};
          return ResultScreen(attempt: Attempt.fromJson(data));
        },
      ),
      GoRoute(
        path: '/scoreboard',
        builder: (context, state) => _legacy(const ScoreboardScreen()),
      ),
      GoRoute(
        path: '/trophy-history',
        builder: (context, state) => _legacy(const TrophyHistoryScreen()),
      ),
      GoRoute(
        path: '/quiz-history',
        builder: (context, state) => _legacy(const QuizHistoryScreen()),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => _legacy(const NotificationsScreen()),
      ),
      GoRoute(
        path: '/chatbot',
        builder: (context, state) =>
            _legacy(ChatbotScreen(initialContext: state.extra as String?)),
      ),
      GoRoute(
        path: '/streak-calendar',
        builder: (context, state) => _legacy(const StreakCalendarScreen()),
      ),
      GoRoute(
        path: '/news-details',
        builder: (context, state) {
          final extraArticle = state.extra as Map<String, dynamic>?;
          final Map<String, dynamic> article =
              (extraArticle != null && extraArticle.isNotEmpty)
                  ? extraArticle
                  : CurrentAffairsService.getArticleMapById(
                      state.uri.queryParameters['id']);
          return _legacy(NewsDetailsScreen(article: article));
        },
      ),
      GoRoute(
        path: '/public-profile',
        builder: (context, state) => _legacy(PublicProfileScreen(
            user: state.extra as Map<String, dynamic>? ?? {})),
      ),
      GoRoute(
        path: '/state-gk',
        builder: (context, state) => _legacy(const StateGkScreen()),
      ),
      GoRoute(
        path: '/current-affairs-gk',
        builder: (context, state) => _legacy(const CurrentAffairsGkScreen()),
      ),
      GoRoute(
        path: '/grammar-hub',
        builder: (context, state) => _legacy(const GrammarHubScreen()),
      ),
      GoRoute(
        path: '/grammar-quiz',
        builder: (context, state) => _legacy(const GrammarQuizScreen()),
      ),
      GoRoute(
        path: '/admin/question-review',
        builder: (context, state) =>
            _legacy(const AdminGate(child: QuestionReviewScreen())),
      ),
      GoRoute(
        path: '/admin/question-flagger',
        builder: (context, state) =>
            _legacy(const AdminGate(child: QuestionFlaggerScreen())),
      ),
      GoRoute(
        path: '/syllabus',
        builder: (context, state) {
          final tabStr = state.uri.queryParameters['tab'];
          final initialTab = (int.tryParse(tabStr ?? '0') ?? 0).clamp(0, 3);
          return _legacy(SyllabusScreen(initialTabIndex: initialTab));
        },
      ),
      GoRoute(
        path: '/bookmarks',
        builder: (context, state) => _legacy(const BookmarksScreen()),
      ),
    ],
  );
});

/// Screens not yet redesigned hardcode light colours; keep them on the light
/// theme so they stay readable when the app is in dark mode.
Widget _legacy(Widget child) => Theme(data: AppTheme.legacyTheme, child: child);

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Donyi Prep',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.trackpad,
          PointerDeviceKind.stylus,
        },
      ),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final clampedScaler = mediaQuery.textScaler.clamp(
          minScaleFactor: 0.85,
          maxScaleFactor: 1.4,
        );
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: clampedScaler),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
