@Tags(['network'])
library;

import 'package:arunachal_exam_app/core/services/current_affairs_service.dart';
import 'package:flutter_test/flutter_test.dart';

// Hits the real feeds: `flutter test --tags network`.
void main() {
  test('every source returns recent, dated stories', () async {
    final r = await CurrentAffairsService().fetch(force: true);
    final bySource = <String, int>{};
    for (final i in r.items) {
      bySource[i.source] = (bySource[i.source] ?? 0) + 1;
    }
    // ignore: avoid_print
    print('failed: ${r.failed}\ncounts: $bySource');
    for (final i in r.items.take(12)) {
      // ignore: avoid_print
      print(
          '${i.dateStr.padRight(12)} ${i.kind.name[0]} ${i.region.name[0]} ${i.examRelated ? "E" : " "} [${i.source}] ${i.title}  img=${i.imageUrl != null}');
    }
    expect(r.failed, isEmpty);
    expect(r.items.where((i) => i.published == null), isEmpty);
    expect(
        r.items.first.published!
            .isAfter(DateTime.now().subtract(const Duration(days: 3))),
        isTrue);
  }, timeout: const Timeout(Duration(minutes: 1)));
}
