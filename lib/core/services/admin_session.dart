import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/supabase_config.dart';

/// Supabase Auth session for the admin screens.
///
/// Question/catalog writes are only allowed by RLS for signed-in users listed
/// in `public.admin_users` (see migrations/006_lock_down_writes.sql). The
/// publishable key alone can read, but can no longer write.
class AdminSession {
  AdminSession._();

  static String get supabaseUrl => SupabaseConfig.url;
  static String get publishableKey => SupabaseConfig.anonKey;

  static String? _accessToken;
  static DateTime? _expiresAt;
  static String? email;

  static bool get isSignedIn =>
      _accessToken != null &&
      _expiresAt != null &&
      DateTime.now().isBefore(_expiresAt!);

  /// Value for the `Authorization` header on admin REST calls.
  static String get bearer => 'Bearer ${isSignedIn ? _accessToken : publishableKey}';

  /// Signs in with Supabase Auth and confirms the account is an admin.
  /// Returns null on success, or an error message.
  static Future<String?> signIn(String emailInput, String password) async {
    final res = await http.post(
      Uri.parse('$supabaseUrl/auth/v1/token?grant_type=password'),
      headers: {'apikey': publishableKey, 'Content-Type': 'application/json'},
      body: jsonEncode({'email': emailInput.trim(), 'password': password}),
    );
    if (res.statusCode != 200) {
      return 'Sign-in failed. Check email and password.';
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final token = data['access_token'] as String?;
    final expiresIn = (data['expires_in'] as num?)?.toInt() ?? 3600;
    if (token == null) return 'Sign-in failed.';

    final check = await http.post(
      Uri.parse('$supabaseUrl/rest/v1/rpc/is_admin'),
      headers: {
        'apikey': publishableKey,
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: '{}',
    );
    if (check.statusCode != 200 || check.body.trim() != 'true') {
      return 'This account is not an admin.';
    }

    _accessToken = token;
    // Refresh a minute early so writes never go out with an expired token.
    _expiresAt = DateTime.now().add(Duration(seconds: expiresIn - 60));
    email = emailInput.trim();
    return null;
  }

  static void signOut() {
    _accessToken = null;
    _expiresAt = null;
    email = null;
  }
}
