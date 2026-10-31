import 'package:flutter_test/flutter_test.dart';
import 'package:arunachal_exam_app/core/services/remote_config_service.dart';
import 'package:arunachal_exam_app/features/mocks/data/live_mock.dart';

void main() {
  group('LiveMock.nextSundaySession', () {
    test('a weekday rolls forward to Sunday 10:00 IST', () {
      // Thursday 23 Oct 2026, 12:00 UTC
      final s = LiveMock.nextSundaySession(DateTime.utc(2026, 10, 22, 12), 120);
      expect(s, DateTime.utc(2026, 10, 25, 4, 30));
      expect(s.weekday, DateTime.sunday);
    });

    test('during the session it stays on the current Sunday', () {
      final s =
          LiveMock.nextSundaySession(DateTime.utc(2026, 10, 25, 5, 0), 120);
      expect(s, DateTime.utc(2026, 10, 25, 4, 30));
    });

    test('after the session ends it moves to next week', () {
      final s =
          LiveMock.nextSundaySession(DateTime.utc(2026, 10, 25, 7, 0), 120);
      expect(s, DateTime.utc(2026, 11, 1, 4, 30));
    });
  });

  test('without remote config it falls back to the weekly mock', () {
    final m = LiveMock.resolve(
        RemoteConfigService.instance, DateTime.utc(2026, 10, 22, 12));
    expect(m.title, 'State-wide Sunday Mock');
    expect(m.testId, isNull);
    expect(m.durationMinutes, 120);
    expect(m.scheduleLabel, 'Sun, 25 Oct  ·  10:00 AM IST');
    expect(m.isLive(DateTime.utc(2026, 10, 25, 5)), isTrue);
    expect(m.isLive(DateTime.utc(2026, 10, 25, 4)), isFalse);
  });
}
