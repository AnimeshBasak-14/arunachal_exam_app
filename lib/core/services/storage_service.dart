import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserName = 'user_name';
  static const String _keyUserPhone = 'user_phone';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserProfilePic = 'user_profile_pic';
  static const String _keyUserDob = 'user_dob';
  static const String _keyUserRating = 'user_rating';
  static const String _keyUserCity = 'user_city';

  bool get isOnboardingCompleted =>
      _prefs.getBool(_keyOnboardingCompleted) ?? false;

  Future<void> setOnboardingCompleted(bool value) async {
    await _prefs.setBool(_keyOnboardingCompleted, value);
  }

  bool get isLoggedIn => _prefs.getBool(_keyIsLoggedIn) ?? false;

  Future<void> setLoggedIn(bool value) async {
    await _prefs.setBool(_keyIsLoggedIn, value);
  }

  String get userEmail =>
      _prefs.getString(_keyUserEmail) ?? 'student@arunachal.in';
  String get userName => _prefs.getString(_keyUserName) ?? 'Student Name';
  String get userPhone => _prefs.getString(_keyUserPhone) ?? '9876543210';
  String get userProfilePic =>
      _prefs.getString(_keyUserProfilePic) ?? 'avatar_green';
  String get userDob => _prefs.getString(_keyUserDob) ?? '2000-01-01';
  int get userRating => _prefs.getInt(_keyUserRating) ?? 1200;
  String get userCity => _prefs.getString(_keyUserCity) ?? 'Itanagar';

  String _cleanKey(String? key) => (key ?? userEmail).trim().toLowerCase();

  // Save current active session + per-account reserved data
  Future<void> saveUser({
    required String name,
    required String email,
    required String phone,
    String? profilePic,
    String? dob,
    int? rating,
    String? city,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPhone = phone.trim().toLowerCase();

    final pic = profilePic ?? userProfilePic;
    final birthDate = dob ?? userDob;
    final currentRating = rating ?? userRating;
    final currentCity = city ?? (userCity.isNotEmpty ? userCity : 'Itanagar');

    final writes = <Future<bool>>[
      _prefs.setString(_keyUserName, name),
      _prefs.setString(_keyUserEmail, email),
      _prefs.setString(_keyUserPhone, phone),
      _prefs.setString(_keyUserProfilePic, pic),
      _prefs.setString(_keyUserDob, birthDate),
      _prefs.setInt(_keyUserRating, currentRating),
      _prefs.setString(_keyUserCity, currentCity),
    ];

    // Save per-account reserved model
    final userMap = {
      'name': name,
      'email': email,
      'phone': phone,
      'profilePic': pic,
      'dob': birthDate,
      'rating': currentRating,
      'city': currentCity,
    };
    final encoded = jsonEncode(userMap);
    if (cleanEmail.isNotEmpty) {
      writes.add(_prefs.setString('account_data_$cleanEmail', encoded));
    }
    if (cleanPhone.isNotEmpty) {
      writes.add(_prefs.setString('account_data_$cleanPhone', encoded));
    }

    await Future.wait(writes);
  }

  UserModel? getAccountData(String emailOrPhone) {
    final key = emailOrPhone.trim().toLowerCase();
    final raw = _prefs.getString('account_data_$key');
    if (raw != null) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        return UserModel(
          name: map['name'] as String? ?? 'Student Name',
          email: map['email'] as String? ?? emailOrPhone,
          phone: map['phone'] as String? ?? '9876543210',
          profilePic: map['profilePic'] as String? ?? 'avatar_green',
          dob: map['dob'] as String? ?? '2000-01-01',
          rating: (map['rating'] as num?)?.toInt() ?? 1200,
          city: map['city'] as String? ?? 'Itanagar',
        );
      } catch (_) {}
    }
    return null;
  }

  Future<void> setProfilePic(String value) async {
    await _prefs.setString(_keyUserProfilePic, value);
    final user = getAccountData(userEmail);
    if (user != null) {
      await saveUser(
        name: user.name,
        email: user.email,
        phone: user.phone,
        profilePic: value,
        dob: user.dob,
        rating: user.rating,
        city: user.city,
      );
    }
  }

  // Account Registry Persistence
  Future<void> registerUserAccount({
    required String emailOrPhone,
    required String password,
    required String name,
    String dob = '2000-01-01',
    int rating = 1200,
    String city = 'Itanagar',
  }) async {
    final key = emailOrPhone.trim().toLowerCase();
    await Future.wait([
      _prefs.setString('reg_pwd_$key', password),
      _prefs.setString('reg_name_$key', name),
      _prefs.setString('reg_dob_$key', dob),
      _prefs.setInt('reg_rating_$key', rating),
      _prefs.setString('reg_city_$key', city),
    ]);
  }

  String? getRegisteredPassword(String emailOrPhone) {
    final key = emailOrPhone.trim().toLowerCase();
    return _prefs.getString('reg_pwd_$key');
  }

  String? getRegisteredName(String emailOrPhone) {
    final key = emailOrPhone.trim().toLowerCase();
    return _prefs.getString('reg_name_$key');
  }

  String? getRegisteredDob(String emailOrPhone) {
    final key = emailOrPhone.trim().toLowerCase();
    return _prefs.getString('reg_dob_$key') ?? '2000-01-01';
  }

  int getRegisteredRating(String emailOrPhone) {
    final key = emailOrPhone.trim().toLowerCase();
    return _prefs.getInt('reg_rating_$key') ?? 1200;
  }

  String getRegisteredCity(String emailOrPhone) {
    final key = emailOrPhone.trim().toLowerCase();
    return _prefs.getString('reg_city_$key') ?? 'Itanagar';
  }

  Future<void> updateRegisteredAccount(
      String oldKey, String newKey, String name, String dob, int rating) async {
    final oldK = oldKey.trim().toLowerCase();
    final newK = newKey.trim().toLowerCase();
    final pwd = _prefs.getString('reg_pwd_$oldK');
    if (pwd != null) {
      final writes = <Future<bool>>[
        _prefs.setString('reg_pwd_$newK', pwd),
        _prefs.setString('reg_name_$newK', name),
        _prefs.setString('reg_dob_$newK', dob),
        _prefs.setInt('reg_rating_$newK', rating),
      ];
      if (oldK != newK) {
        writes.addAll([
          _prefs.remove('reg_pwd_$oldK'),
          _prefs.remove('reg_name_$oldK'),
          _prefs.remove('reg_dob_$oldK'),
          _prefs.remove('reg_rating_$oldK'),
        ]);
      }
      await Future.wait(writes);
    }
  }

  Future<void> updateRegisteredPassword(
      String emailOrPhone, String newPassword) async {
    final key = emailOrPhone.trim().toLowerCase();
    await _prefs.setString('reg_pwd_$key', newPassword);
  }

  // Per-User Quiz History Persistence
  List<String> getQuizHistory([String? emailOrPhone]) {
    final key = _cleanKey(emailOrPhone);
    final userSpecific = _prefs.getStringList('quiz_history_$key');
    if (userSpecific != null) return userSpecific;
    // Fallback to legacy global key if userSpecific is not created yet
    return _prefs.getStringList('quiz_history') ?? [];
  }

  Future<void> saveQuizHistory(List<String> history,
      [String? emailOrPhone]) async {
    final key = _cleanKey(emailOrPhone);
    await Future.wait([
      _prefs.setStringList('quiz_history_$key', history),
      _prefs.setStringList('quiz_history', history),
    ]);
  }

  // Per-User Question Bookmarks
  List<String> getBookmarkedQuestions([String? emailOrPhone]) {
    final key = _cleanKey(emailOrPhone);
    final userSpecific = _prefs.getStringList('bookmarked_questions_$key');
    if (userSpecific != null) return userSpecific;
    return _prefs.getStringList('bookmarked_questions') ?? [];
  }

  Future<void> toggleQuestionBookmark(String questionId,
      [String? emailOrPhone]) async {
    final key = _cleanKey(emailOrPhone);
    final list = getBookmarkedQuestions(key);
    if (list.contains(questionId)) {
      list.remove(questionId);
    } else {
      list.add(questionId);
    }
    await Future.wait([
      _prefs.setStringList('bookmarked_questions_$key', list),
      _prefs.setStringList('bookmarked_questions', list),
    ]);
  }

  // Question Comments
  List<String> getQuestionComments(String questionId) {
    return _prefs.getStringList('comments_$questionId') ?? [];
  }

  Future<void> addQuestionComment(String questionId, String comment) async {
    final list = getQuestionComments(questionId);
    list.add(comment);
    await _prefs.setStringList('comments_$questionId', list);
  }

  Future<void> clearUser() async {
    await Future.wait([
      _prefs.remove(_keyUserName),
      _prefs.remove(_keyUserEmail),
      _prefs.remove(_keyUserPhone),
      _prefs.remove(_keyUserProfilePic),
      _prefs.remove(_keyUserDob),
      _prefs.remove(_keyUserRating),
      _prefs.remove(_keyUserCity),
      _prefs.setBool(_keyIsLoggedIn, false),
    ]);
  }
}
