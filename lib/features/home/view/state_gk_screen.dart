import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/state_gk_data.dart';

class StateGkScreen extends StatefulWidget {
  const StateGkScreen({super.key});

  @override
  State<StateGkScreen> createState() => _StateGkScreenState();
}

class _StateGkScreenState extends State<StateGkScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Overview',
    'Science',
    'History',
    'Administration',
    'Governance',
    'Polity',
    'Geography',
    'Environment',
    'Culture',
    'Demographics',
    'Facts & Literature',
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = StateGkData.chapters.where((ch) {
      final matchesCategory = _selectedCategory == 'All' ||
          ch.category.toLowerCase() == _selectedCategory.toLowerCase();
      final q = _searchQuery.toLowerCase().trim();
      final matchesSearch = q.isEmpty ||
          ch.title.toLowerCase().contains(q) ||
          ch.subtitle.toLowerCase().contains(q) ||
          ch.highlights.any((h) => h.toLowerCase().contains(q)) ||
          ch.keyFacts.any((k) =>
              k.values.any((val) => val.toLowerCase().contains(q)));
      return matchesCategory && matchesSearch;
    }).toList();

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
            Text('State GK Compendium',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text('Arunachal Pradesh Complete Handbook',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                // Search & Filter Header
                Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: AppColors.surface,
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search districts, rivers, GI tags, CMs...',
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
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
                          backgroundColor: AppColors.background,
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
          // Content Chapters List
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('No matching GK topics found.',
                        style: TextStyle(color: AppColors.textSecondary)),
                  )
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.m,
                      AppSpacing.m,
                      AppSpacing.m,
                      MediaQuery.of(context).padding.bottom + 48,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final chapter = filtered[index];
                      return _buildChapterCard(chapter);
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

  Widget _buildChapterCard(StateGkChapter chapter) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ExpansionTile(
        initiallyExpanded: false,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: chapter.category == 'Science'
                ? const Color(0xFF00695C).withValues(alpha: 0.12)
                : AppColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            chapter.category == 'Science'
                ? Icons.science_rounded
                : Icons.menu_book_rounded,
            color: chapter.category == 'Science'
                ? const Color(0xFF00695C)
                : AppColors.primary,
            size: 22,
          ),
        ),
        title: Text(
          chapter.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            chapter.subtitle,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 1),
                const SizedBox(height: 12),
                const Text(
                  'EXAM HIGHLIGHTS & SYNOPSIS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                ...chapter.highlights.map((point) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Text(
                              point,
                              style: const TextStyle(
                                  fontSize: 13.5, height: 1.45),
                            ),
                          ),
                        ],
                      ),
                    )),
                if (chapter.keyFacts.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'QUICK REFERENCE TABLE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      children: chapter.keyFacts.map((row) {
                        final keys = row.keys.toList();
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                row[keys[0]] ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              Flexible(
                                child: Text(
                                  row[keys[1]] ?? '',
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.primaryDark),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
