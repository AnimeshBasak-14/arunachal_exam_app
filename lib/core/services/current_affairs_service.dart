
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CurrentAffairsItem {
  final String id;
  final String title;
  final String summary;
  final String source;
  final String dateStr;
  final String link;

  CurrentAffairsItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.source,
    required this.dateStr,
    required this.link,
  });
}

class CurrentAffairsService {
  final List<CurrentAffairsItem> _fallbackItems = [
    CurrentAffairsItem(
      id: '1',
      title: 'APSSB Announces New Exam Dates',
      summary: 'The APSSB has announced new dates for the upcoming CGL exams.',
      source: 'APSSB GK',
      dateStr: 'Today',
      link: '',
    ),
    CurrentAffairsItem(
      id: '2',
      title: 'State Government Launches New Scheme',
      summary: 'A new scheme for rural development has been launched.',
      source: 'Arunachal Times',
      dateStr: 'Yesterday',
      link: '',
    ),
    CurrentAffairsItem(
      id: '3',
      title: 'Weather Alert: Heavy Rainfall Expected',
      summary: 'Heavy rainfall is expected in several districts.',
      source: 'NewsFY',
      dateStr: '2 days ago',
      link: '',
    ),
  ];

  Future<List<CurrentAffairsItem>> fetchCurrentAffairs() async {
    try {
      final response = await http.get(Uri.parse('https://arunachaltimes.in/feed/'));
      if (response.statusCode == 200) {
        final items = <CurrentAffairsItem>[];
        final xmlString = response.body;
        
        final itemRegex = RegExp(r'<item>(.*?)</item>', dotAll: true);
        final titleRegex = RegExp(r'<title><!\[CDATA\[(.*?)\]\]></title>|<title>(.*?)</title>', dotAll: true);
        final descRegex = RegExp(r'<description><!\[CDATA\[(.*?)\]\]></description>|<description>(.*?)</description>', dotAll: true);
        final dateRegex = RegExp(r'<pubDate>(.*?)</pubDate>', dotAll: true);
        final linkRegex = RegExp(r'<link>(.*?)</link>', dotAll: true);

        int idCounter = 1;
        for (final match in itemRegex.allMatches(xmlString)) {
          final itemStr = match.group(1) ?? '';
          
          final titleMatch = titleRegex.firstMatch(itemStr);
          final title = titleMatch?.group(1) ?? titleMatch?.group(2) ?? 'No Title';
          
          final descMatch = descRegex.firstMatch(itemStr);
          final descRaw = descMatch?.group(1) ?? descMatch?.group(2) ?? '';
          final descClean = descRaw.replaceAll(RegExp(r'<[^>]*>'), '').trim();
          final summary = descClean.length > 100 ? '${descClean.substring(0, 100)}...' : descClean;

          final dateMatch = dateRegex.firstMatch(itemStr);
          final dateStr = dateMatch?.group(1) ?? 'Unknown Date';

          final linkMatch = linkRegex.firstMatch(itemStr);
          final link = linkMatch?.group(1) ?? '';

          items.add(CurrentAffairsItem(
            id: 'api_$idCounter',
            title: title.trim(),
            summary: summary,
            source: 'Arunachal Times',
            dateStr: dateStr.trim(),
            link: link.trim(),
          ));
          idCounter++;
          
          if (items.length >= 10) break; // Limit to 10 items
        }
        
        if (items.isNotEmpty) return items;
      }
    } catch (e) {
      // Return fallback on error
    }
    return _fallbackItems;
  }
}

final currentAffairsServiceProvider = Provider((ref) => CurrentAffairsService());
final currentAffairsProvider = FutureProvider<List<CurrentAffairsItem>>((ref) {
  final service = ref.watch(currentAffairsServiceProvider);
  return service.fetchCurrentAffairs();
});
