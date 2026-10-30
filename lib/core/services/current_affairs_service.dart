import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml/xml.dart';
import 'service_providers.dart';

enum NewsKind { article, video }

/// Where a story is about. Statewide outlets are always [arunachal]; the
/// Northeast-wide feeds are sorted by whether the story mentions the state.
enum NewsRegion { arunachal, northeast }

class CurrentAffairsItem {
  final String id;
  final String title;
  final String summary;
  final String source;
  final DateTime? published;
  final String link;
  final String? imageUrl;
  final NewsKind kind;
  final NewsRegion region;

  /// True when the story is about recruitment, exams or results.
  final bool examRelated;

  const CurrentAffairsItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.source,
    required this.published,
    required this.link,
    this.imageUrl,
    this.kind = NewsKind.article,
    this.region = NewsRegion.arunachal,
    this.examRelated = false,
  });

  String get dateStr => relativeDate(published);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'summary': summary,
        'source': source,
        'published': published?.toIso8601String(),
        'link': link,
        'imageUrl': imageUrl,
        'kind': kind.name,
        'region': region.name,
        'exam': examRelated,
      };

  factory CurrentAffairsItem.fromJson(Map<String, dynamic> j) =>
      CurrentAffairsItem(
        id: j['id'] as String,
        title: j['title'] as String,
        summary: j['summary'] as String? ?? '',
        source: j['source'] as String,
        published: DateTime.tryParse(j['published'] as String? ?? ''),
        link: j['link'] as String? ?? '',
        imageUrl: j['imageUrl'] as String?,
        kind: NewsKind.values.asNameMap()[j['kind']] ?? NewsKind.article,
        region:
            NewsRegion.values.asNameMap()[j['region']] ?? NewsRegion.arunachal,
        examRelated: j['exam'] as bool? ?? false,
      );

  /// Shape expected by NewsDetailsScreen.
  Map<String, dynamic> toArticleMap() => {
        'id': id,
        'title': title,
        'description': summary,
        'summary': summary,
        'source': source,
        'date': dateStr,
        'link': link,
        'pdfUrl': link,
        'imageUrl': imageUrl,
      };
}

String relativeDate(DateTime? d) {
  if (d == null) return 'Recent';
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 60) return '${diff.inMinutes.clamp(1, 59)} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays} days ago';
  const m = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  return '${d.day} ${m[d.month - 1]} ${d.year}';
}

enum _FeedType { rss, googleNews, youtube }

class NewsSource {
  final String name;
  final _FeedType _type;
  final String _target; // feed URL, site domain, or YouTube channel id
  final bool statewide;

  const NewsSource._(this.name, this._type, this._target,
      {this.statewide = true});

  /// The outlet's own RSS/Atom feed.
  const NewsSource.rss(String name, String url, {bool statewide = true})
      : this._(name, _FeedType.rss, url, statewide: statewide);

  /// For sites without a working feed (or that block apps): Google News'
  /// public per-site search feed.
  const NewsSource.site(String name, String domain, {bool statewide = true})
      : this._(name, _FeedType.googleNews, domain, statewide: statewide);

  /// Outlets that publish mainly as YouTube channels.
  const NewsSource.youtube(String name, String channelId)
      : this._(name, _FeedType.youtube, channelId);

  Uri get uri => switch (_type) {
        _FeedType.rss => Uri.parse(_target),
        _FeedType.googleNews => Uri.https('news.google.com', '/rss/search', {
            'q': 'site:$_target when:14d',
            'hl': 'en-IN',
            'gl': 'IN',
            'ceid': 'IN:en',
          }),
        _FeedType.youtube => Uri.https(
            'www.youtube.com', '/feeds/videos.xml', {'channel_id': _target}),
      };

  bool get isGoogleNews => _type == _FeedType.googleNews;
}

class CurrentAffairsService {
  final SharedPreferences? _prefs;
  CurrentAffairsService([this._prefs]);

