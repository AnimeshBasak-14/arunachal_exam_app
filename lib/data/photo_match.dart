import 'chapter_photos.dart';

/// Words too common to tie a photo to a paragraph ("river", "festival").
const _stop = {
  'the',
  'a',
  'an',
  'of',
  'in',
  'at',
  'on',
  'and',
  'or',
  'to',
  'for',
  'from',
  'with',
  'by',
  'its',
  'his',
  'her',
  'their',
  'near',
  'after',
  'during',
  'photo',
  'map',
  'india',
  'indian',
  'arunachal',
  'pradesh',
  'state',
  'national',
  'park',
  'river',
  'lake',
  'festival',
  'first',
  'chief',
  'minister',
  'governor',
  'president',
  'sir',
  'old',
  'new',
  'traditional',
  'sanctuary',
  'wildlife',
  'valley',
  'district',
  'pass',
  'falls',
  'reserve',
  'ruins',
  'forest',
  'town',
  'village',
  'member',
  'west',
  'east',
  'north',
  'south',
  'upper',
  'lower',
  'woman',
  'women',
  'man',
  'men',
  'girl',
  'girls',
  'people',
  'dress',
  'attire',
  'house',
  'building',
  'view',
  'seen',
  'region',
  'area',
  'basin',
  'course',
  'two',
  'one',
  'part',
  'page',
  'original',
  'early',
  'large',
  'largest',
  'famous',
  'portrait',
  'historical',
  'photograph',
  'human',
  'cell',
  'cells',
  'system',
  'light',
  'dance',
  'folk',
  'tribe',
  'tribes',
  'tribal',
  'faith',
  'temple',
  'monastery',
  'statue',
  'memorial',
  'priest',
  'elder',
  'couple',
  'symbol',
  'source',
  'troupe',
  'cultural',
  'war',
  'lok',
  'sabha',
  'snow',
  'capped',
  'mountains',
  'site',
  'road',
  'gateway',
  'entrance',
  'canopy',
};

final _word = RegExp(r"[A-Za-z][A-Za-z\-']+|\d{4}");

/// Distinctive words of a caption: names of people, places, tribes,
/// festivals, years. Lower-cased.
Set<String> photoKeywords(ChapterPhoto p) => {
      for (final m in _word.allMatches(p.caption))
        if (m[0]!.length >= 3 && !_stop.contains(m[0]!.toLowerCase()))
          m[0]!.toLowerCase()
    };

/// How strongly [text] is about [p]: the number of its keywords that appear
/// as whole words (or simple plurals).
int photoScore(ChapterPhoto p, String text) {
  final words = {for (final m in _word.allMatches(text)) m[0]!.toLowerCase()};
  var n = 0;
  for (final k in photoKeywords(p)) {
    if (words.contains(k) || words.contains('${k}s')) n++;
  }
  return n;
}

/// Where each photo of a chapter goes in its article: paragraph index ->
/// photos shown after that paragraph. A photo goes after the paragraph that
/// mentions it most (the earliest on a tie); photos no paragraph mentions are
/// spread evenly through the remaining gaps. With no paragraphs, everything
/// goes under index -1 (before the tables).
Map<int, List<ChapterPhoto>> placeInArticle(
    List<String> paragraphs, List<ChapterPhoto> photos) {
  final out = <int, List<ChapterPhoto>>{};
  if (paragraphs.isEmpty) {
    if (photos.isNotEmpty) out[-1] = [...photos];
    return out;
  }
  final loose = <ChapterPhoto>[];
  for (final p in photos) {
    var best = -1, bestScore = 0;
    for (var i = 0; i < paragraphs.length; i++) {
      final s = photoScore(p, paragraphs[i]);
      if (s > bestScore) {
        best = i;
        bestScore = s;
      }
    }
    if (best < 0) {
      loose.add(p);
    } else {
      (out[best] ??= []).add(p);
    }
  }
  if (loose.isNotEmpty) {
    final free = [
      for (var i = 0; i < paragraphs.length; i++)
        if (!out.containsKey(i)) i
    ];
    final slots =
        free.isEmpty ? [for (var i = 0; i < paragraphs.length; i++) i] : free;
    for (var k = 0; k < loose.length; k++) {
      // Evenly spaced, never before the first paragraph.
      final at = slots[((k + 1) * slots.length ~/ (loose.length + 1))
          .clamp(0, slots.length - 1)];
      (out[at] ??= []).add(loose[k]);
    }
  }
  return out;
}

/// The photo that best illustrates a GK card, or null. Photos from the
/// card's own chapter win; another chapter's photo is used only when it
/// names something in the text (a person, place, tribe or festival).
ChapterPhoto? photoForText(String text, {String? chapterId}) {
  ChapterPhoto? best;
  var bestScore = 0;
  void consider(Iterable<ChapterPhoto> list, int bonus) {
    for (final p in list) {
      final s = photoScore(p, text);
      if (s > 0 && s + bonus > bestScore) {
        best = p;
        bestScore = s + bonus;
      }
    }
  }

  if (chapterId != null) consider(chapterPhotos[chapterId] ?? const [], 1);
  consider(placePhotos.values, 0);
  for (final e in chapterPhotos.entries) {
    if (e.key != chapterId) consider(e.value, 0);
  }
  return best;
}
