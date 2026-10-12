/// Build-time secrets. Never hardcode key values in source.
///
/// Values come from the gitignored `.env` file at build time:
///   flutter run --dart-define-from-file=.env
///   flutter build apk --release --dart-define-from-file=.env
///
/// Note: anything compiled into the app can be extracted from the APK or web
/// bundle. Restrict the Gemini key in Google Cloud Console (API restriction +
/// quota cap), and move calls behind a server proxy before a wide launch.
class AppSecrets {
  AppSecrets._();

  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  static bool get hasGeminiKey => geminiApiKey.isNotEmpty;
}