  /// Checked 29 Oct 2026. The Arunachal Times and Northeast Today sites
  /// return 404/403 to apps on their own feeds, so they go through Google
  /// News. Hopuk Media, A.P Daily Updates and Arunachal News Live publish on
  /// YouTube.
  static const sources = [
    NewsSource.site('The Arunachal Times', 'arunachaltimes.in'),
    NewsSource.rss('Arunachal Observer', 'https://arunachalobserver.org/feed/'),
    NewsSource.rss('Arunachal24', 'https://arunachal24.in/feed/'),
    NewsSource.rss(
        'India Today NE', 'https://www.indiatodayne.in/rss/arunachal-pradesh',
        statewide: false),
    NewsSource.site('Northeast Today', 'northeasttoday.in', statewide: false),
    NewsSource.youtube('Arunachal News Live', 'UC4UXiSBNHe-IW9_CHUD-xJA'),
    NewsSource.youtube('Hopuk Media', 'UC8lYpEv6Fo0tuAqIztSWD1w'),
    NewsSource.youtube('A.P Daily Updates', 'UC3CcOxrJxbp1X5KcoBvkxxg'),
  ];

  static const _cacheKey = 'current_affairs_cache_v2';
  static const _freshFor = Duration(minutes: 20);
  static const _perSource = 15;
  static const _headers = {
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126 Mobile Safari/537.36',
    'Accept':
        'application/rss+xml, application/atom+xml, application/xml, text/xml, */*',
  };

  static List<CurrentAffairsItem> _memory = const [];
  static DateTime? _memoryTime;

  /// Latest stories from every source, newest first. If every source fails
  /// (offline), the last successful result is returned with [FeedResult.offline].
  Future<FeedResult> fetch({bool force = false}) async {
    if (!force &&
        _memory.isNotEmpty &&
        _memoryTime != null &&
        DateTime.now().difference(_memoryTime!) < _freshFor) {
      return FeedResult(_memory, failed: const []);
    }

    final results = await Future.wait(sources.map(_fetchSource));
    final failed = <String>[];
    final all = <CurrentAffairsItem>[];
    for (int i = 0; i < sources.length; i++) {
      final r = results[i];
      if (r == null) {
        failed.add(sources[i].name);
      } else {
        all.addAll(r);
      }
    }

    if (all.isEmpty) {
      final cached = _readCache();
      return FeedResult(cached, failed: failed, offline: true);
    }

    final items = _dedupe(all)
      ..sort((a, b) => (b.published ?? DateTime(2000))
          .compareTo(a.published ?? DateTime(2000)));
    _memory = items;
    _memoryTime = DateTime.now();
    _writeCache(items);
    return FeedResult(items, failed: failed);
  }

  Future<List<CurrentAffairsItem>?> _fetchSource(NewsSource s) async {
    try {
      final res = await http
          .get(s.uri, headers: _headers)
          .timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null;
      final body = utf8.decode(res.bodyBytes, allowMalformed: true);
      return parseFeed(body, s).take(_perSource).toList();
    } catch (_) {
      return null;
    }
  }

