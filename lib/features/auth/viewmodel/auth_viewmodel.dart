import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:firebase_core/firebase_core.dart' hide FirebaseService;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/firebase_service.dart';
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

class AuthViewModel extends StateNotifier<AuthState> {
  final StorageService _storage;
  final FirebaseService _firebase;

  AuthViewModel(this._storage, this._firebase)
      : super(AuthState(
          isLoggedIn: _storage.isLoggedIn,
          user: _storage.isLoggedIn
              ? (_storage.getAccountData(_storage.userEmail) ??
                  UserModel(
                    name: _storage.userName,
                    email: _storage.userEmail,
                    phone: _storage.userPhone,
                    profilePic: _storage.userProfilePic,
                    dob: _storage.userDob,
                    rating: _storage.userRating,
                    city: _storage.userCity,
                  ))
              : null,
        )) {
    if (_storage.isLoggedIn && _storage.userEmail.isNotEmpty) {
      refreshUserFromRemote();
    }
  }

  static String _resolveBestProfilePic(String? remotePic, String? localPic,
      [String fallback = 'avatar_green']) {
    final cleanRemote = (remotePic ?? '').trim();
    final cleanLocal = (localPic ?? '').trim();

    // 1. Prefer custom uploaded picture from remote
    if (cleanRemote.isNotEmpty && !cleanRemote.startsWith('avatar_')) {
      return cleanRemote;
    }
    // 2. Prefer custom uploaded picture from local
    if (cleanLocal.isNotEmpty && !cleanLocal.startsWith('avatar_')) {
      return cleanLocal;
    }
    // 3. Use preset avatar from remote or local
    if (cleanRemote.isNotEmpty) return cleanRemote;
    if (cleanLocal.isNotEmpty) return cleanLocal;
    return fallback;
  }

  Future<void> refreshUserFromRemote() async {
    try {
      final email = _storage.userEmail;
      if (email.isEmpty) return;
      final remote = await _firebase.fetchUserProfile(email);
      if (remote != null) {
        final current = state.user;
        final bestRating = max(current?.rating ?? 0, remote.rating);
        final effectivePic = _resolveBestProfilePic(remote.profilePic, current?.profilePic);

        final updated = (current ?? remote).copyWith(
          name: remote.name.isNotEmpty ? remote.name : current?.name,
          rating: bestRating,
          profilePic: effectivePic,
          city: remote.city.isNotEmpty ? remote.city : current?.city,
        );

        await _storage.saveUser(
          name: updated.name,
          email: updated.email,
          phone: updated.phone,
          profilePic: updated.profilePic,
          dob: updated.dob,
          rating: updated.rating,
          city: updated.city,
        );
        state = state.copyWith(user: updated);
      }
    } catch (e) {
      debugPrint('[AuthViewModel] refreshUserFromRemote error: $e');
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  Future<bool> login(
    String emailOrPhone,
    String password,
  ) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    await Future.delayed(const Duration(milliseconds: 500));

    final cleanInput = emailOrPhone.trim().toLowerCase();
    final isGmail = cleanInput.endsWith('@gmail.com');
    final isPhone = RegExp(r'^\d{10}$').hasMatch(cleanInput);

    if (!isGmail && !isPhone) {
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            'Invalid ID. Only Gmail (@gmail.com) or 10-digit Phone numbers allowed.',
      );
      return false;
    }

    final registeredPassword = await _storage.getRegisteredPassword(cleanInput);
    if (registeredPassword == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Account does not exist. Please register first.',
      );
      return false;
    }

