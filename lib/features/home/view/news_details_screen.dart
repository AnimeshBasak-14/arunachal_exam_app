import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

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
      if (kIsWeb) {
        launched = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
          webOnlyWindowName: '_blank',
        );
      } else {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[Browser] primary launch error: $e');
    }

    if (!launched) {
      try {
        launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (e) {
        debugPrint('[Browser] fallback launch error: $e');
      }
    }

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open link: $trimmed'),
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
    final title = article['title'] as String? ?? 'Arunachal Exam Updates';
    final source = article['source'] as String? ?? 'APSSB Official Portal';
    final date = article['date'] as String? ?? 'Recent';
    final description = article['description'] as String? ??
        article['summary'] as String? ??
        'No detailed description available.';
    final keyPoints = (article['keyPoints'] as List?)?.cast<String>() ??
        <String>[
          'High importance for upcoming APSSB & APPSC recruitment examinations.',
          'Focus on Arunachal Pradesh General Knowledge and current policies.',
        ];

    final rawPdf = article['pdfUrl'] as String?;
    final rawLink = article['link'] as String?;
    final officialNotificationUrl = (rawPdf != null && rawPdf.startsWith('http'))
        ? rawPdf
        : ((rawLink != null && rawLink.startsWith('http'))
            ? rawLink
            : 'https://apssb.nic.in');

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          isDesktop ? 'Arunachal Exam Portal • News & Circulars' : 'News Details',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Article',
            onPressed: () {
              final id = article['id']?.toString() ?? '';
              final shareUrl = id.isNotEmpty
                  ? 'https://animeshbasak-14.github.io/arunachal_exam_app/#/news-details?id=$id'
                  : 'https://animeshbasak-14.github.io/arunachal_exam_app/#/news-details';
              Clipboard.setData(ClipboardData(text: '$title\n\nRead more at: $shareUrl'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Article link copied to clipboard!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? AppSpacing.xl : AppSpacing.m,
                vertical: AppSpacing.l,
              ),
              child: Container(
                decoration: isDesktop
                    ? BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      )
                    : null,
                padding: isDesktop
                    ? const EdgeInsets.all(32)
                    : const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge & Meta Row
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                            ),
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time_rounded,
                                  size: 13, color: AppColors.textHint),
                              const SizedBox(width: 4),
                              Text(
                                date,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          '• 2 min read',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.m),

                    // Title
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isDesktop ? 26 : 21,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.l),

                    // Key Exam Takeaways Callout Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF0FDF4), Color(0xFFF8FAFC)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: const Border(
                          left: BorderSide(color: AppColors.primary, width: 4),
                          top: BorderSide(color: Color(0xFFE2E8F0)),
                          right: BorderSide(color: Color(0xFFE2E8F0)),
                          bottom: BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.lightbulb_rounded,
                                  color: AppColors.primary, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Exam & Syllabus Significance',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...keyPoints.map((point) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 2, right: 8),
                                      child: Icon(Icons.check_circle_rounded,
                                          size: 14, color: AppColors.primary),
                                    ),
                                    Expanded(
                                      child: Text(
                                        point,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          height: 1.45,
                                          color: Color(0xFF334155),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.l),

                    // Article Description
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: isDesktop ? 16 : 15,
                        height: 1.75,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    const Divider(color: Color(0xFFE2E8F0)),
                    const SizedBox(height: AppSpacing.l),

                    // Action Buttons Bar
                    if (isDesktop)
                      Row(
                        children: [
                          Expanded(
                            child: _buildAiButton(context, title, description),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildNotificationButton(
                              context,
                              source,
                              officialNotificationUrl,
                            ),
                          ),
                          if (!kIsWeb) ...[
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildWebPortalButton(context),
                            ),
                          ],
                        ],
                      )
                    else
                      Column(
                        children: [
                          _buildAiButton(context, title, description),
                          const SizedBox(height: 12),
                          _buildNotificationButton(
                            context,
                            source,
                            officialNotificationUrl,
                          ),
                          if (!kIsWeb) ...[
                            const SizedBox(height: 12),
                            _buildWebPortalButton(context),
                          ],
                        ],
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAiButton(BuildContext context, String title, String description) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.auto_awesome_rounded, size: 20),
        label: const Text(
          'Ask AI Tutor About This',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          context.push(
            '/chatbot',
            extra: '$title\n\n$description',
          );
        },
      ),
    );
  }

  Widget _buildNotificationButton(
      BuildContext context, String source, String officialUrl) {
    final isPdf = officialUrl.toLowerCase().endsWith('.pdf');
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: OutlinedButton.icon(
        icon: Icon(
          isPdf ? Icons.picture_as_pdf_rounded : Icons.open_in_new_rounded,
          color: const Color(0xFF0F766E),
          size: 20,
        ),
        label: Text(
          isPdf
              ? 'Download Official PDF ($source)'
              : 'View Official Notification ($source)',
          style: const TextStyle(
            color: Color(0xFF0F766E),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFFF0FDFA),
          side: const BorderSide(color: Color(0xFF99F6E4), width: 1.5),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening official notification from $source...'),
              duration: const Duration(seconds: 2),
            ),
          );
          _openBrowserUrl(context, officialUrl);
        },
      ),
    );
  }

  Widget _buildWebPortalButton(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.language_rounded, size: 18),
        label: const Text(
          'View Article on Web Portal',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF334155),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          final id = article['id']?.toString() ?? '';
          final webUrl = id.isNotEmpty
              ? 'https://animeshbasak-14.github.io/arunachal_exam_app/#/news-details?id=$id'
              : 'https://animeshbasak-14.github.io/arunachal_exam_app/#/news-details';
          _openBrowserUrl(context, webUrl);
        },
      ),
    );
  }
}
