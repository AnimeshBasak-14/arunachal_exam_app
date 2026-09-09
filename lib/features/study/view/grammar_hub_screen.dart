import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/grammar_data.dart';

class GrammarHubScreen extends StatefulWidget {
  const GrammarHubScreen({super.key});

  @override
  State<GrammarHubScreen> createState() => _GrammarHubScreenState();
}

class _GrammarHubScreenState extends State<GrammarHubScreen> {
  String _searchQuery = '';
  String _selectedLevel = 'All';
  String? _selectedTopicId;

  @override
  Widget build(BuildContext context) {
    final allTopics = GrammarData.topics;
    final topics = _selectedLevel == 'All'
        ? allTopics
        : allTopics.where((t) => t.level == _selectedLevel).toList();

    // Filtered rules if searching
    final isSearching = _searchQuery.trim().isNotEmpty;
    final searchLower = _searchQuery.toLowerCase().trim();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'English Grammar Hub',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.quiz_rounded, color: AppColors.primary),
            tooltip: 'Take Grammar Quiz',
            onPressed: () => context.push('/grammar-quiz'),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Banner, Search, and Level Filter
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Column(
                children: [
                  _buildHeaderBanner(context),
                  const SizedBox(height: AppSpacing.m),
                  _buildSearchBar(),
                  const SizedBox(height: AppSpacing.s),
                  _buildLevelFilterRow(),
                ],
              ),
            ),
          ),

          // Search Results or Chapter View
          if (isSearching)
            _buildSearchResults(searchLower)
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Core Grammar Topics',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${topics.length} Modules',
                      style: const TextStyle(fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.m, 0, AppSpacing.m, AppSpacing.xl),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final topic = topics[index];
                    final isExpanded = _selectedTopicId == topic.id;
                    return _buildTopicCard(topic, isExpanded);
                  },
                  childCount: topics.length,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusL),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3C72).withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'APSSB & APPSC English',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade400,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'HIGH YIELD',
                  style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Master golden rules for Subject-Verb Agreement, Tenses, Error Spotting, Prepositions, Voice & Narration with exam-tested examples.',
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/grammar-quiz'),
              icon: const Icon(Icons.play_circle_fill_rounded, color: AppColors.primary, size: 20),
              label: const Text(
                'Test Your Knowledge (Practice Quiz)',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusM)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      onChanged: (val) => setState(() => _searchQuery = val),
      decoration: InputDecoration(
        hintText: 'Search rules, verbs, prepositions...',
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusM),
          borderSide: BorderSide.none,
        ),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textHint),
                onPressed: () => setState(() => _searchQuery = ''),
              )
            : null,
      ),
    );
  }

  Widget _buildLevelFilterRow() {
    final levels = ['All', 'Beginner', 'Intermediate', 'Advanced'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: levels.map((lvl) {
          final isSelected = _selectedLevel == lvl;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                lvl == 'All' ? 'All Levels' : lvl,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: Colors.white,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedLevel = lvl);
                }
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : Colors.grey.shade300,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLevelBadge(String level) {
    Color bg;
    Color fg;
    if (level == 'Beginner') {
      bg = Colors.green.shade50;
      fg = Colors.green.shade800;
    } else if (level == 'Intermediate') {
      bg = Colors.blue.shade50;
      fg = Colors.blue.shade800;
    } else {
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade800;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        level.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTopicCard(GrammarTopic topic, bool isExpanded) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusM),
        border: Border.all(
          color: isExpanded ? AppColors.primary.withOpacity(0.3) : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () {
              setState(() {
                _selectedTopicId = isExpanded ? null : topic.id;
              });
            },
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primaryLight,
              child: const Icon(Icons.auto_stories_rounded, color: AppColors.primary, size: 20),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    topic.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                _buildLevelBadge(topic.level),
              ],
            ),
            subtitle: Text(
              topic.subtitle,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${topic.rules.length} Rules',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textHint,
                ),
              ],
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: topic.rules.map((rule) => _buildRuleItem(rule)).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRuleItem(GrammarRule rule) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusM),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  rule.ruleTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            rule.explanation,
            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4),
          ),
          const SizedBox(height: 8),
          // Incorrect Example
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.error.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.close_rounded, size: 14, color: AppColors.error),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    rule.exampleIncorrect,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.error,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Correct Example
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.success.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_rounded, size: 14, color: AppColors.success),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    rule.exampleCorrect,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (rule.tip != null && rule.tip!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline_rounded, size: 14, color: Colors.amber),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Tip: ${rule.tip}',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchResults(String query) {
    final matchedRules = <Map<String, dynamic>>[];
    for (final topic in GrammarData.topics) {
      for (final rule in topic.rules) {
        if (rule.ruleTitle.toLowerCase().contains(query) ||
            rule.explanation.toLowerCase().contains(query) ||
            rule.exampleCorrect.toLowerCase().contains(query) ||
            rule.exampleIncorrect.toLowerCase().contains(query)) {
          matchedRules.add({
            'topic': topic.title,
            'rule': rule,
          });
        }
      }
    }

    if (matchedRules.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off_rounded, size: 48, color: AppColors.textHint),
                const SizedBox(height: AppSpacing.s),
                Text(
                  'No rules found for "$query"',
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.m, 0, AppSpacing.m, AppSpacing.xl),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = matchedRules[index];
            final rule = item['rule'] as GrammarRule;
            final topicName = item['topic'] as String;
            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.m),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusM),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      topicName,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildRuleItem(rule),
                ],
              ),
            );
          },
          childCount: matchedRules.length,
        ),
      ),
    );
  }
}
