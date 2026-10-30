import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/services/auth_gateway.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/validators.dart';
import '../../../models/user_model.dart';

class AuthState {
  final bool isLoggedIn;
  final UserModel? user;
  final bool isLoading;
  final String? errorMessage;

  AuthState({
    this.isLoggedIn = false,
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    UserModel? user,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Accounts live in Firebase Authentication; the profile (name, city,
/// rating) lives in Firestore under `users/{email}` and is cached locally so
/// the app opens offline.
class AuthViewModel extends StateNotifier<AuthState> {
  final StorageService _storage;
  final FirebaseService _firebase;
  final AuthGateway _auth;

  AuthViewModel(this._storage, this._firebase, this._auth)
      : super(AuthState(
          isLoggedIn: _storage.isLoggedIn,
          user: _storage.isLoggedIn ? _cachedUser(_storage) : null,
        )) {
    if (_storage.isLoggedIn) _verifySession();
  }

  static UserModel _cachedUser(StorageService s) =>
      s.getAccountData(s.userEmail) ??
      UserModel(
        name: s.userName,
        email: s.userEmail,
        phone: s.userPhone,
        profilePic: s.userProfilePic,
        dob: s.userDob,
        rating: s.userRating,
        city: s.userCity,
      );

  /// Sessions saved by versions before Firebase Authentication have no
  /// Firebase user behind them; those are signed out once.
  Future<void> _verifySession() async {
    final email = await _auth.restoredEmail();
    if (email == null || email != _storage.userEmail.toLowerCase()) {
      await logout();
      return;
    }
    await refreshUserFromRemote();
  }

  /// Password change and password re-authentication only apply to email
  /// accounts, not Google ones.
  bool get hasPassword => _auth.hasPassword;

  static String _resolveBestProfilePic(String? remotePic, String? localPic,
      [String fallback = 'avatar_green']) {
    final cleanRemote = (remotePic ?? '').trim();
    final cleanLocal = (localPic ?? '').trim();
    if (cleanRemote.isNotEmpty && !cleanRemote.startsWith('avatar_')) {
      return cleanRemote;
    }
    if (cleanLocal.isNotEmpty && !cleanLocal.startsWith('avatar_')) {
      return cleanLocal;
    }
    if (cleanRemote.isNotEmpty) return cleanRemote;
    if (cleanLocal.isNotEmpty) return cleanLocal;
    return fallback;
  }

  Future<void> refreshUserFromRemote() async {
    try {
      final email = _storage.userEmail;
      if (email.isEmpty) return;
      final remote = await _firebase.fetchUserProfile(email);
      if (remote == null) return;
      final current = state.user;
      final updated = (current ?? remote).copyWith(
        name: remote.name.isNotEmpty ? remote.name : current?.name,
        rating: max(current?.rating ?? 0, remote.rating),
        profilePic:
            _resolveBestProfilePic(remote.profilePic, current?.profilePic),
        city: remote.city.isNotEmpty ? remote.city : current?.city,
        phone: remote.phone.isNotEmpty ? remote.phone : current?.phone,
      );
      await _save(updated);
      state = state.copyWith(user: updated);
    } catch (e) {
      debugPrint('[AuthViewModel] refreshUserFromRemote error: $e');
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  void _fail(String message) {
    state = state.copyWith(isLoading: false, errorMessage: message);
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final clean = email.trim().toLowerCase();
    if (!Validators.isEmail(clean)) {
      _fail('Enter the email address you registered with.');
      return false;
    }
    try {
      final id = await _auth.signInWithEmail(clean, password);
      await _completeSignIn(id, method: 'email');
      return true;
    } on AuthFailure catch (e) {
      // Accounts created before Firebase Authentication only exist on this
      // device. If the old password matches, move the account to Firebase.
      final legacy = await _storage.getRegisteredPassword(clean);
      if (legacy != null && legacy == password && password.length >= 6) {
        try {
          final name = _storage.getRegisteredName(clean) ?? '';
          final id = await _auth.createAccount(clean, password, name);
          await _storage.forgetLegacyPassword(clean);
          await _completeSignIn(id, method: 'email_migrated');
          return true;
        } on AuthFailure catch (m) {
          _fail(m.message);
          return false;
        }
      }
      _fail(e.message);
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    String city = '',
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final clean = email.trim().toLowerCase();
    if (name.trim().isEmpty) {
      _fail('Please enter your name.');
      return false;
    }
    if (!Validators.isEmail(clean)) {
      _fail('Please enter a valid email address.');
      return false;
    }
    if (password.length < 8) {
      _fail('Password must be at least 8 characters.');
      return false;
    }
    if (password != confirmPassword) {
      _fail('Passwords do not match.');
      return false;
    }
    try {
      final id = await _auth.createAccount(clean, password, name.trim());
      await _completeSignIn(id,
          method: 'email', name: name.trim(), city: city, isNew: true);
      return true;
    } on AuthFailure catch (e) {
      _fail(e.message);
      return false;
    }
  }

  /// Returns false when cancelled or failed; failures set [AuthState.errorMessage].
  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final id = await _auth.signInWithGoogle();
      if (id == null) {
        state = state.copyWith(isLoading: false);
        return false;
      }
      await _completeSignIn(id, method: 'google');
      return true;
    } on AuthFailure catch (e) {
      _fail(e.message);
      return false;
    }
  }

  /// Loads (or creates) the Firestore profile for a signed-in identity.
  Future<void> _completeSignIn(AuthIdentity id,
      {required String method,
      String? name,
      String city = '',
      bool isNew = false}) async {
    UserModel? remote;
    try {
      remote = await _firebase.fetchUserProfile(id.email);
    } catch (_) {}
    final local = _storage.getAccountData(id.email);
    final fallbackName = (name?.isNotEmpty ?? false)
        ? name!
        : (id.displayName?.trim().isNotEmpty ?? false)
            ? id.displayName!.trim()
            : _nameFromEmail(id.email);

    final user = UserModel(
      name: (remote?.name.isNotEmpty ?? false)
          ? remote!.name
          : (local?.name.isNotEmpty ?? false)
              ? local!.name
              : fallbackName,
      email: id.email,
      phone: remote?.phone ?? local?.phone ?? '',
      profilePic: _resolveBestProfilePic(
          remote?.profilePic, local?.profilePic ?? id.photoUrl),
      dob: remote?.dob ?? local?.dob ?? '2000-01-01',
      rating: max(remote?.rating ?? 0, local?.rating ?? 0),
      city: (remote?.city.isNotEmpty ?? false)
          ? remote!.city
          : (local?.city ?? city),
    );

    await _save(user);
    await _storage.setLoggedIn(true);
    try {
      isNew || remote == null
          ? await _firebase.logSignUp(method)
          : await _firebase.logLogin(method);
      await _firebase.syncUserProfile(user);
    } catch (_) {}
    state = AuthState(isLoggedIn: true, user: user);
  }

  static String _nameFromEmail(String email) => email
      .split('@')
      .first
      .split(RegExp(r'[._]'))
      .where((s) => s.isNotEmpty)
      .map((s) => '${s[0].toUpperCase()}${s.substring(1)}')
      .join(' ');

  Future<void> _save(UserModel u) => _storage.saveUser(
        name: u.name,
        email: u.email,
        phone: u.phone,
        profilePic: u.profilePic ?? 'avatar_green',
        dob: u.dob,
        rating: u.rating,
        city: u.city,
      );

  Future<bool> sendPasswordReset(String email) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final clean = email.trim().toLowerCase();
    if (!Validators.isEmail(clean)) {
      _fail('Please enter a valid email address.');
      return false;
    }
    try {
      await _auth.sendPasswordReset(clean);
      state = state.copyWith(isLoading: false);
      return true;
    } on AuthFailure catch (e) {
      // Don't reveal whether an email is registered.
      if (e.code == 'user-not-found') {
        state = state.copyWith(isLoading: false);
        return true;
      }
      _fail(e.message);
      return false;
    }
  }

  Future<bool> changePassword(
      String current, String next, String confirm) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    if (next.length < 8) {
      _fail('New password must be at least 8 characters.');
      return false;
    }
    if (next != confirm) {
      _fail('New passwords do not match.');
      return false;
    }
    try {
      await _auth.changePassword(current, next);
      state = state.copyWith(isLoading: false);
      return true;
    } on AuthFailure catch (e) {
      _fail(e.code == 'invalid-credential' || e.code == 'wrong-password'
          ? 'Current password is incorrect.'
          : e.message);
      return false;
    }
  }

  /// Deletes the profile, test history and the sign-in account.
  Future<bool> deleteAccount({String? password}) async {
    final email = state.user?.email ?? _storage.userEmail;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _firebase.deleteUserData(email);
      await _auth.deleteAccount(password: password);
    } on AuthFailure catch (e) {
      _fail(e.code == 'invalid-credential' || e.code == 'wrong-password'
          ? 'Password is incorrect.'
          : e.message);
      return false;
    } catch (e) {
      _fail('Could not delete your data. Check your connection and try again.');
      return false;
    }
    await _storage.clearUser();
    state = AuthState(isLoggedIn: false, user: null);
    return true;
  }

  Future<void> updateRating(int delta) async {
    if (state.user == null) return;
    final updated =
        state.user!.copyWith(rating: max(0, state.user!.rating + delta));
    await _save(updated);
    try {
      await _firebase.syncUserProfile(updated);
    } catch (_) {}
    state = state.copyWith(user: updated);
  }

  /// Updates name, phone, city, photo and date of birth. The email is the
  /// sign-in identity and can't be changed here.
  Future<void> updateProfile({
    required String name,
    String? phone,
    String? profilePic,
    String? dob,
    String? city,
  }) async {
    if (state.user == null) return;
    state = state.copyWith(isLoading: true);
    final updated = state.user!.copyWith(
      name: name.trim(),
      phone: phone?.trim(),
      profilePic: profilePic,
      dob: dob,
      city: city?.trim(),
    );
    await _save(updated);
    try {
      await _firebase.syncUserProfile(updated);
    } catch (_) {}
    state = state.copyWith(isLoading: false, user: updated);
  }

  Future<void> logout() async {
    await _auth.signOut();
    await _storage.clearUser();
    state = AuthState(isLoggedIn: false, user: null);
  }
}

final authViewModelProvider =
    StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  return AuthViewModel(
    ref.watch(storageServiceProvider),
    ref.watch(firebaseServiceProvider),
    ref.watch(authGatewayProvider),
  );
});
