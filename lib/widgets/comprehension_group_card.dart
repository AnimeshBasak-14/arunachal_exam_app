import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/utils/math_utils.dart';

/// Reusable Comprehension Group Card that binds a shared passage / directions
/// and its nested sequence of associated questions into a single cohesive card.
///
/// Features:
/// - Sticky / Collapsible passage header
/// - [InteractiveViewer] around chart/diagram images for seamless pinch-to-zoom
/// - Nested question stack displaying Q85, Q86, Q87 sequentially
/// - Two-pane side-by-side layout on tablets/web (width >= 720px)
class ComprehensionGroupCard extends StatefulWidget {
  final String? title;
  final String? passage;
  final String? passageImage;
  final int startIndex;
  final int endIndex;
  final List<Widget> children;

  const ComprehensionGroupCard({
    super.key,
    this.title,
    this.passage,
    this.passageImage,
    required this.startIndex,
    required this.endIndex,
    required this.children,
  });

  @override
  State<ComprehensionGroupCard> createState() => _ComprehensionGroupCardState();
}

class _ComprehensionGroupCardState extends State<ComprehensionGroupCard> {
  bool _isPassageCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final hasPassage =
        (widget.passage != null && widget.passage!.trim().isNotEmpty) ||
            (widget.passageImage != null && widget.passageImage!.trim().isNotEmpty);

    final rangeText = widget.startIndex == widget.endIndex
        ? 'Q${widget.startIndex}'
        : 'Q${widget.startIndex} – Q${widget.endIndex}';

    return Card(
      key: widget.key,
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusL),
        side: const BorderSide(
          color: Color(0xFF1565C0),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen = constraints.maxWidth >= 720;

            if (isWideScreen && hasPassage) {
              // ─── Tablet / Desktop Two-Pane Side-by-Side ─────────────────────
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildBanner(rangeText),
                  const SizedBox(height: AppSpacing.m),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Pane: Pinned Passage with InteractiveViewer
                        Expanded(
                          flex: 5,
                          child: _buildPassageContainer(
                            rangeText: rangeText,
                            collapsible: false,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.m),
                        const VerticalDivider(
                          color: AppColors.divider,
                          thickness: 1.2,
                        ),
                        const SizedBox(width: AppSpacing.m),
                        // Right Pane: Nested Question Stack
                        Expanded(
                          flex: 7,
                          child: _buildQuestionsList(),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            // ─── Standard Mobile Layout: Vertical Stack ──────────────────────
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBanner(rangeText),
                if (hasPassage) ...[
                  const SizedBox(height: AppSpacing.m),
                  _buildPassageContainer(
                    rangeText: rangeText,
                    collapsible: true,
                  ),
                ],
                const SizedBox(height: AppSpacing.m),
                _buildQuestionsList(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBanner(String rangeText) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF1565C0).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.layers_rounded,
            size: 16,
            color: Color(0xFF1565C0),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.title ?? '📚 Comprehension / Group Questions ($rangeText)',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1565C0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassageContainer({
    required String rangeText,
    required bool collapsible,
  }) {
    final passageText = widget.passage?.trim() ?? '';
    final isLongPassage = passageText.length > 250;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.menu_book_rounded,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Directions ($rangeText)',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              if (collapsible && isLongPassage)
                InkWell(
                  onTap: () {
                    setState(() {
                      _isPassageCollapsed = !_isPassageCollapsed;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isPassageCollapsed ? 'Expand' : 'Collapse',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Icon(
                          _isPassageCollapsed
                              ? Icons.keyboard_arrow_down_rounded
                              : Icons.keyboard_arrow_up_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (!_isPassageCollapsed && passageText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              MathUtils.formatDirectionRange(
                passageText,
                widget.startIndex,
                widget.endIndex,
              ),
              style: const TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ] else if (_isPassageCollapsed && passageText.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              passageText.length > 100
                  ? '${passageText.substring(0, 100)}...'
                  : passageText,
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.textHint,
              ),
            ),
          ],
          // Chart / diagram image with pinch-to-zoom InteractiveViewer
          if (widget.passageImage != null &&
              widget.passageImage!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 280),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.network(
                      widget.passageImage!,
                      fit: BoxFit.contain,
                      loadingBuilder: (ctx, child, progress) => progress == null
                          ? child
                          : const SizedBox(
                              height: 80,
                              child: Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                      errorBuilder: (_, __, ___) => Container(
                        height: 48,
                        padding: const EdgeInsets.all(8),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image_outlined,
                                color: AppColors.textHint, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Diagram preview unavailable',
                              style: TextStyle(
                                  color: AppColors.textHint, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.pinch_rounded, size: 13, color: AppColors.textHint),
                SizedBox(width: 4),
                Text(
                  'Pinch to zoom figure',
                  style: TextStyle(fontSize: 10, color: AppColors.textHint),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestionsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < widget.children.length; i++) ...[
          if (i > 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.s),
              child: Divider(
                color: Color(0xFFE2E8F0),
                thickness: 1.0,
              ),
            ),
          widget.children[i],
        ],
      ],
    );
  }
}