  /// Parses RSS 2.0 or Atom (YouTube). Public for tests.
  static List<CurrentAffairsItem> parseFeed(String xml, NewsSource s) {
    final XmlDocument doc;
    try {
      doc = XmlDocument.parse(xml);
    } catch (_) {
      return const [];
    }
    final out = <CurrentAffairsItem>[];
    var nodes = doc.findAllElements('item').toList();
    final isAtom = nodes.isEmpty;
    if (isAtom) nodes = doc.findAllElements('entry').toList();

    for (final n in nodes) {
      String text(String tag) => _child(n, tag)?.innerText.trim() ?? '';

      var title = cleanText(text('title'));
      if (title.isEmpty) continue;

      var link = text('link');
      if (link.isEmpty) {
        link = _child(n, 'link')?.getAttribute('href') ?? '';
      }
      link = link.trim();

      final rawBody = [
        text('encoded'), // content:encoded
        text('description'),
        text('summary'),
        _child(n, 'group')?.let((g) => _child(g, 'description'))?.innerText ??
            '',
      ].firstWhere((t) => t.trim().isNotEmpty, orElse: () => '');

      var summary = cleanText(rawBody);

      if (s.isGoogleNews) {
        // Google News titles end in " - Outlet" and descriptions repeat the
        // headline as a link, so the summary carries nothing new.
        final dash = title.lastIndexOf(' - ');
        if (dash > 0) title = title.substring(0, dash).trim();
        summary = '';
      }
      if (summary.startsWith(title)) {
        summary = summary.substring(title.length).trim();
      }

      final published = parseFeedDate(text('pubDate').isNotEmpty
          ? text('pubDate')
          : (text('published').isNotEmpty
              ? text('published')
              : text('updated')));

      final haystack = '$title $summary'.toLowerCase();
      final region = s.statewide || _mentionsArunachal(haystack)
          ? NewsRegion.arunachal
          : NewsRegion.northeast;

      out.add(CurrentAffairsItem(
        id: '${s.name}|${link.isNotEmpty ? link : title}'
            .hashCode
            .toRadixString(36),
        title: title,
        summary: summary,
        source: s.name,
        published: published,
        link: link,
        imageUrl: _image(n, rawBody),
        kind: isAtom ? NewsKind.video : NewsKind.article,
        region: region,
        examRelated: _examWords.hasMatch(haystack),
      ));
    }
    return out;
  }

  static XmlElement? _child(XmlElement e, String localName) {
    for (final c in e.childElements) {
      if (c.name.local == localName) return c;
    }
    return null;
  }

  static String? _image(XmlElement n, String rawBody) {
    for (final c in n.descendantElements) {
      final local = c.name.local;
      if (local == 'thumbnail' ||
          (local == 'content' && c.name.prefix == 'media')) {
        final u = c.getAttribute('url');
        if (u != null && u.startsWith('http')) return u;
      }
      if (local == 'enclosure' &&
          (c.getAttribute('type') ?? '').startsWith('image')) {
        return c.getAttribute('url');
      }
    }
    final m = RegExp(r'''<img[^>]+src=["']([^"']+)["']''').firstMatch(rawBody);
    final u = m?.group(1);
    return (u != null && u.startsWith('http')) ? u : null;
  }

  static final _examWords = RegExp(
      r'\b(appsc|apssb|upsc|ssc|recruitment|vacanc|exam|examination|admit card|result|notification|syllabus|interview|selection|cce|cgl|chsl|merit list)');

  static final _arunachalWords = RegExp(
      r'arunachal|itanagar|naharlagun|tawang|pasighat|ziro|bomdila|tezu|roing|namsai|changlang|khonsa|aalo|daporijo|yingkiong|seppa|pema khandu|siang|subansiri|dibang|lohit|kameng');

  static bool _mentionsArunachal(String s) => _arunachalWords.hasMatch(s);

  static List<CurrentAffairsItem> _dedupe(List<CurrentAffairsItem> items) {
    final seen = <String>{};
    final out = <CurrentAffairsItem>[];
    for (final i in items) {
      final key = i.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      final short = key.length > 60 ? key.substring(0, 60) : key;
      if (seen.add(short)) out.add(i);
    }
    return out;
  }

  List<CurrentAffairsItem> _readCache() {
    try {
      final raw = _prefs?.getString(_cacheKey);
      if (raw == null) return const [];
      final list = (jsonDecode(raw) as List)
          .map((e) => CurrentAffairsItem.fromJson(e as Map<String, dynamic>))
          .toList();
      _memory = list;
      return list;
    } catch (_) {
      return const [];
    }
  }

