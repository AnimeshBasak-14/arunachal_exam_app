import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'current_affairs_service.dart';
import 'service_providers.dart';

/// A push message sent from the Firebase console (or a server).
class InboxMessage {
  final String id;
  final String title;
  final String body;
  final DateTime time;
  final String? link;
  const InboxMessage(this.id, this.title, this.body, this.time, {this.link});

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'time': time.toIso8601String(),
        'link': link
      };

  factory InboxMessage.fromJson(Map<String, dynamic> j) => InboxMessage(
        j['id'] as String,
        j['title'] as String? ?? '',
        j['body'] as String? ?? '',
        DateTime.tryParse(j['time'] as String? ?? '') ?? DateTime.now(),
        link: j['link'] as String?,
      );
}

const _inboxKey = 'notification_inbox_v1';
const _seenKey = 'notifications_seen_at';

/// Saves a received push message. Called from the messaging service, which
/// runs outside the widget tree.
Future<void> saveInboxMessage(InboxMessage m) async {
  final prefs = await SharedPreferences.getInstance();
  final list = _read(prefs)..removeWhere((e) => e.id == m.id);
  list.insert(0, m);
  await prefs.setString(
      _inboxKey, jsonEncode(list.take(50).map((e) => e.toJson()).toList()));
}

List<InboxMessage> _read(SharedPreferences p) {
  try {
    return [
      for (final e in jsonDecode(p.getString(_inboxKey) ?? '[]') as List)
        InboxMessage.fromJson(e as Map<String, dynamic>)
    ];
  } catch (_) {
    return [];
  }
}

class InboxState {
  final List<InboxMessage> messages;
  final DateTime seenAt;
  const InboxState(this.messages, this.seenAt);
}

class InboxNotifier extends StateNotifier<InboxState> {
  final SharedPreferences _p;
  InboxNotifier(this._p) : super(_load(_p));

  static InboxState _load(SharedPreferences p) => InboxState(
        _read(p),
        DateTime.fromMillisecondsSinceEpoch(p.getInt(_seenKey) ?? 0),
      );

  void reload() => state = _load(_p);

  /// Marks everything up to now as seen (clears the bell dot).
  Future<void> markSeen() async {
    await _p.setInt(_seenKey, DateTime.now().millisecondsSinceEpoch);
    reload();
  }

  Future<void> remove(String id) async {
    final list = _read(_p)..removeWhere((e) => e.id == id);
    await _p.setString(
        _inboxKey, jsonEncode(list.map((e) => e.toJson()).toList()));
    reload();
  }
}

final inboxProvider = StateNotifierProvider<InboxNotifier, InboxState>(
    (ref) => InboxNotifier(ref.watch(sharedPreferencesProvider)));

/// Exam and recruitment stories from the live news feed, newest first.
final examUpdatesProvider = Provider<List<CurrentAffairsItem>>((ref) {
  final feed = ref.watch(currentAffairsProvider).value;
  return (feed?.items ?? const <CurrentAffairsItem>[])
      .where((i) => i.examRelated && i.kind == NewsKind.article)
      .take(20)
      .toList();
});

/// Dot on the bell: something arrived since the notifications page was last opened.
final hasUnreadNotifProvider = Provider<bool>((ref) {
  final inbox = ref.watch(inboxProvider);
  bool newer(DateTime? t) => t != null && t.isAfter(inbox.seenAt);
  return inbox.messages.any((m) => newer(m.time)) ||
      ref.watch(examUpdatesProvider).any((i) => newer(i.published));
});
