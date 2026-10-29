import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Who is signed in, as confirmed by Firebase Authentication.
class AuthIdentity {
  final String email;
  final String? displayName;
  final String? photoUrl;
  const AuthIdentity(this.email, {this.displayName, this.photoUrl});
}

/// A sign-in problem with a message that can be shown to the user as-is.
class AuthFailure implements Exception {
  final String message;
  final String code;
  const AuthFailure(this.message, [this.code = 'unknown']);
  @override
  String toString() => message;
}

/// The only place that talks to Firebase Auth and Google Sign-In, so the
/// view model can be tested without either.
abstract class AuthGateway {
  /// Email of the restored Firebase session, or null when signed out. On web
  /// the session restores asynchronously, so this waits for the first event.
  Future<String?> restoredEmail();

  /// True when the current account can sign in with a password (so password
  /// change and re-authentication by password make sense).
  bool get hasPassword;

  Future<AuthIdentity> signInWithEmail(String email, String password);
  Future<AuthIdentity> createAccount(String email, String password, String name);

  /// Returns null when the user closes the account picker.
  Future<AuthIdentity?> signInWithGoogle();

  Future<void> sendPasswordReset(String email);
  Future<void> changePassword(String current, String next);

  /// Deletes the Firebase account. Password accounts confirm with [password];
  /// Google accounts confirm by picking the account again.
  Future<void> deleteAccount({String? password});
  Future<void> signOut();
}

class FirebaseAuthGateway implements AuthGateway {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  bool get _ready => Firebase.apps.isNotEmpty;
  bool _googleReady = false;

  @override
  Future<String?> restoredEmail() async {
    if (!_ready) return null;
    final now = _auth.currentUser;
    if (now != null || !kIsWeb) return now?.email?.toLowerCase();
    final user = await _auth
        .authStateChanges()
        .first
        .timeout(const Duration(seconds: 6), onTimeout: () => null);
    return user?.email?.toLowerCase();
  }

  @override
  bool get hasPassword =>
      _ready &&
      (_auth.currentUser?.providerData.any((p) => p.providerId == 'password') ?? false);

  AuthIdentity _identity(User u) => AuthIdentity(
        (u.email ?? '').toLowerCase(),
        displayName: u.displayName,
        photoUrl: u.photoURL,
      );

  Future<T> _guard<T>(Future<T> Function() run) async {
    if (!_ready) {
      throw const AuthFailure('Can\'t reach the sign-in service. Check your connection and try again.', 'no-firebase');
    }
    try {
      return await run();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_message(e.code), e.code);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthFailure('cancelled', 'cancelled');
      }
      debugPrint('[GoogleSignIn] ${e.code}: ${e.description}');
      throw const AuthFailure(
          'Google sign-in isn\'t available right now. Use email and password, or try again later.',
          'google-unavailable');
    }
  }

  static String _message(String code) => switch (code) {
        'invalid-email' => 'That email address doesn\'t look right.',
        'user-disabled' => 'This account has been disabled.',
        'user-not-found' || 'wrong-password' || 'invalid-credential' || 'INVALID_LOGIN_CREDENTIALS' =>
          'Email or password is incorrect.',
        'email-already-in-use' => 'An account already exists for this email. Sign in instead.',
        'weak-password' => 'Choose a stronger password (at least 8 characters).',
        'too-many-requests' => 'Too many attempts. Wait a few minutes and try again.',
        'network-request-failed' => 'No internet connection. Check your network and try again.',
        'requires-recent-login' => 'For your security, sign in again and retry.',
        'account-exists-with-different-credential' =>
          'This email is already registered with a different sign-in method.',
        'popup-blocked' => 'Your browser blocked the sign-in window. Allow pop-ups and try again.',
        'popup-closed-by-user' || 'cancelled-popup-request' => 'cancelled',
        'operation-not-allowed' =>
          'This sign-in method isn\'t switched on yet. Use Continue with Google for now.',
        _ => 'Something went wrong. Please try again.',
      };

  @override
  Future<AuthIdentity> signInWithEmail(String email, String password) => _guard(() async {
        final c = await _auth.signInWithEmailAndPassword(email: email, password: password);
        return _identity(c.user!);
      });

  @override
  Future<AuthIdentity> createAccount(String email, String password, String name) => _guard(() async {
        final c = await _auth.createUserWithEmailAndPassword(email: email, password: password);
        final u = c.user!;
        await u.updateDisplayName(name);
        try {
          await u.sendEmailVerification();
        } catch (_) {}
        return AuthIdentity(email, displayName: name);
      });

  Future<void> _initGoogle() async {
    if (_googleReady) return;
    await GoogleSignIn.instance.initialize();
    _googleReady = true;
  }

  @override
  Future<AuthIdentity?> signInWithGoogle() async {
    try {
      return await _guard(() async {
        if (kIsWeb) {
          final provider = GoogleAuthProvider()..setCustomParameters({'prompt': 'select_account'});
          final c = await _auth.signInWithPopup(provider);
          return _identity(c.user!);
        }
        await _initGoogle();
        // Android shows the system Credential Manager sheet; iOS the Google sheet.
        final account = await GoogleSignIn.instance.authenticate(scopeHint: const ['email']);
        final idToken = account.authentication.idToken;
        if (idToken == null) {
          throw const AuthFailure('Google didn\'t return a sign-in token. Please try again.');
        }
        final c = await _auth.signInWithCredential(GoogleAuthProvider.credential(idToken: idToken));
        return _identity(c.user!);
      });
    } on AuthFailure catch (e) {
      if (e.code == 'cancelled' || e.message == 'cancelled') return null;
      rethrow;
    }
  }

  @override
  Future<void> sendPasswordReset(String email) =>
      _guard(() => _auth.sendPasswordResetEmail(email: email));

  @override
  Future<void> changePassword(String current, String next) => _guard(() async {
        final u = _auth.currentUser;
        if (u == null || u.email == null) throw const AuthFailure('Please sign in again.');
        await u.reauthenticateWithCredential(
            EmailAuthProvider.credential(email: u.email!, password: current));
        await u.updatePassword(next);
      });

  @override
  Future<void> deleteAccount({String? password}) => _guard(() async {
        final u = _auth.currentUser;
        if (u == null) throw const AuthFailure('Please sign in again.');
        if (password != null && u.email != null) {
          await u.reauthenticateWithCredential(
              EmailAuthProvider.credential(email: u.email!, password: password));
        } else if (!kIsWeb) {
          await _initGoogle();
          final account = await GoogleSignIn.instance.authenticate();
          final token = account.authentication.idToken;
          if (token != null) {
            await u.reauthenticateWithCredential(GoogleAuthProvider.credential(idToken: token));
          }
        } else {
          await u.reauthenticateWithPopup(GoogleAuthProvider());
        }
        await u.delete();
      });

  @override
  Future<void> signOut() async {
    try {
      if (_ready) await _auth.signOut();
      if (!kIsWeb && _googleReady) await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }
}

final authGatewayProvider = Provider<AuthGateway>((ref) => FirebaseAuthGateway());