  void _writeCache(List<CurrentAffairsItem> items) {
    try {
      _prefs?.setString(_cacheKey,
          jsonEncode(items.take(120).map((e) => e.toJson()).toList()));
    } catch (_) {}
  }
}

class FeedResult {
  final List<CurrentAffairsItem> items;
  final List<String> failed;
  final bool offline;
  const FeedResult(this.items, {required this.failed, this.offline = false});
}

/// RFC 822 ("Wed, 28 Oct 2026 12:14:29 +0000", also "+05:30" and "GMT")
/// and ISO 8601 dates, converted to local time.
DateTime? parseFeedDate(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return null;
  final iso = DateTime.tryParse(s);
  if (iso != null) return iso.toLocal();

  final m = RegExp(
          r'(\d{1,2})\s+([A-Za-z]{3})[a-z]*\s+(\d{4})\s+(\d{1,2}):(\d{2})(?::(\d{2}))?\s*([+-]\d{2}:?\d{2}|[A-Z]{1,4})?')
      .firstMatch(s);
  if (m == null) return null;
  const months = {
    'jan': 1,
    'feb': 2,
    'mar': 3,
    'apr': 4,
    'may': 5,
    'jun': 6,
    'jul': 7,
    'aug': 8,
    'sep': 9,
    'oct': 10,
    'nov': 11,
    'dec': 12
  };
  final month = months[m.group(2)!.toLowerCase()];
  if (month == null) return null;
  var dt = DateTime.utc(
      int.parse(m.group(3)!),
      month,
      int.parse(m.group(1)!),
      int.parse(m.group(4)!),
      int.parse(m.group(5)!),
      int.parse(m.group(6) ?? '0'));

  final zone = m.group(7) ?? 'GMT';
  final off = RegExp(r'([+-])(\d{2}):?(\d{2})').firstMatch(zone);
  if (off != null) {
    final mins = int.parse(off.group(2)!) * 60 + int.parse(off.group(3)!);
    dt = dt.subtract(Duration(minutes: off.group(1) == '+' ? mins : -mins));
  } else if (zone == 'IST') {
    dt = dt.subtract(const Duration(hours: 5, minutes: 30));
  }
  return dt.toLocal();
}

/// Strips tags, decodes HTML entities and collapses whitespace.
String cleanText(String html) {
  var s = html
      .replaceAll(RegExp(r'<(script|style)[^>]*>.*?</\1>', dotAll: true), ' ')
      .replaceAll(RegExp(r'<br\s*/?>|</p>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]*>'), ' ');
  s = s.replaceAllMapped(RegExp(r'&#(x?)([0-9a-fA-F]+);'), (m) {
    final code =
        int.tryParse(m.group(2)!, radix: m.group(1)!.isEmpty ? 10 : 16);
    return code == null ? '' : String.fromCharCode(code);
  });
  const named = {
    '&nbsp;': ' ',
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&apos;': "'",
    '&hellip;': '…',
    '&rsquo;': '’',
    '&lsquo;': '‘',
    '&ldquo;': '“',
    '&rdquo;': '”',
    '&ndash;': '–',
    '&mdash;': '—'
  };
  named.forEach((k, v) => s = s.replaceAll(k, v));
  s = s
      .replaceAll(
          RegExp(r'The post .{0,200} appeared first on .*$', dotAll: true), '')
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r'\s*\n\s*'), '\n')
      .trim();
  return s;
}

extension on XmlElement {
  T? let<T>(T? Function(XmlElement) f) => f(this);
}

final currentAffairsServiceProvider = Provider<CurrentAffairsService>((ref) {
  SharedPreferences? prefs;
  try {
    prefs = ref.watch(sharedPreferencesProvider);
  } catch (_) {}
  return CurrentAffairsService(prefs);
});

final currentAffairsProvider = FutureProvider<FeedResult>((ref) {
  return ref.watch(currentAffairsServiceProvider).fetch();
});
