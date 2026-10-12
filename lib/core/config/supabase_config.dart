/// Centralized Supabase Configuration.
/// Reads from build-time environment (--dart-define) with safe fallbacks.
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://fllopztywwblbucvaths.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_y68QKKHxBTZxBP3Sf1X7tw_zfFnXX8M',
  );

  static Map<String, String> get authHeaders => {
        'apikey': anonKey,
        'Authorization': 'Bearer $anonKey',
      };
}
