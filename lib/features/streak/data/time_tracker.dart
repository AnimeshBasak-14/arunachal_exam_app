import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/service_providers.dart';
import 'day_key.dart';

/// Time spent per section and sub-section per day, stored only on this phone.
///
/// Sections: `pyq`, `mock`, `cards` (sub = topic name) and `read`
/// (sub = gk, english, syllabus, news, tutor).
class TimeTracker {
  TimeTracker(this._p);
  final SharedPreferences _p;

  static const _key = 'time_log_v1';
  static const keepDays = 120;

  Map<String, dynamic> _read() {
    try {
      return Map<String, dynamic>.from(
          jsonDecode(_p.getString(_key) ?? '{}') as Map);
    } catch (_) {
      return {};
    }
  }

  void add(String section, String sub, int seconds, {DateTime? now}) {
    if (seconds <= 0) return;
    final log = _read();
    final day = Map<String, dynamic>.from(
        (log[dayKey(now ?? DateTime.now())] ?? {}) as Map);
    final sec = Map<String, dynamic>.from((day[section] ?? {}) as Map);
    sec[sub] = ((sec[sub] ?? 0) as int) + seconds;
    day[section] = sec;
    log[dayKey(now ?? DateTime.now())] = day;
    if (log.length > keepDays) {
      final keys = log.keys.toList()..sort();
      for (final k in keys.take(log.length - keepDays)) {
        log.remove(k);
      }
    }
    _p.setString(_key, jsonEncode(log));
  }

  /// section -> sub -> seconds, summed over the last [days] days including today.
  Map<String, Map<String, int>> lastDays(int days, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final log = _read();
    final out = <String, Map<String, int>>{};
    for (int i = 0; i < days; i++) {
      final d = DateTime(today.year, today.month, today.day - i);
      final day = log[dayKey(d)];
      if (day is! Map) continue;
      day.forEach((section, subs) {
        if (subs is! Map) return;
        final target = out.putIfAbsent(section as String, () => {});
        subs.forEach((sub, secs) {
          target[sub as String] = (target[sub] ?? 0) + (secs as int);
        });
      });
    }
    return out;
  }

  static int sectionTotal(Map<String, Map<String, int>> data, String section) =>
      (data[section] ?? const {}).values.fold(0, (a, b) => a + b);
}

final timeTrackerProvider = Provider<TimeTracker>(
    (ref) => TimeTracker(ref.watch(sharedPreferencesProvider)));

/// Counts the time this screen is open and the app is in the foreground.
/// Wrap a screen with it; change [sub] while it is open to switch sub-section.
class TimeTracked extends ConsumerStatefulWidget {
  final String section;
  final String sub;
  final Widget child;
  const TimeTracked({
    super.key,
    required this.section,
    this.sub = 'general',
    required this.child,
  });

  @override
  ConsumerState<TimeTracked> createState() => _TimeTrackedState();
}

class _TimeTrackedState extends ConsumerState<TimeTracked>
    with WidgetsBindingObserver {
  // Read once in initState: `ref` can't be used while the widget is disposing.
  late final TimeTracker _tracker;
  DateTime _mark = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _tracker = ref.read(timeTrackerProvider);
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  void _start() {
    _mark = DateTime.now();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _flush());
  }

  void _flush({String? section, String? sub}) {
    final now = DateTime.now();
    // A flush normally covers about 10 s; cap it so a suspended device
    // can't add minutes it didn't spend.
    final secs = now.difference(_mark).inSeconds.clamp(0, 30);
    _mark = now;
    _tracker.add(section ?? widget.section, sub ?? widget.sub, secs, now: now);
  }

  @override
  void didUpdateWidget(covariant TimeTracked old) {
    super.didUpdateWidget(old);
    if (old.section != widget.section || old.sub != widget.sub) {
      _flush(section: old.section, sub: old.sub);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _start();
    } else {
      _timer?.cancel();
      _flush();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _flush();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
