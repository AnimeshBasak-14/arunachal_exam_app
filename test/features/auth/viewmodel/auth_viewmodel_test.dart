import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:arunachal_exam_app/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:arunachal_exam_app/core/services/storage_service.dart';
import 'package:arunachal_exam_app/core/services/firebase_service.dart';
import 'package:arunachal_exam_app/models/user_model.dart';

class MockStorageService extends Mock implements StorageService {}
class MockFirebaseService extends Mock implements FirebaseService {}
class FakeUserModel extends Fake implements UserModel {}

void main() {
  late MockStorageService mockStorage;
  late MockFirebaseService mockFirebase;
  late AuthViewModel authViewModel;

  setUpAll(() {
    registerFallbackValue(FakeUserModel());
  });

  setUp(() {
    mockStorage = MockStorageService();
    mockFirebase = MockFirebaseService();

    // Default StorageService stubs for AuthViewModel initial state
    when(() => mockStorage.isLoggedIn).thenReturn(false);
    when(() => mockStorage.userEmail).thenReturn('student@arunachal.in');
    when(() => mockStorage.userName).thenReturn('Student Name');
    when(() => mockStorage.userPhone).thenReturn('');
    when(() => mockStorage.userProfilePic).thenReturn('avatar_green');
    when(() => mockStorage.userDob).thenReturn('2000-01-01');
    when(() => mockStorage.userRating).thenReturn(0);
    when(() => mockStorage.userCity).thenReturn('Itanagar');
    when(() => mockFirebase.fetchUserProfile(any())).thenAnswer((_) async => null);

    authViewModel = AuthViewModel(mockStorage, mockFirebase);
  });

  group('AuthViewModel - Initial State & Clear Error', () {
    test('initial state when not logged in', () {
      expect(authViewModel.state.isLoggedIn, false);
      expect(authViewModel.state.user, isNull);
      expect(authViewModel.state.isLoading, false);
      expect(authViewModel.state.errorMessage, isNull);
    });

    test('initial state when logged in loads user from storage', () {
      final savedUser = UserModel(
        name: 'Logged User',
        email: 'logged@gmail.com',
        phone: '',
      );
      when(() => mockStorage.isLoggedIn).thenReturn(true);
      when(() => mockStorage.userEmail).thenReturn('logged@gmail.com');
      when(() => mockStorage.getAccountData('logged@gmail.com')).thenReturn(savedUser);

      final loggedInViewModel = AuthViewModel(mockStorage, mockFirebase);

      expect(loggedInViewModel.state.isLoggedIn, true);
      expect(loggedInViewModel.state.user?.name, 'Logged User');
      expect(loggedInViewModel.state.user?.email, 'logged@gmail.com');
    });

    test('clearError removes error message from state', () async {
      when(() => mockStorage.getRegisteredPassword('invalid')).thenAnswer((_) async => null);

      // Trigger an error first
      await authViewModel.login('invalid', 'pass');
      expect(authViewModel.state.errorMessage, isNotNull);

      authViewModel.clearError();
      expect(authViewModel.state.errorMessage, isNull);
    });
  });

  group('AuthViewModel.login - Validation & Failure Cases', () {
    test('login fails when email is non-gmail and phone is invalid format', () async {
      final result = await authViewModel.login('user@yahoo.com', 'password123');

      expect(result, false);
      expect(authViewModel.state.isLoggedIn, false);
      expect(authViewModel.state.isLoading, false);
      expect(
        authViewModel.state.errorMessage,
        'Invalid ID. Only Gmail (@gmail.com) or 10-digit Phone numbers allowed.',
      );
    });

    test('login fails when phone number is not 10 digits', () async {
      final result = await authViewModel.login('12345', 'password123');

      expect(result, false);
      expect(authViewModel.state.isLoggedIn, false);
      expect(authViewModel.state.isLoading, false);
      expect(
        authViewModel.state.errorMessage,
        'Invalid ID. Only Gmail (@gmail.com) or 10-digit Phone numbers allowed.',
      );
    });

    test('login fails when account does not exist in registered storage', () async {
      when(() => mockStorage.getRegisteredPassword('user@gmail.com')).thenAnswer((_) async => null);

      final result = await authViewModel.login(' user@gmail.com ', 'password123');

      expect(result, false);
      expect(authViewModel.state.isLoggedIn, false);
      expect(authViewModel.state.isLoading, false);
      expect(
        authViewModel.state.errorMessage,
        'Account does not exist. Please register first.',
      );
      verify(() => mockStorage.getRegisteredPassword('user@gmail.com')).called(1);
    });

    test('login fails when password is incorrect', () async {
      when(() => mockStorage.getRegisteredPassword('user@gmail.com')).thenAnswer((_) async => 'correct_pass');

      final result = await authViewModel.login('user@gmail.com', 'wrong_pass');

      expect(result, false);
      expect(authViewModel.state.isLoggedIn, false);
      expect(authViewModel.state.isLoading, false);
      expect(
        authViewModel.state.errorMessage,
        'Incorrect password. Please try again.',
      );
      verify(() => mockStorage.getRegisteredPassword('user@gmail.com')).called(1);
    });
  });

  group('AuthViewModel.login - Success Cases', () {
    test('successful login with existing account data', () async {
      const email = 'user@gmail.com';
      const password = 'correct_password';
      final existingUser = UserModel(
        name: 'Existing User',
        email: email,
        phone: '',
        profilePic: 'avatar_gold',
        dob: '1995-05-15',
        rating: 1350,
        city: 'Itanagar',
      );

      when(() => mockStorage.getRegisteredPassword(email)).thenAnswer((_) async => password);
      when(() => mockStorage.getAccountData(email)).thenReturn(existingUser);
      when(() => mockStorage.saveUser(
            name: any(named: 'name'),
            email: any(named: 'email'),
            phone: any(named: 'phone'),
            profilePic: any(named: 'profilePic'),
            dob: any(named: 'dob'),
            rating: any(named: 'rating'),
            city: any(named: 'city'),
          )).thenAnswer((_) async {});
      when(() => mockStorage.setLoggedIn(true)).thenAnswer((_) async {});
      when(() => mockFirebase.logLogin('email_or_phone')).thenAnswer((_) async {});
      when(() => mockFirebase.syncUserProfile(any())).thenAnswer((_) async {});

      final result = await authViewModel.login(email, password);

      expect(result, true);
      expect(authViewModel.state.isLoggedIn, true);
      expect(authViewModel.state.user?.name, 'Existing User');
      expect(authViewModel.state.user?.email, email);

      verify(() => mockStorage.saveUser(
            name: existingUser.name,
            email: existingUser.email,
            phone: existingUser.phone,
            profilePic: existingUser.profilePic,
            dob: existingUser.dob,
            rating: existingUser.rating,
            city: existingUser.city,
          )).called(1);
      verify(() => mockStorage.setLoggedIn(true)).called(1);
      verify(() => mockFirebase.logLogin('email_or_phone')).called(1);
      verify(() => mockFirebase.syncUserProfile(existingUser)).called(1);
    });

    test('successful login with 10-digit phone number using registered fallback data', () async {
      const phone = '9876543210';
      const password = 'correct_password';

      when(() => mockStorage.getRegisteredPassword(phone)).thenAnswer((_) async => password);
      when(() => mockStorage.getAccountData(phone)).thenReturn(null);
      when(() => mockStorage.getRegisteredName(phone)).thenReturn('Phone User');
      when(() => mockStorage.getRegisteredDob(phone)).thenReturn('1999-12-31');
      when(() => mockStorage.getRegisteredRating(phone)).thenReturn(1400);
      when(() => mockStorage.getRegisteredCity(phone)).thenReturn('Pasighat');

      when(() => mockStorage.saveUser(
            name: any(named: 'name'),
            email: any(named: 'email'),
            phone: any(named: 'phone'),
            profilePic: any(named: 'profilePic'),
            dob: any(named: 'dob'),
            rating: any(named: 'rating'),
            city: any(named: 'city'),
          )).thenAnswer((_) async {});
      when(() => mockStorage.setLoggedIn(true)).thenAnswer((_) async {});
      when(() => mockFirebase.logLogin('email_or_phone')).thenAnswer((_) async {});
      when(() => mockFirebase.syncUserProfile(any())).thenAnswer((_) async {});

      final result = await authViewModel.login(phone, password);

      expect(result, true);
      expect(authViewModel.state.isLoggedIn, true);
      final loggedInUser = authViewModel.state.user;
      expect(loggedInUser, isNotNull);
      expect(loggedInUser!.name, 'Phone User');
      expect(loggedInUser.email, '');
      expect(loggedInUser.phone, phone);
      expect(loggedInUser.dob, '1999-12-31');
      expect(loggedInUser.rating, 1400);
      expect(loggedInUser.city, 'Pasighat');

      verify(() => mockStorage.saveUser(
            name: 'Phone User',
            email: '',
            phone: phone,
            profilePic: 'avatar_green',
            dob: '1999-12-31',
            rating: 1400,
            city: 'Pasighat',
          )).called(1);
      verify(() => mockStorage.setLoggedIn(true)).called(1);
    });

    test('successful login with gmail using registered fallback defaults when registered info is null', () async {
      const email = 'newstudent@gmail.com';
      const password = 'password123';

      when(() => mockStorage.getRegisteredPassword(email)).thenAnswer((_) async => password);
      when(() => mockStorage.getAccountData(email)).thenReturn(null);
      when(() => mockStorage.getRegisteredName(email)).thenReturn(null);
      when(() => mockStorage.getRegisteredDob(email)).thenReturn(null);
      when(() => mockStorage.getRegisteredRating(email)).thenReturn(0);
      when(() => mockStorage.getRegisteredCity(email)).thenReturn('Itanagar');

      when(() => mockStorage.saveUser(
            name: any(named: 'name'),
            email: any(named: 'email'),
            phone: any(named: 'phone'),
            profilePic: any(named: 'profilePic'),
            dob: any(named: 'dob'),
            rating: any(named: 'rating'),
            city: any(named: 'city'),
          )).thenAnswer((_) async {});
      when(() => mockStorage.setLoggedIn(true)).thenAnswer((_) async {});
      when(() => mockFirebase.logLogin('email_or_phone')).thenAnswer((_) async {});
      when(() => mockFirebase.syncUserProfile(any())).thenAnswer((_) async {});

      final result = await authViewModel.login(email, password);

      expect(result, true);
      expect(authViewModel.state.isLoggedIn, true);
      final loggedInUser = authViewModel.state.user;
      expect(loggedInUser, isNotNull);
      expect(loggedInUser!.name, 'Student Name');
      expect(loggedInUser.email, email);
      expect(loggedInUser.phone, '');
      expect(loggedInUser.dob, '2000-01-01');
    });

    test('successful login even when Firebase logging/sync throws an exception', () async {
      const email = 'user@gmail.com';
      const password = 'password123';

      when(() => mockStorage.getRegisteredPassword(email)).thenAnswer((_) async => password);
      when(() => mockStorage.getAccountData(email)).thenReturn(null);
      when(() => mockStorage.getRegisteredName(email)).thenReturn('User');
      when(() => mockStorage.getRegisteredDob(email)).thenReturn('2000-01-01');
      when(() => mockStorage.getRegisteredRating(email)).thenReturn(0);
      when(() => mockStorage.getRegisteredCity(email)).thenReturn('Itanagar');

      when(() => mockStorage.saveUser(
            name: any(named: 'name'),
            email: any(named: 'email'),
            phone: any(named: 'phone'),
            profilePic: any(named: 'profilePic'),
            dob: any(named: 'dob'),
            rating: any(named: 'rating'),
            city: any(named: 'city'),
          )).thenAnswer((_) async {});
      when(() => mockStorage.setLoggedIn(true)).thenAnswer((_) async {});
      when(() => mockFirebase.logLogin(any())).thenThrow(Exception('Firebase connection failed'));

      final result = await authViewModel.login(email, password);

      expect(result, true);
      expect(authViewModel.state.isLoggedIn, true);
      expect(authViewModel.state.user?.email, email);
    });
  });
}