    if (registeredPassword != password) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Incorrect password. Please try again.',
      );
      return false;
    }

    // Load per-account reserved model if present
    final existingAccount = _storage.getAccountData(cleanInput);
    UserModel user = existingAccount ??
        UserModel(
          name: _storage.getRegisteredName(cleanInput) ?? 'Student Name',
          email: isGmail ? cleanInput : '',
          phone: isPhone ? cleanInput : '',
          profilePic: _storage.userProfilePic,
          dob: _storage.getRegisteredDob(cleanInput) ?? '2000-01-01',
          rating: _storage.getRegisteredRating(cleanInput),
          city: _storage.getRegisteredCity(cleanInput),
        );

    // Sync cloud rating & profilePic from Firestore if available
    try {
      final remoteUser = await _firebase.fetchUserProfile(cleanInput);
      if (remoteUser != null) {
        final bestRating = max(user.rating, remoteUser.rating);
        final effectivePic = _resolveBestProfilePic(remoteUser.profilePic, user.profilePic);
        user = user.copyWith(
          name: remoteUser.name.isNotEmpty ? remoteUser.name : user.name,
          rating: bestRating,
          profilePic: effectivePic,
          city: remoteUser.city.isNotEmpty ? remoteUser.city : user.city,
        );
      }
    } catch (_) {}

    await _storage.saveUser(
      name: user.name,
      email: user.email,
      phone: user.phone,
      profilePic: user.profilePic,
      dob: user.dob,
      rating: user.rating,
      city: user.city,
    );
    await _storage.setLoggedIn(true);

    // Sync with Firestore & Analytics
    try {
      await _firebase.logLogin('email_or_phone');
      await _firebase.syncUserProfile(user);
    } catch (_) {}

    state = AuthState(isLoggedIn: true, user: user);
    return true;
  }

  Future<void> updateRating(int delta) async {
    if (state.user == null) return;
    final newRating = max(0, state.user!.rating + delta);
    final updated = state.user!.copyWith(rating: newRating);
    await _storage.saveUser(
      name: updated.name,
      email: updated.email,
      phone: updated.phone,
      profilePic: updated.profilePic,
      dob: updated.dob,
      rating: newRating,
      city: updated.city,
    );
    try {
      await _firebase.syncUserProfile(updated);
    } catch (_) {}
    state = state.copyWith(user: updated);
  }

  Future<bool> register({
    required String name,
    required String emailOrPhone,
    required String dob,
    required String password,
    required String confirmPassword,
    required String otpEntered,
    required String otpSent,
    String city = 'Itanagar',
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    await Future.delayed(const Duration(milliseconds: 500));

    final cleanInput = emailOrPhone.trim().toLowerCase();
    final isGmail = cleanInput.endsWith('@gmail.com');
    final isPhone = RegExp(r'^\d{10}$').hasMatch(cleanInput);

    if (name.trim().isEmpty) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Please enter your name');
      return false;
    }

    if (!isGmail && !isPhone) {
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            'Only Gmail (@gmail.com) or 10-digit Phone numbers are allowed.',
      );
      return false;
    }

    // Check if account already exists
    final existingPwd = await _storage.getRegisteredPassword(cleanInput);
    if (existingPwd != null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            'An account already exists for this Gmail/Phone. Please log in.',
      );
      return false;
    }

    if (otpEntered.isEmpty || otpEntered != otpSent) {
      state = state.copyWith(
          isLoading: false,
          errorMessage: 'Wrong OTP entered. Please check and try again.');
      return false;
    }

    if (password != confirmPassword) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Passwords do not match');
      return false;
    }

    if (password.length < 6) {
      state = state.copyWith(
          isLoading: false,
          errorMessage: 'Password must be at least 6 characters');
      return false;
    }

    final user = UserModel(
      name: name,
      email: isGmail ? cleanInput : '',
      phone: isPhone ? cleanInput : '',
      profilePic: 'avatar_green',
      dob: dob,
      rating: 0,
      city: city,
    );

    // Persist credentials in local storage database
    await _storage.registerUserAccount(
      emailOrPhone: cleanInput,
      password: password,
      name: name,
      dob: dob,
      rating: 0,
      city: city,
    );

    // Save active logged-in user profile & account dictionary
    await _storage.saveUser(
      name: user.name,
      email: user.email,
      phone: user.phone,
      profilePic: user.profilePic,
      dob: user.dob,
      rating: user.rating,
      city: user.city,
    );
    await _storage.setLoggedIn(true);

    // Sync with Firestore & Analytics
    try {
      await _firebase.logSignUp('manual_register');
      await _firebase.syncUserProfile(user);
    } catch (_) {}

    state = AuthState(isLoggedIn: true, user: user);
    return true;
  }

  Future<bool> loginSocial(String provider, {String? email}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await Future.delayed(const Duration(milliseconds: 400));

    final selectedEmail = (email ?? '').trim().toLowerCase();

    // Check if user previously existed with this email
    final savedAccount = selectedEmail.isNotEmpty ? _storage.getAccountData(selectedEmail) : null;

    final UserModel user;
    if (savedAccount != null) {
      // Restore previously saved profile, rating, and city!
      user = savedAccount;
    } else {
      final parts = selectedEmail.isNotEmpty ? selectedEmail.split('@')[0].split('.') : ['Social', 'User'];
      final capName = parts.map((w) {
        if (w.isEmpty) return '';
        return w[0].toUpperCase() + w.substring(1);
      }).join(' ');

      user = UserModel(
        name: capName.isNotEmpty ? capName : 'Social User',
        email: selectedEmail,
        phone: '',
        profilePic: 'avatar_gold',
        dob: '2000-01-01',
        rating: 0,
        city: 'Itanagar',
      );

      // Generate a cryptographically secure random password for social login accounts
      final securePassword = _generateSecureRandomPassword();

      // Register account credentials if new
      if (selectedEmail.isNotEmpty) {
        await _storage.registerUserAccount(
          emailOrPhone: user.email,
          password: securePassword,
          name: user.name,
          dob: user.dob,
          rating: 0,
          city: 'Itanagar',
        );
      }
    }

    await _storage.saveUser(
      name: user.name,
      email: user.email,
      phone: user.phone,
      profilePic: user.profilePic,
      dob: user.dob,
      rating: user.rating,
      city: user.city,
    );
    await _storage.setLoggedIn(true);

    // Sync with Firestore & Analytics
    try {
      await _firebase.logLogin(provider);
      await _firebase.syncUserProfile(user);
    } catch (_) {}

    state = AuthState(isLoggedIn: true, user: user);
    return true;
  }

  Future<bool> loginWithGoogleAccount({
    required String email,
    String? displayName,
    String? photoUrl,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final cleanEmail = email.trim().toLowerCase();
      if (cleanEmail.isEmpty) {
        state = state.copyWith(isLoading: false);
        return false;
      }

      // 1. Check cloud profile in Firestore first
      final remoteUser = await _firebase.fetchUserProfile(cleanEmail);
      final savedAccount = _storage.getAccountData(cleanEmail);

      final rawName = (displayName != null && displayName.trim().isNotEmpty)
          ? displayName.trim()
          : (remoteUser != null && remoteUser.name.isNotEmpty)
              ? remoteUser.name
              : cleanEmail
                  .split('@')[0]
                  .split('.')
                  .map((s) => s.isNotEmpty
                      ? '${s[0].toUpperCase()}${s.substring(1)}'
                      : '')
                  .join(' ');
      final name = rawName.isNotEmpty ? rawName : 'Google Student';

      // Pick best profile picture (preserve custom upload if exists)
      final String effectivePic = _resolveBestProfilePic(
        remoteUser?.profilePic,
        (photoUrl != null && photoUrl.isNotEmpty)
            ? photoUrl
            : savedAccount?.profilePic,
        'avatar_gold',
      );

      // Pick highest rating (NEVER reset to zero!)
      final int effectiveRating = max(
        remoteUser?.rating ?? 0,
        savedAccount?.rating ?? 0,
      );

      final UserModel user = UserModel(
        name: (savedAccount?.name.isNotEmpty == true) ? savedAccount!.name : name,
        email: cleanEmail,
        phone: remoteUser?.phone ?? savedAccount?.phone ?? '',
        profilePic: effectivePic,
        dob: remoteUser?.dob ?? savedAccount?.dob ?? '2000-01-01',
        rating: effectiveRating,
        city: remoteUser?.city ?? savedAccount?.city ?? 'Itanagar',
      );

      final securePassword = _generateSecureRandomPassword();
      await _storage.registerUserAccount(
        emailOrPhone: cleanEmail,
        password: securePassword,
        name: user.name,
        dob: user.dob,
        rating: user.rating,
        city: user.city,
      );

      await _storage.saveUser(
        name: user.name,
        email: user.email,
        phone: user.phone,
        profilePic: user.profilePic,
        dob: user.dob,
        rating: user.rating,
        city: user.city,
      );
      await _storage.setLoggedIn(true);

      try {
        await _firebase.logLogin('google');
        await _firebase.syncUserProfile(user);
      } catch (_) {}

      state = AuthState(isLoggedIn: true, user: user);
      return true;
    } catch (e) {
      debugPrint('[GoogleAccountLogin] Error: $e');
      state = state.copyWith(
          isLoading: false, errorMessage: 'Failed to sign in: $e');
      return false;
    }
  }

  Future<bool> loginWithGoogleNative() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        googleProvider.setCustomParameters({'prompt': 'select_account'});

        final userCredential =
            await FirebaseAuth.instance.signInWithPopup(googleProvider);
        final user = userCredential.user;
        if (user == null || user.email == null || user.email!.isEmpty) {
          state = state.copyWith(isLoading: false);
          return false;
        }

        return await loginWithGoogleAccount(
          email: user.email!,
          displayName: user.displayName,
          photoUrl: user.photoURL,
        );
      } else {
        // 1. First try the Android system account picker via native MethodChannel.
        // AccountManager.newChooseAccountIntent displays the exact system bottom sheet
        // with all Google accounts on device. Once the user selects their account,
        // it directly returns the email without failing on OAuth client verification.
        bool methodChannelFailed = false;
        String? selectedEmail;
        try {
          const channel =
              MethodChannel('com.example.arunachal_exam_app/google_auth');
          selectedEmail =
              await channel.invokeMethod<String>('pickGoogleAccount');
        } catch (e) {
          debugPrint('[GoogleAccountPicker] MethodChannel error: $e');
          methodChannelFailed = true;
        }

        if (!methodChannelFailed) {
          if (selectedEmail != null && selectedEmail.trim().isNotEmpty) {
            return await loginWithGoogleAccount(
              email: selectedEmail.trim(),
            );
          }
          // User dismissed or cancelled the native account chooser
          state = state.copyWith(isLoading: false);
          return false;
        }

        // 2. Fallback to GoogleSignIn plugin if MethodChannel was not available
        final googleSignIn = GoogleSignIn();
        final account = await googleSignIn.signIn();
        if (account == null) {
          state = state.copyWith(isLoading: false);
          return false;
        }

        return await loginWithGoogleAccount(
          email: account.email,
          displayName: account.displayName,
          photoUrl: account.photoUrl,
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint(
          '[GoogleSignIn Web] FirebaseAuthException: ${e.code} - ${e.message}');
      String? message;
      if (e.code == 'popup-closed-by-user' || e.code == 'cancelled') {
        message = null; // User simply closed the popup
      } else if (e.code == 'popup-blocked') {
        message =
            'Popup was blocked by your browser. Please allow popups for this site.';
      } else if (e.code == 'configuration-not-found') {
        message =
            'Google Sign-In is not enabled yet in Firebase Console. Enable "Google" under Firebase Console > Authentication > Sign-in method (100% Free).';
      } else if (e.code == 'unauthorized-domain') {
        message =
            'Domain not authorized. Please add animeshbasak-14.github.io in Firebase Console > Authentication > Settings > Authorized domains.';
      } else {
        message = (e.message != null && e.message!.isNotEmpty && e.message != 'Error')
            ? e.message!
            : 'Google Sign-In is initializing. Please try again or sign in with your email.';
      }
      state = state.copyWith(isLoading: false, errorMessage: message);
      return false;
    } catch (e) {
      debugPrint('[GoogleSignIn] Native sign-in error or cancelled: $e');
      final errStr = e.toString().toLowerCase();
      final String? message = (errStr.contains('cancel') ||
              errStr.contains('popup_closed') ||
              errStr.contains('canceled'))
          ? null
          : 'Google sign-in could not be completed. Please try again.';
      state = state.copyWith(isLoading: false, errorMessage: message);
      return false;
    }
  }

  Future<void> updateProfile({
    required String name,
    required String email,
    required String phone,
    String? profilePic,
    String? dob,
    int? rating,
    String? city,
  }) async {
    if (state.user == null) return;
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 200));

    final selectedPic = profilePic ?? state.user!.profilePic;
    final selectedDob = dob ?? state.user!.dob;
    final selectedRating = rating ?? state.user!.rating;
    final selectedCity = city ?? state.user!.city;

    // Update registered paths
    await _storage.updateRegisteredAccount(
        state.user!.email, email, name, selectedDob, selectedRating);
    if (state.user!.phone.isNotEmpty) {
      await _storage.updateRegisteredAccount(
          state.user!.phone, phone, name, selectedDob, selectedRating);
    }

    await _storage.saveUser(
      name: name,
      email: email,
      phone: phone,
      profilePic: selectedPic,
      dob: selectedDob,
      rating: selectedRating,
      city: selectedCity,
    );

    final updated = state.user!.copyWith(
      name: name,
      email: email,
      phone: phone,
      profilePic: selectedPic,
      dob: selectedDob,
      rating: selectedRating,
      city: selectedCity,
    );

    // Sync profile updates to Firestore
    try {
      await _firebase.syncUserProfile(updated);
    } catch (_) {}

    state = state.copyWith(isLoading: false, user: updated);
  }

  static String _generateSecureRandomPassword([int length = 32]) {
    final random = Random.secure();
    final values = List<int>.generate(length, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  Future<void> logout() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseAuth.instance.signOut();
      }
      if (!kIsWeb) {
        await GoogleSignIn().signOut();
      }
    } catch (_) {}
    await _storage.clearUser();
    state = AuthState(isLoggedIn: false, user: null);
  }
}

final authViewModelProvider =
    StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final firebase = ref.watch(firebaseServiceProvider);
  return AuthViewModel(storage, firebase);
});
