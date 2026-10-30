import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/current_affairs_service.dart';
import '../../../core/theme/aura.dart';
import '../../../core/utils/links.dart';
import '../../../core/widgets/aura/aura_widgets.dart';
import '../../streak/data/time_tracker.dart';
import '../../streak/view/coin_widgets.dart';

enum _Filter { all, arunachal, northeast, exams, videos }

extension on _Filter {
  String get label => switch (this) {
        _Filter.all => 'All',
        _Filter.arunachal => 'Arunachal',
        _Filter.northeast => 'Northeast',
        _Filter.exams => 'Exams & jobs',
        _Filter.videos => 'Videos',
      };

  bool matches(CurrentAffairsItem i) => switch (this) {
        _Filter.all => true,
        _Filter.arunachal => i.region == NewsRegion.arunachal,
        _Filter.northeast => i.region == NewsRegion.northeast,
        _Filter.exams => i.examRelated,
        _Filter.videos => i.kind == NewsKind.video,
      };
}

class CurrentAffairsGkScreen extends ConsumerStatefulWidget {
  const CurrentAffairsGkScreen({super.key});

  @override
  ConsumerState<CurrentAffairsGkScreen> createState() =>
      _CurrentAffairsGkScreenState();
}

class _CurrentAffairsGkScreenState
    extends ConsumerState<CurrentAffairsGkScreen> {
  _Filter _filter = _Filter.all;
  String _query = '';
  bool _searching = false;

  Future<void> _refresh() async {
    await ref.read(currentAffairsServiceProvider).fetch(force: true);
    ref.invalidate(currentAffairsProvider);
    await ref.read(currentAffairsProvider.future);
  }

  @override
  Widget build(BuildContext context) => TimeTracked(
        section: 'read',
        sub: 'news',
        child: _buildContent(context),
      );

  Widget _buildContent(BuildContext context) {
    final a = context.aura;
    final async = ref.watch(currentAffairsProvider);

    return Scaffold(
      body: AuraBackground(
        child: StatusBarScrim(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                AuraSliverBar(
                  onBack: () => context.pop(),
                  title: _searching
                      ? TextField(
                          autofocus: true,
                          onChanged: (v) => setState(() => _query = v),
                          style: AuraType.sans(15, a.ink),
                          cursorColor: a.accent,
                          decoration: InputDecoration(
                            hintText: 'Search stories',
                            hintStyle: AuraType.sans(15, a.inkFaint),
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        )
                      : const Text('Current affairs'),
                  actions: [
                    if (!_searching) const HiddenCoin('news'),
                    IconButton(
                      tooltip: _searching ? 'Close search' : 'Search',
                      icon: Icon(_searching
                          ? CupertinoIcons.xmark
                          : CupertinoIcons.search),
                      onPressed: () => setState(() {
                        _searching = !_searching;
                        if (!_searching) _query = '';
                      }),
                    ),
                  ],
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                      AuraSpace.gutter - 2, 4, AuraSpace.gutter, 6),
                  sliver: SliverToBoxAdapter(
                    child: SegmentedTabs(
                      labels: [for (final f in _Filter.values) f.label],
                      selected: _filter.index,
                      onChanged: (i) =>
                          setState(() => _filter = _Filter.values[i]),
                    ),
                  ),
                ),
                ...async.when(
                  loading: () => [
                    SliverPadding(
                      padding: const EdgeInsets.all(AuraSpace.gutter),
                      sliver: SliverList.separated(
                        itemCount: 6,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (_, __) => const SkeletonBox(height: 92),
                      ),
                    ),
                  ],
                  error: (_, __) => [_empty(context, offline: true)],
                  data: (r) => _stories(context, r),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _stories(BuildContext context, FeedResult r) {
    final a = context.aura;
    final q = _query.trim().toLowerCase();
    final items = r.items
        .where(_filter.matches)
        .where((i) =>
            q.isEmpty ||
            i.title.toLowerCase().contains(q) ||
            i.summary.toLowerCase().contains(q) ||
            i.source.toLowerCase().contains(q))
        .toList();

    final note = r.offline
        ? 'Offline · showing saved stories'
        : r.failed.isNotEmpty
            ? '${r.failed.join(', ')} didn\'t respond · pull to retry'
            : null;

    if (items.isEmpty) {
      return [_empty(context, offline: r.offline && r.items.isEmpty)];
    }

    return [
      if (note != null)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
              AuraSpace.gutter, 6, AuraSpace.gutter, 0),
          sliver: SliverToBoxAdapter(
            child: Text(note, style: AuraType.sans(12, a.inkFaint)),
          ),
        ),
      SliverPadding(
        padding: EdgeInsets.fromLTRB(AuraSpace.gutter, 10, AuraSpace.gutter,
            40 + MediaQuery.paddingOf(context).bottom),
        sliver: SliverList.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => Divider(color: a.hairline, height: 1),
          itemBuilder: (_, i) => _StoryRow(item: items[i]),
        ),
      ),
    ];
  }

  Widget _empty(BuildContext context, {required bool offline}) =>
      SliverFillRemaining(
        hasScrollBody: false,
        child: AuraEmpty(
          icon: offline ? CupertinoIcons.wifi_slash : CupertinoIcons.news,
          title: offline ? 'You\'re offline' : 'Nothing here yet',
          message: offline
              ? 'Connect to the internet to load today\'s stories.'
              : 'No stories match this filter right now.',
          actionLabel: 'Try again',
          onAction: _refresh,
        ),
      );
}

class _StoryRow extends StatelessWidget {
  final CurrentAffairsItem item;
  const _StoryRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final isVideo = item.kind == NewsKind.video;
    return InkWell(
      onTap: () => _showStory(context, item),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(child: Eyebrow(item.source, color: a.accent)),
                    Text('  ·  ${item.dateStr}',
                        style: AuraType.sans(11.5, a.inkFaint)),
                    if (item.examRelated) ...[
                      const SizedBox(width: 8),
                      Tag('Exam', color: a.review),
                    ],
                  ]),
                  const SizedBox(height: 6),
                  Text(item.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AuraType.serif(16.5, a.ink, height: 1.3)),
                  if (item.summary.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(item.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AuraType.sans(13, a.inkMuted, height: 1.45)),
                  ],
                ],
              ),
            ),
            if (item.imageUrl != null) ...[
              const SizedBox(width: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(AuraSpace.radiusS),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.network(
                      item.imageUrl!,
                      width: isVideo ? 112 : 84,
                      height: isVideo ? 63 : 84,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          SizedBox(width: isVideo ? 112 : 84),
                    ),
                    if (isVideo)
                      Icon(CupertinoIcons.play_circle_fill,
                          color: Colors.white.withValues(alpha: 0.9), size: 26),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

void _showStory(BuildContext context, CurrentAffairsItem item) {
  final a = context.aura;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (sheet) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.62,
      maxChildSize: 0.92,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        children: [
          MetaLine([item.source, item.dateStr]),
          const SizedBox(height: 10),
          Text(item.title, style: AuraType.serif(23, a.ink, height: 1.25)),
          if (item.imageUrl != null) ...[
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(AuraSpace.radiusS),
              child: Image.network(item.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            ),
          ],
          if (item.summary.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(item.summary, style: AuraType.sans(15.5, a.ink, height: 1.6)),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed:
                item.link.isEmpty ? null : () => openLink(context, item.link),
            icon: Icon(item.kind == NewsKind.video
                ? CupertinoIcons.play_fill
                : CupertinoIcons.arrow_up_right),
            label: Text(item.kind == NewsKind.video
                ? 'Watch on YouTube'
                : 'Read full story on ${item.source}'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(sheet);
              context.push('/chatbot',
                  extra: 'Explain this news for APPSC/APSSB exam preparation. '
                      'Give background, key facts and 3 likely questions.\n\n'
                      '${item.title}\n\n${item.summary}');
            },
            icon: const Icon(CupertinoIcons.sparkles),
            label: const Text('Explain for my exam'),
          ),
        ],
      ),
    ),
  );
}
