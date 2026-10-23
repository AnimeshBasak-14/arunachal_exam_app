import '../../../core/services/remote_config_service.dart';

/// The next state-wide mock test.
///
/// Scheduled from Remote Config (`live_mock_*` keys). When nothing is
/// scheduled there, it falls back to the weekly Sunday 10:00 AM IST mock.
class LiveMock {
  final String title;
  final DateTime start; // UTC
  final int durationMinutes;
  final String? testId;

  const LiveMock({
    required this.title,
    required this.start,
    required this.durationMinutes,
    this.testId,
  });

  DateTime get end => start.add(Duration(minutes: durationMinutes));
  bool isLive(DateTime now) => !now.isBefore(start) && now.isBefore(end);

  /// Stable key so enrolment resets for each new session.
  String get enrolKey => 'live_mock_enrolled_${start.toIso8601String()}';

  static const _ist = Duration(hours: 5, minutes: 30);
  static const _defaultDuration = 120;

  static LiveMock resolve(RemoteConfigService rc, DateTime now) {
    final nowUtc = now.toUtc();
    final configured = DateTime.tryParse(rc.liveMockStart)?.toUtc();
    final duration = rc.liveMockDurationMinutes > 0
        ? rc.liveMockDurationMinutes
        : _defaultDuration;
    final title =
        rc.liveMockTitle.isNotEmpty ? rc.liveMockTitle : 'State-wide Sunday Mock';
    final testId = rc.liveMockTestId.isNotEmpty ? rc.liveMockTestId : null;

    if (configured != null &&
        configured.add(Duration(minutes: duration)).isAfter(nowUtc)) {
      return LiveMock(
          title: title, start: configured, durationMinutes: duration, testId: testId);
    }
    return LiveMock(
      title: title,
      start: nextSundaySession(nowUtc, duration),
      durationMinutes: duration,
      testId: testId,
    );
  }

  /// Sunday 10:00 IST (04:30 UTC) whose window has not ended yet.
  static DateTime nextSundaySession(DateTime nowUtc, int durationMinutes) {
    var d = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day, 4, 30);
    d = d.add(Duration(days: (DateTime.sunday - d.weekday) % 7));
    if (!d.add(Duration(minutes: durationMinutes)).isAfter(nowUtc)) {
      d = d.add(const Duration(days: 7));
    }
    return d;
  }

  /// "Sun, 26 Oct · 10:00 AM IST"
  String get scheduleLabel {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final t = start.add(_ist);
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final ampm = t.hour < 12 ? 'AM' : 'PM';
    return '${days[t.weekday - 1]}, ${t.day} ${months[t.month - 1]}  ·  $h:$m $ampm IST';
  }
}
