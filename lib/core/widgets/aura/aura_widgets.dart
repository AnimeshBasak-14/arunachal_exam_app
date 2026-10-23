import 'package:flutter/material.dart';
import '../../theme/aura.dart';

/// Soft page backdrop: ivory (or green-black) with a faint tint in one corner
/// so translucent panels read as frosted glass.
class AuraBackground extends StatelessWidget {
  final Widget child;
  const AuraBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: a.bg,
        gradient: RadialGradient(
          center: const Alignment(-1.1, -1.2),
          radius: 1.5,
          colors: [a.bgTint, a.bg],
        ),
      ),
      child: child,
    );
  }
}

/// Frosted panel with an ultra-thin border.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool elevated;
  final Color? borderColor;
  final double radius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.elevated = false,
    this.borderColor,
    this.radius = AuraSpace.radius,
  });

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final shape = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: elevated ? a.surfaceSolid : a.surface,
        borderRadius: shape,
        border: Border.all(color: borderColor ?? a.hairline, width: 0.8),
        boxShadow: elevated ? a.elevatedShadow : a.shadow,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: shape,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class Eyebrow extends StatelessWidget {
  final String text;
  final Color? color;
  const Eyebrow(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: AuraType.eyebrow(color ?? context.aura.inkFaint),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const SectionHeader(this.title, {super.key, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: Text(title, style: AuraType.serif(21, a.ink))),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

/// "2024 · Shift 1 · 100 Qs" in a quiet weight. Empty items are skipped so
/// missing data is simply not shown.
class MetaLine extends StatelessWidget {
  final List<String?> items;
  final Color? color;
  const MetaLine(this.items, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final parts = items.whereType<String>().where((s) => s.isNotEmpty);
    return Text(
      parts.join('  ·  '),
      style: AuraType.sans(12.5, color ?? context.aura.inkMuted),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Text tabs with a thin accent underline.
class SegmentedTabs extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  const SegmentedTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < labels.length; i++)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onChanged(i),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(2, 8, 18, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: AuraType.sans(
                        14,
                        i == selected ? a.ink : a.inkFaint,
                        weight: i == selected ? FontWeight.w600 : FontWeight.w500,
                      ),
                      child: Text(labels[i]),
                    ),
                    const SizedBox(height: 6),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      height: 1.6,
                      width: i == selected ? 22 : 0,
                      color: a.accent,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Small rounded label, e.g. "Incomplete" or a subject name.
class Tag extends StatelessWidget {
  final String text;
  final Color? color;
  const Tag(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.aura.inkMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: c.withValues(alpha: 0.35), width: 0.8),
      ),
      child: Text(
        text,
        style: AuraType.sans(11.5, c, weight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class AuraEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AuraEmpty({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 34, color: a.inkFaint),
          const SizedBox(height: 16),
          Text(title,
              textAlign: TextAlign.center, style: AuraType.serif(20, a.ink)),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: AuraType.sans(14, a.inkMuted, height: 1.5)),
          if (actionLabel != null) ...[
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(minimumSize: const Size(140, 46)),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

/// Quiet placeholder block shown while content loads.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  const SkeletonBox({super.key, this.width, required this.height, this.radius = 12});

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: context.aura.hairline.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

/// Rows inside one glass panel, separated by hairlines.
class GlassList extends StatelessWidget {
  final List<Widget> children;
  final double indent;
  const GlassList({super.key, required this.children, this.indent = 56});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(indent: indent, color: a.hairline),
            children[i],
          ],
        ],
      ),
    );
  }
}

class GlassListRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const GlassListRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 21, color: a.inkMuted),
            const SizedBox(width: 17),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AuraType.sans(15, a.ink, weight: FontWeight.w500)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: AuraType.sans(12.5, a.inkFaint)),
                  ],
                ],
              ),
            ),
            trailing ??
                Icon(Icons.chevron_right_rounded, size: 20, color: a.inkFaint),
          ],
        ),
      ),
    );
  }
}
