import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../viewmodel/exam_viewmodel.dart';

class ApssbCategoriesScreen extends ConsumerWidget {
  const ApssbCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allExams = ref.watch(examViewModelProvider);
    final apssbExams = allExams.where((exam) => exam.categoryId == 'apssb').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.fromLTRB(AppSpacing.m, AppSpacing.xl, AppSpacing.m, AppSpacing.l),
            decoration: const BoxDecoration(
              gradient: AppColors.apssbGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(AppSpacing.radiusXL),
                bottomRight: Radius.circular(AppSpacing.radiusXL),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textWhite),
                      onPressed: () => context.pop(),
                    ),
                    const Text(
                      'APSSB EXAMINATIONS',
                      style: TextStyle(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.only(left: AppSpacing.xl, top: AppSpacing.xs),
                  child: Text(
                    'Arunachal Pradesh Staff Selection Board',
                    style: TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.m),
          
          // Exams List View
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
              itemCount: apssbExams.length,
              itemBuilder: (context, index) {
                final exam = apssbExams[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.s),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                    border: Border.all(color: AppColors.divider, width: 1),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Icon(exam.icon, color: AppColors.primary, size: 22),
                    ),
                    title: Text(
                      exam.code,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      exam.name,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            exam.isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                            color: exam.isBookmarked ? AppColors.primary : AppColors.textHint,
                          ),
                          onPressed: () {
                            ref.read(examViewModelProvider.notifier).toggleBookmark(exam.id);
                          },
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textHint),
                      ],
                    ),
                    onTap: () {
                      context.push('/exam-detail/${exam.id}');
                    },
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
