import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/service_providers.dart';
import '../../../models/user_model.dart';

final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return AuthViewModel(storage);
});

class AuthState {
  final bool isLoggedIn;
  final bool isLoading;
  final UserModel? user;
  final String? errorMessage;

  AuthState({
    required this.isLoggedIn,
    this.isLoading = false,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    bool? isLoading,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthViewModel extends StateNotifier<AuthState> {
  final StorageService _storage;

  AuthViewModel(this._storage)
      : super(AuthState(
          isLoggedIn: _storage.isLoggedIn,
          user: _storage.isLoggedIn
              ? UserModel(
                  name: _storage.userName,
                  email: _storage.userEmail,
                  phone: _storage.userPhone,
                )
              : null,
        ));

  Future<bool> login(String emailOrPhone, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    // Mock validation & network latency simulation
    await Future.delayed(const Duration(milliseconds: 600));

    if (emailOrPhone.isEmpty || password.isEmpty) {
      state = state.copyWith(isLoading: false, errorMessage: 'Fields cannot be empty');
      return false;
    }

    if (password.length < 6) {
      state = state.copyWith(isLoading: false, errorMessage: 'Password must be at least 6 characters');
      return false;
    }

    String extractedName = 'Student Name';
    if (emailOrPhone.contains('@')) {
      final part = emailOrPhone.split('@').first;
      extractedName = part.substring(0, 1).toUpperCase() + part.substring(1);
    } else if (emailOrPhone.isNotEmpty) {
      extractedName = 'Student Name';
    }

    final user = UserModel(
      name: extractedName,
      email: emailOrPhone.contains('@') ? emailOrPhone : 'student@arunachal.in',
      phone: emailOrPhone.contains('@') ? '9876543210' : emailOrPhone,
    );

    await _storage.saveUser(name: user.name, email: user.email, phone: user.phone);
    await _storage.setLoggedIn(true);

    state = AuthState(isLoggedIn: true, user: user);
    return true;
  }

  Future<bool> register(String emailOrPhone, String password, String confirmPassword) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    await Future.delayed(const Duration(milliseconds: 600));

    if (emailOrPhone.isEmpty || password.isEmpty) {
      state = state.copyWith(isLoading: false, errorMessage: 'Fields cannot be empty');
      return false;
    }

    if (password != confirmPassword) {
      state = state.copyWith(isLoading: false, errorMessage: 'Passwords do not match');
      return false;
    }

    if (password.length < 6) {
      state = state.copyWith(isLoading: false, errorMessage: 'Password must be at least 6 characters');
      return false;
    }

    String extractedName = 'Student Name';
    if (emailOrPhone.contains('@')) {
      final part = emailOrPhone.split('@').first;
      extractedName = part.substring(0, 1).toUpperCase() + part.substring(1);
    }

    final user = UserModel(
      name: extractedName,
      email: emailOrPhone.contains('@') ? emailOrPhone : 'student@arunachal.in',
      phone: emailOrPhone.contains('@') ? '9876543210' : emailOrPhone,
    );

    await _storage.saveUser(name: user.name, email: user.email, phone: user.phone);
    await _storage.setLoggedIn(true);

    state = AuthState(isLoggedIn: true, user: user);
    return true;
  }

  Future<void> updateProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    if (state.user == null) return;
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 300));
    await _storage.saveUser(name: name, email: email, phone: phone);
    final updated = state.user!.copyWith(name: name, email: email, phone: phone);
    state = state.copyWith(isLoading: false, user: updated);
  }

  Future<void> logout() async {
    await _storage.clearUser();
    state = AuthState(isLoggedIn: false);
  }
}
