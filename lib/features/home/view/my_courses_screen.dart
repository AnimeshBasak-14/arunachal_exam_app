import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../viewmodel/exam_viewmodel.dart';

class MyCoursesScreen extends ConsumerWidget {
  const MyCoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarked = ref.watch(bookmarkedExamsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('MY COURSE / BOOKMARKS'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.s),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.s),
                child: Text(
                  'Access your pinned APPSC & APSSB examinations quickly.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              if (bookmarked.isEmpty)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bookmark_outline_rounded, size: 72, color: AppColors.textHint.withValues(alpha: 0.5)),
                      const SizedBox(height: AppSpacing.m),
                      const Text(
                        'No bookmarked exams yet',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 16),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      const Text(
                        'Browse exams in categories and tap the bookmark to pin them.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textHint, fontSize: 13),
                      ),
                    ],
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: bookmarked.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final exam = bookmarked[index];
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
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          subtitle: Text(
                            exam.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.bookmark_rounded, color: AppColors.primary),
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
        ),
      ),
    );
  }
}
