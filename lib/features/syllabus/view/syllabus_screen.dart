import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/official_syllabus_data.dart';

class SyllabusScreen extends StatefulWidget {
  final int initialTabIndex;
  const SyllabusScreen({super.key, this.initialTabIndex = 0});

  @override
  State<SyllabusScreen> createState() => _SyllabusScreenState();
}

class _SyllabusScreenState extends State<SyllabusScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _apssbFilter = 'All';
  String _appscFilter = 'All';
  String _subjectFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 3),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _launchPortal(String urlStr) async {
    final uri = Uri.parse(urlStr);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching portal URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Official Exam Syllabus',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              'APSSB & APPSC Exam Schemes & Topic Matrix',
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                children: [
                  // Search field
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.m, vertical: 6),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                        decoration: InputDecoration(
                          hintText: 'Search topics, posts, or marking rules...',
                          hintStyle: const TextStyle(fontSize: 13, color: AppColors.textHint),
                          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.primary),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18, color: AppColors.textHint),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),

                  // TabBar
                  TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.accent,
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    tabs: const [
                      Tab(icon: Icon(Icons.compare_arrows_rounded, size: 18), text: 'Overview'),
                      Tab(icon: Icon(Icons.assignment_outlined, size: 18), text: 'APSSB'),
                      Tab(icon: Icon(Icons.account_balance_outlined, size: 18), text: 'APPSC'),
                      Tab(icon: Icon(Icons.grid_view_rounded, size: 18), text: 'Subjects'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildExecutiveOverviewTab(),
              _buildApssbTab(),
              _buildAppscTab(),
              _buildSubjectMatrixTab(),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 1: EXECUTIVE OVERVIEW (APSSB vs APPSC)
  // ===========================================================================
  Widget _buildExecutiveOverviewTab() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.m),
      children: [
        // Negative Marking Crucial Banner
        Container(
          padding: const EdgeInsets.all(AppSpacing.m),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.info_outline_rounded, color: Colors.amber, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'CRITICAL MARKING POLICY DIFFERENCE',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('APSSB Exams',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          SizedBox(height: 4),
                          Text('• ZERO Negative Marking',
                              style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                          Text('• 2 Marks / Correct MCQ\n• 33% Aggregate Pass',
                              style: TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('APPSC Prelims',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          SizedBox(height: 4),
                          Text('• 1/3rd (0.33) Deduction',
                              style: TextStyle(color: Color(0xFFFCA5A5), fontWeight: FontWeight.bold, fontSize: 12)),
                          Text('• Negative for wrong MCQs\n• Descriptive in Mains',
                              style: TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.m),

        // Official Portal Shortcuts
        Row(
          children: [
            Expanded(
              child: _buildPortalCard(
                title: 'APSSB Official Portal',
                url: 'https://apssb.nic.in',
                subtitle: 'Group C Recruitment Board',
                color: const Color(0xFF0284C7),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPortalCard(
                title: 'APPSC Official Portal',
                url: 'https://appsc.gov.in',
                subtitle: 'State Public Service Commission',
                color: const Color(0xFF7C3AED),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.m),

        const Text(
          'Comparative Executive Parameters',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),

        ...OfficialSyllabusData.executiveOverview.map((item) {
          if (_searchQuery.isNotEmpty &&
              !item.parameter.toLowerCase().contains(_searchQuery) &&
              !item.apssb.toLowerCase().contains(_searchQuery) &&
              !item.appsc.toLowerCase().contains(_searchQuery)) {
            return const SizedBox.shrink();
          }
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.parameter,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.primary,
                        ),
                      ),
                      if (item.note != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Text(
                            item.note!,
                            style: TextStyle(fontSize: 10, color: Colors.amber.shade900, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const Divider(height: 16),
                  _buildComparisonRow('APSSB', item.apssb, const Color(0xFF0284C7)),
                  const SizedBox(height: 8),
                  _buildComparisonRow('APPSC', item.appsc, const Color(0xFF7C3AED)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPortalCard({
    required String title,
    required String url,
    required String subtitle,
    required Color color,
  }) {
    return InkWell(
      onTap: () => _launchPortal(url),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.language_rounded, color: color, size: 20),
                Icon(Icons.open_in_new_rounded, color: color, size: 14),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonRow(String tag, String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 60,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            tag,
            textAlign: TextAlign.center,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary, height: 1.3),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // TAB 2: APSSB EXAMS
  // ===========================================================================
  Widget _buildApssbTab() {
    final filters = ['All', 'CGL', 'CHSL', 'CSL / MTS', 'Uniformed Cadre', 'Technical / Trade'];

    final filteredList = OfficialSyllabusData.apssbSections.where((item) {
      if (_apssbFilter != 'All' && !item.examName.contains(_apssbFilter.replaceAll(' / MTS', ''))) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery;
        return item.examName.toLowerCase().contains(q) ||
            item.subject.toLowerCase().contains(q) ||
            item.targetCadres.toLowerCase().contains(q) ||
            item.syllabusBreakdown.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: 8),
          child: Row(
            children: filters.map((f) {
              final selected = _apssbFilter == f;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(f),
                  selected: selected,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textPrimary,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  onSelected: (val) => setState(() => _apssbFilter = f),
                ),
              );
            }).toList(),
          ),
        ),

        // List
        Expanded(
          child: filteredList.isEmpty
              ? _buildEmptySearch()
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  itemCount: filteredList.length,
                  itemBuilder: (context, idx) {
                    final item = filteredList[idx];
                    return _buildApssbCard(item);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildApssbCard(ApssbSyllabusSection item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Exam Badge & Stage (Flexible wrapping)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.examName,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: item.isSkillTest ? Colors.purple.shade50 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.stage,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: item.isSkillTest ? Colors.purple.shade700 : Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Subject / Topic Title
            Text(
              item.subject,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),

            // Target Cadres
            Text(
              'Posts: ${item.targetCadres}',
              style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),

            // Metrics row
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (item.questions != null)
                  _buildMetricBadge(Icons.quiz_outlined, '${item.questions} Questions'),
                if (item.marks != null)
                  _buildMetricBadge(Icons.military_tech_outlined, '${item.marks} Marks'),
                _buildMetricBadge(Icons.timer_outlined, item.duration),
                _buildMetricBadge(Icons.check_circle_outline, item.markingStandard, isSuccess: true),
              ],
            ),
            const SizedBox(height: 10),

            // Detailed Topics Breakdown
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'OFFICIAL SYLLABUS & TOPIC BREAKDOWN',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.syllabusBreakdown,
                    style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 3: APPSC EXAMS
  // ===========================================================================
  Widget _buildAppscTab() {
    final filters = [
      'All',
      'Civil Services',
      'AESE (AE)',
      'Junior Engineer',
      'Teacher (PGT/TGT)',
      'Agriculture / Horti',
      'Medical Officer'
    ];

    final filteredList = OfficialSyllabusData.appscSections.where((item) {
      if (_appscFilter != 'All') {
        if (_appscFilter == 'Civil Services' && !item.examName.contains('APPSCCE')) return false;
        if (_appscFilter == 'AESE (AE)' && !item.examName.contains('AESE')) return false;
        if (_appscFilter == 'Junior Engineer' && !item.examName.contains('Junior Engineer')) return false;
        if (_appscFilter == 'Teacher (PGT/TGT)' && !item.examName.contains('Teacher')) return false;
        if (_appscFilter == 'Agriculture / Horti' && !item.examName.contains('Agriculture')) return false;
        if (_appscFilter == 'Medical Officer' && !item.examName.contains('Medical')) return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery;
        return item.examName.toLowerCase().contains(q) ||
            item.paperName.toLowerCase().contains(q) ||
            item.primaryCurriculum.toLowerCase().contains(q) ||
            item.arunachalComponent.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: 8),
          child: Row(
            children: filters.map((f) {
              final selected = _appscFilter == f;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(f),
                  selected: selected,
                  selectedColor: const Color(0xFF7C3AED),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textPrimary,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  onSelected: (val) => setState(() => _appscFilter = f),
                ),
              );
            }).toList(),
          ),
        ),

        // List
        Expanded(
          child: filteredList.isEmpty
              ? _buildEmptySearch()
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  itemCount: filteredList.length,
                  itemBuilder: (context, idx) {
                    final item = filteredList[idx];
                    return _buildAppscCard(item);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAppscCard(AppscSyllabusSection item) {
    final hasArunachal = item.arunachalComponent.isNotEmpty && item.arunachalComponent != 'None (Universal Aptitude standards).';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Badge (Flexible wrapping)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.examName,
                    style: const TextStyle(
                      color: Color(0xFF7C3AED),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: item.isInterview ? Colors.orange.shade50 : Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.stage,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: item.isInterview ? Colors.orange.shade800 : Colors.purple.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Paper Name
            Text(
              item.paperName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),

            // Posts
            Text(
              'Posts: ${item.targetCadres}',
              style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),

            // Metrics row
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildMetricBadge(Icons.military_tech_outlined, '${item.marks} Marks'),
                _buildMetricBadge(Icons.timer_outlined, item.duration),
                _buildMetricBadge(
                  Icons.warning_amber_rounded,
                  item.negativeMarking,
                  isWarning: item.negativeMarking.contains('Negative'),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Primary Curriculum
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PRIMARY CURRICULUM & SUB-TOPICS',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.primaryCurriculum,
                    style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
            ),

            // Arunachal Pradesh Specific Component Highlight
            if (hasArunachal) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.terrain_rounded, size: 16, color: Color(0xFFB45309)),
                        SizedBox(width: 6),
                        Text(
                          'ARUNACHAL PRADESH SPECIFIC FOCUS (30-35% WEIGHTAGE)',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.arunachalComponent,
                      style: const TextStyle(fontSize: 11.5, height: 1.35, color: Color(0xFF78350F)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 8),
            // Impact
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.stars_rounded, size: 14, color: AppColors.accent),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Selection Impact: ${item.weightageImpact}',
                    style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 4: SUBJECT-WISE DEEP-DIVE MATRIX
  // ===========================================================================
  Widget _buildSubjectMatrixTab() {
    final categories = [
      'All',
      'Arunachal Pradesh General Studies',
      'General English',
      'Elementary / Quantitative Maths',
      'General Intelligence & Reasoning',
      'General Studies'
    ];

    final filteredList = OfficialSyllabusData.subjectMatrix.where((item) {
      if (_subjectFilter != 'All' && item.category != _subjectFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery;
        return item.category.toLowerCase().contains(q) ||
            item.subTopic.toLowerCase().contains(q) ||
            item.coreCurriculum.toLowerCase().contains(q) ||
            item.highYieldFocus.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Category chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: 8),
          child: Row(
            children: categories.map((c) {
              final selected = _subjectFilter == c;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(c.replaceAll('Arunachal Pradesh ', 'AP ')),
                  selected: selected,
                  selectedColor: const Color(0xFF0F766E),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textPrimary,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  onSelected: (val) => setState(() => _subjectFilter = c),
                ),
              );
            }).toList(),
          ),
        ),

        // List
        Expanded(
          child: filteredList.isEmpty
              ? _buildEmptySearch()
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  itemCount: filteredList.length,
                  itemBuilder: (context, idx) {
                    final item = filteredList[idx];
                    return _buildSubjectMatrixCard(item);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSubjectMatrixCard(SubjectMatrixItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category & Weightage (Flexible wrapping)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.category,
                    style: const TextStyle(
                      color: Color(0xFF0F766E),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.typicalWeightage,
                    style: TextStyle(fontSize: 10, color: Colors.blueGrey.shade800, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Sub-Topic Title
            Text(
              item.subTopic,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),

            // Core Curriculum
            Text(
              item.coreCurriculum,
              style: const TextStyle(fontSize: 12, height: 1.35, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 10),

            // Scope Comparison Grid
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildScopeRow('APSSB Scope (MCQ)', item.apssbScope, const Color(0xFF0284C7)),
                  const Divider(height: 12),
                  _buildScopeRow('APPSC Scope (Analytical)', item.appscScope, const Color(0xFF7C3AED)),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // High Yield Preparation Focus
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.bolt_rounded, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: 'High-Yield Focus: ',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                        TextSpan(
                          text: item.highYieldFocus,
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScopeRow(String title, String content, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 115),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            title,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            content,
            style: const TextStyle(fontSize: 11.5, height: 1.3, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricBadge(IconData icon, String label, {bool isSuccess = false, bool isWarning = false}) {
    Color bg = const Color(0xFFF1F5F9);
    Color text = const Color(0xFF475569);
    if (isSuccess) {
      bg = const Color(0xFFDCFCE7);
      text = const Color(0xFF166534);
    } else if (isWarning) {
      bg = const Color(0xFFFEE2E2);
      text = const Color(0xFF991B1B);
    }
    final screenW = MediaQuery.of(context).size.width;
    return Container(
      constraints: BoxConstraints(maxWidth: screenW > 420 ? 360 : (screenW - 72).clamp(180.0, 360.0)),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 13, color: text),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: text),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearch() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text(
              'No syllabus items found for "$_searchQuery"',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try searching with broader terms like "Maths", "Tribes", "Negative", or "Civil"',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
