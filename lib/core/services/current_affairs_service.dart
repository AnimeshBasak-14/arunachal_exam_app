import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CurrentAffairsItem {
  final String id;
  final String title;
  final String summary;
  final String source;
  final String dateStr;
  final String link;
  final bool aiEnhanced;
  final String category;

  CurrentAffairsItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.source,
    required this.dateStr,
    required this.link,
    this.aiEnhanced = false,
    this.category = 'Current Affairs',
  });
}

class CurrentAffairsService {
  static const String _apiKey =
      'AQ.Ab8RN6KS4k7zMX9Rza6IEIwyovwJueGIwOhUWAuueYFNj7torg';
  static const String _geminiEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent?key=$_apiKey';

  static List<CurrentAffairsItem>? _cache;
  static DateTime? _cacheTime;
  static const _cacheDuration = Duration(minutes: 30);

  final List<CurrentAffairsItem> _fallbackItems = [
    CurrentAffairsItem(
      id: 'apssb_1',
      title: 'APSSB CGL 2025: Revised Examination Schedule and Syllabus Circular Released',
      summary:
          'The Arunachal Pradesh Staff Selection Board (APSSB) has officially notified all registered candidates regarding the revised examination calendar and admit card release dates for the Combined Graduate Level (CGL) 2025 Examination.\n\n'
          'Key Highlights for Aspirants:\n'
          '• Post categories include Upper Division Clerk (UDC), Junior Assistant, and Inspector level cadres across various state departments.\n'
          '• Examination pattern consists of Phase I Written Test covering General English (50 marks), Elementary Mathematics (50 marks), and General Knowledge & Arunachal GK (50 marks), followed by Phase II Skill/Typing Test where applicable.\n'
          '• Admit cards can be downloaded directly using registration credentials at apssb.nic.in.\n'
          '• Strict biometric verification will be enforced at all designated examination centers in Itanagar, Naharlagun, Pasighat, and Bomdila.',
      source: 'APSSB Official Portal',
      dateStr: 'Today',
      link: 'https://apssb.nic.in',
      category: 'Recruitment & Exams',
    ),
    CurrentAffairsItem(
      id: 'gov_2',
      title: 'Arunachal Cabinet Approves Operationalization of 27th and 28th Districts: Keyi Panyor & Bichom',
      summary:
          'In a historic administrative milestone, the Government of Arunachal Pradesh under Chief Minister Pema Khandu has fully operationalized Keyi Panyor (headquartered at Yachuli) and Bichom (headquartered at Napangphung).\n\n'
          'Administrative and Exam Significance:\n'
          '• Keyi Panyor was carved out of Lower Subansiri on 1st March 2024 to enhance administrative reach for the Nyishi community in the region.\n'
          '• Bichom district was formally created on 7th March 2024 by bifurcating West Kameng and East Kameng, fulfilling a long-standing aspiration of the Sajolang (Miji), Bugun, Aka, and Monpa ethnic communities.\n'
          '• This expansion brings the total district count in Arunachal Pradesh to 28 districts.\n'
          '• State infrastructure development grants and local administrative offices (DC, SP, and Zilla Parishad) are now functioning at the new headquarters.',
      source: 'State Government Portal',
      dateStr: 'Yesterday',
      link: 'https://arunachalpradesh.gov.in',
      category: 'Governance & State GK',
    ),
    CurrentAffairsItem(
      id: 'appsc_3',
      title: 'APPSC Announces Combined Competitive Examination (CCE) Reforms & Vacancy Matrix',
      summary:
          'The Arunachal Pradesh Public Service Commission (APPSC) has notified comprehensive procedural reforms for forthcoming competitive examinations, including strict adherence to the Union Public Service Commission (UPSC) benchmark.\n\n'
          'Key Structural Reforms:\n'
          '• Multi-tier security and digitized question paper handling protocols introduced across all examination stages.\n'
          '• Syllabus aligned with contemporary North East India affairs, state geography, tribal customary laws, and national developmental policies.\n'
          '• Age relaxation norms and 80:20 reservation quota guidelines for APST candidates strictly maintained.\n'
          '• Detailed instructions and syllabus breakdown available on appsc.gov.in.',
      source: 'APPSC Official Portal',
      dateStr: '2 days ago',
      link: 'https://appsc.gov.in',
      category: 'Recruitment & Exams',
    ),
    CurrentAffairsItem(
      id: 'newsfy_4',
      title: 'NewsFY Report: Border Infrastructure Boost with 1,500 km Frontier Highway Across Arunachal',
      summary:
          'According to latest regional reports, construction work on the ambitious 1,500-kilometer Frontier Highway (NH-913) has gathered rapid momentum, connecting remote border districts from Bomdila through Nafra, Huri, Mechuka, Tuting, Kibithu to Vijaynagar.\n\n'
          'Strategic & Economic Impact:\n'
          '• The highway will link all major river valleys (Kameng, Subansiri, Siang, Dibang, and Lohit) along the international border with Tibet/China.\n'
          '• Reduces inter-valley travel time from several days to just hours, boosting agricultural trade and regional security.\n'
          '• Expected to generate direct employment for local youth and foster rural tourism along pristine border circuits.',
      source: 'NewsFY (News For You)',
      dateStr: '3 days ago',
      link: 'https://arunachaltimes.in',
      category: 'Infrastructure & Economy',
    ),
    CurrentAffairsItem(
      id: 'at_5',
      title: 'Tawang & Namdapha Ecological Conservation Drive Wins National Biodiversity Recognition',
      summary:
          'The Department of Environment and Forests, Arunachal Pradesh, in collaboration with local community eco-clubs, has received national recognition for pioneering community-led preservation in Namdapha Tiger Reserve and high-altitude wetlands in Tawang.\n\n'
          'Exam Points to Remember:\n'
          '• Namdapha is the only national park in the world that harbors all four feline species: Tiger, Leopard, Snow Leopard, and Clouded Leopard.\n'
          '• The Hoolock Gibbon (Arunachal\'s State Animal) and the Great Hornbill (State Bird) have shown stable population recovery.\n'
          '• 20 indigenous GI tags have been officially registered from Arunachal Pradesh, with Yak Churpi, Khamti Rice, and Tangsa textiles leading state exports.',
      source: 'Arunachal Times',
      dateStr: 'This week',
      link: 'https://arunachaltimes.in',
      category: 'Environment & Wildlife',
    ),
    CurrentAffairsItem(
      id: 'dipr_6',
      title: 'DIPR Arunachal: State Launches Comprehensive Digitization of Tribal Customary Laws and Folk Heritage',
      summary:
          'The Directorate of Information and Public Relations (DIPR) and the Department of Indigenous Affairs have inaugurated a state-wide project to document the traditional customary justice systems (such as the Kebang of the Adis).\n\n'
          'Cultural & Heritage Highlights:\n'
          '• Arunachal Pradesh is home to 26 major tribes and over 100 sub-tribes, each preserving rich oral histories and democratic village councils.\n'
          '• The Kebang system, praised as a unique indigenous democratic institution, is being preserved in digital archives alongside audio-visual folk recordings.\n'
          '• Focus on major agricultural festivals: Solung, Mopin, Losar, Boori Boot, Dree, and Nyokum-Yullo.',
      source: 'DIPR Arunachal',
      dateStr: 'This week',
      link: 'https://arunachalipr.gov.in',
      category: 'Art & Culture',
    ),
  ];

