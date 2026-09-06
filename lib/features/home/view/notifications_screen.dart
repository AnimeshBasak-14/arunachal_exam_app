import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

import 'package:shared_preferences/shared_preferences.dart';

// ─── Notification Model ────────────────────────────────────────────────────
class AppNotification {
  final String id;
  final String title;
  final String body;
  final IconData icon;
  final Color color;
  final DateTime time;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
    required this.time,
    this.isRead = false,
  });
}

// ─── Provider ─────────────────────────────────────────────────────────────
final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<AppNotification>>((ref) {
  return NotificationsNotifier();
});

final hasUnreadNotifProvider = Provider<bool>((ref) {
  return ref.watch(notificationsProvider).any((n) => !n.isRead);
});

class NotificationsNotifier extends StateNotifier<List<AppNotification>> {
  NotificationsNotifier()
      : super([
          AppNotification(
            id: 'n1',
            title: '🆕 New PYQ Papers Available',
            body:
                'APPSC 2024 Previous Year Papers have been added. Start practising now!',
            icon: Icons.article_rounded,
            color: AppColors.primary,
            time: DateTime.now().subtract(const Duration(minutes: 15)),
          ),
          AppNotification(
            id: 'n2',
            title: '🏆 Rank Progression Update!',
            body:
                'You\'re climbing the MLBB-style ranks! Keep practicing to reach Grandmaster & Mythic status.',
            icon: Icons.emoji_events_rounded,
            color: AppColors.accent,
            time: DateTime.now().subtract(const Duration(hours: 1)),
          ),
          AppNotification(
            id: 'n3',
            title: '📅 Mock Test Reminder',
            body:
                'You haven\'t taken a mock test today. Consistency is key to APPSC/APSSB success!',
            icon: Icons.timer_rounded,
            color: AppColors.secondary,
            time: DateTime.now().subtract(const Duration(hours: 3)),
            isRead: true,
          ),
          AppNotification(
            id: 'n4',
            title: '💬 New Discussion in Bookmarks',
            body:
                'Check out new explanations added for General English questions.',
            icon: Icons.comment_rounded,
            color: const Color(0xFF8B5CF6),
            time: DateTime.now().subtract(const Duration(days: 1)),
            isRead: true,
          ),
          AppNotification(
            id: 'n5',
            title: '📢 Welcome to Arunachal Exam Prep!',
            body:
                'Start with APPSC or APSSB exams. Bookmark questions, track your rank globally.',
            icon: Icons.campaign_rounded,
            color: AppColors.primary,
            time: DateTime.now().subtract(const Duration(days: 3)),
            isRead: true,
          ),
        ]) {
    _loadDismissed();
  }

  Future<void> _loadDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getStringList('dismissed_notification_ids') ?? [];
    if (dismissed.isNotEmpty) {
      if (mounted) {
        state = state.where((n) => !dismissed.contains(n.id)).toList();
      }
    }
  }

  void markAllRead() {
    state = state
        .map((n) => AppNotification(
              id: n.id,
              title: n.title,
              body: n.body,
              icon: n.icon,
              color: n.color,
              time: n.time,
              isRead: true,
            ))
        .toList();
  }

  void markRead(String id) {
    state = state.map((n) {
      if (n.id == id) {
        return AppNotification(
          id: n.id,
          title: n.title,
          body: n.body,
          icon: n.icon,
          color: n.color,
          time: n.time,
          isRead: true,
        );
      }
      return n;
    }).toList();
  }

  void dismiss(String id) async {
    state = state.where((n) => n.id != id).toList();
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getStringList('dismissed_notification_ids') ?? [];
    if (!dismissed.contains(id)) {
      dismissed.add(id);
      await prefs.setStringList('dismissed_notification_ids', dismissed);
    }
  }
}

// ─── Notifications Screen ─────────────────────────────────────────────────
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final hasUnread = notifications.any((n) => !n.isRead);

    // Mark all as read when screen is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsProvider.notifier).markAllRead();
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Notifications'),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: () =>
                  ref.read(notificationsProvider.notifier).markAllRead(),
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 64,
                      color: AppColors.textHint.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  const Text(
                    'No notifications yet',
                    style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You\'re all caught up!',
                    style: TextStyle(fontSize: 13, color: AppColors.textHint),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return Dismissible(
                  key: Key(notif.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) {
                    ref.read(notificationsProvider.notifier).dismiss(notif.id);
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: AppColors.error.withValues(alpha: 0.12),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.error),
                  ),
                  child: InkWell(
                    onTap: () => ref
                        .read(notificationsProvider.notifier)
                        .markRead(notif.id),
                    child: Container(
                      color: notif.isRead
                          ? Colors.transparent
                          : notif.color.withValues(alpha: 0.05),
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.m, vertical: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: notif.color.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child:
                                Icon(notif.icon, color: notif.color, size: 22),
                          ),
                          const SizedBox(width: 12),
                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notif.title,
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: notif.isRead
                                              ? FontWeight.w600
                                              : FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (!notif.isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: notif.color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notif.body,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _timeAgo(notif.time),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textHint,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Dismiss button
                          IconButton(
                            icon: const Icon(Icons.close_rounded,
                                size: 18, color: AppColors.textHint),
                            constraints: const BoxConstraints(
                                minWidth: 32, minHeight: 32),
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              ref
                                  .read(notificationsProvider.notifier)
                                  .dismiss(notif.id);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
