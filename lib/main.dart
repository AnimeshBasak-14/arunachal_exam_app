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
import 'features/home/view/notifications_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/services/streak_service.dart';
import 'core/services/notification_service.dart';
import 'features/chatbot/view/chatbot_screen.dart';
import 'features/home/view/streak_calendar_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint(
        "Firebase initialization skipped (google-services.json not found yet): $e");
  }

  // Enable Firestore offline persistence
  try {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } catch (_) {}

  // Initialize notifications
  await NotificationService.initialize();

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
      FirebaseAnalyticsObserver(analytics: analytics),
    ],
    redirect: (context, state) {
      final isGoingToOnboarding = state.matchedLocation == '/onboarding';
      final isGoingToWelcome = state.matchedLocation == '/welcome';
      final isGoingToLogin = state.matchedLocation == '/login';
      final isGoingToRegister = state.matchedLocation == '/register';

      final isAuthRoute =
          isGoingToWelcome || isGoingToLogin || isGoingToRegister;

      // 1. If onboarding is not completed, force onboarding screen
      if (!onboardingCompleted) {
        return isGoingToOnboarding ? null : '/onboarding';
      }

      // 2. If logged in but on auth/onboarding routes, go to home
      if (isLoggedIn) {
        if (isAuthRoute ||
            isGoingToOnboarding ||
            state.matchedLocation == '/') {
          return '/home';
        }
        return null;
      }

      // 3. If not logged in and not on auth routes, redirect to welcome page
      if (!isLoggedIn && !isAuthRoute) {
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
        builder: (context, state) => const RegisterScreen(),
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
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/chatbot',
        builder: (context, state) => const ChatbotScreen(),
      ),
      GoRoute(
        path: '/streak-calendar',
        builder: (context, state) => const StreakCalendarScreen(),
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
    );
  }
}
