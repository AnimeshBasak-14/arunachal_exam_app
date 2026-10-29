import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/services/wiki_service.dart';
import '../../../core/theme/aura.dart';
import '../../../core/utils/links.dart';
import '../../../core/widgets/aura/aura_widgets.dart';
import '../../../data/gk_places.dart';

/// Google Maps, styled to the app palette. Google draws India's official
/// boundaries for users in India. The API key comes from MAPS_API_KEY in
/// android/local.properties (Android) and ios/Flutter/Secrets.xcconfig (iOS).
final _outlineProvider = FutureProvider<List<List<LatLng>>>((ref) async {
  final raw = await rootBundle.loadString('assets/map/arunachal_outline.json');
  final rings = (jsonDecode(raw)['rings'] as List).cast<List>();
  return [
    for (final r in rings)
      [
        for (final p in r.cast<List>())
          LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble())
      ]
  ];
});

String _mapStyle(Aura a, bool dark) {
  String hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
  final land = dark ? '#0b1415' : '#f0f4f8';
  final water = dark ? '#16292c' : '#d2dde0';
  final road = dark ? '#1c2e31' : '#ffffff';
  Map<String, Object> rule(String? feature, String? element,
          List<Map<String, Object>> stylers) =>
      {
        if (feature != null) 'featureType': feature,
        if (element != null) 'elementType': element,
        'stylers': stylers,
      };
  return jsonEncode([
    rule(null, 'geometry', [
      {'color': land}
    ]),
    rule(null, 'labels.icon', [
      {'visibility': 'off'}
    ]),
    rule(null, 'labels.text.fill', [
      {'color': hex(a.inkMuted)}
    ]),
    rule(null, 'labels.text.stroke', [
      {'color': land}
    ]),
    rule('water', 'geometry', [
      {'color': water}
    ]),
    rule('road', 'geometry', [
      {'color': road}
    ]),
    rule('road', 'labels', [
      {'visibility': 'off'}
    ]),
    rule('poi', null, [
      {'visibility': 'off'}
    ]),
    rule('transit', null, [
      {'visibility': 'off'}
    ]),
    rule('landscape.natural.terrain', 'geometry', [
      {'color': dark ? '#0e1a1c' : '#e6ece9'}
    ]),
    rule('administrative.country', 'geometry.stroke', [
      {'color': hex(a.inkFaint)},
      {'weight': 1}
    ]),
    rule('administrative.province', 'geometry.stroke', [
      {'color': hex(a.inkFaint)},
      {'weight': 0.6}
    ]),
  ]);
}

class GkMapScreen extends ConsumerStatefulWidget {
  const GkMapScreen({super.key});

  @override
  ConsumerState<GkMapScreen> createState() => _GkMapScreenState();
}

class _GkMapScreenState extends ConsumerState<GkMapScreen> {
  static const _home = LatLng(27.95, 94.45);
  static const _homeZoom = 6.4;

  GoogleMapController? _map;
  double _zoom = _homeZoom;
  final _rng = math.Random();
  final _icons = <String, BitmapDescriptor>{};
  final _drawing = <String>{};
  PlaceKind? _kind;
  GkPlace? _selected;

  // "Find it" game: tap the right marker for the named place.
  GkPlace? _target;
  GkPlace? _missed;
  int _score = 0, _rounds = 0;

  List<GkPlace> get _visible => _kind == null
      ? gkPlaces
      : gkPlaces.where((p) => p.kind == _kind).toList();

  void _move(LatLng to, double zoom) =>
      _map?.animateCamera(CameraUpdate.newLatLngZoom(to, zoom));

  void _tap(GkPlace p) {
    HapticFeedback.selectionClick();
    if (_target != null) {
      final right = p == _target;
      setState(() {
        _rounds++;
        if (right) {
          _score++;
          _missed = null;
        } else {
          _missed = _target;
        }
        _selected = _target;
      });
      right ? HapticFeedback.mediumImpact() : HapticFeedback.heavyImpact();
      _move(LatLng(_target!.lat, _target!.lng), math.max(_zoom, 7));
      return;
    }
    setState(() => _selected = p);
    _move(LatLng(p.lat, p.lng), math.max(_zoom, 7.2));
  }

  void _nextTarget() {
    final pool = _visible.where((p) => p != _target).toList();
    setState(() {
      _target = pool[_rng.nextInt(pool.length)];
      _selected = null;
      _missed = null;
    });
    _move(_home, _homeZoom);
  }

  void _toggleGame() {
    if (_target != null) {
      setState(() {
        _target = null;
        _missed = null;
        _score = 0;
        _rounds = 0;
      });
    } else {
      _nextTarget();
    }
  }

