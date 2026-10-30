import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import '../theme/aura.dart';

/// Wikimedia asks apps to identify themselves; anonymous clients are
/// throttled first.
const photoHeaders = {
  // Add the app's website here once it exists (Wikimedia's UA policy).
  'User-Agent': 'Dawnlit/1.0 (com.zap.dawnlit; study app by ZAP)',
};

/// Photos stay on the phone for 90 days. At most three download at once:
/// Wikimedia answers bursts with "429 Too Many Requests", which used to
/// leave photos blank.
final photoCache = CacheManager(Config(
  'dawnlit_photos',
  stalePeriod: const Duration(days: 90),
  maxNrOfCacheObjects: 800,
  fileService: HttpFileService()..concurrentFetches = 3,
));

/// Widget tests have no network or disk plugins.
final bool _inTest =
    !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

/// A network photo that is kept on the phone after the first view and
/// retries on its own when a download fails, instead of staying blank.
class NetPhoto extends StatefulWidget {
  final String url;
  final BoxFit fit;

  /// Decode at this width (physical pixels) to save memory.
  final int? decodeWidth;

  /// Shown while loading. Defaults to a shimmer box.
  final Widget? placeholder;
  const NetPhoto(
    this.url, {
    super.key,
    this.fit = BoxFit.cover,
    this.decodeWidth,
    this.placeholder,
  });

  @override
  State<NetPhoto> createState() => _NetPhotoState();
}

class _NetPhotoState extends State<NetPhoto> {
  static const _maxAttempts = 6;
  static final _jitter = math.Random();
  int _attempt = 0;
  Timer? _retry;

  @override
  void didUpdateWidget(NetPhoto old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) {
      _retry?.cancel();
      _attempt = 0;
    }
  }

  @override
  void dispose() {
    _retry?.cancel();
    super.dispose();
  }

  void _again() {
    _retry?.cancel();
    CachedNetworkImage.evictFromCache(widget.url, cacheManager: photoCache);
    if (mounted) setState(() => _attempt++);
  }

  Widget _failed(BuildContext context) {
    // Back off 1.5, 3, 6, 12, 24 s (plus a little jitter so photos on the
    // same page don't retry together), then wait for a tap.
    if (_attempt < _maxAttempts - 1 && !(_retry?.isActive ?? false)) {
      final ms = 1500 * (1 << _attempt) + _jitter.nextInt(700);
      _retry = Timer(Duration(milliseconds: ms), _again);
    }
    final a = context.aura;
    return GestureDetector(
      onTap: _again,
      child: ColoredBox(
        color: a.bgTint,
        child: Center(
          child: Icon(
            _attempt >= _maxAttempts - 1
                ? CupertinoIcons.arrow_clockwise
                : CupertinoIcons.photo,
            color: a.inkFaint,
            size: 26,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loading = widget.placeholder ??
        ColoredBox(color: context.aura.hairline.withValues(alpha: 0.6));
    if (_inTest) {
      return Image.network(widget.url,
          fit: widget.fit, errorBuilder: (_, __, ___) => loading);
    }
    return CachedNetworkImage(
      key: ValueKey('${widget.url}#$_attempt'),
      imageUrl: widget.url,
      cacheManager: photoCache,
      httpHeaders: photoHeaders,
      fit: widget.fit,
      memCacheWidth: widget.decodeWidth,
      filterQuality: FilterQuality.medium,
      fadeInDuration: const Duration(milliseconds: 220),
      fadeOutDuration: const Duration(milliseconds: 120),
      placeholder: (_, __) => loading,
      errorWidget: (context, _, __) => _failed(context),
    );
  }
}
