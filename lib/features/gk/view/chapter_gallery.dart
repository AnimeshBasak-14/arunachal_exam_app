import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/aura.dart';
import '../../../core/utils/links.dart';
import '../../../core/widgets/aura/aura_widgets.dart';
import '../../../data/chapter_photos.dart';

/// Pictures for a GK chapter: a swipeable row, tap to zoom, and the author
/// and licence under each photo. Shows nothing if the chapter has none.
class ChapterGallery extends StatelessWidget {
  final String chapterId;
  const ChapterGallery({super.key, required this.chapterId});

  @override
  Widget build(BuildContext context) {
    final photos = chapterPhotos[chapterId];
    if (photos == null || photos.isEmpty) return const SizedBox.shrink();
    final a = context.aura;
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Expanded(child: SectionHeader('Pictures')),
          Text('${photos.length}', style: AuraType.digits(13, a.inkFaint)),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          // Image 180 + caption (2 lines) + credit (2 lines), scaled with text.
          height: 180 + 96 * scale,
          child: ListView.separated(
            // Bleeds to the screen edge so it is clearly swipeable.
            clipBehavior: Clip.none,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: photos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _PhotoCard(
              photo: photos[i],
              onOpen: () => _openViewer(context, photos, i),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Photos from Wikimedia Commons. Tap a picture to enlarge it; the credit is under each one.',
          style: AuraType.sans(12, a.inkFaint, height: 1.45),
        ),
      ],
    );
  }

  void _openViewer(BuildContext context, List<ChapterPhoto> photos, int start) {
    Navigator.of(context).push(PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (_, __, ___) => _Viewer(photos: photos, start: start),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    ));
  }
}

Map<String, String>? get _imageHeaders => kIsWeb
    ? null
    : const {
        'User-Agent': 'Dawnlit/1.0 (study app by ZAP; contact via Play listing)'
      };

class _PhotoCard extends StatelessWidget {
  final ChapterPhoto photo;
  final VoidCallback onOpen;
  const _PhotoCard({required this.photo, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return SizedBox(
      width: 250,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            label: 'Enlarge picture: ${photo.caption}',
            excludeSemantics: true,
            child: GestureDetector(
              onTap: onOpen,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AuraSpace.radiusS),
                child: SizedBox(
                  width: 250,
                  height: 180,
                  child: Image.network(
                    photo.url,
                    headers: _imageHeaders,
                    fit: BoxFit.cover,
                    cacheWidth: 600,
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : const SkeletonBox(height: 180, radius: 0),
                    errorBuilder: (_, __, ___) => ColoredBox(
                      color: a.surface,
                      child: Center(
                        child: Icon(CupertinoIcons.photo,
                            color: a.inkFaint, size: 28),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(photo.caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AuraType.sans(13.5, a.ink,
                  weight: FontWeight.w500, height: 1.3)),
          const SizedBox(height: 2),
          InkWell(
            onTap: () => openLink(context, photo.page),
            child: Text('Photo: ${photo.author} · ${photo.license}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AuraType.sans(11, a.inkFaint, height: 1.3)),
          ),
        ],
      ),
    );
  }
}

class _Viewer extends StatefulWidget {
  final List<ChapterPhoto> photos;
  final int start;
  const _Viewer({required this.photos, required this.start});

  @override
  State<_Viewer> createState() => _ViewerState();
}

class _ViewerState extends State<_Viewer> {
  late final _controller = PageController(initialPage: widget.start);
  late int _index = widget.start;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.photos[_index];
    const onDark = Color(0xFFF2F2F2);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        PageView.builder(
          controller: _controller,
          itemCount: widget.photos.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (_, i) => InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Center(
              child: Image.network(
                widget.photos[i].url,
                headers: _imageHeaders,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : const Center(
                        child: CircularProgressIndicator(color: onDark)),
                errorBuilder: (_, __, ___) =>
                    const Icon(CupertinoIcons.photo, color: onDark, size: 40),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              tooltip: 'Close',
              icon: const Icon(CupertinoIcons.xmark, color: onDark),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
                20, 28, 20, 20 + MediaQuery.paddingOf(context).bottom),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xCC000000)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.caption,
                    style: AuraType.serif(19, onDark, height: 1.25)),
                const SizedBox(height: 6),
                Text('Photo: ${p.author} · ${p.license}',
                    style: AuraType.sans(12.5, onDark.withValues(alpha: 0.75),
                        height: 1.4)),
                const SizedBox(height: 4),
                TextButton(
                  style: TextButton.styleFrom(
                      foregroundColor: onDark,
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft),
                  onPressed: () => openLink(context, p.page),
                  child: const Text('Full credit on Wikimedia Commons'),
                ),
                Text('${_index + 1} of ${widget.photos.length}',
                    style: AuraType.sans(11.5, onDark.withValues(alpha: 0.55))),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}
