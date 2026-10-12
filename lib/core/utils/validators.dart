/// Shared validation for account IDs (email or Indian 10-digit mobile).
class Validators {
  Validators._();

  static final RegExp _email =
      RegExp(r'^[a-z0-9._%+\-]+@[a-z0-9\-]+(\.[a-z0-9\-]+)*\.[a-z]{2,}$');
  static final RegExp _phone = RegExp(r'^\d{10}$');

  /// Expects input already trimmed and lowercased.
  static bool isEmail(String value) => _email.hasMatch(value);

  static bool isPhone(String value) => _phone.hasMatch(value);

  static const String invalidIdMessage =
      'Enter a valid email address or 10-digit phone number.';
}
