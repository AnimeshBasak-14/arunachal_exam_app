import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MyApp(),
    ),
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final onboardingCompleted = ref.watch(onboardingViewModelProvider);
  final authState = ref.watch(authViewModelProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isGoingToOnboarding = state.matchedLocation == '/onboarding';
      final isGoingToWelcome = state.matchedLocation == '/welcome';
      final isGoingToLogin = state.matchedLocation == '/login';
      final isGoingToRegister = state.matchedLocation == '/register';

      final isAuthRoute = isGoingToWelcome || isGoingToLogin || isGoingToRegister;

      // 1. If onboarding is not completed, force onboarding screen
      if (!onboardingCompleted) {
        return isGoingToOnboarding ? null : '/onboarding';
      }

      // 2. If logged in but on auth/onboarding routes, go to home
      if (authState.isLoggedIn) {
        if (isAuthRoute || isGoingToOnboarding || state.matchedLocation == '/') {
          return '/home';
        }
        return null;
      }

      // 3. If not logged in and not on auth routes, redirect to welcome page
      if (!authState.isLoggedIn && !isAuthRoute) {
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
