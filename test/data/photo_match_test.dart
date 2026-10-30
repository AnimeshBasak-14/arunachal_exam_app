import 'package:arunachal_exam_app/data/chapter_photos.dart';
import 'package:arunachal_exam_app/data/gk_places.dart';
import 'package:arunachal_exam_app/data/photo_match.dart';
import 'package:arunachal_exam_app/data/state_gk_data.dart';
import 'package:arunachal_exam_app/features/learn/data/card_photos.dart';
import 'package:arunachal_exam_app/features/learn/data/learn_deck.dart';
import 'package:flutter_test/flutter_test.dart';

ChapterPhoto photo(String caption) =>
    ChapterPhoto('a/ab/x.jpg', caption, 'Someone', 'CC0', 2000);

void main() {
  test('keywords keep names and drop common words', () {
    expect(photoKeywords(photo('Nyishi man in a hornbill-beak headdress')),
        containsAll(['nyishi', 'hornbill-beak', 'headdress']));
    expect(photoKeywords(photo('The Lohit river near Parshuram Kund')),
        {'lohit', 'parshuram', 'kund'});
    expect(photoKeywords(photo('Indian soldiers in the 1962 war')),
        containsAll(['soldiers', '1962']));
  });

  test('a photo goes after the paragraph that mentions it most', () {
    final paras = [
      'Arunachal has 26 major tribes.',
      'Solung is the main festival of the Adi.',
      'Nyokum is celebrated by the Nyishi in February.',
    ];
    final placed = placeInArticle(paras, [
      photo('Nyokum festival (Nyishi)'),
      photo('Tapu, a folk dance of the Adi'),
    ]);
    expect(placed[2]!.single.caption, 'Nyokum festival (Nyishi)');
    expect(placed[1]!.single.caption, 'Tapu, a folk dance of the Adi');
    expect(placed.containsKey(0), isFalse);
  });

  test('photos no paragraph mentions are spread through the article', () {
    final paras = List.generate(9, (i) => 'Paragraph $i about nothing.');
    final placed =
        placeInArticle(paras, [photo('Alpha'), photo('Beta'), photo('Gamma')]);
    expect(placed.values.expand((l) => l).length, 3);
    expect(placed.keys.toSet().length, 3, reason: 'one per gap, not bunched');
    expect(placed.keys.every((k) => k >= 0 && k < 9), isTrue);
  });

  test('a chapter without paragraphs shows its photos before the tables', () {
    final placed = placeInArticle(const [], [photo('Alpha')]);
    expect(placed[-1], hasLength(1));
  });

  test('every chapter photo is placed exactly once', () {
    for (final ch in StateGkData.chapters) {
      final photos = chapterPhotos[ch.id] ?? const <ChapterPhoto>[];
      final placed = placeInArticle(ch.highlights, photos);
      expect(placed.values.expand((l) => l).length, photos.length,
          reason: ch.id);
    }
  });

  test('a matched photo sits beside a paragraph that names it', () {
    for (final ch in StateGkData.chapters) {
      final photos = chapterPhotos[ch.id] ?? const <ChapterPhoto>[];
      final placed = placeInArticle(ch.highlights, photos);
      for (final e in placed.entries) {
        for (final p in e.value) {
          final named = ch.highlights.any((h) => photoScore(p, h) > 0);
          if (named) {
            expect(photoScore(p, ch.highlights[e.key]), greaterThan(0),
                reason: '${ch.id}: ${p.caption}');
          }
        }
      }
    }
  });

  group('card photos', () {
    test('English and vocabulary cards never get one', () {
      for (final t in [LearnTopic.grammar, LearnTopic.vocab]) {
        for (final c in learnDeck[t]!) {
          expect(photoForCard(c), isNull, reason: c.id);
        }
      }
    });

    test('map place cards use the place photo', () {
      final p = gkPlaces.firstWhere((p) => placePhotos.containsKey(p.wiki));
      final card = learnDeck[LearnTopic.arunachal]!
          .firstWhere((c) => c.place == p && c.kind == CardKind.fact);
      expect(photoForCard(card), same(placePhotos[p.wiki]));
    });

    test('a good share of GK cards get a related photo', () {
      final gk = [
        for (final t in LearnTopic.values)
          if (t != LearnTopic.grammar && t != LearnTopic.vocab) ...learnDeck[t]!
      ];
      final withPhoto = gk.where((c) => photoForCard(c) != null).length;
      expect(withPhoto / gk.length, greaterThan(0.25),
          reason: '$withPhoto of ${gk.length}');
    });

    test('a card photo always names something on the card', () {
      for (final t in LearnTopic.values) {
        for (final c in learnDeck[t]!) {
          final p = photoForCard(c);
          if (p == null || c.place != null) continue;
          final text = [
            c.prompt,
            c.body ?? '',
            c.explain ?? '',
            if (c.options.isNotEmpty) c.options[c.answer],
          ].join(' ');
          expect(photoScore(p, text), greaterThan(0),
              reason: '${c.id}: ${p.caption}');
        }
      }
    });
  });
}
