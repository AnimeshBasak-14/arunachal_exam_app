import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../viewmodel/exam_viewmodel.dart';
import '../../../models/exam.dart';
import '../../../data/exam_spec_data.dart';

class ExamDetailScreen extends ConsumerStatefulWidget {
  final String examId;
  const ExamDetailScreen({super.key, required this.examId});

  @override
  ConsumerState<ExamDetailScreen> createState() => _ExamDetailScreenState();
}

class _ExamDetailScreenState extends ConsumerState<ExamDetailScreen> {
  int? _expandedIndex;

  List<Widget> _buildModuleContent(
      BuildContext context, Exam exam, ExamSpec spec, ModuleItem module) {
    if (module.title == 'Syllabus') {
      return spec.syllabusDetails.map((detail) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 6, right: 8),
                child: Icon(Icons.circle, size: 6, color: AppColors.primary),
              ),
              Expanded(
                child: Text(
                  detail,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList();
    } else if (module.title == 'PYQ') {
      return spec.pyqPapers.map((p) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.s),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: ListTile(
            dense: true,
            leading: const Icon(Icons.article_rounded,
                color: AppColors.primary, size: 20),
            title: Text(
              p.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            subtitle: const Text('Tap to solve full paper with solutions',
                style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded,
                size: 12, color: AppColors.textHint),
            onTap: () {
              context.push('/pyqs/${p.code}/${p.year}');
            },
          ),
        );
      }).toList();
    } else if (module.title == 'QUIZ') {
      return spec.quizzes.map((q) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.s),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.divider),
          ),
          child: ListTile(
            dense: true,
            leading: const Icon(Icons.quiz_rounded,
                color: AppColors.primary, size: 20),
            title: Text(
              q.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            subtitle: Text(q.desc,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
            trailing:
                const Icon(Icons.play_arrow_rounded, color: AppColors.primary),
            onTap: () {
              context.push('/mock-test/${exam.code}/${q.type}');
            },
          ),
        );
      }).toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final exams = ref.watch(examViewModelProvider);
    final exam = exams.firstWhere((e) => e.id == widget.examId,
        orElse: () => exams.first);
    final spec = ExamSpecData.getSpec(exam.id, exam.code);

    final isAppsc = exam.categoryId == 'appsc';
    final themeGradient =
        isAppsc ? AppColors.appscGradient : AppColors.apssbGradient;

    final modules = [
      ModuleItem(
        title: 'Syllabus',
        icon: Icons.menu_book_rounded,
      ),
      ModuleItem(
        title: 'PYQ',
        icon: Icons.edit_note_rounded,
      ),
      ModuleItem(
        title: 'QUIZ',
        icon: Icons.assignment_outlined,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.s, AppSpacing.xl, AppSpacing.m, AppSpacing.l),
            decoration: BoxDecoration(
              gradient: themeGradient,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(AppSpacing.radiusXL),
                bottomRight: Radius.circular(AppSpacing.radiusXL),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: AppColors.textWhite),
                          onPressed: () => context.pop(),
                        ),
                        Text(
                          exam.code,
                          style: const TextStyle(
                            color: AppColors.textWhite,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        exam.isBookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: AppColors.textWhite,
                      ),
                      onPressed: () {
                        ref
                            .read(examViewModelProvider.notifier)
                            .toggleBookmark(exam.id);
                      },
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(
                      left: AppSpacing.xl, top: AppSpacing.xs),
                  child: Text(
                    exam.name,
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.m),

          // Modules List (Syllabus, PYQ, Quiz)
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
              itemCount: modules.length,
              itemBuilder: (context, index) {
                final module = modules[index];
                final isExpanded = _expandedIndex == index;

                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.s),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                    border: Border.all(color: AppColors.divider, width: 1),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryLight,
                          child: Icon(module.icon,
                              color: AppColors.primary, size: 22),
                        ),
                        title: Text(
                          module.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            fontSize: 16,
                          ),
                        ),
                        trailing: Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textHint,
                        ),
                        onTap: () {
                          setState(() {
                            _expandedIndex = isExpanded ? null : index;
                          });
                        },
                      ),
                      if (isExpanded) ...[
                        const Divider(height: 1, color: AppColors.divider),
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.m),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: _buildModuleContent(
                                context, exam, spec, module),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ModuleItem {
  final String title;
  final IconData icon;

  ModuleItem({
    required this.title,
    required this.icon,
  });
}
