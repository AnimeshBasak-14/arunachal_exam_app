import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import '../config/supabase_config.dart';
import '../constants/app_secrets.dart';

/// One message in a conversation with the model.
class AiTurn {
  final bool fromUser;
  final String text;
  final String? imageBase64; // JPEG
  const AiTurn.user(this.text, {this.imageBase64}) : fromUser = true;
  const AiTurn.model(this.text)
      : fromUser = false,
        imageBase64 = null;
}

class AiException implements Exception {
  final String message;
  const AiException(this.message);
  @override
  String toString() => message;
}

/// Gemini access for the whole app.
///
/// Release builds should be built WITHOUT `GEMINI_API_KEY`: requests then go
/// to the `ai-tutor` Supabase Edge Function (supabase/functions/ai-tutor),
/// which keeps the key on the server and only answers signed-in users.
/// Debug builds with the key in `.env` call Gemini directly.
class AiService {
  AiService._();

  static const model = 'gemini-3.6-flash';

  static const tutorPrompt =
      'You are Dawnlit\'s tutor for Arunachal Pradesh state exams (APPSC CCE, APSSB CGL/CHSL/MTS). Answer clearly and accurately for an exam aspirant. Use short paragraphs and '
      'bullet points, highlight key facts, and end with a one-line memory tip when useful. If you are not '
      'sure of a fact (dates, office-holders, numbers), say so and suggest checking the official source. '
      'Do not claim to represent APPSC, APSSB or the government.';

  static bool get usesProxy => !AppSecrets.hasGeminiKey;

  static Future<String> generate(List<AiTurn> turns,
      {String system = tutorPrompt, Duration timeout = const Duration(seconds: 45)}) async {
    final body = {
      'system_instruction': {
        'parts': [
          {'text': system}
        ]
      },
      'contents': [
        for (final t in turns)
          {
            'role': t.fromUser ? 'user' : 'model',
            'parts': [
              if (t.imageBase64 != null)
                {
                  'inline_data': {'mime_type': 'image/jpeg', 'data': t.imageBase64}
                },
              {'text': t.text},
            ],
          }
      ],
    };

    final http.Response res;
    try {
      res = usesProxy ? await _viaProxy(body, timeout) : await _direct(body, timeout);
    } on TimeoutException {
      throw const AiException('The tutor took too long to answer. Please try again.');
    } on AiException {
      rethrow;
    } catch (_) {
      throw const AiException('Couldn\'t reach the tutor. Check your internet connection.');
    }

    if (res.statusCode == 429) {
      throw const AiException('The tutor is busy right now. Try again in a minute.');
    }
    if (res.statusCode == 401) {
      throw const AiException('Please sign in again to use the tutor.');
    }
    if (res.statusCode != 200) {
      throw const AiException('The tutor is unavailable right now. Please try again later.');
    }
    try {
      final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final parts = (data['candidates'] as List).first['content']['parts'] as List;
      final text = parts.map((p) => (p as Map)['text'] as String? ?? '').join().trim();
      if (text.isEmpty) throw const FormatException();
      return text;
    } catch (_) {
      throw const AiException('The tutor couldn\'t answer that. Try rephrasing.');
    }
  }

  static Future<http.Response> _direct(Map<String, dynamic> body, Duration timeout) => http
      .post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent'),
        headers: {'Content-Type': 'application/json', 'x-goog-api-key': AppSecrets.geminiApiKey},
        body: jsonEncode(body),
      )
      .timeout(timeout);

  static Future<http.Response> _viaProxy(Map<String, dynamic> body, Duration timeout) async {
    final user = Firebase.apps.isEmpty ? null : FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken();
    if (token == null) throw const AiException('Please sign in to use the tutor.');
    return http
        .post(
          Uri.parse('${SupabaseConfig.url}/functions/v1/ai-tutor'),
          headers: {
            'Content-Type': 'application/json',
            'apikey': SupabaseConfig.anonKey,
            'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
            'x-firebase-token': token,
          },
          body: jsonEncode({'model': model, 'request': body}),
        )
        .timeout(timeout);
  }
}
