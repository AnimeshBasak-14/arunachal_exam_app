import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Lead photo and intro paragraph for a Wikipedia article. Text is CC BY-SA;
/// the page link is kept so the screen can credit and link the source.
class WikiSummary {
  final String title;
  final String extract;
  final String? imageUrl;
  final String pageUrl;
  const WikiSummary(this.title, this.extract, this.imageUrl, this.pageUrl);
}

final wikiSummaryProvider =
    FutureProvider.family<WikiSummary?, String>((ref, title) async {
  ref.keepAlive();
  final path = Uri.encodeComponent(title.replaceAll(' ', '_'));
  try {
    final res = await http.get(
      Uri.parse('https://en.wikipedia.org/api/rest_v1/page/summary/$path'),
      headers: const {
        'Api-User-Agent': 'ZAP exam app (basakanimesh16@gmail.com)',
        'User-Agent': 'ZAP exam app (basakanimesh16@gmail.com)',
      },
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) return null;
    final j = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return WikiSummary(
      j['title'] as String? ?? title,
      j['extract'] as String? ?? '',
      (j['thumbnail'] as Map?)?['source'] as String?,
      ((j['content_urls'] as Map?)?['mobile'] as Map?)?['page'] as String? ??
          'https://en.wikipedia.org/wiki/$path',
    );
  } catch (_) {
    return null;
  }
});