  /// Round dot markers, drawn once per colour and size, then cached.
  BitmapDescriptor _icon(
      Color fill, Color ring, double size, double ringWidth) {
    final key = '${fill.toARGB32()}-${ring.toARGB32()}-$size-$ringWidth';
    final cached = _icons[key];
    if (cached != null) return cached;
    if (_drawing.add(key)) _drawIcon(key, fill, ring, size, ringWidth);
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
  }

  Future<void> _drawIcon(
      String key, Color fill, Color ring, double size, double ringWidth) async {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final px = (size + ringWidth * 2 + 6) * dpr;
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    final center = Offset(px / 2, px / 2);
    final r = size * dpr / 2;
    c.drawCircle(
        center + Offset(0, dpr),
        r + ringWidth * dpr,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.22)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1.5 * dpr));
    c.drawCircle(center, r + ringWidth * dpr, Paint()..color = ring);
    c.drawCircle(center, r, Paint()..color = fill);
    final img = await rec.endRecording().toImage(px.ceil(), px.ceil());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null || !mounted) return;
    setState(() => _icons[key] = BitmapDescriptor.bytes(
        bytes.buffer.asUint8List(),
        imagePixelRatio: dpr));
  }

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final outline = ref.watch(_outlineProvider).value;
    final revealed = _target == null || _selected != null;
    final top = MediaQuery.paddingOf(context).top;

    final markers = <Marker>{
      for (final p in _visible)
        Marker(
          markerId: MarkerId(p.wiki),
          position: LatLng(p.lat, p.lng),
          anchor: const Offset(0.5, 0.5),
          zIndexInt: p == _selected ? 2 : 1,
          consumeTapEvents: true,
          onTap: () => _tap(p),
          icon: _icon(
            revealed ? _kindColor(context, p.kind) : a.inkMuted,
            p == _missed ? a.danger : a.surfaceSolid,
            p == _selected ? 20 : (p.kind == PlaceKind.capital ? 15 : 12),
            p == _selected || p == _missed ? 3 : 2,
          ),
        ),
    };

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition:
                const CameraPosition(target: _home, zoom: _homeZoom),
            style: _mapStyle(a, dark),
            onMapCreated: (c) => _map = c,
            onCameraMove: (p) => _zoom = p.zoom,
            onTap: (_) => setState(() => _selected = null),
            minMaxZoomPreference: const MinMaxZoomPreference(2, 15),
            rotateGesturesEnabled: false,
            tiltGesturesEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            myLocationButtonEnabled: false,
            compassEnabled: false,
            padding: EdgeInsets.only(
                top: top + 100,
                bottom: MediaQuery.paddingOf(context).bottom + 8),
            gestureRecognizers: {
              Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new)
            },
            markers: markers,
            polygons: {
              if (outline != null) ...{
                // Dim the rest of the world so Arunachal stands out.
                Polygon(
                  polygonId: const PolygonId('world'),
                  points: const [
                    LatLng(85, -179.9),
                    LatLng(85, 0),
                    LatLng(85, 179.9),
                    LatLng(-85, 179.9),
                    LatLng(-85, 0),
                    LatLng(-85, -179.9),
                  ],
                  holes: outline,
                  fillColor: a.bg.withValues(alpha: dark ? 0.55 : 0.45),
                  strokeWidth: 0,
                ),
                for (int i = 0; i < outline.length; i++)
                  Polygon(
                    polygonId: PolygonId('ap$i'),
                    points: outline[i],
                    fillColor: a.accent.withValues(alpha: 0.03),
                    strokeColor: a.accent,
                    strokeWidth: 2,
                  ),
              },
            },
          ),
          // Top bar: back, filters, game toggle.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    _RoundButton(
                        icon: CupertinoIcons.back,
                        tooltip: 'Back',
                        onTap: () => context.pop()),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text('Arunachal on the map',
                            style: AuraType.serif(19, a.ink))),
                    _RoundButton(
                      icon: CupertinoIcons.scope,
                      tooltip: 'Back to Arunachal',
                      onTap: () => _move(_home, _homeZoom),
                    ),
                    const SizedBox(width: 8),
                    _RoundButton(
                      icon: _target == null
                          ? CupertinoIcons.game_controller
                          : CupertinoIcons.xmark,
                      tooltip: _target == null ? 'Play Find it' : 'Stop game',
                      highlighted: _target != null,
                      onTap: _toggleGame,
                    ),
                  ]),
                  const SizedBox(height: 10),
                  MediaQuery.withClampedTextScaling(
                    maxScaleFactor: 1.15,
                    child: SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _FilterChip('All', _kind == null,
                              () => setState(() => _kind = null)),
                          for (final k in PlaceKind.values)
                            _FilterChip(k.label, _kind == k,
                                () => setState(() => _kind = k),
                                color: _kindColor(context, k)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_target != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16 + MediaQuery.paddingOf(context).bottom,
              child: _GameCard(
                target: _target!,
                answered: _selected != null,
                correct: _selected != null && _missed == null,
                score: _score,
                rounds: _rounds,
                onNext: _nextTarget,
              ),
            )
          else if (_selected != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: _PlaceSheet(
                key: ValueKey(_selected!.wiki),
                place: _selected!,
                onClose: () => setState(() => _selected = null),
              ),
            ),
        ],
      ),
    );
  }
}

