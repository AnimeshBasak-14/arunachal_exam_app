import 'dart:math' as math;
import '../../streak/data/day_key.dart';
import '../../../data/chapter_photos.dart';
import '../../../data/photo_match.dart';
import 'learn_deck.dart';

/// Share of matching cards that show their photo on a given day. Less than
/// all of them on purpose: a photo that may or may not appear keeps swiping
/// a little surprising.
const photoChance = 0.65;

/// Whether card [c] shows its photo today. Random, but fixed for the day so a
/// card does not change when you swipe back to it.
bool photoShownToday(LearnCard c, {DateTime? now}) {
  final d = now ?? DateTime.now();
  var h = 2166136261; // FNV-1a: the same on every run and device
  for (final u in '${c.id}|${dayKey(d)}'.codeUnits) {
    h = ((h ^ u) * 16777619) & 0x7fffffff;
  }
  return math.Random(h).nextDouble() < photoChance;
}

final _chapterId = RegExp(r'^([a-z]+\d+)\.');
final _cache = <String, ChapterPhoto?>{};

/// The photo for [c], or null. English and vocabulary cards never get one;
/// map places use their own checked photo; other cards get a photo only
/// when its caption names something on the card. For quizzes the answer
/// counts too, so callers show the photo only after the card is answered.
ChapterPhoto? photoForCard(LearnCard c) {
  if (c.topic == LearnTopic.grammar || c.topic == LearnTopic.vocab) {
    return null;
  }
  return _cache.putIfAbsent(c.id, () {
    if (c.place != null) return placePhotos[c.place!.wiki];
    final text = [
      c.prompt,
      c.body ?? '',
      if (c.kind == CardKind.quiz && c.options.isNotEmpty) c.options[c.answer],
      c.explain ?? '',
    ].join(' ');
    return photoForText(text, chapterId: _chapterId.firstMatch(c.id)?[1]);
  });
}
