import 'package:arunachal_exam_app/core/services/auth_gateway.dart';
import 'package:arunachal_exam_app/core/services/firebase_service.dart';
import 'package:arunachal_exam_app/core/services/storage_service.dart';
import 'package:arunachal_exam_app/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:arunachal_exam_app/models/user_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockFirebase extends Mock implements FirebaseService {}

class MockSecure extends Mock implements FlutterSecureStorage {}

class FakeUser extends Fake implements UserModel {}

/// In-memory stand-in for Firebase Auth.
class FakeGateway implements AuthGateway {
  final accounts = <String, String>{}; // email -> password
  String? current;
  AuthIdentity? googleAccount;
  bool deleted = false;

  @override
  Future<String?> restoredEmail() async => current;

  @override
  bool get hasPassword => current != null && accounts.containsKey(current);

  @override
  Future<AuthIdentity> signInWithEmail(String email, String password) async {
    if (accounts[email] != password) {
      throw const AuthFailure('Email or password is incorrect.', 'invalid-credential');
    }
    current = email;
    return AuthIdentity(email);
  }

  @override
  Future<AuthIdentity> createAccount(String email, String password, String name) async {
    if (accounts.containsKey(email)) throw const AuthFailure('exists', 'email-already-in-use');
    accounts[email] = password;
    current = email;
    return AuthIdentity(email, displayName: name);
  }

  @override
  Future<AuthIdentity?> signInWithGoogle() async {
    current = googleAccount?.email;
    return googleAccount;
  }

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> changePassword(String c, String n) async {
    if (accounts[current] != c) throw const AuthFailure('wrong', 'invalid-credential');
    accounts[current!] = n;
  }

  @override
  Future<void> deleteAccount({String? password}) async {
    if (password != null && accounts[current] != password) {
      throw const AuthFailure('wrong', 'invalid-credential');
    }
    deleted = true;
    current = null;
  }

  @override
  Future<void> signOut() async => current = null;
}

