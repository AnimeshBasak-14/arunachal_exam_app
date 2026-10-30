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
      'CC BY-SA 4.0', 'CC BY-SA 3.0', 'CC BY-SA 2.5', 'CC BY-SA 2.0',
      'CC BY 4.0', 'CC BY 3.0', 'CC BY 2.5', 'CC BY 2.0',
      'CC0', 'Public domain', 'GODL-India', 'EdictGov-India',
    };
    for (final e in chapterPhotos.entries) {
      for (final p in e.value) {
        final who = '${e.key}: ${p.caption}';
        expect(p.url, startsWith('https://'), reason: who);
        expect(p.url, contains('wikimedia.org'), reason: who);
        expect(p.caption.trim(), isNotEmpty, reason: who);
        expect(p.author.trim(), isNotEmpty, reason: who);
        expect(free, contains(p.license), reason: who);
        expect(p.page, startsWith('https://commons.wikimedia.org/wiki/File:'), reason: who);
      }
    }
  });

  test('no chapter repeats a picture', () {
    for (final e in chapterPhotos.entries) {
      final urls = e.value.map((p) => p.url).toList();
      // The same photo may deliberately appear under two captions (for
      // example a tribe in two sections), but never twice in a row.
      for (int i = 1; i < urls.length; i++) {
        expect(urls[i], isNot(urls[i - 1]), reason: '${e.key} #$i');
      }
    }
  });

  test('the tribes chapter covers Nyishi, Adi, Galo and Apatani', () {
    final captions = chapterPhotos['ch9']!.map((p) => p.caption.toLowerCase()).join(' | ');
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
    String value(String symbol) => symbols.firstWhere((r) => r['Symbol'] == symbol)['Value']!;
    expect(value('State Animal'), contains('Mithun'));
    expect(value('State Bird'), contains('Hornbill'));
    expect(value('State Fish'), contains('Mahseer'));
  });
}
