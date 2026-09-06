import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/primary_button.dart';

class NewsDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> article;

  const NewsDetailsScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final title = article['title'] as String? ?? 'News';
    final source = article['source'] as String? ?? 'Arunachal Times';
    final date = article['date'] as String? ?? 'Today';
    final description = article['description'] as String? ?? 'No details available.';
    final keyPoints = article['keyPoints'] as List<String>? ?? ['Important for APSSB exams.'];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('News Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    source,
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  date,
                  style: const TextStyle(color: AppColors.textHint, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            const Text(
              'Key Exam Points:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            ...keyPoints.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(color: AppColors.primary, fontSize: 16)),
                      Expanded(child: Text(p, style: const TextStyle(height: 1.4))),
                    ],
                  ),
                )),
            const SizedBox(height: AppSpacing.l),
            Text(
              description,
              style: const TextStyle(
                fontSize: 15,
                height: 1.6,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              text: 'Ask AI Tutor About This',
              icon: Icons.chat_bubble_outline_rounded,
              onPressed: () {
                context.push(
                  '/chatbot',
                  extra: '$title\n\n$description',
                );
              },
            ),
            const SizedBox(height: AppSpacing.m),
            OutlinedButton.icon(
              icon: const Icon(Icons.picture_as_pdf_rounded),
              label: const Text('View Official Notification / Advert PDF'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () async {
                final linkStr = article['link'] as String?;
                final target = (linkStr != null && linkStr.startsWith('http'))
                    ? linkStr
                    : 'https://apssb.nic.in';
                final url = Uri.parse(target);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
