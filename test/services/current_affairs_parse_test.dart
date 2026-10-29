import 'package:arunachal_exam_app/core/services/current_affairs_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses RFC 822 dates with every offset style', () {
    final utc = DateTime.utc(2026, 10, 28, 12, 14, 29);
    expect(parseFeedDate('Wed, 28 Oct 2026 12:14:29 +0000')!.toUtc(), utc);
    expect(parseFeedDate('Wed, 28 Oct 2026 17:44:29 +05:30')!.toUtc(), utc);
    expect(parseFeedDate('Wed, 28 Oct 2026 17:44:29+0530')!.toUtc(), utc);
    expect(parseFeedDate('Wed, 28 Oct 2026 12:14:29 GMT')!.toUtc(), utc);
    expect(parseFeedDate('2026-10-28T12:14:29+00:00')!.toUtc(), utc);
    expect(parseFeedDate('garbage'), isNull);
  });

  test('cleans HTML and entities', () {
    expect(cleanText('<p>CM&#8217;s visit &amp; review</p>'), 'CM’s visit & review');
  });

  test('parses RSS and Atom', () {
    const rss = '''<rss><channel><item><title><![CDATA[APSSB releases CGL result]]></title>
<link>https://x.in/a</link><pubDate>Wed, 28 Oct 2026 12:00:00 +0000</pubDate>
<description><![CDATA[<img src="https://x.in/i.jpg"> Body text]]></description></item></channel></rss>''';
    final r = CurrentAffairsService.parseFeed(rss, CurrentAffairsService.sources[1]);
    expect(r.single.title, 'APSSB releases CGL result');
    expect(r.single.imageUrl, 'https://x.in/i.jpg');
    expect(r.single.examRelated, isTrue);
    expect(r.single.kind, NewsKind.article);

    const atom = '''<feed xmlns="http://www.w3.org/2005/Atom" xmlns:media="http://search.yahoo.com/mrss/">
<entry><title>Tawang update</title><link rel="alternate" href="https://youtu.be/1"/>
<published>2026-10-28T12:00:00+00:00</published><media:group><media:thumbnail url="https://i.ytimg.com/1.jpg"/>
<media:description>Desc</media:description></media:group></entry></feed>''';
    final v = CurrentAffairsService.parseFeed(atom, CurrentAffairsService.sources.last);
    expect(v.single.link, 'https://youtu.be/1');
    expect(v.single.kind, NewsKind.video);
    expect(v.single.imageUrl, 'https://i.ytimg.com/1.jpg');
    expect(v.single.summary, 'Desc');
  });
}