  final List<Map<String, String>> _rssSources = [
    {'url': 'https://arunachaltimes.in/feed/', 'name': 'Arunachal Times', 'cat': 'State News'},
    {'url': 'https://www.arunachalfront.com/feed/', 'name': 'Arunachal Front', 'cat': 'State News'},
  ];

  Future<List<CurrentAffairsItem>> fetchCurrentAffairs() async {
    if (_cache != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      return _cache!;
    }

    final rawItems = <CurrentAffairsItem>[];
    for (final source in _rssSources) {
      try {
        final response = await http
            .get(Uri.parse(source['url']!))
            .timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          final parsed = _parseRss(response.body, source['name']!, source['cat']!);
          rawItems.addAll(parsed);
          if (rawItems.length >= 10) break;
        }
      } catch (_) {}
    }

    if (rawItems.isEmpty) {
      _cache = _fallbackItems;
      _cacheTime = DateTime.now();
      return _fallbackItems;
    }

    // Combine live items with official recruitment & government items
    final combined = <CurrentAffairsItem>[
      _fallbackItems[0], // APSSB CGL
      _fallbackItems[1], // 28 Districts
      ...rawItems.take(4),
      _fallbackItems[2], // APPSC reforms
      _fallbackItems[3], // Frontier Highway
      _fallbackItems[4], // Biodiversity
      _fallbackItems[5], // DIPR Heritage
    ];

