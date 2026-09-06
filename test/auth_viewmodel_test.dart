import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:arunachal_exam_app/models/user_model.dart';
import 'package:arunachal_exam_app/core/services/storage_service.dart';
import 'package:arunachal_exam_app/core/services/firebase_service.dart';
import 'package:arunachal_exam_app/features/auth/viewmodel/auth_viewmodel.dart';

class MockFirebaseService implements FirebaseService {
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
  Future<void> syncUserProfile(UserModel user) async {}

  @override
  Future<void> saveQuizResultToFirestore(String userEmail, Map<String, dynamic> resultData) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storageService;
  late MockFirebaseService firebaseService;
  late AuthViewModel authViewModel;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storageService = StorageService(prefs);
    firebaseService = MockFirebaseService();
    authViewModel = AuthViewModel(storageService, firebaseService);
  });

  group('AuthViewModel Security Tests - No Hardcoded Default Fallbacks', () {
    test('register with Gmail does not set hardcoded test phone', () async {
      final success = await authViewModel.register(
        name: 'John Doe',
        emailOrPhone: 'johndoe@gmail.com',
        dob: '1998-05-15',
        password: 'password123',
        confirmPassword: 'password123',
        otpEntered: '123456',
        otpSent: '123456',
      );

      expect(success, true);
      final user = authViewModel.state.user;
      expect(user, isNotNull);
      expect(user!.email, 'johndoe@gmail.com');
      expect(user.phone, isNot('9876543210'));
      expect(user.phone, '');
    });

    test('register with Phone does not set hardcoded test email', () async {
      final success = await authViewModel.register(
        name: 'Jane Doe',
        emailOrPhone: '9876543211',
        dob: '1999-01-01',
        password: 'password123',
        confirmPassword: 'password123',
        otpEntered: '123456',
        otpSent: '123456',
      );

      expect(success, true);
      final user = authViewModel.state.user;
      expect(user, isNotNull);
      expect(user!.phone, '9876543211');
      expect(user.email, isNot('candidate.google@gmail.com'));
      expect(user.email, '');
    });

    test('login with Phone does not set hardcoded test email', () async {
      await storageService.registerUserAccount(
        emailOrPhone: '9876543211',
        password: 'password123',
        name: 'Jane Doe',
      );

      final success = await authViewModel.login('9876543211', 'password123');

      expect(success, true);
      final user = authViewModel.state.user;
      expect(user, isNotNull);
      expect(user!.phone, '9876543211');
      expect(user.email, isNot('candidate.google@gmail.com'));
      expect(user.email, '');
    });

    test('loginSocial without email parameter does not default to candidate.google@gmail.com', () async {
      final success = await authViewModel.loginSocial('google');

      expect(success, true);
      final user = authViewModel.state.user;
      expect(user, isNotNull);
      expect(user!.email, isNot('candidate.google@gmail.com'));
      expect(user.phone, isNot('9876543210'));
    });
  });
}
