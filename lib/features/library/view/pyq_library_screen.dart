import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/exam_goals.dart';
import '../../../core/theme/aura.dart';
import '../../../core/widgets/aura/aura_widgets.dart';
import '../../papers/data/paper.dart';
import '../../papers/view/paper_widgets.dart';
import '../../shell/view/app_shell.dart';

/// Searchable list of previous-year papers grouped by year.
class PyqLibraryScreen extends ConsumerStatefulWidget {
  const PyqLibraryScreen({super.key});

  @override
  ConsumerState<PyqLibraryScreen> createState() => _PyqLibraryScreenState();
}

class _PyqLibraryScreenState extends ConsumerState<PyqLibraryScreen> {
  final _search = TextEditingController();
  String _query = '';

  static const _filters = <Department?>[null, ...Department.primary];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Paper> _apply(List<Paper> all, Department? dept) {
    final q = _query.trim().toLowerCase();
    return all.where((p) {
      if (dept != null && p.department != dept) return false;
      if (q.isEmpty) return true;
      return p.title.toLowerCase().contains(q) ||
          p.examCode.toLowerCase().contains(q) ||
          (p.subject ?? '').toLowerCase().contains(q) ||
          (p.year?.toString().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final dept = ref.watch(libraryDepartmentProvider);
    final async = ref.watch(papersProvider(PaperKind.pyq));
    final bottom = 110 + MediaQuery.paddingOf(context).bottom;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(papersProvider(PaperKind.pyq));
        await ref.read(papersProvider(PaperKind.pyq).future);
      },
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverToBoxAdapter(
            child: ChromeHeader(
              title: 'PYQ Library',
              subtitle: async.hasValue
                  ? '${async.value!.papers.length} papers from APPSC & APSSB'
                  : 'Previous year papers',
            ),
          ),
          SliverSafeArea(
            top: false,
            bottom: false,
            sliver: SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  AuraSpace.gutter, 22, AuraSpace.gutter, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _search,
                      onChanged: (v) => setState(() => _query = v),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search exam, subject or year',
                        prefixIcon: const Icon(CupertinoIcons.search, size: 19),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                icon: const Icon(
                                    CupertinoIcons.clear_circled_solid,
                                    size: 18),
                                onPressed: () {
                                  _search.clear();
                                  setState(() => _query = '');
                                },
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SegmentedTabs(
                      labels: [for (final d in _filters) d?.label ?? 'All'],
                      selected: _filters.indexOf(dept),
                      onChanged: (i) => ref
                          .read(libraryDepartmentProvider.notifier)
                          .state = _filters[i],
                    ),
                  ],
                ),
              ),
            ),
          ),
          ...async.when(
            loading: () => [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    AuraSpace.gutter, 16, AuraSpace.gutter, 0),
                sliver: SliverList.separated(
                  itemCount: 5,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, __) =>
                      const SkeletonBox(height: 96, radius: 20),
                ),
              ),
            ],
            error: (_, __) => [_empty(offline: true)],
            data: (result) {
              final papers = _apply(result.papers, dept);
              if (result.papers.isEmpty) return [_empty(offline: true)];
              if (papers.isEmpty) {
                return [
                  SliverToBoxAdapter(
                    child: AuraEmpty(
                      icon: CupertinoIcons.search,
                      title: 'No matching papers',
                      message:
                          'Try another year or exam name, or clear the filter.',
                      actionLabel: 'Clear filters',
                      onAction: () {
                        _search.clear();
                        setState(() => _query = '');
                        ref.read(libraryDepartmentProvider.notifier).state =
                            null;
                      },
                    ),
                  ),
                ];
              }
              final byYear = <int?, List<Paper>>{};
              for (final p in papers) {
                byYear.putIfAbsent(p.year, () => []).add(p);
              }
              final years = byYear.keys.toList()
                ..sort((x, y) => (y ?? 0).compareTo(x ?? 0));
              return [
                if (result.isOffline)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        AuraSpace.gutter, 14, AuraSpace.gutter, 0),
                    sliver: SliverToBoxAdapter(
                      child: Text('Offline · showing saved list',
                          style: AuraType.sans(12.5, a.review)),
                    ),
                  ),
                for (final y in years) ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        AuraSpace.gutter, 26, AuraSpace.gutter, 12),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        children: [
                          Text(y?.toString() ?? 'Year not listed',
                              style: AuraType.serif(19, a.ink)),
                          const SizedBox(width: 12),
                          Expanded(child: Divider(color: a.hairline)),
                          const SizedBox(width: 12),
                          Text('${byYear[y]!.length}',
                              style: AuraType.digits(12, a.inkFaint)),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AuraSpace.gutter),
                    sliver: SliverList.separated(
                      itemCount: byYear[y]!.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => PaperRow(paper: byYear[y]![i]),
                    ),
                  ),
                ],
              ];
            },
          ),
          SliverToBoxAdapter(child: SizedBox(height: bottom)),
        ],
      ),
    );
  }

  Widget _empty({required bool offline}) => SliverToBoxAdapter(
        child: AuraEmpty(
          icon: CupertinoIcons.wifi_slash,
          title: 'No papers to show',
          message:
              'We could not reach the paper bank and there is no saved list on this device yet.',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(papersProvider(PaperKind.pyq)),
        ),
      );
}