void main() {
  late StorageService storage;
  late MockFirebase firebase;
  late MockSecure secure;
  late FakeGateway gateway;
  final secureData = <String, String>{};

  setUpAll(() => registerFallbackValue(FakeUser()));

  Future<AuthViewModel> make([Map<String, Object> prefs = const {}]) async {
    SharedPreferences.setMockInitialValues(prefs);
    storage = StorageService(await SharedPreferences.getInstance(), secure);
    return AuthViewModel(storage, firebase, gateway);
  }

  setUp(() {
    secureData.clear();
    firebase = MockFirebase();
    secure = MockSecure();
    gateway = FakeGateway();
    when(() => secure.read(key: any(named: 'key')))
        .thenAnswer((i) async => secureData[i.namedArguments[#key] as String]);
    when(() => secure.write(key: any(named: 'key'), value: any(named: 'value'))).thenAnswer(
        (i) async => secureData[i.namedArguments[#key] as String] = i.namedArguments[#value] as String);
    when(() => secure.delete(key: any(named: 'key')))
        .thenAnswer((i) async => secureData.remove(i.namedArguments[#key] as String));
    when(() => firebase.fetchUserProfile(any())).thenAnswer((_) async => null);
    when(() => firebase.syncUserProfile(any())).thenAnswer((_) async {});
    when(() => firebase.logLogin(any())).thenAnswer((_) async {});
    when(() => firebase.logSignUp(any())).thenAnswer((_) async {});
    when(() => firebase.deleteUserData(any())).thenAnswer((_) async {});
  });

  test('starts signed out', () async {
    final vm = await make();
    expect(vm.state.isLoggedIn, isFalse);
    expect(vm.state.user, isNull);
  });

  test('register creates a Firebase account and a profile', () async {
    final vm = await make();
    final ok = await vm.register(
        name: 'Tashi Bam', email: 'Tashi@Mail.com ', password: 'secret123', confirmPassword: 'secret123');
    expect(ok, isTrue);
    expect(gateway.accounts['tashi@mail.com'], 'secret123');
    expect(vm.state.user?.name, 'Tashi Bam');
    expect(vm.state.user?.phone, '');
    verify(() => firebase.syncUserProfile(any())).called(1);
  });

  test('register rejects short or mismatched passwords before calling Firebase', () async {
    final vm = await make();
    expect(await vm.register(name: 'A', email: 'a@b.com', password: 'short', confirmPassword: 'short'), isFalse);
    expect(
        await vm.register(name: 'A', email: 'a@b.com', password: 'longenough', confirmPassword: 'different'),
        isFalse);
    expect(gateway.accounts, isEmpty);
  });

  test('login rejects a wrong password and does not sign in', () async {
    gateway.accounts['a@b.com'] = 'right-password';
    final vm = await make();
    expect(await vm.login('a@b.com', 'wrong-password'), isFalse);
    expect(vm.state.isLoggedIn, isFalse);
    expect(vm.state.errorMessage, 'Email or password is incorrect.');
  });

  test('login restores the Firestore profile', () async {
    gateway.accounts['a@b.com'] = 'pass1234';
    when(() => firebase.fetchUserProfile('a@b.com')).thenAnswer(
        (_) async => UserModel(name: 'Remote Name', email: 'a@b.com', phone: '9000000000', rating: 40));
    final vm = await make();
    expect(await vm.login('a@b.com', 'pass1234'), isTrue);
    expect(vm.state.user?.name, 'Remote Name');
    expect(vm.state.user?.rating, 40);
  });

  test('a phone number is not accepted as a login id', () async {
    final vm = await make();
    expect(await vm.login('9876543210', 'whatever'), isFalse);
    expect(vm.state.isLoggedIn, isFalse);
  });

  test('pre-Firebase local accounts move to Firebase on first login', () async {
    secureData['reg_pwd_old@b.com'] = 'oldpass1';
    final vm = await make({'reg_name_old@b.com': 'Old User'});
    expect(await vm.login('old@b.com', 'oldpass1'), isTrue);
    expect(gateway.accounts['old@b.com'], 'oldpass1');
    expect(secureData.containsKey('reg_pwd_old@b.com'), isFalse);
  });

  test('a wrong password never migrates a local account', () async {
    secureData['reg_pwd_old@b.com'] = 'oldpass1';
    final vm = await make();
    expect(await vm.login('old@b.com', 'guess123'), isFalse);
    expect(gateway.accounts, isEmpty);
  });

  test('Google sign-in creates a profile for a new account', () async {
    gateway.googleAccount = const AuthIdentity('new.user@gmail.com', displayName: 'New User');
    final vm = await make();
    expect(await vm.signInWithGoogle(), isTrue);
    expect(vm.state.user?.email, 'new.user@gmail.com');
    expect(vm.state.user?.name, 'New User');
  });

  test('cancelling Google sign-in is not an error', () async {
    final vm = await make();
    expect(await vm.signInWithGoogle(), isFalse);
    expect(vm.state.errorMessage, isNull);
  });

  test('a saved session without a Firebase user is signed out', () async {
    final vm = await make({'is_logged_in': true, 'user_email': 'ghost@b.com', 'user_name': 'Ghost'});
    expect(vm.state.isLoggedIn, isTrue);
    await pumpEventQueue();
    expect(vm.state.isLoggedIn, isFalse);
  });

  test('a saved session backed by Firebase stays signed in', () async {
    gateway.current = 'real@b.com';
    final vm = await make({'is_logged_in': true, 'user_email': 'real@b.com', 'user_name': 'Real'});
    await pumpEventQueue();
    expect(vm.state.isLoggedIn, isTrue);
  });

  test('delete account needs the right password, then removes data and sign-in', () async {
    gateway.accounts['a@b.com'] = 'pass1234';
    final vm = await make();
    await vm.login('a@b.com', 'pass1234');
    expect(await vm.deleteAccount(password: 'nope'), isFalse);
    expect(vm.state.isLoggedIn, isTrue);
    expect(await vm.deleteAccount(password: 'pass1234'), isTrue);
    expect(gateway.deleted, isTrue);
    expect(vm.state.isLoggedIn, isFalse);
  });
}
