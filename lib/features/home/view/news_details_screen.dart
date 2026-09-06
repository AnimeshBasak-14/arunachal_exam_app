import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/primary_button.dart';

class NewsDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> article;

  const NewsDetailsScreen({super.key, required this.article});

  static Future<void> _openBrowserUrl(BuildContext context, String urlString) async {
    final trimmed = urlString.trim();
    if (trimmed.isEmpty) return;
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return;

    bool launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[Browser] externalApplication error: $e');
    }

    if (!launched) {
      try {
        launched = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      } catch (e) {
        debugPrint('[Browser] inAppBrowserView error: $e');
      }
    }

    if (!launched) {
      try {
        launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (e) {
        debugPrint('[Browser] platformDefault error: $e');
      }
    }

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open browser for: $trimmed'),
          action: SnackBarAction(
            label: 'Copy Link',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: trimmed));
            },
          ),
        ),
      );
    }
  }

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
      body: SafeArea(
        top: false,
        bottom: true,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: AppSpacing.m,
                right: AppSpacing.m,
                top: AppSpacing.m,
                bottom: MediaQuery.of(context).padding.bottom + 48,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      source,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 14, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(
                        date,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
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
                            const Text('• ',
                                style: TextStyle(
                                    color: AppColors.primary, fontSize: 16)),
                            Expanded(
                                child: Text(p,
                                    style: const TextStyle(height: 1.4))),
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
                  ElevatedButton.icon(
                    icon: const Icon(Icons.language_rounded),
                    label: const Text('View Article on Web Portal'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      _openBrowserUrl(
                        context,
                        'https://animeshbasak-14.github.io/arunachal_exam_app/',
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.s),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                    label: Text('Download / View Official Notification ($source)'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      final linkStr = article['link'] as String?;
                      final target = (linkStr != null && linkStr.startsWith('http'))
                          ? linkStr
                          : 'https://apssb.nic.in';
                      _openBrowserUrl(context, target);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
