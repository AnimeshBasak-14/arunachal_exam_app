import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/aura.dart';
import '../../../core/utils/links.dart';
import '../../../core/widgets/net_photo.dart';
import '../../../data/chapter_photos.dart';

/// Originals narrower than this are shown small rather than stretched.
const _smallOriginal = 700;

/// Physical pixels needed to fill [logical] points on this screen.
int _px(BuildContext context, double logical) =>
    (logical * MediaQuery.devicePixelRatioOf(context)).ceil();

bool _isSmall(ChapterPhoto p) =>
    p.width < _smallOriginal && !p.path.toLowerCase().endsWith('.svg');

/// Photos placed inside an article. One photo is shown full width; several
/// at the same spot become a swipeable row. [all] is every photo of the
/// page, so the viewer can swipe through them all.
class ArticlePhotos extends StatelessWidget {
  final List<ChapterPhoto> photos;
  final List<ChapterPhoto> all;
  const ArticlePhotos({super.key, required this.photos, required this.all});

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) return const SizedBox.shrink();
    void open(ChapterPhoto p) => openPhotoViewer(context, all, all.indexOf(p));
    if (photos.length == 1) {
      final p = photos.first;
      return Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 22),
        child: _isSmall(p)
            ? _CompactPhoto(photo: p, onOpen: () => open(p))
            : _WidePhoto(photo: p, onOpen: () => open(p)),
      );
    }
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.4);
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 22),
      child: SizedBox(
        // Image 180 + caption (2 lines) + credit (2 lines), scaled with text.
        height: 180 + 92 * scale,
        child: ListView.separated(
          clipBehavior: Clip.none,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: photos.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) => SizedBox(
            width: 260,
            child: _Captioned(
              photo: photos[i],
              onOpen: () => open(photos[i]),
              image: _Frame(
                height: 180,
                photo: photos[i],
                fit: _isSmall(photos[i]) ? BoxFit.contain : BoxFit.cover,
                decode: _px(context, 260),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens the full-screen viewer at [start].
void openPhotoViewer(
    BuildContext context, List<ChapterPhoto> photos, int start) {
  Navigator.of(context).push(PageRouteBuilder<void>(
    opaque: false,
    barrierColor: Colors.black,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (_, __, ___) =>
        PhotoViewer(photos: photos, start: math.max(0, start)),
    transitionsBuilder: (_, anim, __, child) =>
        FadeTransition(opacity: anim, child: child),
  ));
}

/// "Photo: author · licence", linking to the Commons page.
class PhotoCredit extends StatelessWidget {
  final ChapterPhoto photo;
  final Color? color;
  const PhotoCredit(this.photo, {super.key, this.color});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => openLink(context, photo.page),
        child: Text('Photo: ${photo.author} · ${photo.license}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style:
                AuraType.sans(11, color ?? context.aura.inkFaint, height: 1.3)),
      );
}

class _Frame extends StatelessWidget {
  final ChapterPhoto photo;
  final double? height;
  final double? aspect;
  final BoxFit fit;
  final int decode;
  const _Frame({
    required this.photo,
    required this.decode,
    this.height,
    this.aspect,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final img = ColoredBox(
      color: context.aura.bgTint,
      child: NetPhoto(photo.url(decode), fit: fit, decodeWidth: decode),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(AuraSpace.radiusS),
      child: aspect != null
          ? AspectRatio(aspectRatio: aspect!, child: img)
          : SizedBox(height: height, width: double.infinity, child: img),
    );
  }
}

class _Captioned extends StatelessWidget {
  final ChapterPhoto photo;
  final Widget image;
  final VoidCallback onOpen;
  const _Captioned(
      {required this.photo, required this.image, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          label: 'Enlarge picture: ${photo.caption}',
          excludeSemantics: true,
          child: GestureDetector(onTap: onOpen, child: image),
        ),
        const SizedBox(height: 8),
        Text(photo.caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AuraType.sans(13.5, a.ink,
                weight: FontWeight.w500, height: 1.3)),
        const SizedBox(height: 2),
        PhotoCredit(photo),
      ],
    );
  }
}

class _WidePhoto extends StatelessWidget {
  final ChapterPhoto photo;
  final VoidCallback onOpen;
  const _WidePhoto({required this.photo, required this.onOpen});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, c) => _Captioned(
          photo: photo,
          onOpen: onOpen,
          image: _Frame(
            photo: photo,
            aspect: 3 / 2,
            decode: _px(context, c.maxWidth),
          ),
        ),
      );
}

/// Small originals (old portraits, tiny diagrams): thumbnail beside the
/// caption, so they are never blown up into a blur.
class _CompactPhoto extends StatelessWidget {
  final ChapterPhoto photo;
  final VoidCallback onOpen;
  const _CompactPhoto({required this.photo, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Semantics(
        button: true,
        label: 'Enlarge picture: ${photo.caption}',
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onOpen,
          child: SizedBox(
            width: 104,
            child:
                _Frame(photo: photo, aspect: 4 / 5, decode: _px(context, 104)),
          ),
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(top: 4),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(photo.caption,
                style: AuraType.sans(14.5, a.ink,
                    weight: FontWeight.w500, height: 1.35)),
            const SizedBox(height: 4),
            PhotoCredit(photo),
          ]),
        ),
      ),
    ]);
  }
}

/// Full-screen photos: swipe between them, pinch to zoom. Shows the quick
/// copy at once and swaps in the sharpest one (up to 3840 px) when it lands.
class PhotoViewer extends StatefulWidget {
  final List<ChapterPhoto> photos;
  final int start;
  const PhotoViewer({super.key, required this.photos, required this.start});

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
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
    final screen = _px(context, MediaQuery.sizeOf(context).longestSide);
    // Room to zoom in without decoding a 40 MB bitmap.
    final decode = math.min(3840, (screen * 1.6).ceil());
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        PageView.builder(
          controller: _controller,
          itemCount: widget.photos.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (_, i) {
            final ph = widget.photos[i];
            return InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: Center(
                child: NetPhoto(
                  ph.url(3840),
                  fit: BoxFit.contain,
                  decodeWidth: decode,
                  // The quick copy the page already showed, from the cache.
                  placeholder: Stack(fit: StackFit.expand, children: [
                    NetPhoto(ph.url(960),
                        fit: BoxFit.contain,
                        decodeWidth: 960,
                        placeholder: const SizedBox.shrink()),
                    const Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 160),
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: onDark),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            );
          },
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
                20, 36, 20, 20 + MediaQuery.paddingOf(context).bottom),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xDD000000)],
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
                if (widget.photos.length > 1)
                  Text('${_index + 1} of ${widget.photos.length}',
                      style:
                          AuraType.sans(11.5, onDark.withValues(alpha: 0.55))),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}
