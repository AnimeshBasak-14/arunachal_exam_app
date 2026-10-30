import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/service_providers.dart';
import 'day_key.dart';

/// Coins are a score for showing up and exploring. They are earned once per
/// reason and day, kept on this phone, and have no cash value.
class CoinReward {
  CoinReward._();
  static const dailyCorrect = 10;
  static const dailyTried = 3;
  static const dailyGoal = 5;
  static const finishedPaper = 10;
  static const hiddenCoin = 2;
}

class CoinEvent {
  final String date;
  final int amount;
  final String reason;
  const CoinEvent(this.date, this.amount, this.reason);

  Map<String, dynamic> toJson() => {'d': date, 'a': amount, 'r': reason};
  factory CoinEvent.fromJson(Map<String, dynamic> j) =>
      CoinEvent(j['d'] as String, j['a'] as int, j['r'] as String);
}

class CoinState {
  final int balance;
  final List<CoinEvent> events; // newest first
  const CoinState(this.balance, this.events);
}

class CoinsNotifier extends Notifier<CoinState> {
  static const _balanceKey = 'coins_balance_v1';
  static const _eventsKey = 'coins_events_v1';
  static const _keysKey = 'coins_keys_v1';

  late Set<String> _keys;
  SharedPreferences get _p => ref.read(sharedPreferencesProvider);

  @override
  CoinState build() {
    final p = _p;
    _keys = (p.getStringList(_keysKey) ?? const []).toSet();
    var events = <CoinEvent>[];
    try {
      events = [
        for (final e in jsonDecode(p.getString(_eventsKey) ?? '[]') as List)
          CoinEvent.fromJson(e as Map<String, dynamic>)
      ];
    } catch (_) {}
    return CoinState(p.getInt(_balanceKey) ?? 0, events);
  }

  bool has(String key) => _keys.contains(key);

  /// Adds [amount] coins once per [key]. Returns false if already awarded.
  bool award(String key, int amount, String reason, {DateTime? now}) {
    if (amount <= 0 || !_keys.add(key)) return false;
    final events = [
      CoinEvent(dayKey(now ?? DateTime.now()), amount, reason),
      ...state.events,
    ].take(100).toList();
    state = CoinState(state.balance + amount, events);
    _p
      ..setInt(_balanceKey, state.balance)
      ..setString(
          _eventsKey, jsonEncode(events.map((e) => e.toJson()).toList()))
      ..setStringList(_keysKey, _keys.toList());
    return true;
  }
}

final coinsProvider =
    NotifierProvider<CoinsNotifier, CoinState>(CoinsNotifier.new);

/// Screens a hidden coin can sit on. Each day three of them hold one.
const hiddenCoinSpots = [
  'library',
  'mocks',
  'progress',
  'gk',
  'english',
  'syllabus',
  'news',
  'account',
];

/// The same three spots for everyone on a given date.
List<String> hiddenSpotsFor(DateTime day) {
  final spots = [...hiddenCoinSpots]..shuffle(math.Random(dayNumber(day)));
  return spots.take(3).toList();
}

String hiddenCoinKey(DateTime day, String spot) =>
    'hidden:${dayKey(day)}:$spot';
