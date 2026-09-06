import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/current_affairs_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class CurrentAffairsGkScreen extends ConsumerStatefulWidget {
  const CurrentAffairsGkScreen({super.key});

  @override
  ConsumerState<CurrentAffairsGkScreen> createState() =>
      _CurrentAffairsGkScreenState();
}

class _CurrentAffairsGkScreenState
    extends ConsumerState<CurrentAffairsGkScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Recruitment & Exams',
    'Governance & State GK',
    'Infrastructure & Economy',
    'Environment & Wildlife',
    'Art & Culture',
    'State News',
  ];

  @override
  Widget build(BuildContext context) {
    final affairsAsync = ref.watch(currentAffairsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Affairs & GK',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text('Daily State & National Updates for APSSB',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => ref.refresh(currentAffairsProvider),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                // State GK Banner Shortcut
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: InkWell(
              onTap: () => context.push('/state-gk'),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F9D58), Color(0xFF0B8043)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F9D58).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.auto_stories_rounded,
                        color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Arunachal Pradesh State GK Compendium',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '11 Chapters: History, 28 Districts, GI Tags, Polity & Culture',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded,
                        color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
          ),
          // Search & Filter
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search news, notifications, or topics...',
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = cat == _selectedCategory;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                          backgroundColor: AppColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.divider,
                            ),
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedCategory = cat);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Articles List
          Expanded(
            child: affairsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text('Could not load current affairs: $err'),
              ),
              data: (articles) {
                final filtered = articles.where((a) {
                  final matchesCat = _selectedCategory == 'All' ||
                      a.category.toLowerCase() ==
                          _selectedCategory.toLowerCase();
                  final q = _searchQuery.toLowerCase().trim();
                  final matchesQuery = q.isEmpty ||
                      a.title.toLowerCase().contains(q) ||
                      a.summary.toLowerCase().contains(q) ||
                      a.source.toLowerCase().contains(q);
                  return matchesCat && matchesQuery;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No articles found matching criteria.',
                        style: TextStyle(color: AppColors.textSecondary)),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    MediaQuery.of(context).padding.bottom + 48,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.m),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 1.5,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          context.push(
                            '/news-details',
                            extra: {
                              'title': item.title,
                              'summary': item.summary,
                              'source': item.source,
                              'date': item.dateStr,
                              'link': item.link,
                            },
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.m),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      item.source,
                                      style: const TextStyle(
                                        color: AppColors.primaryDark,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    item.dateStr,
                                    style: const TextStyle(
                                      color: AppColors.textHint,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (item.aiEnhanced)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.auto_awesome,
                                              size: 11,
                                              color: AppColors.accent),
                                          SizedBox(width: 3),
                                          Text(
                                            'Exam Ready',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: AppColors.accent,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.5,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.summary,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  height: 1.4,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero),
                                    onPressed: () {
                                      context.push(
                                        '/chatbot',
                                        extra:
                                            '${item.title}\n\n${item.summary}',
                                      );
                                    },
                                    icon: const Icon(
                                        Icons.chat_bubble_outline_rounded,
                                        size: 14),
                                    label: const Text('Ask AI Tutor',
                                        style: TextStyle(fontSize: 12)),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Read Full >',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
    ),
    ),
    );
  }
}