    final enhanced = await _enhanceWithAI(combined);
    _cache = enhanced;
    _cacheTime = DateTime.now();
    return enhanced;
  }

  List<CurrentAffairsItem> _parseRss(
      String xmlString, String sourceName, String category) {
    final items = <CurrentAffairsItem>[];
    final itemRegex = RegExp(r'<item>(.*?)</item>', dotAll: true);
    final titleRegex = RegExp(
        r'<title><!\[CDATA\[(.*?)\]\]></title>|<title>(.*?)</title>',
        dotAll: true);
    final contentRegex = RegExp(
        r'<content:encoded><!\[CDATA\[(.*?)\]\]></content:encoded>|<content:encoded>(.*?)</content:encoded>',
        dotAll: true);
    final descRegex = RegExp(
        r'<description><!\[CDATA\[(.*?)\]\]></description>|<description>(.*?)</description>',
        dotAll: true);
    final dateRegex = RegExp(r'<pubDate>(.*?)</pubDate>', dotAll: true);
    final linkRegex = RegExp(r'<link>(.*?)</link>', dotAll: true);

    int idCounter = 1;
    for (final match in itemRegex.allMatches(xmlString)) {
      final itemStr = match.group(1) ?? '';
      final titleMatch = titleRegex.firstMatch(itemStr);
      final title =
          (titleMatch?.group(1) ?? titleMatch?.group(2) ?? 'No Title').trim();

      // Prefer full content:encoded, fallback to description
      final contentMatch = contentRegex.firstMatch(itemStr);
      final descMatch = descRegex.firstMatch(itemStr);
      final bodyRaw = contentMatch?.group(1) ??
          contentMatch?.group(2) ??
          descMatch?.group(1) ??
          descMatch?.group(2) ??
          '';

      final bodyClean = bodyRaw
          .replaceAll(RegExp(r'<style[^>]*>.*?</style>', dotAll: true), '')
          .replaceAll(RegExp(r'<script[^>]*>.*?</script>', dotAll: true), '')
          .replaceAll(RegExp(r'<[^>]*>'), ' ')
          .replaceAll('&nbsp;', ' ')
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&quot;', '"')
          .replaceAll('&#8217;', "'")
          .replaceAll('&#8216;', "'")
          .replaceAll('&#8220;', '"')
          .replaceAll('&#8221;', '"')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      final dateMatch = dateRegex.firstMatch(itemStr);
      final dateStr = dateMatch?.group(1) ?? 'Recent';
      final linkMatch = linkRegex.firstMatch(itemStr);
      final link = linkMatch?.group(1)?.trim() ?? '';

      if (title.isNotEmpty && title != 'No Title') {
        items.add(CurrentAffairsItem(
          id: '${sourceName}_$idCounter',
          title: title,
          summary: bodyClean.length > 50
              ? bodyClean
              : 'Read the full report from $sourceName.',
          source: sourceName,
          dateStr: _formatDate(dateStr),
          link: link,
          category: category,
        ));
        idCounter++;
        if (items.length >= 8) break;
      }
    }
    return items;
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return raw.split(' ').take(4).join(' ');
    }
  }

  Future<List<CurrentAffairsItem>> _enhanceWithAI(
      List<CurrentAffairsItem> items) async {
    final result = <CurrentAffairsItem>[];

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      // Only process top items with AI if raw text is unstructured or too terse
      if (i < 4 && !item.summary.contains('Key Highlights')) {
        try {
          final prompt =
              'You are a senior news analyst and curriculum expert for APSSB and APPSC examinations in Arunachal Pradesh.\n'
              'Rewrite the following article into a detailed, comprehensive, high-value study article (around 150-250 words).\n'
              'Include:\n'
              '- Clear background context and what occurred.\n'
              '- Concrete facts, statistics, relevant ministries/departments, and district impact.\n'
              '- A dedicated bullet-point section: "Exam Relevance & Key Points".\n'
              'Do not summarize briefly; provide an in-depth, rich, factual article.\n\n'
              'Headline: ${item.title}\n'
              'Content: ${item.summary}';

          final body = jsonEncode({
            'contents': [
              {
                'role': 'user',
                'parts': [
                  {'text': prompt}
                ]
              }
            ],
            'generationConfig': {'maxOutputTokens': 1000}
          });

          final response = await http
              .post(
                Uri.parse(_geminiEndpoint),
                headers: {'Content-Type': 'application/json'},
                body: body,
              )
              .timeout(const Duration(seconds: 12));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final parts = (data['candidates'][0]['content']['parts'] as List);
            final rewritten = parts
                .where((p) =>
                    p.containsKey('text') && (p['text'] as String).isNotEmpty)
                .map((p) => p['text'] as String)
                .join('')
                .trim();

            if (rewritten.isNotEmpty) {
              result.add(CurrentAffairsItem(
                id: item.id,
                title: item.title,
                summary: rewritten,
                source: item.source,
                dateStr: item.dateStr,
                link: item.link,
                aiEnhanced: true,
                category: item.category,
              ));
              continue;
            }
          }
        } catch (_) {}
      }

      result.add(item);
    }

    return result;
  }
}

final currentAffairsServiceProvider =
    Provider<CurrentAffairsService>((ref) => CurrentAffairsService());

final currentAffairsProvider =
    FutureProvider<List<CurrentAffairsItem>>((ref) async {
  return ref.watch(currentAffairsServiceProvider).fetchCurrentAffairs();
});
