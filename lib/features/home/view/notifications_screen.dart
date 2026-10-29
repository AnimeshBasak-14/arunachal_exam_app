import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/current_affairs_service.dart';
import '../../../core/services/notification_inbox.dart';
import '../../../core/theme/aura.dart';
import '../../../core/utils/links.dart';
import '../../../core/widgets/aura/aura_widgets.dart';
import '../../learn/view/study_widgets.dart';

export '../../../core/services/notification_inbox.dart' show hasUnreadNotifProvider;

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  late DateTime _seenBefore;

  @override
  void initState() {
    super.initState();
    _seenBefore = ref.read(inboxProvider).seenAt;
    // Pick up pushes saved while the app was closed, then clear the bell dot.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final inbox = ref.read(inboxProvider.notifier)..reload();
      await inbox.markSeen();
    });
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final inbox = ref.watch(inboxProvider).messages;
    final feed = ref.watch(currentAffairsProvider);
    final updates = ref.watch(examUpdatesProvider);
    bool isNew(DateTime? t) => t != null && t.isAfter(_seenBefore);

    return StudyPage(
      title: 'Notifications',
      children: [
        if (inbox.isNotEmpty) ...[
          const SectionHeader('From Dawnlit'),
          const SizedBox(height: 10),
          GlassList(indent: 18, children: [
            for (final m in inbox)
              Dismissible(
                key: ValueKey(m.id),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => ref.read(inboxProvider.notifier).remove(m.id),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: a.danger.withValues(alpha: 0.12),
                  child: Icon(CupertinoIcons.trash, color: a.danger),
                ),
                child: _Row(
                  title: m.title,
                  body: m.body,
                  meta: relativeDate(m.time),
                  unread: isNew(m.time),
                  onTap: m.link == null ? null : () => openLink(context, m.link!),
                ),
              ),
          ]),
          const SizedBox(height: 28),
        ],
        Row(children: [
          const Expanded(child: SectionHeader('Exam & recruitment news')),
          TextButton(
            onPressed: () => context.push('/current-affairs-gk'),
            child: const Text('All news'),
          ),
        ]),
        const SizedBox(height: 4),
        Text('From Arunachal news outlets. Always confirm dates on appsc.gov.in or apssb.nic.in.',
            style: AuraType.sans(12.5, a.inkFaint, height: 1.45)),
        const SizedBox(height: 12),
        if (feed.isLoading && updates.isEmpty)
          for (int i = 0; i < 3; i++)
            const Padding(padding: EdgeInsets.only(bottom: 10), child: SkeletonBox(height: 72))
        else if (updates.isEmpty)
          AuraEmpty(
            icon: CupertinoIcons.bell,
            title: 'Nothing new right now',
            message: 'Exam notices and results reported in Arunachal news will appear here.',
            actionLabel: 'Refresh',
            onAction: () => ref.invalidate(currentAffairsProvider),
          )
        else
          GlassList(indent: 18, children: [
            for (final i in updates)
              _Row(
                title: i.title,
                body: i.source,
                meta: i.dateStr,
                unread: isNew(i.published),
                onTap: () => openLink(context, i.link),
              ),
          ]),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String title, body, meta;
  final bool unread;
  final VoidCallback? onTap;
  const _Row({required this.title, required this.body, required this.meta, required this.unread, this.onTap});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 10),
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                  color: unread ? a.accent : Colors.transparent, shape: BoxShape.circle),
            ),
          ),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: AuraType.sans(15, a.ink, weight: unread ? FontWeight.w600 : FontWeight.w500, height: 1.4)),
              const SizedBox(height: 4),
              Text(body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AuraType.sans(13.5, a.inkMuted, height: 1.45)),
              const SizedBox(height: 2),
              Text(meta, style: AuraType.sans(12, a.inkFaint)),
            ]),
          ),
        ]),
      ),
    );
  }
}
