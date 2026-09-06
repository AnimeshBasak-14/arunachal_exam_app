import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arunachal_exam_app/core/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storageService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storageService = StorageService(prefs);
  });

  test('saveUser correctly stores active session and account data', () async {
    await storageService.saveUser(
      name: 'Tashi Tsering',
      email: 'tashi@arunachal.in',
      phone: '9876543210',
      profilePic: 'avatar_blue',
      dob: '1998-05-15',
      rating: 1350,
      city: 'Naharlagun',
    );

    expect(storageService.userName, 'Tashi Tsering');
    expect(storageService.userEmail, 'tashi@arunachal.in');
    expect(storageService.userPhone, '9876543210');
    expect(storageService.userProfilePic, 'avatar_blue');
    expect(storageService.userDob, '1998-05-15');
    expect(storageService.userRating, 1350);
    expect(storageService.userCity, 'Naharlagun');

    final account = storageService.getAccountData('tashi@arunachal.in');
    expect(account, isNotNull);
    expect(account!.name, 'Tashi Tsering');
    expect(account.rating, 1350);
  });

  test('clearUser removes user keys and sets isLoggedIn to false', () async {
    await storageService.saveUser(
      name: 'Tashi Tsering',
      email: 'tashi@arunachal.in',
      phone: '9876543210',
    );
    await storageService.setLoggedIn(true);
    expect(storageService.isLoggedIn, true);

    await storageService.clearUser();

    expect(storageService.isLoggedIn, false);
    expect(storageService.userName, 'Student Name'); // default value
    expect(storageService.userEmail, 'student@arunachal.in'); // default value
  });

  test('registerUserAccount and getRegistered password/info work as expected',
      () async {
    await storageService.registerUserAccount(
      emailOrPhone: 'user@test.com',
      password: 'securePass123',
      name: 'Test User',
      dob: '2001-02-03',
      rating: 1250,
      city: 'Itanagar',
    );

    expect(
        storageService.getRegisteredPassword('user@test.com'), 'securePass123');
    expect(storageService.getRegisteredName('user@test.com'), 'Test User');
    expect(storageService.getRegisteredDob('user@test.com'), '2001-02-03');
    expect(storageService.getRegisteredRating('user@test.com'), 1250);
    expect(storageService.getRegisteredCity('user@test.com'), 'Itanagar');
  });

  test('saveQuizHistory and toggleQuestionBookmark persist lists correctly',
      () async {
    await storageService.saveQuizHistory(['quiz1', 'quiz2'], 'user@test.com');
    expect(storageService.getQuizHistory('user@test.com'), ['quiz1', 'quiz2']);

    await storageService.toggleQuestionBookmark('q101', 'user@test.com');
    expect(storageService.getBookmarkedQuestions('user@test.com'), ['q101']);

    await storageService.toggleQuestionBookmark('q101', 'user@test.com');
    expect(storageService.getBookmarkedQuestions('user@test.com'), isEmpty);
  });
}
