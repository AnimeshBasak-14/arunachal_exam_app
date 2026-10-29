/// Build-time secrets. Never hardcode key values in source.
///
/// For local development only:
///   flutter run --dart-define=GEMINI_API_KEY=...
///
/// Release builds are built without it; the AI tutor then goes through the
/// `ai-tutor` server proxy (see docs/LAUNCH_SETUP.md). Never build a release
/// with `--dart-define-from-file=.env`: that file also holds server secrets.
class AppSecrets {
  AppSecrets._();

  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  static bool get hasGeminiKey => geminiApiKey.isNotEmpty;
}