Color _kindColor(BuildContext context, PlaceKind k) {
  final a = context.aura;
  return switch (k) {
    PlaceKind.capital => a.danger,
    PlaceKind.district => a.accent,
    PlaceKind.heritage => a.review,
    PlaceKind.nature => const Color(0xFF2F6B55),
    PlaceKind.border => a.inkMuted,
    PlaceKind.water => a.info,
  };
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool highlighted;
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return Material(
      color: highlighted ? a.accent : a.surfaceSolid,
      shape: CircleBorder(side: BorderSide(color: a.hairline)),
      elevation: 0,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        icon: Icon(icon, size: 20, color: highlighted ? a.onAccent : a.ink),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;
  const _FilterChip(this.label, this.selected, this.onTap, {this.color});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? a.accent : a.surfaceSolid,
        shape: StadiumBorder(side: BorderSide(color: a.hairline)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(children: [
              if (color != null) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 7),
              ],
              Text(label,
                  style: AuraType.sans(12.5, selected ? a.onAccent : a.ink,
                      weight: FontWeight.w600)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final GkPlace target;
  final bool answered, correct;
  final int score, rounds;
  final VoidCallback onNext;
  const _GameCard({
    required this.target,
    required this.answered,
    required this.correct,
    required this.score,
    required this.rounds,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return GlassCard(
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Expanded(
                child: Eyebrow(
                    answered
                        ? (correct ? 'Correct' : 'Not quite')
                        : 'Find it on the map',
                    color: answered
                        ? (correct ? const Color(0xFF2F6B55) : a.danger)
                        : a.inkFaint)),
            Text('$score / $rounds', style: AuraType.digits(14, a.ink)),
          ]),
          const SizedBox(height: 6),
          Text(target.name, style: AuraType.serif(22, a.ink)),
          if (answered) ...[
            const SizedBox(height: 6),
            Text(target.facts.first,
                style: AuraType.sans(13.5, a.inkMuted, height: 1.45)),
            const SizedBox(height: 12),
            FilledButton(onPressed: onNext, child: const Text('Next place')),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('${target.kind.label} · tap its marker',
                  style: AuraType.sans(13, a.inkFaint)),
            ),
        ],
      ),
    );
  }
}

class _PlaceSheet extends ConsumerWidget {
  final GkPlace place;
  final VoidCallback onClose;
  const _PlaceSheet({super.key, required this.place, required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = context.aura;
    final wiki = ref.watch(wikiSummaryProvider(place.wiki));
    final w = wiki.value;
    final maxH = MediaQuery.sizeOf(context).height * 0.58;

    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      margin: EdgeInsets.fromLTRB(
          10, 0, 10, 10 + MediaQuery.paddingOf(context).bottom),
      decoration: BoxDecoration(
        color: a.surfaceSolid,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: a.hairline),
        boxShadow: a.elevatedShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (w?.imageUrl != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(w!.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => ColoredBox(color: a.bgTint)),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Eyebrow('${place.kind.label} · ${place.district}',
                            color: _kindColor(context, place.kind)),
                        const SizedBox(height: 4),
                        Text(place.name, style: AuraType.serif(22, a.ink)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: onClose,
                    icon: const Icon(CupertinoIcons.xmark, size: 18),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final f in place.facts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 7, right: 10),
                            child: Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                    color: a.accent, shape: BoxShape.circle)),
                          ),
                          Expanded(
                            child: Text(f,
                                style:
                                    AuraType.sans(14.5, a.ink, height: 1.45)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (wiki.isLoading)
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: SkeletonBox(height: 60),
              )
            else if (w != null && w.extract.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(color: a.hairline),
                    const SizedBox(height: 10),
                    Text(w.extract,
                        style: AuraType.sans(13.5, a.inkMuted, height: 1.55)),
                    TextButton.icon(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      onPressed: () => openLink(context, w.pageUrl),
                      icon: const Icon(CupertinoIcons.arrow_up_right, size: 14),
                      label: Text('Wikipedia · CC BY-SA',
                          style: AuraType.sans(12.5, a.accent,
                              weight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
