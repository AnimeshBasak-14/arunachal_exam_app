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
import 'core/services/service_providers.dart';
import 'features/onboarding/view/onboarding_screen.dart';
import 'features/onboarding/viewmodel/onboarding_viewmodel.dart';
import 'features/auth/view/welcome_screen.dart';
import 'features/auth/view/login_screen.dart';
import 'features/auth/view/register_screen.dart';
import 'features/auth/view/forgot_password_screen.dart';
import 'features/auth/viewmodel/auth_viewmodel.dart';
import 'features/home/view/home_screen.dart';
import 'features/home/view/appsc_categories.dart';
import 'features/home/view/apssb_categories.dart';
import 'features/home/view/exam_detail_screen.dart';
import 'features/profile/view/edit_profile_screen.dart';
import 'features/home/view/my_courses_screen.dart';
import 'features/profile/view/bio_screen.dart';
import 'features/profile/view/change_email_screen.dart';
import 'features/profile/view/change_phone_screen.dart';
import 'features/profile/view/change_password_screen.dart';
import 'features/home/view/pyq_paper_screen.dart';
import 'features/home/view/mock_test_screen.dart';
import 'features/home/view/mock_test_result_screen.dart';
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
import 'core/services/current_affairs_service.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'core/services/remote_config_service.dart';
import 'core/services/fcm_service.dart';

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
          .log("Arunachal Exam Prep started (v1.0.1)");
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

      // Allow public direct access to news articles via deep-link
      final isPublicRoute = state.matchedLocation.startsWith('/news-details');

      // 1. If logged in, go to /home from any auth, onboarding, or root route
      if (isLoggedIn) {
        if (isAuthRoute ||
            isGoingToOnboarding ||
            state.matchedLocation == '/') {
          return '/home';
        }
        return null;
      }

      // 2. On Web, bypass mobile onboarding slides completely
      if (kIsWeb) {
        if (!isAuthRoute && !isPublicRoute) {
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
          body: Center(
            child: CircularProgressIndicator(),
          ),
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
          if (extra is Map<String, dynamic>) {
            return RegisterScreen(
              initialEmail: extra['email'] as String?,
              initialName: extra['name'] as String?,
            );
          }
          return const RegisterScreen();
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/appsc',
        builder: (context, state) => const AppscCategoriesScreen(),
      ),
      GoRoute(
        path: '/apssb',
        builder: (context, state) => const ApssbCategoriesScreen(),
      ),
      GoRoute(
        path: '/exam-detail/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ExamDetailScreen(examId: id);
        },
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/my-courses',
        builder: (context, state) => const MyCoursesScreen(),
      ),
      GoRoute(
        path: '/bio',
        builder: (context, state) => const BioScreen(),
      ),
      GoRoute(
        path: '/change-email',
        builder: (context, state) => const ChangeEmailScreen(),
      ),
      GoRoute(
        path: '/change-phone',
        builder: (context, state) => const ChangePhoneScreen(),
      ),
      GoRoute(
        path: '/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/pyqs/:examCode/:year',
        builder: (context, state) {
          final examCode = state.pathParameters['examCode'] ?? '';
          final yearText = state.pathParameters['year'] ?? '';
          final year = int.tryParse(yearText) ?? 2021;
          return PyqPaperScreen(examCode: examCode, year: year);
        },
      ),
      GoRoute(
        path: '/mock-test/:examCode/:type',
        builder: (context, state) {
          final examCode = state.pathParameters['examCode'] ?? '';
          final type = state.pathParameters['type'] ?? '';
          return MockTestScreen(examCode: examCode, testType: type);
        },
      ),
      GoRoute(
        path: '/mock-test-result',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>? ?? {};
          return MockTestResultScreen(resultData: data);
        },
      ),
      GoRoute(
        path: '/scoreboard',
        builder: (context, state) => const ScoreboardScreen(),
      ),
      GoRoute(
        path: '/trophy-history',
        builder: (context, state) => const TrophyHistoryScreen(),
      ),
      GoRoute(
        path: '/quiz-history',
        builder: (context, state) => const QuizHistoryScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/chatbot',
        builder: (context, state) => ChatbotScreen(
          initialContext: state.extra as String?,
        ),
      ),
      GoRoute(
        path: '/streak-calendar',
        builder: (context, state) => const StreakCalendarScreen(),
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
          return NewsDetailsScreen(article: article);
        },
      ),
      GoRoute(
        path: '/public-profile',
        builder: (context, state) {
          final user = state.extra as Map<String, dynamic>? ?? {};
          return PublicProfileScreen(user: user);
        },
      ),
      GoRoute(
        path: '/state-gk',
        builder: (context, state) => const StateGkScreen(),
      ),
      GoRoute(
        path: '/current-affairs-gk',
        builder: (context, state) => const CurrentAffairsGkScreen(),
      ),
      GoRoute(
        path: '/grammar-hub',
        builder: (context, state) => const GrammarHubScreen(),
      ),
      GoRoute(
        path: '/grammar-quiz',
        builder: (context, state) => const GrammarQuizScreen(),
      ),
    ],
  );
});

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Arunachal Exam Prep',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
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
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
