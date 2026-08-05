import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserName = 'user_name';
  static const String _keyUserPhone = 'user_phone';
  static const String _keyIsLoggedIn = 'is_logged_in';

  bool get isOnboardingCompleted => _prefs.getBool(_keyOnboardingCompleted) ?? false;

  Future<void> setOnboardingCompleted(bool value) async {
    await _prefs.setBool(_keyOnboardingCompleted, value);
  }

  bool get isLoggedIn => _prefs.getBool(_keyIsLoggedIn) ?? false;

  Future<void> setLoggedIn(bool value) async {
    await _prefs.setBool(_keyIsLoggedIn, value);
  }

  String get userEmail => _prefs.getString(_keyUserEmail) ?? 'student@exam.in';
  String get userName => _prefs.getString(_keyUserName) ?? 'Student Name';
  String get userPhone => _prefs.getString(_keyUserPhone) ?? '9876543210';

  Future<void> saveUser({
    required String name,
    required String email,
    required String phone,
  }) async {
    await _prefs.setString(_keyUserName, name);
    await _prefs.setString(_keyUserEmail, email);
    await _prefs.setString(_keyUserPhone, phone);
  }

  Future<void> clearUser() async {
    await _prefs.remove(_keyUserName);
    await _prefs.remove(_keyUserEmail);
    await _prefs.remove(_keyUserPhone);
    await _prefs.setBool(_keyIsLoggedIn, false);
  }
}
