import 'package:arunachal_exam_app/data/chapter_photos.dart';
import 'package:arunachal_exam_app/data/national_gk_data.dart';
import 'package:arunachal_exam_app/data/state_gk_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final chapterIds = {
    for (final c in [...StateGkData.chapters, ...NationalGkData.chapters]) c.id
  };

  test('every photo belongs to a real chapter', () {
    expect(chapterPhotos.keys.toSet().difference(chapterIds), isEmpty);
  });

  test('every Arunachal and General Studies chapter has pictures', () {
    for (final id in chapterIds) {
      expect(chapterPhotos[id], isNotEmpty, reason: id);
    }
  });

  test('every photo has a free licence, a credit and a source page', () {
    const free = {
      'CC BY-SA 4.0',
      'CC BY-SA 3.0',
      'CC BY-SA 2.5',
      'CC BY-SA 2.0',
      'CC BY 4.0',
      'CC BY 3.0',
      'CC BY 2.5',
      'CC BY 2.0',
      'CC0',
      'Public domain',
      'GODL-India',
      'EdictGov-India',
      'FAL',
    };
    final all = {
      ...chapterPhotos.map((k, v) => MapEntry(k, v)),
      'places': placePhotos.values.toList(),
    };
    for (final e in all.entries) {
      for (final p in e.value) {
        final who = '${e.key}: ${p.caption}';
        expect(p.url(960), startsWith('https://upload.wikimedia.org/'),
            reason: who);
        expect(p.width, greaterThan(100), reason: who);
        expect(p.caption.trim(), isNotEmpty, reason: who);
        expect(p.author.trim(), isNotEmpty, reason: who);
        expect(free, contains(p.license), reason: who);
        expect(p.page, startsWith('https://commons.wikimedia.org/wiki/File:'),
            reason: who);
      }
    }
  });

  test('no chapter repeats a picture', () {
    for (final e in chapterPhotos.entries) {
      final urls = e.value.map((p) => p.path).toList();
      // The same photo may deliberately appear under two captions (for
      // example a tribe in two sections), but never twice in a row.
      for (int i = 1; i < urls.length; i++) {
        expect(urls[i], isNot(urls[i - 1]), reason: '${e.key} #$i');
      }
    }
  });

  test('the tribes chapter covers Nyishi, Adi, Galo and Apatani', () {
    final captions =
        chapterPhotos['ch9']!.map((p) => p.caption.toLowerCase()).join(' | ');
    for (final tribe in ['nyishi', 'adi', 'galo', 'apatani']) {
      expect(captions, contains(tribe));
    }
    // Festivals, faith and places, not only portraits.
    for (final word in ['festival', 'monastery', 'donyi-polo']) {
      expect(captions, contains(word));
    }
  });

  test('the state symbols are right', () {
    final symbols = StateGkData.chapters.first.keyFacts;
    String value(String symbol) =>
        symbols.firstWhere((r) => r['Symbol'] == symbol)['Value']!;
    expect(value('State Animal'), contains('Mithun'));
    expect(value('State Bird'), contains('Hornbill'));
    expect(value('State Fish'), contains('Mahseer'));
  });

  group('photo sizes', () {
    const big = ChapterPhoto('a/ab/Big_photo.jpg', 'x', 'y', 'CC0', 5000);
    const small = ChapterPhoto('a/ab/Small.jpg', 'x', 'y', 'CC0', 800);
    const svg = ChapterPhoto('a/ab/Diagram.svg', 'x', 'y', 'CC0', 600);
    const tif = ChapterPhoto('a/ab/Cell.tif', 'x', 'y', 'CC0', 813);
    const video = ChapterPhoto('a/ab/Dance.webm', 'x', 'y', 'CC0', 640);
    const base = 'https://upload.wikimedia.org/wikipedia/commons';

    test('asks for the smallest standard size that is sharp enough', () {
      expect(
          big.url(700), '$base/thumb/a/ab/Big_photo.jpg/960px-Big_photo.jpg');
      expect(
          big.url(960), '$base/thumb/a/ab/Big_photo.jpg/960px-Big_photo.jpg');
      expect(
          big.url(2000), '$base/thumb/a/ab/Big_photo.jpg/3840px-Big_photo.jpg');
      expect(
          big.url(9999), '$base/thumb/a/ab/Big_photo.jpg/3840px-Big_photo.jpg');
    });

    test('never asks for a copy wider than the original', () {
      expect(small.url(500), '$base/thumb/a/ab/Small.jpg/500px-Small.jpg');
      expect(small.url(960), '$base/a/ab/Small.jpg');
      expect(small.url(3840), '$base/a/ab/Small.jpg');
    });

    test('vector, TIFF and video files use rendered copies', () {
      expect(
          svg.url(1280), '$base/thumb/a/ab/Diagram.svg/1280px-Diagram.svg.png');
      expect(tif.url(3840),
          '$base/thumb/a/ab/Cell.tif/lossy-page1-500px-Cell.tif.jpg');
      expect(
          video.url(960), '$base/thumb/a/ab/Dance.webm/500px--Dance.webm.jpg');
    });

    test('every map place photo is at least 1000 px wide or kept on purpose',
        () {
      final small = [
        for (final e in placePhotos.entries)
          if (e.value.width < 1000) e.key
      ];
      // Only these have no better free photo yet.
      expect(small.toSet(), {'Hawai, Arunachal Pradesh', 'Pangsau Pass'});
    });
  });
}
