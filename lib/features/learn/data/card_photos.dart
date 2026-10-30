import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/service_providers.dart';
import '../../../data/chapter_photos.dart';
import '../../../data/photo_match.dart';
import 'learn_deck.dart';

/// Test feature: show a related photo on GK cards. Off by default because
/// it uses more mobile data.
final cardPhotosProvider =
    NotifierProvider<CardPhotosNotifier, bool>(CardPhotosNotifier.new);

class CardPhotosNotifier extends Notifier<bool> {
  static const key = 'beta_card_photos';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(key) ?? false;

  Future<void> set(bool on) async {
    state = on;
    await ref.read(sharedPreferencesProvider).setBool(key, on);
  }
}

/// Subjects that can show pictures. English and vocabulary never do.
const photoTopics = [
  LearnTopic.arunachal,
  LearnTopic.history,
  LearnTopic.polity,
  LearnTopic.geography,
  LearnTopic.economy,
  LearnTopic.environment,
  LearnTopic.science,
];

/// Which subjects show pictures once the feature is on. All by default.
final cardPhotoTopicsProvider =
    NotifierProvider<CardPhotoTopicsNotifier, Set<LearnTopic>>(
        CardPhotoTopicsNotifier.new);

class CardPhotoTopicsNotifier extends Notifier<Set<LearnTopic>> {
  static const key = 'beta_card_photo_topics';

  @override
  Set<LearnTopic> build() {
    final saved = ref.watch(sharedPreferencesProvider).getStringList(key);
    if (saved == null) return photoTopics.toSet();
    return {
      for (final t in photoTopics)
        if (saved.contains(t.name)) t
    };
  }

  Future<void> toggle(LearnTopic t) async {
    state = state.contains(t) ? ({...state}..remove(t)) : {...state, t};
    await ref
        .read(sharedPreferencesProvider)
        .setStringList(key, [for (final x in state) x.name]);
  }
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
