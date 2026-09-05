import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:arunachal_exam_app/core/services/storage_service.dart';
import 'package:arunachal_exam_app/core/services/firebase_service.dart';
import 'package:arunachal_exam_app/features/auth/viewmodel/auth_viewmodel.dart';

class FakeFirebaseService implements FirebaseService {
  @override
  FirebaseAnalytics get analytics => throw UnimplementedError();

  @override
  FirebaseFirestore get firestore => throw UnimplementedError();

  @override
  Future<void> logScreenView(String screenName) async {}

  @override
  Future<void> logLogin(String method) async {}

  @override
  Future<void> logSignUp(String method) async {}

  @override
  Future<void> logQuizCompleted({
    required String examCode,
    required double score,
    required double maxScore,
    required int trophiesChange,
    required int timeTakenSeconds,
    required String rankTier,
  }) async {}

  @override
  Future<void> syncUserProfile(dynamic user) async {}

  @override
  Future<void> saveQuizResultToFirestore(String userEmail, Map<String, dynamic> resultData) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storageService;
  late FakeFirebaseService firebaseService;
  late AuthViewModel authViewModel;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storageService = StorageService(prefs);
    firebaseService = FakeFirebaseService();
    authViewModel = AuthViewModel(storageService, firebaseService);
  });

  test('loginSocial generates a unique secure password and prevents default password login', () async {
    const testEmail = 'user1.test@gmail.com';

    // Perform social login for a new account
    final success = await authViewModel.loginSocial('google', email: testEmail);
    expect(success, isTrue);

    // Retrieve the registered password from storage
    final registeredPassword = storageService.getRegisteredPassword(testEmail);
    expect(registeredPassword, isNotNull);
    expect(registeredPassword, isNot(equals('socialpassword')));
    expect(registeredPassword!.length, greaterThanOrEqualTo(32));

    // Create a new AuthViewModel instance to test normal email login
    final loginViewModel = AuthViewModel(storageService, firebaseService);

    // Attempt to log in using the old hardcoded 'socialpassword'
    final loginWithSocialPwd = await loginViewModel.login(testEmail, 'socialpassword');
    expect(loginWithSocialPwd, isFalse);
    expect(loginViewModel.state.errorMessage, equals('Incorrect password. Please try again.'));

    // Attempt to log in with the generated secure password
    final loginWithSecurePwd = await loginViewModel.login(testEmail, registeredPassword);
    expect(loginWithSecurePwd, isTrue);
  });
}
